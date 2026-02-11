// -----------------------------------------------------------------------------
// This file is part of RetroVault
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
    volumes.push_back(make_unique<V>(*this, make_unique<Volume>(*image)));
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

vector<string>
FuseDevice::describe() const noexcept
{
    return image->describe();
}

bool
FuseDevice::needsSaving() const
{
    for (auto &volume: volumes) {
        if (volume->stat().dirtyBlocks > 0) return true;
    }
    
    return dirty;
}

FuseVolume &
FuseDevice::getVolume(isize v)
{
    return *volumes.at(v);
}

void
FuseDevice::mount(const fs::path &mountPoint, isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    volumes[partition]->mount(mountPoint);
}

void
FuseDevice::mount(const fs::path &mountPoint)
{
    if (volumes.size() == 1) {

        mount(mountPoint, 0);
        return;
    }

    for (isize i = 0; i < volumes.size(); i++) {
        mount(mountPoint / std::to_string(i), i);
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

void
FuseDevice::save()
{
    // Flush all volumes
    for (auto &volume : volumes) { volume->flush(); }
    
    // Update image
    image->save();
}

void
FuseDevice::save(isize volume)
{
    assert(volume < isize(volumes.size()));

    flush(volume);
    image->saveBlocks(volumes[volume]->getRange());
}

void
FuseDevice::saveAs(const fs::path &url)
{
    flush();
    image->saveAs(url);
}

void
FuseDevice::saveAs(const fs::path &url, isize volume)
{
    // TODO
}

void
FuseDevice::revert()
{
    
}

void
FuseDevice::revert(isize volume)
{
    assert(volume < isize(volumes.size()));
}

void
FuseDevice::flush()
{
    for (isize i = 0; i < volumes.size(); ++i) { flush(i); }
}

void
FuseDevice::flush(isize volume)
{
    assert(volume < isize(volumes.size()));
        
    if (volumes[volume]->stat().dirtyBlocks > 0) {
        
        volumes[volume]->flush();
        dirty = true;
    }
}

void
FuseDevice::invalidate()
{
    for (auto &volume : volumes) { volume->invalidate(); }
}

void
FuseDevice::invalidate(isize volume)
{
    assert(volume < isize(volumes.size()));
    volumes[volume]->invalidate();
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

FSPosixStat
FuseDevice::stat(isize partition)
{
    assert(partition >= 0 && partition < volumes.size());
    return volumes[partition]->stat();
}

u8
FuseDevice::readByte(isize offset) const
{
    return image->readByte(offset);
}

u8
FuseDevice::readByte(isize offset, isize volume) const
{
    return volumes[volume]->getVolume().readByte(offset);
}

void
FuseDevice::writeByte(isize offset, u8 value)
{
    if (image->readByte(offset) != value) {
     
        image->writeByte(offset, value);
        dirty = true;
    }
    
}

void
FuseDevice::writeByte(isize offset, u8 value, isize volume)
{
    if (volumes[volume]->getVolume().readByte(offset) != value) {
        
        volumes[volume]->getVolume().writeByte(offset, value);
        dirty = true;
    }
}
