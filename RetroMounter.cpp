// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "RetroMounter.h"
#include "AmigaFileSystem.h"
#include "FuseDebug.h"
#include "VAmiga.h"
#include "Media.h"

using namespace vamiga;

int
RetroMounter::launch()
{
    string demo = "/tmp/demo.adf";
    string mountpoint = "/Volumes/adf";

    try {

        AmigaFileSystem amigaFS(demo);
        amigaFS.mount(mountpoint);

    } catch (std::exception &e) {

        printf("Error: %s\n", e.what());
    }
    return 1;
}
