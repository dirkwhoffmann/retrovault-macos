// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"

class FuseDelegate {

public:

    virtual ~FuseDelegate() = default;

    virtual FUSE_GETATTR { return -ENOSYS; }
    virtual FUSE_OPEN    { return -ENOSYS; }
    virtual FUSE_READ    { return -ENOSYS; }
    virtual FUSE_READDIR { return -ENOSYS; }
    virtual FUSE_INIT    { return nullptr; }
};
