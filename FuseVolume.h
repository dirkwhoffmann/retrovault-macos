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
#include "FileSystem.h"
#include "PosixView.h"

using namespace retro::vault;

namespace vamiga {

class FileSystem;
class PosixFileSystem;

}

class FuseVolume : public FuseMountPoint {

    // Logical volume
    unique_ptr<Volume> vol;

    // Raw file system on top of the volume
    unique_ptr<amiga::FileSystem> fs;

    // POSIX layer on top of the raw file system
    unique_ptr<PosixView> dos;

    // Synchronization lock
    std::mutex mtx;

public:

    static int posixErrno(const Error &err);

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

    i64 reads() const { return vol->reads; }
    i64 writes() const { return vol->writes; }

    void flush() { dos->flush(); }
    
private:

    template <typename Fn> int fsexec(Fn &&fn) {

        std::lock_guard<std::mutex> guard(mtx);

        try {
            return fn();
        } catch (const Error &err) {
            mylog("           Error: %d (%s)\n", posixErrno(err), err.what());
            return -posixErrno(err);
        } catch (...) {
            mylog("           Exception: %d\n", EIO);
            return -EIO;
        }
    }
};
