// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "utl/common.h"

namespace retro::vault {

struct FileSystemError : public utl::Error {

    static constexpr long OK                = 0;
    static constexpr long UNKNOWN           = 1;

    // Posix
    static constexpr long POSIX             = 10;

    const char *errstr() const noexcept override {

        switch (payload) {

            case UNKNOWN:                   return "UNKNOWN";
            case POSIX:                     return "POSIX";

            default:
                return "???";
        }
    }

public:

    explicit FileSystemError(long fault, const std::string &s = "");
    explicit FileSystemError(long fault, const char *s) : FileSystemError(fault, std::string(s)) { };
    explicit FileSystemError(long fault, const std::filesystem::path &p) : FileSystemError(fault, p.string()) { };
    explicit FileSystemError(long fault, std::integral auto v) : FileSystemError(fault, std::to_string(v)) { };
};

}
