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
#include "FuseDevice.h"
#include "FuseDebug.h"
#include "FileSystems/Amiga/PosixAdapter.h"
#include "FileSystems/Amiga/FileSystem.h"
#include "FileSystems/CBM/PosixAdapter.h"
#include "FileSystems/CBM/FileSystem.h"

using namespace retro::vault;

FuseVolume::FuseVolume(class FuseDevice &d, unique_ptr<Volume> v) :
device(d), vol(std::move(v))
{
    
}

FuseAmigaVolume::FuseAmigaVolume(FuseDevice &d, unique_ptr<Volume> v) : FuseVolume(d, std::move(v))
{
    mylog("Creating Amiga file system...\n");
    fs = std::make_unique<amiga::FileSystem>(*vol);

    std::stringstream ss;
    fs->dumpInfo(ss);
    std::cout << ss.str();

    mylog("Wrapping into API layer...\n");
    dos = std::make_unique<amiga::PosixAdapter>(*this->fs);
}

FuseCBMVolume::FuseCBMVolume(class FuseDevice &d, unique_ptr<Volume> v) : FuseVolume(d, std::move(v))
{
    mylog("Creating CBM file system...\n");
    fs = std::make_unique<cbm::FileSystem>(*vol);

    std::stringstream ss;
    fs->dumpStatfs(ss);
    std::cout << ss.str();

    mylog("Wrapping into API layer...\n");
    dos = std::make_unique<cbm::PosixAdapter>(*this->fs);
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

void
FuseVolume::commit()
{
    // Write all dirty blocks back to the image
    flush();
    
    // Write the image back to the image file
    device.image->save(getRange());
}


//
// Amiga volume
//

vector<string>
FuseAmigaVolume::blockTypes() const noexcept
{
    vector<string> result;
    result.reserve(amiga::FSBlockTypeEnum::maxVal);
    for (isize i = 0; i < amiga::FSBlockTypeEnum::maxVal; ++i) {
        result.push_back(string(amiga::FSBlockTypeEnum::help(amiga::FSBlockType(i))));
    }
    return result;
}

string
FuseAmigaVolume::blockType(isize blockNr) const
{
    return amiga::FSBlockTypeEnum::help(fs->typeOf(BlockNr(blockNr)));
}

string
FuseAmigaVolume::typeOf(isize blockNr, isize pos) const
{
    auto type = fs->typeOf(BlockNr(blockNr), pos);
    return amiga::FSItemTypeEnum::key(type);
}

void
FuseAmigaVolume::xray(bool strict)
{
    fs->doctor.xray(strict);
}

const std::vector<BlockNr> &
FuseAmigaVolume::blockErrors() const
{
    return fs->doctor.diagnosis.blockErrors;
}

const std::vector<BlockNr> &
FuseAmigaVolume::usedButUnallocated() const
{
    return fs->doctor.diagnosis.usedButUnallocated;
}
    
const std::vector<BlockNr> &
FuseAmigaVolume::unusedButAllocated() const
{
    return fs->doctor.diagnosis.unusedButAllocated;
}

void
FuseAmigaVolume::createUsageMap(u8 *buf, isize len) const
{
    fs->doctor.createUsageMap(buf, len);
}

void
FuseAmigaVolume::createAllocationMap(u8 *buf, isize len) const
{
    fs->doctor.createAllocationMap(buf, len);
}

void
FuseAmigaVolume::createHealthMap(u8 *buf, isize len) const
{
    fs->doctor.createHealthMap(buf, len);
}


//
// CBM volume
//

vector<string>
FuseCBMVolume::blockTypes() const noexcept
{
    
    vector<string> result;
    result.reserve(cbm::FSBlockTypeEnum::maxVal);
    for (isize i = 0; i < cbm::FSBlockTypeEnum::maxVal; ++i) {
        result.push_back(string(cbm::FSBlockTypeEnum::help(cbm::FSBlockType(i))));
    }
    return result;
}

string
FuseCBMVolume::blockType(isize blockNr) const
{
    return cbm::FSBlockTypeEnum::help(fs->typeOf(BlockNr(blockNr)));
}

string
FuseCBMVolume::typeOf(isize blockNr, isize pos) const
{
    auto type = fs->typeOf(BlockNr(blockNr), pos);
    return cbm::FSItemTypeEnum::key(type);
}

void
FuseCBMVolume::xray(bool strict)
{
    fs->doctor.xray(strict);
}

const std::vector<BlockNr> &
FuseCBMVolume::blockErrors() const
{
    return fs->doctor.diagnosis.blockErrors;
}

const std::vector<BlockNr> &
FuseCBMVolume::usedButUnallocated() const
{
    return fs->doctor.diagnosis.usedButUnallocated;
}
    
const std::vector<BlockNr> &
FuseCBMVolume::unusedButAllocated() const
{
    return fs->doctor.diagnosis.unusedButAllocated;
}

void
FuseCBMVolume::createUsageMap(u8 *buf, isize len) const
{
    fs->doctor.createUsageMap(buf, len);
}

void
FuseCBMVolume::createAllocationMap(u8 *buf, isize len) const
{
    fs->doctor.createAllocationMap(buf, len);
}

void
FuseCBMVolume::createHealthMap(u8 *buf, isize len) const
{
    fs->doctor.createHealthMap(buf, len);
}
