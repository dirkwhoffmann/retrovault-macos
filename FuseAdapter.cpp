// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseAdapter.h"

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
FuseAdapter::myMain()
{
    printf("useAdapter::myMain()\n");

    std::vector<std::string> params = {

        "loopback",
        "-onative_xattr,volname=loopback,norm_insensitive",
        // "-f",
        "-d",
        "/Volumes/loop"
    };

    std::vector<char *> argv;
    for (auto& s : params) argv.push_back(s.data());

    printf("Calling fuse_main\n");
    auto result = fuse_main((int)argv.size(), argv.data(), &callbacks, this);

    printf("Exiting with error code %d\n", result);
    return result;
}

