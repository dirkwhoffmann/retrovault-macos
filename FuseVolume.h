// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseMountPoint.h"
#include "FuseDebug.h"
#include "BlockDevice.h"
#include "FileSystems/FSError.h"
#include "FileSystems/PosixView.h"
#include "FileSystems/Amiga/FileSystem.h"
#include "FileSystems/CBM/FileSystem.h"

using namespace retro::vault;


class FuseDevice;

class FuseVolume : public FuseMountPoint {

protected:
    
    // The device this volume belongs to
    class FuseDevice &device;
    
    // Logical volume
    unique_ptr<Volume> vol;

    // POSIX layer on top of the raw file system
    unique_ptr<PosixView> dos;

    // Synchronization lock
    std::mutex mtx;

public:

    FuseVolume(FuseDevice &device, unique_ptr<Volume> vol);
    virtual ~FuseVolume();

    FUSE_GETATTR  override;
    FUSE_MKDIR    override;
    FUSE_UNLINK   override;
    FUSE_RMDIR    override;
    FUSE_RENAME   override;
    FUSE_CHMOD    override;
    FUSE_TRUNCATE override;
    FUSE_OPEN     override;
    FUSE_READ     override;
    FUSE_WRITE    override;
    FUSE_STATFS   override;
    FUSE_RELEASE  override;
    FUSE_READDIR  override;
    FUSE_INIT     override;
    FUSE_DESTROY  override;
    FUSE_ACCESS   override;
    FUSE_CREATE   override;
    FUSE_UTIMENS  override;

    Volume &getVolume() { return *vol; }
    
    virtual vector<string> describe() const noexcept = 0;

    FSPosixStat stat();
    
    Range<isize> getRange() const { return vol->getRange(); }
    
    virtual vector<string> blockTypes() const = 0;
    virtual string blockType(isize blockNr) const = 0;
    virtual string typeOf(isize blockNr, isize pos) const = 0;

    // FS doctor
    virtual void xrayBitmap(bool strict) = 0;
    virtual void xray(bool strict) = 0;
    virtual string xray(isize blockNr, isize pos, bool strict, optional<u8> &expected) const = 0;
    virtual const std::vector<BlockNr> &blockErrors() const = 0;
    virtual const std::vector<BlockNr> &usedButUnallocated() const = 0;
    virtual const std::vector<BlockNr> &unusedButAllocated() const = 0;
    virtual void rectifyAllocationMap(bool strict) = 0;
    virtual void rectify(bool strict) = 0;

    // GUI helpers
    virtual void createUsageMap(u8 *buf, isize len) const = 0;
    virtual void createAllocationMap(u8 *buf, isize len) const = 0;
    virtual void createHealthMap(u8 *buf, isize len) const = 0;
    
    i64 reads() const { return vol->reads; }
    i64 writes() const { return vol->writes; }

    bool isWriteProtected() { return dos->isWriteProtected(); }
    void writeProtect(bool yesno) { dos->writeProtect(yesno); }

    // Writes all changes back to the image file
    void push();
    
    void flush() { dos->flush(); }
    
protected:

    template <typename Fn> int fsexec(Fn &&fn) {

        std::lock_guard<std::mutex> guard(mtx);

        try {

            return fn();

        } catch (const FSError &err) {

            mylog("           FSError: %ld (%s)\n", err.payload, err.what());
            return -err.posixErrno();
            
        } catch (const Error &err) {
            
            mylog("           Error: %ld (%s)\n", err.payload, err.what());
            return -EIO;
            
        } catch (...) {
            
            mylog("           Exception: %d\n", EIO);
            return -EIO;
        }
    }
};


class FuseAmigaVolume : public FuseVolume {
    
    // Raw file system on top of the volume
    unique_ptr<amiga::FileSystem> fs;
    
public:
    
    FuseAmigaVolume(FuseDevice &device, unique_ptr<Volume> vol);
    vector<string> describe() const noexcept override { return fs->describe(); }
    vector<string> blockTypes() const noexcept override;
    string blockType(isize blockNr) const override;
    string typeOf(isize blockNr, isize pos) const override;
    
    void xrayBitmap(bool strict) override;
    void xray(bool strict) override;
    string xray(isize blockNr, isize pos, bool strict, optional<u8> &expected) const override;
    const std::vector<BlockNr> &blockErrors() const override;
    const std::vector<BlockNr> &usedButUnallocated() const override;
    const std::vector<BlockNr> &unusedButAllocated() const override;
    void rectifyAllocationMap(bool strict) override;
    void rectify(bool strict) override;

    void createUsageMap(u8 *buf, isize len) const override;
    void createAllocationMap(u8 *buf, isize len) const override;
    void createHealthMap(u8 *buf, isize len) const override;
};

class FuseCBMVolume : public FuseVolume {
    
    // Raw file system on top of the volume
    unique_ptr<cbm::FileSystem> fs;
    
public:
    
    FuseCBMVolume(FuseDevice &device, unique_ptr<Volume> vol);
    vector<string> describe() const noexcept override { return fs->describe(); }
    vector<string> blockTypes() const noexcept override;
    string blockType(isize blockNr) const override;
    string typeOf(isize blockNr, isize pos) const override;

    void xrayBitmap(bool strict) override;
    void xray(bool strict) override;
    string xray(isize blockNr, isize pos, bool strict, optional<u8> &expected) const override;
    const std::vector<BlockNr> &blockErrors() const override;
    const std::vector<BlockNr> &usedButUnallocated() const override;
    const std::vector<BlockNr> &unusedButAllocated() const override;
    void rectifyAllocationMap(bool strict) override;
    void rectify(bool strict) override;

    void createUsageMap(u8 *buf, isize len) const override;
    void createAllocationMap(u8 *buf, isize len) const override;
    void createHealthMap(u8 *buf, isize len) const override;
};
