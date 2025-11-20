// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseAdapter.h"

/*
extern "C" {

    int loopbackMain(int argc, char *argv[]);
    int loopback2Main(int argc, char *argv[]);
}
*/

fuse_operations
FuseAdapter::callbacks = {

    .getattr    = getattr,
    .readlink   = readlink,
    .mkdir      = mkdir,
    .unlink     = unlink,
    .rmdir      = rmdir,
    .rename     = rename,
    .chmod      = chmod,
    .chown      = chown,
    .truncate   = truncate,
    .open       = open,
    .read       = read,
    .write      = write,
    .statfs     = statfs,
    .readdir    = readdir,
    .init       = init,
    .destroy    = destroy,
    .access     = access,
    .create     = create,
    .utimens    = utimens
};

void
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
    // auto result = loopbackMain((int)argv.size(), argv.data());



    auto result = myMain((int)argv.size(), argv.data());
    printf("Result = %d\n", result);
}

int
FuseAdapter::myMain(int argc, char *argv[])
{

    struct loopback {

        uint32_t blocksize;
        bool case_insensitive;
    };
    loopback loopback;

    const struct fuse_opt loopback_opts[] = {

        { "fsblocksize=%u", offsetof(struct loopback, blocksize), 0 },
        { "case_insensitive", offsetof(struct loopback, case_insensitive), true },
        FUSE_OPT_END
    };

    int res = 0;
    struct fuse_args args = FUSE_ARGS_INIT(argc, argv);

    loopback.blocksize = 4096;
    loopback.case_insensitive = 0;
    if (fuse_opt_parse(&args, &loopback, loopback_opts, NULL) == -1) {
        exit(1);
    }

    umask(0);

    printf("Calling fuse_main\n");
    res = fuse_main(args.argc, args.argv, &callbacks, this);

    fuse_opt_free_args(&args);
    return res;

}

