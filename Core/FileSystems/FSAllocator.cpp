/// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FSDoctor.h"
#include "FileSystem.h"

namespace vamiga {

FSComponent::FSComponent(FileSystem& fs) : fs(fs), traits(fs.traits)
{

}

bool
FSAllocator::isUnallocated(Block nr) const noexcept
{
    assert(isize(nr) < traits.blocks);

    // The first two blocks are always allocated and not part of the bitmap
    if (nr < 2) return false;

    // Locate the allocation bit in the bitmap block
    isize byte, bit;
    auto *bm = locateAllocationBit(nr, &byte, &bit);

    // Read the bit
    return bm ? GET_BIT(bm->data()[byte], bit) : false;
}

FSBlock *
FSAllocator::locateAllocationBit(Block nr, isize *byte, isize *bit) noexcept
{
    assert(isize(nr) < traits.blocks);

    // The first two blocks are always allocated and not part of the map
    if (nr < 2) return nullptr;
    nr -= 2;

    // Locate the bitmap block which stores the allocation bit
    isize bitsPerBlock = (traits.bsize - 4) * 8;
    isize bmNr = nr / bitsPerBlock;

    // Get the bitmap block
    FSBlock *bm = (bmNr < (isize)fs.bmBlocks.size()) ? fs.read(fs.bmBlocks[bmNr], FSBlockType::BITMAP) : nullptr;
    if (!bm) {
        warn("Failed to lookup allocation bit for block %d (%ld)\n", nr, bmNr);
        return nullptr;
    }

    // Locate the byte position (note: the long word ordering will be reversed)
    nr = nr % bitsPerBlock;
    isize rByte = nr / 8;

    // Rectifiy the ordering
    switch (rByte % 4) {
        case 0: rByte += 3; break;
        case 1: rByte += 1; break;
        case 2: rByte -= 1; break;
        case 3: rByte -= 3; break;
    }

    // Skip the checksum which is located in the first four bytes
    rByte += 4;
    assert(rByte >= 4 && rByte < traits.bsize);

    *byte = rByte;
    *bit = nr % 8;

    return bm;
}

const FSBlock *
FSAllocator::locateAllocationBit(Block nr, isize *byte, isize *bit) const noexcept
{
    return const_cast<const FSBlock *>(const_cast<FSAllocator *>(this)->locateAllocationBit(nr, byte, bit));
}

isize
FSAllocator::numUnallocated() const noexcept
{
    isize result = 0;
    for (auto &it : serializeBitmap()) result += util::popcount(it);

    if (FS_DEBUG) {

        isize count = 0;
        for (isize i = 0; i < fs.numBlocks(); i++) { if (isUnallocated(Block(i))) count++; }
        debug(true, "Unallocated blocks: Fast code: %ld Slow code: %ld\n", result, count);
        assert(count == result);
    }

    return result;
}

isize
FSAllocator::numAllocated() const noexcept
{
    return fs.numBlocks() - numUnallocated();
}

std::vector<u32>
FSAllocator::serializeBitmap() const
{
    if (!fs.isFormatted()) return {};

    auto longwords = ((fs.numBlocks() - 2) + 31) / 32;
    std::vector<u32> result;
    result.reserve(longwords);

    // Iterate through all bitmap blocks
    isize j = 0;
    for (auto &it : fs.bmBlocks) {

        if (auto *bm = fs.read(it, FSBlockType::BITMAP); bm) {

            auto *data = bm->data();
            for (isize i = 4; i < traits.bsize; i += 4) {

                if (j == longwords) break;
                result.push_back(HI_HI_LO_LO(data[i], data[i+1], data[i+2], data[i+3]));
                j++;
            }
        }
    }

    // Zero out the superfluous bits in the last word
    if (auto bits = (fs.numBlocks() - 2) % 32; bits && !result.empty()) {
        result.back() &= (1 << bits) - 1;
    }

    return result;
}

void
FSAllocator::setAllocationBit(Block nr, bool value)
{
    isize byte, bit;

    if (FSBlock *bm = locateAllocationBit(nr, &byte, &bit)) {
        REPLACE_BIT(bm->data()[byte], bit, value);
    }
}

}
