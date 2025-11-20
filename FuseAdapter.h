// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "Vamiga.h"
#include "FuseAPI.h"

class FuseAdapter {

#include "FuseAdapterCallbacks.h"

    static fuse_operations callbacks;

    static FuseAdapter &self() {
        return *(static_cast<FuseAdapter *>(fuse_get_context()->private_data));
    }

public:
    
    int myMain();
};


