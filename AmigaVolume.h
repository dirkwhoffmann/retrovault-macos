// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseFileSystem.h"
#include "FuseDebug.h"
#include "FileSystem.h"
#include "ADFFile.h"

using namespace vamiga;

namespace vamiga {

class FileSystem;
class PosixFileSystem;

}

class AmigaVolume : public FuseFileSystem {
    
    friend class AmigaDevice;

    // Raw file system
    std::unique_ptr<FileSystem> fs;

    // DOS layer on top of the raw file system
    std::unique_ptr<PosixFileSystem> dos;

    // Synchronization lock
    std::mutex mtx;

public:

    static int posixErrno(const Error &err);

    AmigaVolume(std::unique_ptr<FileSystem> fs);
    ~AmigaVolume();

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
