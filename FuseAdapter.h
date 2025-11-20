// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "VAmiga.h"
#include "Media.h"
#include "FuseAPI.h"

using std::string;
using namespace vamiga;

class FuseAdapter {

#include "FuseAdapterCallbacks.h"

    bool debug = true;

    ADFFile *adf = nullptr;
    MutableFileSystem *fs = nullptr;

    static fuse_operations callbacks;

    static FuseAdapter &self() {
        return *(static_cast<FuseAdapter *>(fuse_get_context()->private_data));
    }

public:

    // void log(const string &s);
    // void log(const char* fmt, auto&&... args);
    void log(const std::function<void(std::ostream &)> &func);

    template<typename... Args>
    void log(const char* fmt, Args&&... args) {
        std::string message = std::vformat(fmt, std::make_format_args(args...));
        std::cout << message;
    }

    int myMain();
};


