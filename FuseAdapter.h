// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseAPI.h"
#include "FuseDelegate.h"
#include "FuseDebug.h"

class FuseAdapter {

    static t_getattr    getattr;
    static t_open       open;
    static t_read       read;
    static t_readdir    readdir;
    static t_init       init;

    static fuse_operations callbacks;

    static FuseAdapter &self() {
        return *(static_cast<FuseAdapter *>(fuse_get_context()->private_data));
    }

public:

    bool debug = true;
    FuseDelegate *delegate = nullptr;

public:

    int mount(string mountpoint);
};


