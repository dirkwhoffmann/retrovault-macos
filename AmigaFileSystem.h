// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseDelegate.h"
#include "VAmiga.h"
#include "Media.h"

using namespace vamiga;

class AmigaFileSystem : FuseDelegate {

    // Amiga Disk File
    ADFFile *adf = nullptr;

    // File system extracted from the ADF
    class MutableFileSystem *fs = nullptr;

public:

    static int posixErrno(const AppError &err);

    FUSE_GETATTR override;
    FUSE_MKDIR   override;
    FUSE_RMDIR   override;
    FUSE_RENAME  override;
    FUSE_OPEN    override;
    FUSE_READ    override;
    FUSE_STATFS  override;
    FUSE_READDIR override;
    FUSE_INIT    override;
    FUSE_UTIMENS override;

    AmigaFileSystem(string &filename);

    int mount(string &mountpoint);
};
