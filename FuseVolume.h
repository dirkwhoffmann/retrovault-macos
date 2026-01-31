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

/*
namespace vamiga {

// class FileSystem;
// class PosixFileSystem;

}
*/

class FuseVolume : public FuseMountPoint {

protected:
    
    // Logical volume
    unique_ptr<Volume> vol;

    // POSIX layer on top of the raw file system
    unique_ptr<PosixView> dos;

    // Synchronization lock
    std::mutex mtx;

public:

    FuseVolume(unique_ptr<Volume> vol);
    ~FuseVolume();

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

    FSPosixStat stat();
    
    Range<isize> getRange() const { return vol->getRange(); }
    
    i64 reads() const { return vol->reads; }
    i64 writes() const { return vol->writes; }

    bool isWriteProtected() { return dos->isWriteProtected(); }
    void writeProtect(bool yesno) { dos->writeProtect(yesno); }
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
    
    FuseAmigaVolume(unique_ptr<Volume> vol);
};


class FuseCBMVolume : public FuseVolume {
    
    // Raw file system on top of the volume
    unique_ptr<cbm::FileSystem> fs;
  
public:
    
    FuseCBMVolume(unique_ptr<Volume> vol);
};
