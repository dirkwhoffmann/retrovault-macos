// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

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

#define FUSE_USE_VERSION 26
#include "fuse.h"

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
 #define FUSE_GETATTR(P)     int (P##getattr) (const char *, struct stat *)
 #define FUSE_READLINK(P)    int (P##readlink) (const char *, char *, size_t)
 #define FUSE_GETDIR(P)      int (P##getdir) (const char *, fuse_dirh_t, fuse_dirfil_t)
 #define FUSE_MKDIR(P)       int (P##mkdir) (const char *, mode_t)
 #define FUSE_UNLINK(P)      int (P##unlink) (const char *)
 #define FUSE_RMDIR(P)       int (P##rmdir) (const char *)
 #define FUSE_SYMLINK(P)     int (P##symlink) (const char *, const char *)
 #define FUSE_RENAME(P)      int (P##rename) (const char *, const char *)
 #define FUSE_LINK(P)        int (P##link) (const char *, const char *)
 #define FUSE_CHMOD(P)       int (P##chmod) (const char *, mode_t)
 #define FUSE_CHOWN(P)       int (P##chown) (const char *, uid_t, gid_t)
 #define FUSE_TRUNCATE(P)    int (P##truncate) (const char *, off_t)
 #define FUSE_MKNOD(P)       int (P##mknod) (const char *, mode_t, dev_t)

 #define FUSE_UTIME(P)       int (P##utime) (const char *, struct utimbuf *)
 #define FUSE_OPEN(P)        int (P##open) (const char *, struct fuse_file_info *)
 #define FUSE_READ(P)        int (P##read) (const char *, char *, size_t, off_t, struct fuse_file_info *)
 #define FUSE_WRITE(P)       int (P##write) (const char *, const char *, size_t, off_t, struct fuse_file_info *)
 #define FUSE_STATFS(P)      int (P##statfs) (const char *, struct statvfs *)
 #define FUSE_FLUSH(P)       int (P##flush) (const char *, struct fuse_file_info *)
 #define FUSE_RELEASE(P)     int (P##release) (const char *, struct fuse_file_info *)
 #define FUSE_FSYNC(P)       int (P##fsync) (const char *, int, struct fuse_file_info *)
 #ifdef __APPLE__
 #define FUSE_SETXATTR(P)    int (P##setxattr) (const char *, const char *, const char *, size_t, int, uint32_t)
 #else
 #define FUSE_SETXATTR(P)    int (P##setxattr) (const char *, const char *, const char *, size_t, int)
 #endif
 #ifdef __APPLE__
 #define FUSE_GETXATTR(P)    int (P##getxattr) (const char *, const char *, char *, size_t, uint32_t)
 #else
 #define FUSE_GETXATTR(P)    int (P##getxattr) (const char *, const char *, char *, size_t)
 #endif
 #define FUSE_LISTXATTR(P)   int (P##listxattr) (const char *, char *, size_t)
 #define FUSE_REMOVEXATTR(P) int (P##removexattr) (const char *, const char *)
 #define FUSE_OPENDIR(P)     int (P##opendir) (const char *, struct fuse_file_info *)
 #define FUSE_READDIR(P)     int (P##readdir) (const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *)
 #define FUSE_RELEASEDIR(P)  int (P##releasedir) (const char *, struct fuse_file_info *)
 #define FUSE_FSYNCDIR(P)    int (P##fsyncdir) (const char *, int, struct fuse_file_info *)
 #define FUSE_INIT(P)        void *(P##init) (struct fuse_conn_info *conn)
 #define FUSE_DESTROY(P)     void (P##destroy) (void *)
 #define FUSE_ACCESS(P)      int (P##access) (const char *, int)
 #define FUSE_CREATE(P)      int (P##create) (const char *, mode_t, struct fuse_file_info *)
 #define FUSE_FTRUNCATE(P)   int (P##ftruncate) (const char *, off_t, struct fuse_file_info *)
 #define FUSE_FGETATTR(P)    int (P##fgetattr) (const char *, struct stat *, struct fuse_file_info *)
 #define FUSE_LOCK(P)        int (P##lock) (const char *, struct fuse_file_info *, int cmd, struct flock *)
 #define FUSE_UTIMENS(P)     int (P##utimens) (const char *, const struct timespec tv[2])
 #define FUSE_BMAP(P)        int (P##bmap) (const char *, size_t blocksize, uint64_t *idx)
 #define FUSE_IOCTL(P)       int (P##ioctl) (const char *, int cmd, void *arg, struct fuse_file_info *, unsigned int, void *)
 #define FUSE_POLL(P)        int (P##poll) (const char *, struct fuse_file_info *, struct fuse_pollhandle *, unsigned *)
 #define FUSE_WRITE_BUF(P)   int (P##write_buf) (const char *, struct fuse_bufvec *buf, off_t off, struct fuse_file_info *)
 #define FUSE_READ_BUF(P)    int (P##read_buf) (const char *, struct fuse_bufvec **bufp, size_t, off_t, struct fuse_file_info *)
 #define FUSE_FLOCK(P)       int (P##flock) (const char *, struct fuse_file_info *, int op)
 #define FUSE_FALLOCATE(P)   int (*P##fallocate) (const char *, int, off_t, off_t, struct fuse_file_info *)
 #ifdef __APPLE__
 #define FUSE_RESERVED00(P)  int (*P##reserved00)(void *, void *, void *, void *, void *, void *, void *, void *)
 #define FUSE_MONITOR(P)     void (*P##monitor)(const char *, uint32_t)
 #define FUSE_RENAMEX(P)     int (*P##renamex) (const char *, const char *, unsigned int)
 #define FUSE_STATFS_X(P)    int (*P##statfs_x) (const char *, struct statfs *)
 #define FUSE_SETVOLNAME(P)  int (*P##setvolname) (const char *)
 #define FUSE_EXCHANGE(P)    int (*P##exchange) (const char *, const char *, unsigned long)
 #define FUSE_GETXTIMES(P)   int (*P##getxtimes) (const char *, struct timespec *bkuptime, struct timespec *)
 #define FUSE_SETBKUPTIME(P) int (*P##setbkuptime) (const char *, const struct timespec *tv)
 #define FUSE_SETCHGTIME(P)  int (*P##setchgtime) (const char *, const struct timespec *tv)
 #define FUSE_SRTCRTIME(P)   int (*P##setcrtime) (const char *, const struct timespec *tv)
 #define FUSE_CHFLAGS(P)     int (*P##chflags) (const char *, uint32_t)
 #define FUSE_SETATTR_X(P)   int (*P##setattr_x) (const char *, struct setattr_x *)
 #define FUSE_FSETATTR_X(P)  int (*P##fsetattr_x) (const char *, struct setattr_x *, struct fuse_file_info *)
 #endif

 */
