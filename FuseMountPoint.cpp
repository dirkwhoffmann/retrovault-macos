// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseMountPoint.h"
#include "FileSystem.h"
#include <fuse.h>
#include <iostream>
#include <sys/mount.h>

fuse_operations
FuseMountPoint::callbacks = {

    .getattr    = hooks::getattr,
    .mkdir      = hooks::mkdir,
    .unlink     = hooks::unlink,
    .rmdir      = hooks::rmdir,
    .rename     = hooks::rename,
    .chmod      = hooks::chmod,
    .truncate   = hooks::truncate,
    .open       = hooks::open,
    .read       = hooks::read,
    .write      = hooks::write,
    .statfs     = hooks::statfs,
    .release    = hooks::release,
    .readdir    = hooks::readdir,
    .init       = hooks::init,
    .destroy    = hooks::destroy,
    .access     = hooks::access,
    .create     = hooks::create,
    .utimens    = hooks::utimens
};

void
FuseMountPoint::setListener(const void *listener, AdapterCallback *callback)
{
    this->listener = listener;
    this->callback = callback;
}

void
FuseMountPoint::mount(const fs::path &mp)
{
    mountPoint = mp;

    // Unmount existing volume (if any)
    mylog("Unmounting existing volume %s...\n", mountPoint.string().c_str());
    (void)::unmount(mountPoint.c_str(), 0);

    fuseThread = std::thread([&]() {

        struct fuse_args args = FUSE_ARGS_INIT(0, nullptr);
        fuse_opt_add_arg(&args, "-f"); // Force foreground
        fuse_opt_add_arg(&args, "-olocal"); // Make the volume appear in Finder
        fuse_opt_add_arg(&args, "-ovolname=ADF");

        try {

            printf("mp.c_str() = %s\n", mountPoint.c_str());

            fuse_chan *channel = fuse_mount(mountPoint.c_str(), &args);
            if (!channel) {

                printf("Channel is null\n");
                return;
            }
            gateway = fuse_new(channel, &args, &callbacks, sizeof(callbacks), this);
            if (!gateway) {

                printf("Gateway is null\n");
                fuse_unmount(mountPoint.c_str(), channel);
                return;
            }

            // Blocking loop (runs until unmounted or fuse_exit called)
            printf("Launching fuse loop...\n");
            fuse_loop(gateway);

            // Remove the mount point
            printf("Unmouting %s\n", mountPoint.c_str());
            fuse_unmount(mountPoint.c_str(), channel);

            // Cleanup
            printf("Destroy...\n");
            fuse_destroy(gateway);
            gateway = nullptr;
            printf("Destroyed.\n");
            if (listener) { callback(listener, 42); }

        } catch (std::exception &e) {
            printf("Exception: %s\n", e.what());
        }
    });

    // fuseThread.detach();
    
    /*
     std::vector<std::string> params = {

     "vmount",
     // "-onative_xattr,volname=adf,norm_insensitive",
     "-ovolname=adf,norm_insensitive",
     // "-f",
     // "-d",
     mountPoint
     };

     std::vector<char *> argv;
     for (auto& s : params) argv.push_back(s.data());

     printf("Calling fuse_main %p\n", this);
     auto result = fuse_main((int)argv.size(), argv.data(), &callbacks, this);

     printf("Exiting with error code %d\n", result);
     return result;
     */
}

void
FuseMountPoint::unmount()
{
    printf("FuseAdapter::unmount()\n");

    if (gateway) {
        
        printf("Calling fuse_exit...\n");
        fuse_exit(gateway);
    }

    printf("Waiting for the thread to terminate...\n");
    if (fuseThread.joinable()) {

        // Wait for clean shutdown
        fuseThread.join();
    }
    
    printf("Done.\n");
}

int
FuseMountPoint::hooks::getattr(const char *path, struct stat* st)
{
    mylog("[getattr]  %s\n", path);
    return self().getattr(path, st);
}

int
FuseMountPoint::hooks::mkdir(const char *path, mode_t mode)
{
    mylog("[mkdir]    %s, %x\n", path, mode);
    return self().mkdir(path, mode);
}

int
FuseMountPoint::hooks::unlink(const char *path)
{
    mylog("[unlink]   %s\n", path);
    return self().unlink(path);
}

int
FuseMountPoint::hooks::rmdir(const char *path)
{
    mylog("[rmdir]    %s\n", path);
    return self().rmdir(path);
}

int
FuseMountPoint::hooks::rename(const char *oldpath, const char *newpath)
{
    mylog("[rename]   %s, %s\n", oldpath, newpath);
    return self().rename(oldpath, newpath);
}

int
FuseMountPoint::hooks::chmod(const char *path, mode_t mode)
{
    mylog("[chmod]    %s, %x\n", path, mode);
    return self().chmod(path, mode);
}

int
FuseMountPoint::hooks::truncate(const char* path, off_t size)
{
    mylog("[truncate] %s, %lld\n", path, size);
    return self().truncate(path, size);
}

int
FuseMountPoint::hooks::open(const char* path, struct fuse_file_info* fi)
{
    mylog("[open]     %s\n", path);
    return self().open(path, fi);
}

int
FuseMountPoint::hooks::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    mylog("[read]     %s, %ld, %lld\n", path, size, offset);
    return self().read(path, buf, size, offset, fi);
}

int
FuseMountPoint::hooks::write(const char* path, const char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    mylog("[write]    %s, %ld, %lld\n", path, size, offset);
    return self().write(path, buf, size, offset, fi);
}

int
FuseMountPoint::hooks::statfs(const char *path, struct statvfs *st)
{
    mylog("[statfs]   %s\n", path);
    return self().statfs(path, st);
}

int
FuseMountPoint::hooks::release(const char *path, struct fuse_file_info *fi)
{
    mylog("[release]  %s\n", path);
    return self().release(path, fi);
}

int
FuseMountPoint::hooks::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
               off_t offset, struct fuse_file_info* fi)
{
    mylog("[readdir]  %s, %lld\n", path, offset);
    return self().readdir(path, buf, filler, offset, fi);
}

void *
FuseMountPoint::hooks::init(struct fuse_conn_info* conn)
{
    mylog("[init]");

    // We ignore the result of the delegate method
    (void)self().init(conn);

    // Instead, we return a pointer to the FUSE adapter
    return &self();
}

void
FuseMountPoint::hooks::destroy(void *ptr)
{
    mylog("[destroy]  %p\n", ptr);
    self().destroy(ptr);
}

int
FuseMountPoint::hooks::access(const char *path, const int mask)
{
    mylog("[access]   %s, %x\n", path, mask);
    return self().access(path, mask);
}

int
FuseMountPoint::hooks::create(const char *path, mode_t mode, struct fuse_file_info *fi)
{
    mylog("[create]   %s, %x\n", path, mode);
    return self().create(path, mode, fi);
}

int
FuseMountPoint::hooks::utimens(const char *path, const struct timespec tv[2])
{
    mylog("[utimens]  %s\n", path);
    return self().utimens(path, tv);
}
