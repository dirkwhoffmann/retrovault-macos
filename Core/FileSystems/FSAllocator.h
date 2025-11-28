// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FSTypes.h"
#include "CoreObject.h"

namespace vamiga {

class FSComponent : public CoreObject {

public:

    class FileSystem &fs;
    const FSTraits &traits;

    FSComponent(FileSystem& fs);

    const char *objectName() const override { return "FSComponent"; }
    void _dump(Category category, std::ostream &os) const override { }
};

class FSAllocator final : public FSComponent {

public:

    using FSComponent::FSComponent;

    //
    // Managing the block allocation bitmap
    //

public:

    // Checks if a block is allocated or unallocated
    bool isUnallocated(Block nr) const noexcept;
    bool isAllocated(Block nr) const noexcept { return !isUnallocated(nr); }

    // Returns the number of allocated or unallocated blocks
    isize numUnallocated() const noexcept;
    isize numAllocated() const noexcept;

    // Marks a block as allocated or free
    void markAsAllocated(Block nr) { setAllocationBit(nr, 0); }
    void markAsFree(Block nr) { setAllocationBit(nr, 1); }
    void setAllocationBit(Block nr, bool value);

protected:

    // Locates the allocation bit for a certain block
    FSBlock *locateAllocationBit(Block nr, isize *byte, isize *bit) noexcept;
    const FSBlock *locateAllocationBit(Block nr, isize *byte, isize *bit) const noexcept;

    // Translate the bitmap into to a vector with the n-th bit set iff the n-th block is free
    std::vector<u32> serializeBitmap() const;

public:

};

}
