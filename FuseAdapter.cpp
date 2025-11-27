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
#include <fuse.h>
#include <iostream>
#include <sys/mount.h>

fuse_operations
FuseAdapter::callbacks = {

    .getattr    = getattr,
    .mkdir      = mkdir,
    .unlink     = unlink,
    .rmdir      = rmdir,
    .rename     = rename,
    .chmod      = chmod,
    .truncate   = truncate,
    .open       = open,
    .read       = read,
    .write      = write,
    .statfs     = statfs,
    .release    = release,
    .readdir    = readdir,
    .init       = init,
    .destroy    = destroy,
    /*
    .access     = access,
     */
    .create     = create,
    .utimens    = utimens
};

void
FuseAdapter::mount(const fs::path &mp)
{
    mountpoint = mp;

    // Unmount existing volume (if any)
    mylog("Unmounting existing volume %s...\n", mountpoint.string().c_str());
    (void)unmount(mountpoint.c_str(), 0);

    if (fuseThread.joinable()) {
        printf("Joining...\n");
        fuseThread.join();
    }

    fuseThread = std::thread([&]() {

        struct fuse_args args = FUSE_ARGS_INIT(0, nullptr);
        fuse_opt_add_arg(&args, "-f");   // force foreground

        try {

            printf("mp.c_str() = %s\n", mountpoint.c_str());

            channel = fuse_mount(mountpoint.c_str(), &args);
            if (!channel) {

                printf("Channel is null\n");
                return;
            }
            gateway = fuse_new(channel, &args, &callbacks, sizeof(callbacks), this);

            if (gateway) {

                printf("Gateway = %p\n", gateway);
                
                // Blocking loop (runs until unmounted or fuse_exit called)
                fuse_loop(gateway);

                // Cleanup
                fuse_destroy(gateway);
            }

            // Remove the mountpoint
            fuse_unmount(mountpoint.c_str(), channel);

        } catch (std::exception &e) {
            printf("Exception: %s\n", e.what());
        }
    });

    /*
    std::vector<std::string> params = {

        "vmount",
        // "-onative_xattr,volname=adf,norm_insensitive",
        "-ovolname=adf,norm_insensitive",
        // "-f",
        // "-d",
        mountpoint
    };

    std::vector<char *> argv;
    for (auto& s : params) argv.push_back(s.data());

    printf("Calling fuse_main %p\n", this);
    auto result = fuse_main((int)argv.size(), argv.data(), &callbacks, this);

    printf("Exiting with error code %d\n", result);
    return result;
    */
}

int
FuseAdapter::getattr(const char *path, struct stat* st)
{
    mylog("[getattr]  %s\n", path);
    return self().delegate->getattr(path, st);
}

int
FuseAdapter::mkdir(const char *path, mode_t mode)
{
    mylog("[mkdir]    %s, %x\n", path, mode);
    return self().delegate->mkdir(path, mode);
}

int
FuseAdapter::unlink(const char *path)
{
    mylog("[unlink]   %s\n", path);
    return self().delegate->unlink(path);
}

int
FuseAdapter::rmdir(const char *path)
{
    mylog("[rmdir]    %s\n", path);
    return self().delegate->rmdir(path);
}

int
FuseAdapter::rename(const char *oldpath, const char *newpath)
{
    mylog("[rename]   %s, %s\n", oldpath, newpath);
    return self().delegate->rename(oldpath, newpath);
}

int
FuseAdapter::chmod(const char *path, mode_t mode)
{
    mylog("[chmod]    %s, %x\n", path, mode);
    return self().delegate->chmod(path, mode);
}

int
FuseAdapter::truncate(const char* path, off_t size)
{
    mylog("[truncate] %s, %lld\n", path, size);
    return self().delegate->truncate(path, size);
}

int
FuseAdapter::open(const char* path, struct fuse_file_info* fi)
{
    mylog("[open]     %s\n", path);
    return self().delegate->open(path, fi);
}

int
FuseAdapter::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    mylog("[read]     %s, %ld, %lld\n", path, size, offset);
    return self().delegate->read(path, buf, size, offset, fi);
}

int
FuseAdapter::write(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    mylog("[write]    %s, %ld, %lld\n", path, size, offset);
    return self().delegate->write(path, buf, size, offset, fi);
}

int
FuseAdapter::statfs(const char *path, struct statvfs *st)
{
    mylog("[statfs]   %s\n", path);
    return self().delegate->statfs(path, st);
}

int
FuseAdapter::release(const char *path, struct fuse_file_info *fi)
{
    mylog("[release]  %s\n", path);
    return self().delegate->release(path, fi);
}

int
FuseAdapter::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
               off_t offset, struct fuse_file_info* fi)
{
    mylog("[readdir]  %s, %lld\n", path, offset);
    return self().delegate->readdir(path, buf, filler, offset, fi);
}

void *
FuseAdapter::init(struct fuse_conn_info* conn)
{
    mylog("[init]");

    // We ignore the result of the delegate method
    (void)self().delegate->init(conn);

    // Instead, we return a pointer to the FUSE adapter
    return &self();
}

void
FuseAdapter::destroy(void *ptr)
{
    mylog("[destroy]  %p\n", ptr);
    self().delegate->destroy(ptr);
}

int
FuseAdapter::access(const char *path, const int mask)
{
    mylog("[access]   %s, %x\n", path, mask);
    return self().delegate->access(path, mask);
}

int
FuseAdapter::create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
    mylog("[create]   %s, %x\n", path, mode);
    return self().delegate->create(path, mode, fi);
}

int
FuseAdapter::utimens(const char *path, const struct timespec tv[2])
{
    mylog("[utimens]  %s\n", path);
    return self().delegate->utimens(path, tv);
}
