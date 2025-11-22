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
#include "MutableFileSystem.h"
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

    log("Extracting file system...\n");
    fs = new MutableFileSystem(*adf);
    assert(fs != nullptr);
}

int
AmigaFileSystem::mount(string &mountpoint)
{
    FuseAdapter adapter;

    adapter.delegate = this;
    printf("adapter.delegate = %p\n", adapter.delegate);
    auto err = adapter.mount(mountpoint);

    assert(false);
    return err;
}

int
AmigaFileSystem::getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

    return fsexec([&]{

        // TODO: The code below should already cover this case. Remove this
        if (strcmp(path, "/") == 0) {
            st->st_mode  = S_IFDIR | 0755;
            st->st_nlink = 1;
            return 0;
        }

        auto &node = fs->seek(fs->root(), string(path));
        auto size = node.getFileSize();
        // auto prot = node.getProtectionBits();
        auto dir  = node.isDirectory();

        st->st_mode  = dir ? (S_IFDIR | 0755) : (S_IFREG | 0644);
        st->st_nlink = 1;
        st->st_size  = size;
        return 0;
    });
}

int
AmigaFileSystem::mkdir(const char *path, mode_t mode)
{
    auto fullpath = fs::path(path);
    auto parent   = fullpath.parent_path();
    auto name     = fullpath.filename();

    return fsexec([&]{

        auto &node = fs->seek(fs->root(), parent);
        fs->createDir(node, name);
        return 0;
    });
}

int
AmigaFileSystem::rmdir(const char *path)
{
    auto fullpath = fs::path(path);
    auto parent   = fullpath.parent_path();
    auto name     = fullpath.filename();

    return fsexec([&]{

        // Seek the parent directory
        auto &node = fs->seek(fs->root(), parent);
        if (!node.isDirectory()) throw AppError(Fault::FS_NOT_A_DIRECTORY);

        // Remove the directory
        fs->deleteFile(node);
        return 0;
    });
}

int
AmigaFileSystem::rename(const char *oldpath, const char *newpath)
{
    /*
    auto fullpath = fs::path(path);
    auto parent   = fullpath.parent_path();
    auto name     = fullpath.filename();
    */

    // TODO: THIS FUNCTION WILL LIKELY NOT WORK
    // What happens if new path is at a different location?
    // The fs->rename function cannot handle that.
    // TODO: ADD rename(node, fs::path) which internally can call MOVE?!

    return fsexec([&]{

        // Seek the item to rename
        auto &node = fs->seek(fs->root(), string(oldpath));

        // Rename it
        fs->rename(node, newpath);
        return 0;
    });
}

int
AmigaFileSystem::open(const char *path, struct fuse_file_info *fi)
{
    if (auto *node = fs->seekPtr(&fs->root(), string(path)); node) {

        return 0;
    }
    
    return -ENOENT;
}

int
AmigaFileSystem::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
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
AmigaFileSystem::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                          off_t offset, struct fuse_file_info* fi)
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
AmigaFileSystem::init(struct fuse_conn_info* conn)
{
    log([conn](std::ostream &os){ dump(os, conn); });
    return this;
}
