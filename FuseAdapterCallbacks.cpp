// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#if 0

#include "FuseAdapter.h"
#include "FuseDebug.h"

// REMOVE ASAP
static const char* file_name = "hello.txt";
static const char* file_content = "Hello from FUSE!\n";

int
FuseAdapter::getattr(const char* path, struct stat* st)
{
    return self()._getattr(path, st);
}

int
FuseAdapter::_getattr(const char* path, struct stat* st)
{
    memset(st, 0, sizeof(*st));

    if (strcmp(path, "/") == 0) {
        st->st_mode = S_IFDIR | 0755;
        st->st_nlink = 1;
        return 0;
    }

    if (strcmp(path+1, file_name) == 0) {
        st->st_mode = S_IFREG | 0444;
        st->st_nlink = 1;
        st->st_size = strlen(file_content);
        return 0;
    }

    return -ENOENT;
}

/*
int
FuseAdapter::readlink(const char* path, char* buf, size_t size)
{
    return self()._readlink(path, buf, size);
}

int
FuseAdapter::_readlink(const char* path, char* buf, size_t size)
{
    return 0;
}

int
FuseAdapter::mkdir(const char* path, mode_t mode)
{
    return self()._mkdir(path, mode);
}

int
FuseAdapter::_mkdir(const char* path, mode_t mode)
{
    return 0;
}

int
FuseAdapter::unlink(const char* path)
{
    return self()._unlink(path);
}

int
FuseAdapter::_unlink(const char* path)
{
    return 0;
}

int
FuseAdapter::rmdir(const char* path)
{
    return self()._rmdir(path);
}

int
FuseAdapter::_rmdir(const char* path)
{
    return 0;
}

int
FuseAdapter::rename(const char* oldpath, const char* newpath)
{
    return self()._rename(oldpath, newpath);
}

int
FuseAdapter::_rename(const char* oldpath, const char* newpath)
{
    return 0;
}

int
FuseAdapter::chmod(const char* path, mode_t mode)
{
    return self()._chmod(path, mode);
}

int
FuseAdapter::_chmod(const char* path, mode_t mode)
{
    return 0;
}

int
FuseAdapter::chown(const char* path, uid_t uid, gid_t gid)
{
    return self()._chown(path, uid, gid);
}

int
FuseAdapter::_chown(const char* path, uid_t uid, gid_t gid)
{
    return 0;
}

int
FuseAdapter::truncate(const char* path, off_t size)
{
    return self()._truncate(path, size);
}

int
FuseAdapter::_truncate(const char* path, off_t size)
{
    return 0;
}
*/

int
FuseAdapter::open(const char* path, struct fuse_file_info* fi)
{
    return self()._open(path, fi);
}

int
FuseAdapter::_open(const char* path, struct fuse_file_info* fi)
{
    if (strcmp(path + 1, file_name) != 0)
        return -ENOENT;

    return 0;   // success
}

int
FuseAdapter::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return self()._read(path, buf, size, offset, fi);
}

int
FuseAdapter::_read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    size_t len = strlen(file_content);
    if (strcmp(path + 1, "hello.txt") != 0)
        return -ENOENT;
    if (offset >= len)
        return 0;
    size_t to_copy = size < len - offset ? size : len - offset;
    memcpy(buf, file_content + offset, to_copy);
    return (int)to_copy;
}

/*
int
FuseAdapter::write(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return self()._write(path, buf, size, offset, fi);
}

int
FuseAdapter::_write(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return 0;
}

int
FuseAdapter::statfs(const char* path, struct statvfs* st)
{
    return self()._statfs(path, st);
}

int
FuseAdapter::_statfs(const char* path, struct statvfs* st)
{
    return 0;
}
*/

int
FuseAdapter::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
               off_t offset, struct fuse_file_info* fi)
{
    return self()._readdir(path, buf, filler, offset, fi);
}

int
FuseAdapter::_readdir(const char* path, void* buf, fuse_fill_dir_t filler,
               off_t offset, struct fuse_file_info* fi)
{
    if (strcmp(path, "/") != 0)
        return -ENOENT;

    filler(buf, ".",  NULL, 0);
    filler(buf, "..", NULL, 0);
    filler(buf, file_name, NULL, 0);

    return 0;
}

void *
FuseAdapter::init(struct fuse_conn_info* conn)
{
    return self()._init(conn);
}

void *
FuseAdapter::_init(struct fuse_conn_info* conn)
{
    log([conn](std::ostream &os){ dump(os, conn); });

    return this;
}

/*
void
FuseAdapter::destroy(void* private_data)
{
    return self()._destroy(private_data);
}

void
FuseAdapter::_destroy(void* private_data)
{

}

int
FuseAdapter::access(const char* path, int mask)
{
    return self()._access(path, mask);
}

int
FuseAdapter::_access(const char* path, int mask)
{
    return 0;
}

int
FuseAdapter::create(const char* path, mode_t mode, struct fuse_file_info* fi)
{
    return self()._create(path, mode, fi);
}

int
FuseAdapter::_create(const char* path, mode_t mode, struct fuse_file_info* fi)
{
    return 0;
}

int
FuseAdapter::utimens(const char* path, const struct timespec tv[2])
{
    return self()._utimens(path, tv);
}

int
FuseAdapter::_utimens(const char* path, const struct timespec tv[2])
{
    return 0;
}
*/

#endif
