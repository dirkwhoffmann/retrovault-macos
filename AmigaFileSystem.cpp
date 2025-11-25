// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "AmigaFileSystem.h"
#include "VAmiga.h"
#include "Media.h"
#include "DosFileSystem.h"
#include "FuseAdapter.h"
#include "FuseDebug.h"

using namespace vamiga;

template <typename Fn>
int fsexec(Fn &&fn)
{
    try {
        return fn();
    } catch (const AppError &err) {
        return -AmigaFileSystem::posixErrno(err);
    } catch (...) {
        return -EIO;
    }
}

int
AmigaFileSystem::posixErrno(const AppError &err)
{
    switch (Fault(err.data)) {

            // Generic / unknown
        case Fault::FS_UNKNOWN:
        case Fault::FS_UNINITIALIZED:
        case Fault::FS_UNFORMATTED:
        case Fault::FS_CORRUPTED:
        case Fault::FS_OUT_OF_RANGE:
            return EIO;   // Input/output error

            // Path / lookup related
        case Fault::FS_INVALID_PATH:
        case Fault::FS_INVALID_REGEX:
            return EINVAL; // Invalid argument
        case Fault::FS_NOT_FOUND:
            return ENOENT; // No such file or directory
        case Fault::FS_NOT_A_DIRECTORY:
            return ENOTDIR; // Not a directory
        case Fault::FS_NOT_A_FILE:
            return EISDIR; // Is a directory (attempt to open a directory as file)
        case Fault::FS_NOT_A_FILE_OR_DIRECTORY:
            return EIO;   // Input/output error

            // Existence
        case Fault::FS_EXISTS:
            return EEXIST; // File exists

            // Read/Write permissions or media constraints
        case Fault::FS_READ_ONLY:
            return EROFS; // Read-only filesystem

        case Fault::FS_OUT_OF_SPACE:
            return ENOSPC; // No space left on device

            // Open / create errors
        case Fault::FS_CANNOT_OPEN:
            return EACCES; // Permission denied (best match)
        case Fault::FS_CANNOT_CREATE_DIR:
        case Fault::FS_CANNOT_CREATE_FILE:
            return EIO; // General I/O error (no better POSIX category)

            // Directory constraints
        case Fault::FS_DIR_NOT_EMPTY:
            return ENOTEMPTY; // Directory not empty

            // Unsupported volume / geometry issues (Amiga specific)
        case Fault::FS_UNSUPPORTED:
        case Fault::FS_WRONG_BSIZE:
        case Fault::FS_WRONG_CAPACITY:
        case Fault::FS_WRONG_DOS_TYPE:
        case Fault::FS_WRONG_BLOCK_TYPE:
        case Fault::FS_HAS_CYCLES:
            return EINVAL; // Invalid argument (filesystem mismatch)

        default:
            return EIO; // Safe fallback
    }
}

AmigaFileSystem::AmigaFileSystem(string &filename)
{
    log("Trying to load {}...\n", filename.c_str());
    adf = new ADFFile(filename);
    assert(adf != nullptr);

    log("Extracting raw file system...\n");
    fs = new MutableFileSystem(*adf);
    assert(fs != nullptr);

    log("Wrapping into DOS layer...\n");
    dos = new DosFileSystem(*fs);
    assert(dos != nullptr);

}

int
AmigaFileSystem::mount(string &mountpoint)
{
    FuseAdapter adapter;

    adapter.delegate = this;

    // Make a blocking call to mount...
    auto err = adapter.mount(mountpoint);

    return err;
}

int
AmigaFileSystem::getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

    return fsexec([&]{

        auto stat   = dos->getStat(path);
        auto create = stat.ctime.time();
        auto modify = stat.mtime.time();

        st->st_mode = stat.mode();
        st->st_nlink = 1;
        st->st_size = stat.size;
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
AmigaFileSystem::mkdir(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->mkdir(path);
        return 0;
    });
}

int
AmigaFileSystem::unlink(const char *path)
{
    return fsexec([&]{

        dos->unlink(path);
        return 0;
    });
}

int
AmigaFileSystem::rmdir(const char *path)
{
    return fsexec([&]{

        dos->rmdir(path);
        return 0;
    });
}

int
AmigaFileSystem::rename(const char *oldpath, const char *newpath)
{
    return fsexec([&]{

        dos->move(oldpath, newpath);
        return 0;
    });
}

int
AmigaFileSystem::chmod(const char *path, mode_t mode)
{
    return fsexec([&]{

        dos->chmod(path, mode);
        return 0;
    });
}

int
AmigaFileSystem::chown(const char *path, uid_t uid, gid_t gid)
{
    return -ENOENT;
}

int
AmigaFileSystem::truncate(const char *path, off_t size)
{
    return -ENOENT;
}

int
AmigaFileSystem::open(const char *path, struct fuse_file_info *fi)
{
    return fsexec([&]{

        fi->fh = dos->open(path, (u32)fi->flags);
        return 0;
    });
}

int
AmigaFileSystem::read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return fsexec([&]{

        auto &node = fs->seek(fs->root(), string(path));

        // Get data
        Buffer<u8> buffer; node.extractData(buffer);

        // Check if the offset is in range
        if (offset >= buffer.size) return 0;

        // Determine the number of bytes to copy
        auto count = std::min(size, size_t(buffer.size - offset));

        // Copy data
        memcpy(buf, buffer.ptr + offset, count);

        return (int)count;
    });
}

int
AmigaFileSystem::statfs(const char *path, struct statvfs *st)
{
    memset(st, 0, sizeof(*st));

    const auto blockSize = (unsigned long)fs->blockSize();
    const auto total     = (fsblkcnt_t)fs->numBlocks();
    const auto free      = (fsblkcnt_t)fs->freeBlocks();

    st->f_bsize   = blockSize;         // Preferred block size
    st->f_frsize  = blockSize;         // Fundamental block size

    st->f_blocks  = total;             // Total data blocks in FS
    st->f_bfree   = free;              // Free blocks
    st->f_bavail  = free;              // Same as bfree (no root user concept)

    st->f_fsid    = 0;                 // Not required — FUSE ignores this
    st->f_flag    = 0;                 // No mount flags
    st->f_namemax = 30;                // Amiga filename limit (OFS/FFS)

    return 0;
}

int
AmigaFileSystem::readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                          off_t offset, struct fuse_file_info *fi)
{
    return fsexec([&]{

        auto &node = fs->seek(fs->root(), string(path));

        filler(buf, ".",  NULL, 0);
        filler(buf, "..", NULL, 0);

        // Extract the directory tree
        FSTree tree(node, { .recursive = false });

        // Walk the tree
        tree.bfsWalk( [&](const FSTree &it) {

            auto name = it.node->getName();
            printf("File: %s\n", name.c_str());
            filler(buf, name.c_str(), NULL, 0);
        });

        return 0;
    });
}

void *
AmigaFileSystem::init(struct fuse_conn_info *conn)
{
    return nullptr;
}

void
AmigaFileSystem::destroy(void *)
{

}

int
AmigaFileSystem::access(const char *path, const int mask)
{
    return -ENOENT;
}

int
AmigaFileSystem::create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
    return -ENOENT;
}

int
AmigaFileSystem::utimens(const char *path, const struct timespec tv[2])
{
    // NOT IMPLEMENTED YET
    return 0;
}
