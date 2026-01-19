// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "AmigaDevice.h"

// #include "FileSystemFactory.h"

using retro::vault::image::ADFFile;

/*
namespace vamiga {

class FileSystem;
class PosixFileSystem;

}
*/

AmigaDevice::AmigaDevice(const fs::path &filename)
{
    mylog("Trying to load %s...\n", filename.string().c_str());
    // mediaFile = std::make_unique<MediaFile>(filename);

    /*
    if (mediaFile->type() != FileType::ADF) {

        warn("%s is not an ADF. Aborting.\n", filename.string().c_str());
        return;
    }
    */

    // Get the ADF
    unique_ptr<ADFFile> adf = make_unique<ADFFile>(filename);

    // Create the block device
    mylog("Creating block device...\n");
    dev = std::move(adf);

    // Create a logical volume
    mylog("Creating volume...\n");
    unique_ptr<Volume> vol = make_unique<Volume>(*dev);

    mylog("Creating AmigaVolume...\n");
    volumes.push_back(make_unique<AmigaVolume>(std::move(vol)));

    mylog("Installed volumes: %zu\n", volumes.size());
}

AmigaDevice::~AmigaDevice()
{
    printf("Destroying AmigaFileSystem\n");
}

void
AmigaDevice::setListener(const void *listener, AdapterCallback *callback)
{
    for (auto &volume : volumes) volume->setListener(listener, callback);
}

void
AmigaDevice::mount(isize partition, const fs::path &mountPoint)
{
    assert(partition >= 0 && partition < volumes.size());
    volumes[partition]->mount(mountPoint);
}

void
AmigaDevice::mount(const fs::path &mountPoint)
{
    // this->mountPoint = mountPoint;

    if (volumes.size() == 1) {

        mount(0, mountPoint);
        return;
    }

    for (isize i = 0; i < volumes.size(); i++) {
        mount(i, mountPoint / std::to_string(i));
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

amiga::FSTraits
AmigaDevice::traits(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    return volumes[partition]->fs->getTraits();
}

FSPosixStat
AmigaDevice::stat(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    return volumes[partition]->fs->stat();
}

amiga::FSBootStat
AmigaDevice::bootStat(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    return volumes[partition]->fs->bootStat();
}
