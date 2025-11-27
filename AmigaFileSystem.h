// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAdapter.h"
#include "FuseDelegate.h"
#include "FuseDebug.h"
#include "VAmiga.h"
#include "Media.h"

using namespace vamiga;

namespace vamiga {

class MutableFileSystem;
class DosFileSystem;

}

class AmigaFileSystem : public FuseDelegate {

public:

    // Fuse adapter
    FuseAdapter adapter;

private:
    
    // Amiga Disk File
    ADFFile *adf = nullptr;

    // Raw file system extracted from the ADF
    MutableFileSystem *fs = nullptr;

    // DOS layer on top of 'fs'
    DosFileSystem *dos = nullptr;

    // Synchronization lock
    std::mutex mtx;

public:

    static int posixErrno(const AppError &err);

    AmigaFileSystem(const fs::path &filename);
    ~AmigaFileSystem();

    void mount(const fs::path &mountpoint);
    void unmount();

    // int mount(string &mountpoint);

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
        } catch (const AppError &err) {
            mylog("           Error: %d (%s)\n", AmigaFileSystem::posixErrno(err), err.what());
            return -AmigaFileSystem::posixErrno(err);
        } catch (...) {
            mylog("           Exception: %d\n", EIO);
            return -EIO;
        }
    }
};
