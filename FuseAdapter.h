// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"
#include "FuseDelegate.h"
#include "FuseAdapterDelegate.h"
#include "FuseDebug.h"
#include <thread>

class FuseAdapter {

    std::thread fuseThread;
    struct fuse *gateway = nullptr;
    fuse_chan *channel = nullptr;
    fs::path mountpoint;

public:

    bool debug = true;
    FuseAdapterDelegate *adapterDelegate = nullptr;
    const void *listener = nullptr; // Experimental
    AdapterCallback *callback = nullptr; // Experimental
    FuseDelegate *delegate = nullptr;

    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);
    
private:

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

    static fuse_operations callbacks;

    static FuseAdapter &self() {
        return *(static_cast<FuseAdapter *>(fuse_get_context()->private_data));
    }

public:

    void mount(const fs::path &mountpoint);
    void unmount();
};
