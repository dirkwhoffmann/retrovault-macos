// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseVolume.h"
#include "DiskImage.h"
#include "BlockDevice.h"

using namespace retro::vault;

/* Overview:
 *
 * Three classes participate in binding the file system to the FUSE backend.
 *
 * FuseDevice:
 *
 *     Wraps a disk image and manages a collection of FuseVolume instances.
 *
 * FuseVolume:
 *
 *     A specialized FuseMountPoint that wraps a logical volume and hosts a
 *     file system mounted on that volume.
 *
 * FuseMountPoint:
 *
 *     Represents a single FUSE file system. It acts as a thin wrapper around
 *     the FUSE C API, connecting application-level code with the FUSE backend.
 *
 *    ------------------          ------------------
 *   |    FuseDevice    |        |  FuseMountPoint  |
 *    ------------------          ------------------
 *           < >                          ^
 *            |                           |
 *            |                n  ------------------
 *            -------------------|    FuseVolume    |
 *                                ------------------
 *                                        ^
 *              --------------------------|-------------------------
 *             |                          |                         |
 *    ------------------          ------------------       ------------------
 *   | FuseAmigaVolume  |        |  FuseCBMVolume   |     |        ...       |
 *    ------------------          ------------------       ------------------
 */

class FuseDevice {
    
    // Wrapped image file
    std::unique_ptr<DiskImage> image;

    // Logical volumes
    std::vector<std::unique_ptr<FuseVolume>> volumes;

    
    //
    // Methods
    //

public:

    FuseDevice(const fs::path &filename);
    ~FuseDevice();

    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);

    const FuseVolume &getVolume(isize volume);
    const DiskImage *getImage() { return image.get(); }

private:
    
    template<typename I, typename V> void makeVolumeFor(const fs::path& filename);
 
    
    //
    // Mounting and unmounting volumes
    //
    
public:
    
    void mount(isize volume, const fs::path &mountPoint);
    void mount(const fs::path &mountPoint);
    void unmount(isize volume);
    void unmount();

    // Writes all changes back to the image file
    void save();
    
    
    //
    // Querying properties
    //
    
    FSPosixStat stat(isize volume);
    ImageInfo imageInfo() const { return image->info(); }
    isize imageSize() const { return image->size(); }
    isize bsize() const { return image->bsize(); }
    isize count() const { return volumes.size(); }
};
