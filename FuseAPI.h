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
using std::unexpected;

//
// Fuse operations as defined in fuse.h
//

#define FUSE_GETATTR     int (getattr) (const char *, struct stat *)
#define FUSE_READLINK    int (readlink) (const char *, char *, size_t)
#define FUSE_GETDIR      int (getdir) (const char *, fuse_dirh_t, fuse_dirfil_t)
#define FUSE_MKDIR       int (mkdir) (const char *, mode_t)
#define FUSE_UNLINK      int (unlink) (const char *)
#define FUSE_RMDIR       int (rmdir) (const char *)
#define FUSE_SYMLINK     int (symlink) (const char *, const char *)
#define FUSE_RENAME      int (rename) (const char *, const char *)
#define FUSE_LINK        int (link) (const char *, const char *)
#define FUSE_CHMOD       int (chmod) (const char *, mode_t)
#define FUSE_CHOWN       int (chown) (const char *, uid_t, gid_t)
#define FUSE_TRUNCATE    int (truncate) (const char *, off_t)
#define FUSE_MKNOD       int (mknod) (const char *, mode_t, dev_t)

#define FUSE_UTIME       int (utime) (const char *, struct utimbuf *)
#define FUSE_OPEN        int (open) (const char *, struct fuse_file_info *)
#define FUSE_READ        int (read) (const char *, char *, size_t, off_t, struct fuse_file_info *)
#define FUSE_WRITE       int (write) (const char *, const char *, size_t, off_t, struct fuse_file_info *)
#define FUSE_STATFS      int (statfs) (const char *, struct statvfs *)
#define FUSE_FLUSH       int (flush) (const char *, struct fuse_file_info *)
#define FUSE_RELEASE     int (release) (const char *, struct fuse_file_info *)
#define FUSE_FSYNC       int (fsync) (const char *, int, struct fuse_file_info *)
#ifdef __APPLE__
#define FUSE_SETXATTR    int (setxattr) (const char *, const char *, const char *, size_t, int, uint32_t)
#else
#define FUSE_SETXATTR    int (setxattr) (const char *, const char *, const char *, size_t, int)
#endif
#ifdef __APPLE__
#define FUSE_GETXATTR    int (getxattr) (const char *, const char *, char *, size_t, uint32_t)
#else
#define FUSE_GETXATTR    int (getxattr) (const char *, const char *, char *, size_t)
#endif
#define FUSE_LISTXATTR   int (listxattr) (const char *, char *, size_t)
#define FUSE_REMOVEXATTR int (removexattr) (const char *, const char *)
#define FUSE_OPENDIR     int (opendir) (const char *, struct fuse_file_info *)
#define FUSE_READDIR     int (readdir) (const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *)
#define FUSE_RELEASEDIR  int (releasedir) (const char *, struct fuse_file_info *)
#define FUSE_FSYNCDIR    int (fsyncdir) (const char *, int, struct fuse_file_info *)
#define FUSE_INIT        void *(init) (struct fuse_conn_info *conn)
#define FUSE_DESTROY     void (destroy) (void *)
#define FUSE_ACCESS      int (access) (const char *, int)
#define FUSE_CREATE      int (create) (const char *, mode_t, struct fuse_file_info *)
#define FUSE_FTRUNCATE   int (ftruncate) (const char *, off_t, struct fuse_file_info *)
#define FUSE_FGETATTR    int (fgetattr) (const char *, struct stat *, struct fuse_file_info *)
#define FUSE_LOCK        int (lock) (const char *, struct fuse_file_info *, int cmd, struct flock *)
#define FUSE_UTIMENS     int (utimens) (const char *, const struct timespec tv[2])
#define FUSE_BMAP        int (bmap) (const char *, size_t blocksize, uint64_t *idx)
#define FUSE_IOCTL       int (ioctl) (const char *, int cmd, void *arg, struct fuse_file_info *, unsigned int, void *)
#define FUSE_POLL        int (poll) (const char *, struct fuse_file_info *, struct fuse_pollhandle *, unsigned *)
#define FUSE_WRITE_BUF   int (write_buf) (const char *, struct fuse_bufvec *buf, off_t off, struct fuse_file_info *)
#define FUSE_READ_BUF    int (read_buf) (const char *, struct fuse_bufvec **bufp, size_t, off_t, struct fuse_file_info *)
#define FUSE_FLOCK       int (flock) (const char *, struct fuse_file_info *, int op)
#define FUSE_FALLOCATE   int (*fallocate) (const char *, int, off_t, off_t, struct fuse_file_info *)
#ifdef __APPLE__
#define FUSE_RESERVED00  int (*reserved00)(void *, void *, void *, void *, void *, void *, void *, void *)
#define FUSE_MONITOR     void (*monitor)(const char *, uint32_t)
#define FUSE_RENAMEX     int (*renamex) (const char *, const char *, unsigned int)
#define FUSE_STATFS_X    int (*statfs_x) (const char *, struct statfs *)
#define FUSE_SETVOLNAME  int (*setvolname) (const char *)
#define FUSE_EXCHANGE    int (*exchange) (const char *, const char *, unsigned long)
#define FUSE_GETXTIMES   int (*getxtimes) (const char *, struct timespec *bkuptime, struct timespec *)
#define FUSE_SETBKUPTIME int (*setbkuptime) (const char *, const struct timespec *tv)
#define FUSE_SETCHGTIME  int (*setchgtime) (const char *, const struct timespec *tv)
#define FUSE_SRTCRTIME   int (*setcrtime) (const char *, const struct timespec *tv)
#define FUSE_CHFLAGS     int (*chflags) (const char *, uint32_t)
#define FUSE_SETATTR_X   int (*setattr_x) (const char *, struct setattr_x *)
#define FUSE_FSETATTR_X  int (*fsetattr_x) (const char *, struct setattr_x *, struct fuse_file_info *)
#endif

/*
// File system object attributes
// using t_getattr  = int(const char *, struct stat *);
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


//
// C++ API
//

using t_getattr_cpp = expected<struct stat, int>(const fs::path&);
using t_open_cpp = expected<void, int>(const fs::path&, struct fuse_file_info&);
using t_read_cpp = expected<string, int>(const fs::path&, size_t, off_t, const struct fuse_file_info&);
using t_readdir_cpp = expected<std::vector<string>, int>(const fs::path&);
using t_init_cpp = void *(struct fuse_conn_info &);
*/
