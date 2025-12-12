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

class AmigaDevice : public FuseFileSystem {

    // Amiga Disk File
    std::unique_ptr<ADFFile> adf;

    // Logical volumes
    std::vector<std::unique_ptr<AmigaVolume>> volumes;

public:

    AmigaDevice(const fs::path &filename);
    ~AmigaDevice();

    void mount(isize partition, const fs::path &mountpoint);
    void mount(const fs::path &mountpoint);
    void unmount(isize partition);
    void unmount();
};
