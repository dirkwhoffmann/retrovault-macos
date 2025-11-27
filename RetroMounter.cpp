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
    fs::path demo = "/tmp/demo.adf";
    fs::path mountpoint = "/Volumes/adf";

    try {

        printf("RetroMounter: Creating AmigaFileSystem...\n");
        afs = std::make_unique<AmigaFileSystem>(demo);

        printf("RetroMounter: Connecting the file system to the adpater...\n");
        adapter.delegate = afs.get();

        printf("RetroMounter: Mounting volume...\n");
        adapter.mount(mountpoint);

        printf("RetroMounter: Mounted.\n");

    } catch (std::exception &e) {

        printf("Error: %s\n", e.what());
    }
    return 1;
}
