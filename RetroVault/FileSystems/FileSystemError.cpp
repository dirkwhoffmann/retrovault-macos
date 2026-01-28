// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "FileSystemError.h"

namespace retro::vault {

FileSystemError::FileSystemError(long code, const string &s) : utl::Error(code)
{
    switch (code)
    {
        case POSIX:
            set_msg(s.empty() ? "POSIX errno: " + std::to_string(code) : s);
            break;

        default:
            set_msg(string("Error code ") + std::to_string(payload) + " (" + errstr() + ").");
            break;
    }
}

}
