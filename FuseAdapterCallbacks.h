// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#define API(return_type, name, ...) \
    static return_type name(__VA_ARGS__); return_type _##name(__VA_ARGS__);

API(int, getattr, const char* path, struct stat* st)
API(int, readlink, const char *, char *, size_t)
API(int, mkdir, const char *, mode_t)
API(int, unlink, const char *)
API(int, rmdir, const char *)
API(int, rename, const char *, const char *)
API(int, chmod, const char *, mode_t)
API(int, chown, const char *, uid_t, gid_t)
API(int, truncate, const char *, off_t)
API(int, open, const char * path, struct fuse_file_info *)
API(int, read, const char *, char *, size_t size, off_t offset, struct fuse_file_info *)
API(int, write, const char *, const char *, size_t, off_t, struct fuse_file_info *)
API(int, statfs, const char *, struct statvfs *)
API(int, readdir, const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *)
API(void *, init, struct fuse_conn_info *conn)
API(void, destroy, void *)
API(int, access, const char *, int)
API(int, create, const char *, mode_t, struct fuse_file_info *)
API(int, utimens, const char *, const struct timespec tv[2])

#undef API
