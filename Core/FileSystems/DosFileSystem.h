// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "MutableFileSystem.h"
#include <fcntl.h>

namespace vamiga {

struct Handle {

    // Unique indentifier
    isize id = 0;

    // File header block
    Block headerBlock = 0;

    // I/O offset
    isize offset = 0;

    // Open mode
    u32 flags = 0;
};

using HandleRef = isize;

struct NodeMeta {

    // Number of directory entries
    isize linkCount = 0;

    // Open file handles
    std::unordered_set<HandleRef> openHandles;

    // Number of open handles
    isize openCount() { return openHandles.size(); };
};

class DosFileSystem {
    
    MutableFileSystem &fs;

    // Runtime metadata
    std::unordered_map<Block, NodeMeta> meta;

    // Handle storage
    std::unordered_map<HandleRef, Handle> handles;

    // Handle counter
    isize nextHandle = 3;

public:

    explicit DosFileSystem(MutableFileSystem &fs);

    //
    // Querying file properties
    //

public:

    FSStat getStat(Block nr) const;
    FSStat getStat(const FSBlock &fhd) const;

private:

    NodeMeta *getMeta(Block nr);
    NodeMeta *getMeta(const FSBlock &block) { return getMeta(block.nr); }
    NodeMeta &ensureMeta(Block nr);
    NodeMeta &ensureMeta(const FSBlock &block) { return ensureMeta(block.nr); }


    //
    // Handling directories
    //

public:
    
    void mkdir(const fs::path &path);
    void rmdir(const fs::path &path);


    //
    // Handling files
    //

public:

    HandleRef open(const fs::path &path, u32 flags);
    void close(HandleRef handle);
    void unlink(const fs::path &path);
    void create(const fs::path &path);
    isize lseek(HandleRef ref, isize offset, u16 whence = 0);

private:

    void tryReclaim(const FSBlock &block);

    Handle &getHandle(HandleRef ref);
};

}
