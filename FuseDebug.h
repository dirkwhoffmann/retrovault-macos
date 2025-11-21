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
#include <functional>
#include <string>
#include <iostream>
#include <sstream>

const bool debug = true;

inline static void
log(const std::function<void(std::ostream &)> &func)
{
    if (debug) {

        std::stringstream ss;
        func(ss);
        std::cout << ss.str();
    }
}

template<typename... Args>
inline void log(const char* fmt, Args&&... args) {

    if (debug) {

        std::string message = std::vformat(fmt, std::make_format_args(args...));
        std::cout << message;
    }
}

void dump(std::ostream &os, fuse_conn_info *p);
void dump(std::ostream &os, fuse_context *p);

