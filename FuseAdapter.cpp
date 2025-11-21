// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseAdapter.h"
#include "MutableFileSystem.h"
#include <sys/mount.h>
#include <iostream>

fuse_operations
FuseAdapter::callbacks = {

    .getattr    = getattr,
    /*
    .readlink   = readlink,
    .mkdir      = mkdir,
    .unlink     = unlink,
    .rmdir      = rmdir,
    .rename     = rename,
    .chmod      = chmod,
    .chown      = chown,
    .truncate   = truncate,
     */
    .open       = open,
    .read       = read,
    /*
    .write      = write,
    .statfs     = statfs,
     */
    .readdir    = readdir,
    .init       = init,
    /*
    .destroy    = destroy,
    .access     = access,
    .create     = create,
    .utimens    = utimens
    */
};

int
FuseAdapter::mount(string mountpoint)
{
    // Unmount the volume if it is still mounted
    log("Unmounting existing volume {}...\n", mountpoint);
    (void)unmount(mountpoint.c_str(), 0);

    std::vector<std::string> params = {

        "vmount",
        "-onative_xattr,volname=adf,norm_insensitive",
        // "-f",
        "-d",
        mountpoint
    };

    std::vector<char *> argv;
    for (auto& s : params) argv.push_back(s.data());

    printf("Calling fuse_main %p\n", this);
    auto result = fuse_main((int)argv.size(), argv.data(), &callbacks, this);

    printf("Exiting with error code %d\n", result);
    return result;
}

int
FuseAdapter::getattr(const char* path, struct stat* st)
{
    return self().delegate->getattr(path, st);
}

int
FuseAdapter::open(const char* path, struct fuse_file_info* fi)
{
    return self().delegate->open(path, fi);
}

int
FuseAdapter::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    return self().delegate->read(path, buf, size, offset, fi);
}

int
FuseAdapter::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
               off_t offset, struct fuse_file_info* fi)
{
    return self().delegate->readdir(path, buf, filler, offset, fi);
}

void *
FuseAdapter::init(struct fuse_conn_info* conn)
{
    self().delegate->init(conn);
    return &self();
}
