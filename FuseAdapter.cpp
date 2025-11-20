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

void
FuseAdapter::log(const std::function<void(std::ostream &)> &func)
{
    if (debug) {

        std::stringstream ss;
        func(ss);
        std::cout << ss.str();
    }
}

int
FuseAdapter::myMain()
{
    const char *demo = "/tmp/demo.adf";

    try {
        log("Trying to load {}...\n", demo);
        adf = new ADFFile(demo);
        assert(adf != nullptr);

        log("Extracting file system...\n");
        fs = new MutableFileSystem(*adf);
        assert(fs != nullptr);

        string mountpoint = "/Volumes/adf";

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

        log("Calling fuse_main\n");
        auto result = fuse_main((int)argv.size(), argv.data(), &callbacks, this);

        printf("Exiting with error code %d\n", result);
        return result;

    } catch (std::exception &e) {

        printf("Error: %s\n", e.what());
    }
    return 1;
}

