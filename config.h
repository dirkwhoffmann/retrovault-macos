// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "debug.h"

//
// Release settings
//

// Version number
static constexpr int VER_MAJOR      = 4;
static constexpr int VER_MINOR      = 4;
static constexpr int VER_SUBMINOR   = 0;
static constexpr int VER_BETA       = 5;


//
// Debug settings
//

static constexpr bool betaRelease = VER_BETA != 0;

#ifdef NDEBUG
static constexpr bool releaseBuild = 1;
static constexpr bool debugBuild = 0;
typedef const int debugflag;
#else
static constexpr bool releaseBuild = 0;
static constexpr bool debugBuild = 1;
typedef int debugflag;
#endif

namespace vamiga {

// File systems
extern debugflag FS_DEBUG;

// Hard Drives
extern debugflag HDR_ACCEPT_ALL;

// Media types
extern debugflag ADF_DEBUG;
extern debugflag HDF_DEBUG;
extern debugflag DMS_DEBUG;
extern debugflag IMG_DEBUG;


//
// Forced error conditions
//

extern debugflag FORCE_LAUNCH_ERROR;
extern debugflag FORCE_HDR_TOO_LARGE;
extern debugflag FORCE_HDR_UNSUPPORTED_C;
extern debugflag FORCE_HDR_UNSUPPORTED_H;
extern debugflag FORCE_HDR_UNSUPPORTED_S;
extern debugflag FORCE_HDR_UNSUPPORTED_B;
extern debugflag FORCE_HDR_UNKNOWN_GEOMETRY;
extern debugflag FORCE_HDR_MODIFIED;
extern debugflag FORCE_FS_WRONG_BSIZE;
extern debugflag FORCE_FS_WRONG_CAPACITY;
extern debugflag FORCE_FS_WRONG_DOS_TYPE;
extern debugflag FORCE_DMS_CANT_CREATE;

}

#include <assert.h>
