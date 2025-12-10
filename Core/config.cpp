// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"

namespace vamiga {

// File systems
debugflag FS_DEBUG        = 0;

// Hard Drives
debugflag HDR_ACCEPT_ALL  = 0;

// Media types
debugflag ADF_DEBUG       = 0;
debugflag HDF_DEBUG       = 0;
debugflag DMS_DEBUG       = 0;
debugflag IMG_DEBUG       = 0;


//
// Forced error conditions
//

debugflag FORCE_LAUNCH_ERROR             = 0;
debugflag FORCE_HDR_TOO_LARGE            = 0;
debugflag FORCE_HDR_UNSUPPORTED_C        = 0;
debugflag FORCE_HDR_UNSUPPORTED_H        = 0;
debugflag FORCE_HDR_UNSUPPORTED_S        = 0;
debugflag FORCE_HDR_UNSUPPORTED_B        = 0;
debugflag FORCE_HDR_UNKNOWN_GEOMETRY     = 0;
debugflag FORCE_HDR_MODIFIED             = 0;
debugflag FORCE_FS_WRONG_BSIZE           = 0;
debugflag FORCE_FS_WRONG_CAPACITY        = 0;
debugflag FORCE_FS_WRONG_DOS_TYPE        = 0;
debugflag FORCE_DMS_CANT_CREATE          = 0;

}
