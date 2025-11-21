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
#include <iostream>
#include <expected>
#include <functional>

using std::string;

class FuseAdapter {

    static t_getattr    getattr;//    t_getattr   _getattr;
    static t_open       open;  //     t_open      _open;
    static t_read       read;    //   t_read      _read;
    static t_readdir    readdir; //   t_readdir   _readdir;
    static t_init       init;    //   t_init      _init;

    static fuse_operations callbacks;

    static FuseAdapter &self() {
        return *(static_cast<FuseAdapter *>(fuse_get_context()->private_data));
    }

public:

    bool debug = true;
    FuseDelegate *delegate = nullptr;

    // std::expected<int, bool> test();

public:

    int mount(string mountpoint);
};


