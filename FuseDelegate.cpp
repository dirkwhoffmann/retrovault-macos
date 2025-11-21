// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseDelegate.h"

int
FuseDelegate::getattr(const char* path, struct stat* stbuf)
{
    return -ENOSYS;
}

int
FuseDelegate::open(const char* path, struct fuse_file_info* fi)
{
    return -ENOSYS;
}

int
FuseDelegate::read(const char* path,
                   char* buf,
                   size_t size,
                   off_t offset,
                   struct fuse_file_info* fi)
{
    return -ENOSYS;
}

int
FuseDelegate::readdir(const char* path,
                      void* buf,
                      fuse_fill_dir_t filler,
                      off_t offset,
                      struct fuse_file_info* fi)
{
    return -ENOSYS;
}

void *
FuseDelegate::init(struct fuse_conn_info* conn)
{
    return nullptr;
}
