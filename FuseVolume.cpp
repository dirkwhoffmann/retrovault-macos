// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "FuseVolume.h"
#include "FuseDebug.h"
#include "FileSystems/Amiga/FSError.h"
#include "FileSystems/Amiga/PosixAdapter.h"

using namespace retro::vault;

FuseVolume::FuseVolume(unique_ptr<Volume> v) : vol(std::move(v))
{
    
}

FuseAmigaVolume::FuseAmigaVolume(unique_ptr<Volume> v) : FuseVolume(std::move(v))
{
    mylog("Creating file system...\n");    
    fs = std::make_unique<amiga::FileSystem>(*vol);

    std::stringstream ss;
    fs->dumpInfo(ss);
    std::cout << ss.str();

    mylog("Wrapping into DOS layer...\n");
    dos = std::make_unique<amiga::PosixAdapter>(*this->fs);
}

FuseVolume::~FuseVolume()
{
    printf("Destroying FuseVolume\n");
}

int
FuseVolume::getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

    return fsexec([&]{

        auto attr   = dos->attr(path);
        auto create = attr.ctime;
        auto modify = attr.mtime;

        st->st_mode = attr.prot;
        st->st_nlink = 1;
        st->st_size = attr.size;
        st->st_birthtimespec.tv_sec  = create;
        st->st_birthtimespec.tv_nsec = 0;
        st->st_mtimespec.tv_sec      = modify ? modify : create;
        st->st_mtimespec.tv_nsec     = 0;
        st->st_ctimespec.tv_sec      = modify ? modify : create;
        st->st_ctimespec.tv_nsec     = 0;
        st->st_atimespec.tv_sec      = modify ? modify : create;
        st->st_atimespec.tv_nsec     = 0;

        return 0;
    });
}

int
FuseVolume::mkdir(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->mkdir(path);
        return 0;
    });
}

int
FuseVolume::unlink(const char *path)
{
    return fsexec([&]{

        dos->unlink(path);
        return 0;
    });
}

int
FuseVolume::rmdir(const char *path)
{
    return fsexec([&]{

        dos->rmdir(path);
        return 0;
    });
}

int
FuseVolume::rename(const char *oldpath, const char *newpath)
{
    return fsexec([&]{

        dos->move(oldpath, newpath);
        return 0;
    });
}

int
FuseVolume::chmod(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->chmod(path, mode);
        return 0;
    });
}

int
FuseVolume::truncate(const char *path, off_t size)
{
    return fsexec([&]{

        dos->resize(path, size);
        return 0;
    });}

int
FuseVolume::open(const char *path, struct fuse_file_info *fi)
{
    return fsexec([&]{

        fi->fh = (uint64_t)dos->open(path, (u32)fi->flags);
        return 0;
    });
}

int
FuseVolume::read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return fsexec([&]{

        auto count = dos->read(HandleRef(fi->fh), std::span{(u8 *)buf, size});
        return int(count);
    });
}

int
FuseVolume::write(const char *path, const char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
{
    return fsexec([&]{

        auto count = dos->write(HandleRef(fi->fh), std::span{(u8 *)buf, size});
        return int(count);
    });
}

int
FuseVolume::statfs(const char *path, struct statvfs *st)
{
    memset(st, 0, sizeof(*st));

    const auto &stat = dos->stat();
    const auto bsize = (unsigned long)stat.bsize;
    const auto total = (fsblkcnt_t)stat.blocks;
    const auto free  = (fsblkcnt_t)stat.freeBlocks;

    st->f_bsize   = bsize;         // Preferred block size
    st->f_frsize  = bsize;         // Fundamental block size

    st->f_blocks  = total;             // Total data blocks in FS
    st->f_bfree   = free;              // Free blocks
    st->f_bavail  = free;              // Same as bfree (no root user concept)

    st->f_fsid    = 0;                 // Not required — FUSE ignores this
    st->f_flag    = 0;                 // No mount flags
    st->f_namemax = 30;                // Amiga filename limit (OFS/FFS)

    return 0;
}

int
FuseVolume::release(const char *path, struct fuse_file_info *fi)
{
    return fsexec([&]{

        dos->close(HandleRef(fi->fh));
        return 0;
    });
}

int
FuseVolume::readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                          off_t offset, struct fuse_file_info *fi)
{
    return fsexec([&]{

        filler(buf, ".",  NULL, 0);
        filler(buf, "..", NULL, 0);

        for (auto &name : dos->readDir(path)) {
            filler(buf, name.c_str(), NULL, 0);
        }
        return 0;
    });
}

void *
FuseVolume::init(struct fuse_conn_info *conn)
{
    return nullptr;
}

void
FuseVolume::destroy(void *)
{

}

int
FuseVolume::access(const char *path, const int mask)
{
    return -ENOSYS;
}

int
FuseVolume::create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
    return fsexec([&]{

        dos->create(path);
        fi->fh = (uint64_t)dos->open(path, mode);
        return 0;
    });
}

int
FuseVolume::utimens(const char *path, const struct timespec tv[2])
{
    // NOT IMPLEMENTED YET
    return 0;
}

FSPosixStat
FuseVolume::stat()
{
    return dos->stat();
}

