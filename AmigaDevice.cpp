// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "AmigaDevice.h"
#include "FileSystemFactory.h"

using namespace vamiga;

/*
namespace vamiga {

class FileSystem;
class PosixFileSystem;

}
*/

AmigaDevice::AmigaDevice(const fs::path &filename)
{
    mylog("Trying to load %s...\n", filename.string().c_str());
    adf = std::make_unique<ADFFile>(filename);

    mylog("Extracting raw file system...\n");
    auto fs = FileSystemFactory::fromADF(*adf);
    assert(fs.get() != nullptr);

    mylog("Creating volume...\n");
    volumes.push_back(std::make_unique<AmigaVolume>(std::move(fs)));

    mylog("Installed volumes: %zu\n", volumes.size());
}

AmigaDevice::~AmigaDevice()
{
    printf("Destroying AmigaFileSystem\n");
}

void
AmigaDevice::mount(isize partition, const fs::path &mountpoint)
{
    assert(partition >= 0 && partition < volumes.size());
    volumes[partition]->mount(mountpoint);
}

void
AmigaDevice::mount(const fs::path &mountpoint)
{
    if (volumes.size() == 1) {

        mount(0, mountpoint);
        return;
    }

    for (isize i = 0; i < volumes.size(); i++) {
        mount(i, mountpoint / std::to_string(i));
    }
}

void
AmigaDevice::unmount(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    volumes[partition]->unmount();
}

void
AmigaDevice::unmount()
{
    for (isize i = 0; i < volumes.size(); i++) {
        unmount(i);
    }
}
