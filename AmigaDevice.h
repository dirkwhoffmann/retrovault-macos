// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "AmigaVolume.h"
#include "MediaFile.h"

class AmigaDevice {

    // Amiga Disk File
    std::unique_ptr<MediaFile> mediaFile;

public:

    // Logical volumes
    std::vector<std::unique_ptr<AmigaVolume>> volumes;

public:

    AmigaDevice(const fs::path &filename);
    ~AmigaDevice();

    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);
    
    void mount(isize volume, const fs::path &mountPoint);
    void mount(const fs::path &mountPoint);
    void unmount(isize volume);
    void unmount();

    FSTraits traits(isize volume);
    FSStat stat(isize volume);
    FSBootStat bootStat(isize volume);

    isize count() { return volumes.size(); }
};
