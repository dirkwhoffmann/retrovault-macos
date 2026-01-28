// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"
#include "FuseFileSystemTypes.h"
#include "FuseDebug.h"
#include <thread>

class FuseMountPoint {

    // Background thread
    std::thread fuseThread;
    
    // Gateway to the FUSE backend
    struct fuse *gateway = nullptr;

    // Mount point in the host file system ("/Volumes/...")
    fs::path mountPoint;

public:

    // Set to true to enable debug messages
    bool debug = true;
        
    // Delegate (message receiver)
    AdapterCallback *callback = nullptr;

    // Payload send to message receiver
    const void *listener = nullptr;

    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);
    
private:

    // Static FUSE hooks
    struct hooks {
        
        static FUSE_GETATTR;
        static FUSE_MKDIR;
        static FUSE_UNLINK;
        static FUSE_RMDIR;
        static FUSE_RENAME;
        static FUSE_CHMOD;
        static FUSE_TRUNCATE;
        static FUSE_OPEN;
        static FUSE_READ;
        static FUSE_WRITE;
        static FUSE_STATFS;
        static FUSE_RELEASE;
        static FUSE_READDIR;
        static FUSE_INIT;
        static FUSE_DESTROY;
        static FUSE_ACCESS;
        static FUSE_CREATE;
        static FUSE_UTIMENS;
    };

    // Class members called from the static hooks
    virtual FUSE_GETATTR  { return -ENOSYS; }
    virtual FUSE_MKDIR    { return -ENOSYS; }
    virtual FUSE_UNLINK   { return -ENOSYS; }
    virtual FUSE_RMDIR    { return -ENOSYS; }
    virtual FUSE_RENAME   { return -ENOSYS; }
    virtual FUSE_CHMOD    { return -ENOSYS; }
    virtual FUSE_CHOWN    { return -ENOSYS; }
    virtual FUSE_TRUNCATE { return -ENOSYS; }
    virtual FUSE_OPEN     { return -ENOSYS; }
    virtual FUSE_READ     { return -ENOSYS; }
    virtual FUSE_WRITE    { return -ENOSYS; }
    virtual FUSE_STATFS   { return -ENOSYS; }
    virtual FUSE_RELEASE  { return -ENOSYS; }
    virtual FUSE_READDIR  { return -ENOSYS; }
    virtual FUSE_INIT     { return nullptr; }
    virtual FUSE_DESTROY  { }
    virtual FUSE_ACCESS   { return -ENOSYS; }
    virtual FUSE_CREATE   { return -ENOSYS; }
    virtual FUSE_UTIMENS  { return -ENOSYS; }

    static fuse_operations callbacks;

    static FuseMountPoint &self() {
        return *(static_cast<FuseMountPoint *>(fuse_get_context()->private_data));
    }

public:

    const fs::path &getMountPoint() const { return mountPoint; }

    // Mounts a file system at the provides mount point
    void mount(const fs::path &mountpoint);

    // Unmounts the file system
    void unmount();
};
