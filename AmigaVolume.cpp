// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "AmigaVolume.h"
#include "Media.h"
#include "PosixFileSystem.h"
#include "FuseDebug.h"

using namespace vamiga;

/*
template <typename Fn>
int fsexec(Fn &&fn)
{
    try {
        return fn();
    } catch (const AppError &err) {
        log("           Error: {} ({})\n", AmigaFileSystem::posixErrno(err), err.what());
        return -AmigaFileSystem::posixErrno(err);
    } catch (...) {
        log("           Exception: {}\n", EIO);
        return -EIO;
    }
}
*/

int
AmigaVolume::posixErrno(const Error &err)
{
    switch (err.payload) {

            // Generic / unknown
        case FSError::FS_UNKNOWN:
        case FSError::FS_UNFORMATTED:
        case FSError::FS_CORRUPTED:
        case FSError::FS_OUT_OF_RANGE:
            return EIO;   // Input/output error

            // Path / lookup related
        case FSError::FS_INVALID_PATH:
        case FSError::FS_INVALID_REGEX:
            return EINVAL; // Invalid argument
        case FSError::FS_NOT_FOUND:
            return ENOENT; // No such file or directory
        case FSError::FS_NOT_A_DIRECTORY:
            return ENOTDIR; // Not a directory
        case FSError::FS_NOT_A_FILE:
            return EISDIR; // Is a directory (attempt to open a directory as file)
        case FSError::FS_NOT_A_FILE_OR_DIRECTORY:
            return EIO;   // Input/output error

            // Existence
        case FSError::FS_EXISTS:
            return EEXIST; // File exists

            // Read/Write permissions or media constraints
        case FSError::FS_READ_ONLY:
            return EROFS; // Read-only filesystem

        case FSError::FS_OUT_OF_SPACE:
            return ENOSPC; // No space left on device

            // Open / create errors
        case FSError::FS_CANNOT_OPEN:
            return EACCES; // Permission denied (best match)
        case FSError::FS_CANNOT_CREATE_DIR:
        case FSError::FS_CANNOT_CREATE_FILE:
            return EIO; // General I/O error (no better POSIX category)

            // Directory constraints
        case FSError::FS_DIR_NOT_EMPTY:
            return ENOTEMPTY; // Directory not empty

            // Unsupported volume / geometry issues (Amiga specific)
        case FSError::FS_UNSUPPORTED:
        case FSError::FS_WRONG_BSIZE:
        case FSError::FS_WRONG_CAPACITY:
        case FSError::FS_WRONG_DOS_TYPE:
        case FSError::FS_WRONG_BLOCK_TYPE:
        case FSError::FS_HAS_CYCLES:
            return EINVAL; // Invalid argument (filesystem mismatch)

        default:
            return EIO; // Safe fallback
    }
}

/*
AmigaVolume::AmigaVolume(const fs::path &filename)
{
    mylog("Trying to load %s...\n", filename.string().c_str());
    adf = new ADFFile(filename);
    assert(adf != nullptr);

    mylog("Extracting raw file system...\n");
    fs = FileSystemFactory::fromADF(*adf);
    assert(fs != nullptr);

    std::stringstream ss;
    fs->dumpInfo(ss);
    std::cout << ss.str();

    mylog("Wrapping into DOS layer...\n");
    dos = std::make_unique<PosixFileSystem>(*fs);
    assert(dos != nullptr);
}
*/

AmigaVolume::AmigaVolume(unique_ptr<Volume> v) : vol(std::move(v))
{
    mylog("Creating file system...\n");
    fs = std::make_unique<FileSystem>(*vol);

    std::stringstream ss;
    fs->dumpInfo(ss);
    std::cout << ss.str();

    mylog("Wrapping into DOS layer...\n");
    dos = std::make_unique<PosixFileSystem>(*this->fs);
}

AmigaVolume::~AmigaVolume()
{
    printf("Destroying AmigaFileSystem\n");
}

int
AmigaVolume::getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

    return fsexec([&]{

        auto attr   = dos->attr(path);
        auto create = attr.ctime.time();
        auto modify = attr.mtime.time();

        st->st_mode = attr.mode();
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
AmigaVolume::mkdir(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->mkdir(path);
        return 0;
    });
}

int
AmigaVolume::unlink(const char *path)
{
    return fsexec([&]{

        dos->unlink(path);
        return 0;
    });
}

int
AmigaVolume::rmdir(const char *path)
{
    return fsexec([&]{

        dos->rmdir(path);
        return 0;
    });
}

int
AmigaVolume::rename(const char *oldpath, const char *newpath)
{
    return fsexec([&]{

        dos->move(oldpath, newpath);
        return 0;
    });
}

int
AmigaVolume::chmod(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->chmod(path, mode);
        return 0;
    });
}

int
AmigaVolume::truncate(const char *path, off_t size)
{
    return fsexec([&]{

        dos->resize(path, size);
        return 0;
    });}

int
AmigaVolume::open(const char *path, struct fuse_file_info *fi)
{
    return fsexec([&]{

        fi->fh = dos->open(path, (u32)fi->flags);
        return 0;
    });
}

int
AmigaVolume::read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return fsexec([&]{

        auto count = dos->read(HandleRef(fi->fh), std::span{(u8 *)buf, size});
        return int(count);
    });
}

int
AmigaVolume::write(const char *path, const char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
{
    return fsexec([&]{

        auto count = dos->write(HandleRef(fi->fh), std::span{(u8 *)buf, size});
        return int(count);
    });
}

int
AmigaVolume::statfs(const char *path, struct statvfs *st)
{
    memset(st, 0, sizeof(*st));

    const auto &stat = dos->stat();
    const auto bsize = (unsigned long)stat.traits.bsize;
    const auto total = (fsblkcnt_t)stat.traits.blocks;
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
AmigaVolume::release(const char *path, struct fuse_file_info *fi)
{
    return fsexec([&]{

        dos->close(fi->fh);
        return 0;
    });
}

int
AmigaVolume::readdir(const char *path, void *buf, fuse_fill_dir_t filler,
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
AmigaVolume::init(struct fuse_conn_info *conn)
{
    return nullptr;
}

void
AmigaVolume::destroy(void *)
{

}

int
AmigaVolume::access(const char *path, const int mask)
{
    return -ENOSYS;
}

int
AmigaVolume::create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
    return fsexec([&]{

        dos->create(path);
        fi->fh = dos->open(path, mode);
        return 0;
    });
}

int
AmigaVolume::utimens(const char *path, const struct timespec tv[2])
{
    // NOT IMPLEMENTED YET
    return 0;
}
