// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#define FUSE_USE_VERSION 26
#include "fuse.h"

#include <string>
#include <iostream>
#include <sstream>
#include <expected>
#include <filesystem>
#include <functional>
#include <cerrno>

namespace fs = std::filesystem;
using std::string;
using std::expected;

// File system object attributes
using t_getattr  = int(const char *, struct stat *);
using t_readlink = int(const char *, char *, size_t);

// Directory operations
using t_mknod    = int(const char *, mode_t, dev_t);
using t_mkdir    = int(const char *, mode_t);
using t_unlink   = int(const char *);
using t_rmdir    = int(const char *);
using t_symlink  = int(const char *, const char *);
using t_rename   = int(const char *, const char *);
using t_link     = int(const char *, const char *);
using t_chmod    = int(const char *, mode_t);
using t_chown    = int(const char *, uid_t, gid_t);
using t_truncate = int(const char *, off_t);
using t_utime    = int(const char *, struct utimbuf *);

// File operations
using t_open     = int(const char *, struct fuse_file_info *);
using t_read     = int(const char *, char *, size_t, off_t, struct fuse_file_info *);
using t_write    = int(const char *, const char *, size_t, off_t, struct fuse_file_info *);
using t_statfs   = int(const char *, struct statvfs *, struct fuse_file_info *);
using t_flush    = int(const char *, struct fuse_file_info *);
using t_release  = int(const char *, struct fuse_file_info *);
using t_fsync    = int(const char *, int, struct fuse_file_info *);

// Extended attributes
using t_setxattr     = int(const char *, const char *, const char *, size_t, uint32_t);
using t_getxattr     = int(const char *, const char *, char *, size_t, uint32_t);
using t_listxattr    = int(const char *, char *, size_t);
using t_removexattr  = int(const char *, const char *);

// Directory iteration
using t_opendir    = int(const char *, struct fuse_file_info *);
using t_readdir    = int(const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *);
using t_releasedir = int(const char *, struct fuse_file_info *);
using t_fsyncdir   = int(const char *, int, struct fuse_file_info *);

// Lifecycle
using t_init    = void*(struct fuse_conn_info *);
using t_destroy = void(void *);

// Access control
using t_access = int(const char *, int);

// File creation and manipulation
using t_create    = int(const char *, mode_t, struct fuse_file_info *);
using t_ftruncate = int(const char *, off_t, struct fuse_file_info *);
using t_fgetattr  = int(const char *, struct stat *, struct fuse_file_info *);

// File locking
using t_lock = int(const char *, struct fuse_file_info *, int, struct flock *);

// Extended create op
using t_setvolname = int(const char *volname);
using t_getvolname = int(char *volname, size_t size);

// IOCTL
using t_ioctl = int(const char *, int, void *, struct fuse_file_info *, unsigned int, void *);

// Polling
using t_poll = int(const char *, struct fuse_file_info *, struct fuse_pollhandle *, unsigned *);

// Write buffer (macFUSE extension)
using t_write_buf = int(const char *, struct fuse_bufvec *, off_t, struct fuse_file_info *);
using t_read_buf  = int(const char *, struct fuse_bufvec **, size_t, off_t, struct fuse_file_info *);
