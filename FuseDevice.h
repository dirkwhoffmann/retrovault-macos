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
 * FuseMountPoint:
 *
 *     Represents a single FUSE file system. It acts as a thin wrapper around
 *     the FUSE C API, connecting application-level code with the FUSE backend.
 *
 * FuseVolume:
 *
 *     A specialized FuseMountPoint that wraps a logical volume and hosts a
 *     file system mounted on that volume.
 *
 * FuseDevice:
 *
 *     Wraps a disk image and manages a collection of FuseVolume instances.
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
        
    friend class FuseVolume;
    
    // Wrapped image file
    std::unique_ptr<DiskImage> image;

    // Logical volumes
    std::vector<std::unique_ptr<FuseVolume>> volumes;

    
    //
    // Initializing
    //

public:

    FuseDevice(const fs::path &filename);
    ~FuseDevice();
    
    // Registers a listener together with it's callback function
    void setListener(const void *listener, AdapterCallback *func);

private:
    
    // Create a volume (I = image type, V = volume type)
    template<typename I, typename V> void makeVolumeFor(const fs::path& filename);

    
    //
    // Querying information
    //

public:
    
    FuseVolume &getVolume(isize volume);
    DiskImage *getImage() { return image.get(); }

    vector<string> describe() const noexcept;
 
    
    //
    // Configuring
    //
    
public:

    // Returns true if the specified volume is mounted read-only
    bool isWriteProtected(isize volume);

    // Changes the write protection status for the specified volume
    void writeProtect(bool yesno, isize volume);

    
    //
    // Mounting and unmounting volumes
    //
    
public:
    
    // void open(const fs::path &url);
    void mount(const fs::path &mountPoint, isize volume);
    void mount(const fs::path &mountPoint);

    void unmount(isize volume);
    void unmount();
    
    void save();
    void save(isize volume);
    
    void saveAs(const fs::path &url);
    void saveAs(const fs::path &url, isize volume);
    
    void revert();
    void revert(isize volume);
    
    
    //
    // Querying properties
    //
    
    FSPosixStat stat(isize volume);
    ImageInfo imageInfo() const { return image->info(); }
    isize imageSize() const { return image->size(); }
    isize bsize() const { return image->bsize(); }
    isize count() const { return volumes.size(); }
};
