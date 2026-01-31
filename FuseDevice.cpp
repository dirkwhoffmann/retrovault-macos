// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseDevice.h"

#include "ADFFile.h"
#include "D64File.h"

using retro::vault::image::ADFFile;
using retro::vault::image::D64File;

FuseDevice::FuseDevice(const fs::path &filename)
{
    mylog("Scanning image %s...\n", filename.string().c_str());

    ImageFormat format = ImageFormat::UNKNOWN;
    if (auto info = DiskImage::about(filename))
        format = info->format;

    mylog("Format: %s\n", ImageFormatEnum::key(format));

    switch (format) {
            
        case ImageFormat::ADF: makeVolumeFor<ADFFile,FuseAmigaVolume>(filename); break;
        case ImageFormat::D64: makeVolumeFor<D64File,FuseCBMVolume>(filename); break;

        default:
            throw IOError(IOError::FILE_TYPE_UNSUPPORTED);
    }
    
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
    // mylog("Creating block device...\n");
    // image = make_unique<ADFFile>(filename); // std::move(adf);

    // Create a logical volume
    // mylog("Creating volume...\n");
    // unique_ptr<Volume> vol = make_unique<Volume>(*image);

    // mylog("Creating FuseVolume...\n");
    // volumes.push_back(make_unique<FuseAmigaVolume>(std::move(vol)));

    mylog("Installed volumes: %zu\n", volumes.size());
}

template<typename I, typename V> void
FuseDevice::makeVolumeFor(const fs::path& filename)
{
    image = make_unique<I>(filename);
    volumes.push_back(make_unique<V>(make_unique<Volume>(*image)));
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
FuseDevice::unmount(isize volume)
{
    assert(volume >= 0 && volume < volumes.size());

    // Remove the volume from the vector
    std::unique_ptr<FuseVolume> vol = std::move(volumes[volume]);
    volumes.erase(volumes.begin() + volume);
    
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

bool
FuseDevice::isWriteProtected(isize volume)
{
    assert(volume >= 0 && volume < volumes.size());
    return volumes[volume]->isWriteProtected();
}

void
FuseDevice::writeProtect(bool yesno, isize volume)
{
    assert(volume >= 0 && volume < volumes.size());
    volumes[volume]->writeProtect(yesno);
}

void
FuseDevice::commit(isize volume)
{
    // Write all dirty blocks back to the image
    volumes[volume]->flush();
    
    // Write the image back to the image file
    image->save(volumes[volume]->getRange());
}

void
FuseDevice::commit()
{
    for (auto &volume : volumes)
        image->save(volume->getRange());    
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
