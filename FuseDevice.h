// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseVolume.h"
#include "ADFFile.h"
#include "FileSystems/Amiga/FSTypes.h"
#include "BlockDevice.h"

using namespace retro::vault;

class FuseDevice {

public:
    
    // Image file
    std::unique_ptr<DiskImage> image;

    // Logical volumes
    std::vector<std::unique_ptr<FuseVolume>> volumes;

public:

    FuseDevice(const fs::path &filename);
    ~FuseDevice();

    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);

    const FuseVolume &getVolume(isize volume);

    void mount(isize volume, const fs::path &mountPoint);
    void mount(const fs::path &mountPoint);
    void unmount(isize volume);
    void unmount();

    FSPosixStat stat(isize volume);
    ImageInfo imageInfo() const { return image->info(); }
    isize imageSize() const { return image->size(); }
    isize count() const { return volumes.size(); }
};
