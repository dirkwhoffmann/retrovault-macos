// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseDevice.h"

// #include "FileSystemFactory.h"
#include "ADFFile.h"

using retro::vault::image::ADFFile;

FuseDevice::FuseDevice(const fs::path &filename)
{
    mylog("Trying to load %s...\n", filename.string().c_str());
    // image = std::make_unique<MediaFile>(filename);

    /*
    if (image->type() != FileType::ADF) {

        warn("%s is not an ADF. Aborting.\n", filename.string().c_str());
        return;
    }
    */

    // Get the ADF
    // unique_ptr<ADFFile> adf = make_unique<ADFFile>(filename);

    // image = std::move(adf);

    // Create the block device
    mylog("Creating block device...\n");
    image = make_unique<ADFFile>(filename); // std::move(adf);

    // Create a logical volume
    mylog("Creating volume...\n");
    unique_ptr<Volume> vol = make_unique<Volume>(*image);

    mylog("Creating FuseVolume...\n");
    volumes.push_back(make_unique<FuseVolume>(std::move(vol)));

    mylog("Installed volumes: %zu\n", volumes.size());
}

FuseDevice::~FuseDevice()
{
    printf("Destroying FuseDevice\n");
}

void
FuseDevice::setListener(const void *listener, AdapterCallback *callback)
{
    for (auto &volume : volumes) volume->setListener(listener, callback);
}

const FuseVolume &
FuseDevice::getVolume(isize v)
{
    return *volumes.at(v);
}

void
FuseDevice::mount(isize partition, const fs::path &mountPoint)
{
    assert(partition >= 0 && partition < volumes.size());
    volumes[partition]->mount(mountPoint);
}

void
FuseDevice::mount(const fs::path &mountPoint)
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
FuseDevice::unmount(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());

    // Remove the volume from the vector
    std::unique_ptr<FuseVolume> vol = std::move(volumes[partition]);
    volumes.erase(volumes.begin() + partition);
    
    // Unmount the volume asynchroneously
    std::thread([vol = std::move(vol)]() mutable {
        
        vol->unmount();
        
    }).detach();
}

void
FuseDevice::unmount()
{
    while (!volumes.empty()) { unmount(0); }
}

void
FuseDevice::save()
{
    // Flush all volumes
    for (auto &volume: volumes) { volume->flush(); }
    
    // Save image
    image->save();
}

FSPosixStat
FuseDevice::stat(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    return volumes[partition]->stat();
}
