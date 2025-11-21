// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"

/*
// File system object attributes
// typedef int (t_getattr) (const char *, struct stat *);
using t_getattr = int(const char *, struct stat *);
typedef int (t_readlink) (const char *, char *, size_t);

// Directory operations
typedef int (t_mknod) (const char *, mode_t, dev_t);
typedef int (*t_mkdir) (const char *, mode_t);
typedef int (*t_unlink) (const char *);
typedef int (*t_rmdir) (const char *);
typedef int (*t_symlink) (const char *, const char *);
typedef int (*t_rename) (const char *, const char *);
typedef int (*t_link) (const char *, const char *);
typedef int (*t_chmod) (const char *, mode_t);
typedef int (*t_chown) (const char *, uid_t, gid_t);
typedef int (*t_truncate) (const char *, off_t);
typedef int (*t_utime) (const char *, struct utimbuf *);

// File operations
typedef int (*t_open) (const char *, struct fuse_file_info *);
typedef int (*t_read) (const char *, char *, size_t, off_t, struct fuse_file_info *);
typedef int (*t_write) (const char *, const char *, size_t, off_t, struct fuse_file_info *);
typedef int (*t_statfs) (const char *, struct statvfs *, struct fuse_file_info *);
typedef int (*t_flush) (const char *, struct fuse_file_info *);
typedef int (*t_release) (const char *, struct fuse_file_info *);
typedef int (*t_fsync) (const char *, int, struct fuse_file_info *);

// Extended attributes
typedef int (*t_setxattr) (const char *, const char *, const char *, size_t, uint32_t);
typedef int (*t_getxattr) (const char *, const char *, char *, size_t, uint32_t);
typedef int (*t_listxattr) (const char *, char *, size_t);
typedef int (*t_removexattr) (const char *, const char *);

// Directory iteration
typedef int (*t_opendir) (const char *, struct fuse_file_info *);
typedef int (*t_readdir) (const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *);
typedef int (*t_releasedir) (const char *, struct fuse_file_info *fi);
typedef int (*t_fsyncdir) (const char *, int, struct fuse_file_info *);

// Lifecycle
typedef void* (*t_init) (struct fuse_conn_info *, struct fuse_config *);
typedef void (*t_destroy) (void *);

// Access control
typedef int (*t_access) (const char *, int);

// File creation and manipulation
typedef int (*t_create) (const char *, mode_t, struct fuse_file_info *);
typedef int (*t_ftruncate) (const char *, off_t, struct fuse_file_info *);
typedef int (*t_fgetattr) (const char *, struct stat *, struct fuse_file_info *);

// File locking
typedef int (*t_lock) (const char *, struct fuse_file_info *, int, struct flock *);

// Extended create op
typedef int (*t_setvolname) (const char *volname);
typedef int (*t_getvolname) (char *volname, size_t size);

// IOCTL
typedef int (*t_ioctl) (const char *, int, void *, struct fuse_file_info *, unsigned int, void *);

// Polling
typedef int (*t_poll) (const char *, struct fuse_file_info *, struct fuse_pollhandle *, unsigned *);

// Write buffer (macFUSE extension)
typedef int (*t_write_buf) (const char *, struct fuse_bufvec *, off_t, struct fuse_file_info *);
typedef int (*t_read_buf) (const char *, struct fuse_bufvec **, size_t, off_t, struct fuse_file_info *);
*/

class FuseDelegate {

public:

    virtual ~FuseDelegate() = default;

    // Low-level API (raw FUSE callbacks)
    virtual t_getattr    getattr;
    virtual t_open       open;
    virtual t_read       read;
    virtual t_readdir    readdir;
    virtual t_init       init;

    // High-level API (C++ convenience)
    std::expected<struct stat, int> getattr(const string &path);
    std::expected<struct fuse_file_info, int> open(const string &path, struct fuse_file_info* fi);
    std::expected<struct fuse_file_info, int> read(const string &path, size_t size, off_t offset);
    std::expected<std::vector<string>, int> read(const string &path);
};
