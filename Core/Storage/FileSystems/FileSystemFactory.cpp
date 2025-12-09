// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "FileSystemFactory.h"
#include "ADFFile.h"
#include "HDFFile.h"
#include "utl/io.h"

namespace vamiga {

std::unique_ptr<FileSystem>
FileSystemFactory::fromADF(const ADFFile &adf) {

    auto desc = adf.getFileSystemDescriptor();
    return std::make_unique<FileSystem>(desc, adf.data.ptr, desc.numBlocks * 512);
}

std::unique_ptr<FileSystem>
FileSystemFactory::fromHDF(const HDFFile &hdf, isize part)
{
    auto desc = hdf.getFileSystemDescriptor(part);
    return std::make_unique<FileSystem>(desc, hdf.partitionData(part), hdf.partitionSize(part));
}

std::unique_ptr<FileSystem>
FileSystemFactory::createEmpty(isize capacity, isize blockSize)
{
    return std::make_unique<FileSystem>(capacity, blockSize);
}

std::unique_ptr<FileSystem>
FileSystemFactory::createFromDescriptor(const FSDescriptor &desc,
                                                   const fs::path &path)
{
    return std::make_unique<FileSystem>(desc, path);
}

std::unique_ptr<FileSystem>
FileSystemFactory::createLowLevel(Diameter dia,
                                  Density den,
                                  FSFormat dos,
                                  const fs::path &path)
{
    return std::make_unique<FileSystem>(FSDescriptor(dia, den, dos), path);
}

void
FileSystemFactory::initFromADF(FileSystem &fs, const ADFFile &adf)
{
    auto desc = adf.getFileSystemDescriptor();
    fs.init(desc, adf.data.ptr, desc.numBlocks * 512);
}

void
FileSystemFactory::initFromHDF(FileSystem &fs, const HDFFile &hdf, isize part)
{
    auto desc = hdf.getFileSystemDescriptor(part);
    fs.init(desc, hdf.partitionData(part), hdf.partitionSize(part));
}

void
FileSystemFactory::initCreateEmpty(FileSystem &fs, isize capacity, isize blockSize)
{
    fs.init(capacity, blockSize);
}

void
FileSystemFactory::initFromDescriptor(FileSystem &fs, const FSDescriptor &desc, const fs::path &path)
{
    fs.init(desc, path);
}
void
FileSystemFactory::initLowLevel(FileSystem &fs, Diameter dia, Density den, FSFormat dos, const fs::path &path)
{
    fs.init(FSDescriptor(dia, den, dos), path);

}

}
