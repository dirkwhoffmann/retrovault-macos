// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseDelegate.h"
#include "VAmiga.h"
#include "Media.h"

using namespace vamiga;

class AmigaFileSystem : FuseDelegate {

    // Amiga Disk File
    ADFFile *adf = nullptr;

    // File system extracted from the ADF
    class MutableFileSystem *fs = nullptr;

public:

    t_getattr  getattr  override;
    t_open     open     override;
    t_read     read     override;
    t_readdir  readdir  override;
    t_init     init     override;

    AmigaFileSystem(string &filename);

    int mount(string &mountpoint);
};
