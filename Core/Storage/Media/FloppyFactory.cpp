// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "FloppyFactory.h"
#include "Media.h"
#include "utl/io.h"

namespace vamiga {

std::unique_ptr<FloppyFile>
FloppyFactory::make(const fs::path &path)
{
    std::unique_ptr<FloppyFile> result;

    switch (MediaFile::type(path)) {

        case FileType::ADF:  result = make_unique<ADFFile>(path); break;
        case FileType::ADZ:  result = make_unique<ADZFile>(path); break;
        case FileType::IMG:  result = make_unique<IMGFile>(path); break;

        default:
            throw IOError(IOError::FILE_TYPE_UNSUPPORTED);
    }

    result->path = path;
    return result;
}

}
