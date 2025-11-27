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

void
RetroMounter::mount(const fs::path &path)
{
    fs::path mountpoint = "/Volumes" / path.stem();

    try {

        printf("RetroMounter: Creating AmigaFileSystem for %s...\n", path.c_str());
        afs = std::make_unique<AmigaFileSystem>(path);

        printf("RetroMounter: Connecting the file system to the adpater...\n");
        adapter.delegate = afs.get();

        printf("RetroMounter: Mounting volume at %s...\n", mountpoint.c_str());
        adapter.mount(mountpoint);

        printf("RetroMounter: Mounted.\n");

    } catch (std::exception &e) {

        printf("Error: %s\n", e.what());
    }
}

void
RetroMounter::unmount()
{
    adapter.unmount();
}
