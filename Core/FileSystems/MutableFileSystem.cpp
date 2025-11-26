// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "config.h"
#include "IOUtils.h"
#include "MutableFileSystem.h"
#include "Host.h"
#include "MemUtils.h"
#include <climits>
#include <unordered_set>
#include <stack>

namespace vamiga {

void
MutableFileSystem::init(isize capacity, isize bsize)
{
    traits.blocks   = capacity;
    traits.bytes    = capacity * bsize;
    traits.bsize    = bsize;

    storage.init(capacity);

    if (isize(rootBlock) >= capacity) rootBlock = 0;
    if (isize(current) >= capacity) current = 0;
}

void
MutableFileSystem::init(const FSDescriptor &layout, const fs::path &path)
{
    if (FS_DEBUG) { layout.dump(); }

    // Create all blocks
    init(isize(layout.numBlocks));

    // Copy layout parameters
    traits.dos      = layout.dos;
    traits.reserved = layout.numReserved;
    rootBlock       = layout.rootBlock;
    bmBlocks        = layout.bmBlocks;
    bmExtBlocks     = layout.bmExtBlocks;

    // Format the file system
    format();

    // Start allocating blocks at the middle of the disk
    ap = rootBlock;

    // Print some debug information
    if (FS_DEBUG) { dump(Category::State); }
    
    // Import files if a path is given
    if (!path.empty()) {
        
        // Add all files
        import(root(), path, true, true);

        // Assign device name
        setName(FSName(path.filename().string()));
    }
}

void
MutableFileSystem::init(Diameter dia, Density den, FSFormat dos, const fs::path &path)
{
    // Get a device descriptor
    auto descriptor = FSDescriptor(dia, den, dos);
    
    // Create the device
    init(descriptor, path);
}

void
MutableFileSystem::format(string name)
{
    format(traits.dos);
}

void
MutableFileSystem::format(FSFormat dos, string name){

    require_initialized();

    traits.dos = dos;
    if (dos == FSFormat::NODOS) return;

    // Perform some consistency checks
    assert(numBlocks() > 2);
    assert(rootBlock > 0);

    // Trash all existing data
    storage.init(numBlocks());

    // Create boot blocks
    storage[0].init(FSBlockType::BOOT);
    storage[1].init(FSBlockType::BOOT);

    // Create the root block
    storage[rootBlock].init(FSBlockType::ROOT);

    // Create bitmap blocks
    for (auto& ref : bmBlocks) {
        
        // storage.write(ref, new FSBlock(this, ref, FSBlockType::BITMAP_BLOCK));
        storage[ref].init(FSBlockType::BITMAP);
    }

    // Add bitmap extension blocks
    Block pred = rootBlock;
    for (auto &ref : bmExtBlocks) {

        // storage.write(ref, new FSBlock(this, ref, FSBlockType::BITMAP_EXT_BLOCK));
        storage[ref].init(FSBlockType::BITMAP_EXT);
        storage[pred].setNextBmExtBlockRef(ref);
        pred = ref;
    }
    
    // Add all bitmap block references
    storage[rootBlock].addBitmapBlockRefs(bmBlocks);

    // Mark free blocks as free in the bitmap block
    // TODO: SPEED THIS UP
    for (isize i = 0; i < numBlocks(); i++) {
        if (storage.isEmpty(Block(i))) markAsFree(Block(i));
    }
    
    // Set the volume name
    if (name != "") setName(name);

    // Rectify checksums
    storage[0].updateChecksum();
    storage[1].updateChecksum();
    storage[rootBlock].updateChecksum();
    for (auto& ref : bmBlocks) { storage[ref].updateChecksum(); }
    for (auto& ref : bmExtBlocks) { storage[ref].updateChecksum(); }

    // Set the current directory
    current = rootBlock;
}

void
MutableFileSystem::setName(FSName name)
{
    if (auto *rb = storage.read(rootBlock, FSBlockType::ROOT); rb) {

        rb->setName(name);
        rb->updateChecksum();
    }
}

/*
isize
MutableFileSystem::requiredDataBlocks(isize fileSize) const
{
    // Compute the capacity of a single data block
    isize numBytes = traits.bsize - (traits.ofs() ? 24 : 0);

    // Compute the required number of data blocks
    return (fileSize + numBytes - 1) / numBytes;
}

isize
MutableFileSystem::requiredFileListBlocks(isize fileSize) const
{
    // Compute the required number of data blocks
    isize numBlocks = requiredDataBlocks(fileSize);
    
    // Compute the number of data block references in a single block
    isize numRefs = (traits.bsize / 4) - 56;

    // Small files do not require any file list block
    if (numBlocks <= numRefs) return 0;
    
    // Compute the required number of additional file list blocks
    return (numBlocks - 1) / numRefs;
}

isize
MutableFileSystem::requiredBlocks(isize fileSize) const
{
    isize numDataBlocks = requiredDataBlocks(fileSize);
    isize numFileListBlocks = requiredFileListBlocks(fileSize);
    
    debug(FS_DEBUG, "Required file header blocks : %d\n",  1);
    debug(FS_DEBUG, "       Required data blocks : %ld\n", numDataBlocks);
    debug(FS_DEBUG, "  Required file list blocks : %ld\n", numFileListBlocks);
    
    return 1 + numDataBlocks + numFileListBlocks;
}
*/

bool
MutableFileSystem::allocatable(isize count) const
{
    Block i = ap;
    isize capacity = numBlocks();
    
    while (count > 0) {

        if (storage.getType(Block(i)) == FSBlockType::EMPTY) {
            if (--count == 0) break;
        }
        
        i = (i + 1) % capacity;
        if (i == ap) return false;
    }
    
    return true;
}

Block
MutableFileSystem::allocate()
{
    Block i = ap;
    
    while (!isEmpty(i)) {
        
        if ((i = (i + 1) % numBlocks()) == ap) {
            
            debug(FS_DEBUG, "No more free blocks\n");
            throw AppError(Fault::FS_OUT_OF_SPACE);
        }
    }
    
    read(i)->type = FSBlockType::UNKNOWN;
    markAsAllocated(i);
    ap = (i + 1) % numBlocks();
    return i;
}

void
MutableFileSystem::allocate(isize count, std::vector<Block> &result, std::vector<Block> prealloc)
{
    /* Allocate multiple blocks and return them in `result`.
     *
     * Parameters:
     *
     * count    – number of blocks to allocate
     * result   – vector to store the allocated blocks
     * prealloc – optional list of pre-allocated blocks. If not empty, these
     *            blocks are used first: the allocator moves blocks from
     *            `prealloc` into `result` until `prealloc` is empty.
     *            Remaining blocks (if any) are allocated normally.
     *
     * Notes:
     *
     * - The function does not modify `prealloc` outside of moving blocks.
     * - Guarantees that `result` contains exactly `count` blocks upon return.
     */

    // Step 1: Use pre-allocated blocks first
    while (!prealloc.empty() && count > 0) {

        result.push_back(prealloc.back());
        prealloc.pop_back();
        count--;
    }

    // Step 2: Allocate remaining blocks from free space
    Block i = ap;
    while (count > 0) {

        if (isEmpty(i)) {

            read(i)->type = FSBlockType::UNKNOWN;
            result.push_back(i);
            count--;
        }

        // Move to the next block
        i = (i + 1) % numBlocks();

        // Fail if we looped all the way and still need blocks
        if (i == ap && count > 0) {

            debug(FS_DEBUG, "No more free blocks\n");
            throw AppError(Fault::FS_OUT_OF_SPACE);
        }
    }

    // Step 3: Mark all blocks as allocated
    for (const auto &b : result) markAsAllocated(b);

    // Step 4: Advance allocation pointer
    ap = i;
}

void
MutableFileSystem::deallocateBlock(Block nr)
{
    storage[nr].init(FSBlockType::EMPTY);
    markAsFree(nr);
}

void
MutableFileSystem::deallocateBlocks(const std::vector<Block> &nrs)
{
    for (Block nr : nrs) { deallocateBlock(nr); }
}

void
MutableFileSystem::addFileListBlock(Block at, Block head, Block prev)
{
    if (auto *prevBlock = read(prev); prevBlock) {

        storage[at].init(FSBlockType::FILELIST);
        storage[at].setFileHeaderRef(head);

        prevBlock->setNextListBlockRef(at);
    }
}

void
MutableFileSystem::addDataBlock(Block at, isize id, Block head, Block prev)
{
    if (auto *prevBlock = read(prev); prevBlock) {

        storage[at].init(traits.ofs() ? FSBlockType::DATA_OFS : FSBlockType::DATA_FFS);
        storage[at].setDataBlockNr((Block)id);
        storage[at].setFileHeaderRef(head);
        prevBlock->setNextDataBlockRef(at);
    }
}

FSBlock &
MutableFileSystem::newUserDirBlock(const FSName &name)
{
    Block nr = allocate();

    storage[nr].init(FSBlockType::USERDIR);
    storage[nr].setName(name);
    return at(nr);
}

FSBlock &
MutableFileSystem::newFileHeaderBlock(const FSName &name)
{
    Block nr = allocate();

    storage[nr].init(FSBlockType::FILEHEADER);
    storage[nr].setName(name);
    return at(nr);
}

void
MutableFileSystem::updateChecksums() noexcept
{
    storage.updateChecksums();
}

void
MutableFileSystem::makeBootable(BootBlockId id)
{
    assert(storage.getType(0) == FSBlockType::BOOT);
    assert(storage.getType(1) == FSBlockType::BOOT);
    storage[0].writeBootBlock(id, 0);
    storage[1].writeBootBlock(id, 1);
}

void
MutableFileSystem::killVirus()
{
    assert(storage.getType(0) == FSBlockType::BOOT);
    assert(storage.getType(1) == FSBlockType::BOOT);

    if (bootBlockType() == BootBlockType::VIRUS) {

        auto id =
        traits.ofs() ? BootBlockId::AMIGADOS_13 :
        traits.ffs() ? BootBlockId::AMIGADOS_20 : BootBlockId::NONE;

        if (id != BootBlockId::NONE) {
            storage[0].writeBootBlock(id, 0);
            storage[1].writeBootBlock(id, 1);
        } else {
            std::memset(storage[0].data() + 4, 0, traits.bsize - 4);
            std::memset(storage[1].data(), 0, traits.bsize);
        }
    }
}

void
MutableFileSystem::setAllocationBit(Block nr, bool value)
{
    isize byte, bit;
    
    if (FSBlock *bm = locateAllocationBit(nr, &byte, &bit)) {
        REPLACE_BIT(bm->data()[byte], bit, value);
    }
}

void
MutableFileSystem::rectifyAllocationMap()
{
    for (isize i = 0, max = numBlocks(); i < max; i++) {
        
        auto free = isUnallocated(Block(i));
        auto empty = isEmpty(Block(i));

        if (empty && !free) {
            markAsFree(Block(i));
        }
        if (!empty && free) {
            markAsAllocated(Block(i));
        }
    }
}

FSBlock &
MutableFileSystem::createDir(FSBlock &at, const FSName &name)
{
    ensureDirectory(at);

    // Error out if the file already exists
    if (seekPtr(&at, name)) throw(AppError(Fault::FS_EXISTS, name.cpp_str()));

    FSBlock &block = newUserDirBlock(name);
    block.setParentDirRef(at.nr);
    addToHashTable(at.nr, block.nr);

    return block;
}

FSBlock &
MutableFileSystem::link(FSBlock &at, const FSName &name)
{
    FSBlock &fhb = newFileHeaderBlock(name);

    try {
        link(at, name, fhb);
    } catch(...) {
        deallocateBlock(fhb.nr);
        throw;
    }

    return fhb;
}

void
MutableFileSystem::link(FSBlock &at, const FSName &name, FSBlock &fhb)
{
    // Files can only be linked to directories
    if (!at.isDirectory()) throw AppError(Fault::FS_NOT_A_DIRECTORY);

    // Error out if the file already exists
    if (seekPtr(&at, name)) throw(AppError(Fault::FS_EXISTS, name.cpp_str()));

    // Wire up
    fhb.setParentDirRef(at.nr);
    addToHashTable(at.nr, fhb.nr);
}

void
MutableFileSystem::unlink(const FSBlock &node)
{
    // Check block type
    if (!node.isFile() && !node.isDirectory()) throw AppError(Fault::FS_NOT_A_FILE);

    // Remove the file from the hash table
    deleteFromHashTable(node);
}


void
MutableFileSystem::reclaim(const FSBlock &node)
{
    if (node.isDirectory()) {

        // Remove user directory block
        storage.erase(node.nr); markAsFree(node.nr);
        return;
    }

    if (node.isFile()) {

        // Collect all blocks occupied by this file
        auto dataBlocks = collectDataBlocks(node.nr);
        auto listBlocks = collectListBlocks(node.nr);

        // Remove all blocks
        storage.erase(node.nr); markAsFree(node.nr);
        for (auto &it : dataBlocks) { storage.erase(it); markAsFree(it); }
        for (auto &it : listBlocks) { storage.erase(it); markAsFree(it); }
        return;
    }

    throw AppError(Fault::FS_NOT_A_FILE_OR_DIRECTORY, node.absName());
}


FSBlock &
MutableFileSystem::createFile(FSBlock &at, const FSName &name)
{
    if (at.isDirectory()) {

        // Error out if the file already exists
        if (seekPtr(&at, name)) throw(AppError(Fault::FS_EXISTS, name.cpp_str()));

        FSBlock &block = newFileHeaderBlock(name);
        block.setParentDirRef(at.nr);
        addToHashTable(at.nr, block.nr);
        return block;
    }
    throw AppError(Fault::FS_NOT_A_DIRECTORY, at.absName());
}

FSBlock &
MutableFileSystem::createFile(FSBlock &at, const FSName &name, const Buffer<u8> &buf)
{
    return createFile(at, name, buf.ptr, buf.size);
}

FSBlock &
MutableFileSystem::createFile(FSBlock &top, const FSName &name, const string &str)
{
    return createFile(top, name, (const u8 *)str.c_str(), (isize)str.size());
}

FSBlock &
MutableFileSystem::createFile(FSBlock &top, const FSName &name, const u8 *buf, isize size)
{
    assert(buf);

    // Compute the number of data block references held in a file header or list block
    // const usize numRefs = ((traits.bsize / 4) - 56);

    // Create a file header block
    auto &fhb = createFile(top, name);

    // Set file size
    fhb.setFileSize(u32(size));

    // Create the file
    return createFile(fhb, buf, size);

    /*
    // Allocate blocks
    std::vector<Block> listBlocks;
    std::vector<Block> dataBlocks;
    allocateFileBlocks(size, listBlocks, dataBlocks);

    for (usize i = 0; i < listBlocks.size(); i++) {

        // Add a list block
        addFileListBlock(listBlocks[i], file.nr, i == 0 ? file.nr : listBlocks[i-1]);
    }

    for (usize i = 0; i < dataBlocks.size(); i++) {

        // Add a data block
        addDataBlock(dataBlocks[i], i + 1, file.nr, i == 0 ? file.nr : dataBlocks[i-1]);

        // Determine the list block managing this data block
        FSBlock *lb = read((i < numRefs) ? file.nr : listBlocks[i / numRefs - 1]);

        // Link the data block
        lb->addDataBlockRef(dataBlocks[0], dataBlocks[i]);

        // Add data bytes
        isize written = addData(dataBlocks[i], buf, size);
        buf += written;
        size -= written;
    }

    // Rectify checksums
    for (auto &it : listBlocks) { at(it).updateChecksum(); }
    for (auto &it : dataBlocks) { at(it).updateChecksum(); }
    file.updateChecksum();
    // top.updateChecksum();

    return file;
    */
}

/*
FSBlock &
MutableFileSystem::createFile(FSBlock &top, FSBlock &fhb, const u8 *buf, isize size)
{
    // Number of data block references held in a file header or list block
    const usize numRefs = ((traits.bsize / 4) - 56);

    // Allocate blocks
    std::vector<Block> listBlocks;
    std::vector<Block> dataBlocks;
    allocateFileBlocks(size, listBlocks, dataBlocks);

    for (usize i = 0; i < listBlocks.size(); i++) {

        // Add a list block
        addFileListBlock(listBlocks[i], fhb.nr, i == 0 ? fhb.nr : listBlocks[i-1]);
    }

    for (usize i = 0; i < dataBlocks.size(); i++) {

        // Add a data block
        addDataBlock(dataBlocks[i], i + 1, fhb.nr, i == 0 ? fhb.nr : dataBlocks[i-1]);

        // Determine the list block managing this data block
        FSBlock *lb = read((i < numRefs) ? fhb.nr : listBlocks[i / numRefs - 1]);

        // Link the data block
        lb->addDataBlockRef(dataBlocks[0], dataBlocks[i]);

        // Add data bytes
        isize written = addData(dataBlocks[i], buf, size);
        buf += written;
        size -= written;
    }

    // Rectify checksums
    for (auto &it : listBlocks) { at(it).updateChecksum(); }
    for (auto &it : dataBlocks) { at(it).updateChecksum(); }
    fhb.updateChecksum();
    // top.updateChecksum();

    return fhb;
}
*/

FSBlock &
MutableFileSystem::createFile(FSBlock &fhb,
                              const u8 *buf, isize size,
                              std::vector<Block> listBlocks,
                              std::vector<Block> dataBlocks)
{
    // Number of data block references held in a file header or list block
    const usize numRefs = ((traits.bsize / 4) - 56);

    // Start with a clean reference area
    fhb.setNextListBlockRef(0);
    fhb.setNextDataBlockRef(0);
    for (isize i = 0; i < numRefs; i++) fhb.setDataBlockRef(i, 0);

    // Allocate blocks
    allocateFileBlocks(size, listBlocks, dataBlocks);

    for (usize i = 0; i < listBlocks.size(); i++) {

        // Add a list block
        addFileListBlock(listBlocks[i], fhb.nr, i == 0 ? fhb.nr : listBlocks[i-1]);
    }

    for (usize i = 0; i < dataBlocks.size(); i++) {

        // Add a data block
        addDataBlock(dataBlocks[i], i + 1, fhb.nr, i == 0 ? fhb.nr : dataBlocks[i-1]);

        // Determine the list block managing this data block
        FSBlock *lb = read((i < numRefs) ? fhb.nr : listBlocks[i / numRefs - 1]);

        // Link the data block
        lb->addDataBlockRef(dataBlocks[0], dataBlocks[i]);

        // Add data bytes
        isize written = addData(dataBlocks[i], buf, size);
        buf += written;
        size -= written;
    }

    // Set file size
    fhb.setFileSize(u32(size));

    // Rectify checksums
    for (auto &it : listBlocks) { at(it).updateChecksum(); }
    for (auto &it : dataBlocks) { at(it).updateChecksum(); }
    fhb.updateChecksum();

    return fhb;
}

void
MutableFileSystem::resize(FSBlock &at, isize size)
{
    // Get data
    Buffer<u8> buffer; at.extractData(buffer);

    // Resize the buffer (pad with 0 if the buffer expands)
    buffer.resize(size, 0);

    // Resize the file with the contents of the created buffer
    resize(at, buffer);
}

void
MutableFileSystem::resize(FSBlock &at, const Buffer<u8> &data)
{
    // Collect all blocks occupied by this file
    auto dataBlocks = collectDataBlocks(at.nr);
    auto listBlocks = collectListBlocks(at.nr);

    // Update the file contents
    createFile(at, data.ptr, data.size, dataBlocks, listBlocks);
}

void
MutableFileSystem::rename(FSBlock &item, const FSName &name)
{
    // Renaming the root node renames the name of the file system
    if (item.isRoot()) { setName(name); return; }

    // For files and directories, reposition the item in the hash table
    move(item, *item.getParentDirBlock(), name);
}

void
MutableFileSystem::move(FSBlock &item, const FSBlock &dest, const FSName &name)
{
    ensureDirectory(dest);

    // Remove the item from the hash table
    deleteFromHashTable(item);

    // Rename if a new name is provided
    if (name != "") item.setName(name);

    // Add the item to the new hash table
    addToHashTable(dest.nr, item.nr);

    // Assign the new parent directory
    item.setParentDirRef(dest.nr);
}

void
MutableFileSystem::copy(const FSBlock &item, FSBlock &dest)
{
    copy(item, dest, item.cppName());
}

void
MutableFileSystem::copy(const FSBlock &item, FSBlock &dest, const FSName &name)
{
    if (!item.isFile()) throw AppError(Fault::FS_NOT_A_FILE, item.absName());
    if (!dest.isDirectory()) throw AppError(Fault::FS_NOT_A_DIRECTORY, dest.absName());

    // Read the file
    Buffer<u8> buffer; item.extractData(buffer);

    // Recreate the file at the target location
    createFile(dest, name, buffer);
}

void
MutableFileSystem::deleteFile(const FSBlock &node)
{
    unlink(node);
    reclaim(node);

    /*
    if (!node.isFile()) throw AppError(Fault::FS_NOT_A_FILE, node.absName());

    // Collect all blocks occupied by this file
    auto dataBlocks = collectDataBlocks(node.nr);
    auto listBlocks = collectListBlocks(node.nr);

    // Remove the file from the hash table
    deleteFromHashTable(node);

    // Remove all blocks
    storage.erase(node.nr); markAsFree(node.nr);
    for (auto &it : dataBlocks) { storage.erase(it); markAsFree(it); }
    for (auto &it : listBlocks) { storage.erase(it); markAsFree(it); }
    */
}

/*
void
MutableFileSystem::rmdir(const FSBlock &at)
{
    // Only directories can be removed
    if (!at.isDirectory()) throw AppError(Fault::FS_NOT_A_DIRECTORY);

    // The directory must be empty
    FSTree tree(at, FSOpt{});
    if (!tree.empty()) throw AppError(Fault::FS_DIR_NOT_EMPTY);

    // Remove directory from hash table
    deleteFromHashTable(at);
}
*/

void
MutableFileSystem::addToHashTable(const FSBlock &item)
{
    addToHashTable(item.getParentDirRef(), item.nr);
}

void
MutableFileSystem::addToHashTable(Block parent, Block ref)
{
    FSBlock *pp = read(parent);
    if (!pp) throw AppError(Fault::FS_OUT_OF_RANGE);
    if (!pp->hasHashTable()) throw AppError(Fault::FS_WRONG_BLOCK_TYPE);

    FSBlock *pr = read(ref);
    if (!pr) throw AppError(Fault::FS_OUT_OF_RANGE);
    if (!pr->isHashable()) throw AppError(Fault::FS_WRONG_BLOCK_TYPE);

    // Read the linked list from the proper hash-table bucket
    u32 hash = pr->hashValue() % pp->hashTableSize();
    auto chain = collectHashedBlocks(pp->nr, hash);

    if (chain.empty()) {

        // If the bucket is empty, make the reference the first entry
        pp->setHashRef(hash, ref);
        pp->updateChecksum();

    } else {

        // Otherwise, put the reference at the end of the linked list
        read(chain.back())->setNextHashRef(ref);
        read(chain.back())->updateChecksum();
    }
}

void
MutableFileSystem::deleteFromHashTable(const FSBlock &item)
{
    deleteFromHashTable(item.getParentDirRef(), item.nr);
}

void
MutableFileSystem::deleteFromHashTable(Block parent, Block ref)
{
    FSBlock *pp = read(parent);
    if (!pp) throw AppError(Fault::FS_OUT_OF_RANGE);
    if (!pp->hasHashTable()) throw AppError(Fault::FS_WRONG_BLOCK_TYPE);

    FSBlock *pr = read(ref);
    if (!pr) throw AppError(Fault::FS_OUT_OF_RANGE);
    if (!pr->isHashable()) throw AppError(Fault::FS_WRONG_BLOCK_TYPE);

    // Read the linked list from the proper hash-table bucket
    u32 hash = pr->hashValue() % pp->hashTableSize();
    auto chain = collectHashedBlocks(pp->nr, hash);

    // Find the element
    if (auto it = std::find(chain.begin(), chain.end(), ref); it != chain.end()) {

        auto pred = it != chain.begin() ? *(it - 1) : 0;
        auto succ = (it + 1) != chain.end() ? *(it + 1) : 0;

        // Remove the element from the list
        if (!pred) {

            pp->setHashRef(hash, succ);
            pp->updateChecksum();

        } else {

            read(pred)->setNextHashRef(succ);
            read(pred)->updateChecksum();
        }
    }
}

isize
MutableFileSystem::addData(Block nr, const u8 *buf, isize size)
{
    FSBlock *block = read(nr);
    return block ? addData(*block, buf, size) : 0;
}

isize
MutableFileSystem::addData(FSBlock &block, const u8 *buf, isize size)
{
    isize count = 0;
    
    switch (block.type) {
            
        case FSBlockType::DATA_OFS:
            
            count = std::min(traits.bsize - 24, size);
            std::memcpy(block.data() + 24, buf, count);
            block.setDataBytesInBlock((u32)count);
            block.updateChecksum();
            break;

        case FSBlockType::DATA_FFS:

            count = std::min(traits.bsize, size);
            std::memcpy(block.data(), buf, count);
            break;

        default:
            break;
    }
    
    return count;
}

void
MutableFileSystem::allocateFileBlocks(isize bytes,
                                      std::vector<Block> &listBlocks,
                                      std::vector<Block> &dataBlocks)
{
    /* This function takes a file size and two lists:

            listBlocks  – pre-allocated list blocks (extension blocks)
            dataBlocks  – pre-allocated data blocks

        It first determines how many blocks of each type are required to store
        a file of the given size. If the caller provided more blocks than needed,
        the surplus blocks are freed. If fewer blocks are provided, new blocks
        are allocated and appended to the respective lists.
    */

    auto freeSurplus = [&](std::vector<Block> &blocks, usize count) {

        if (blocks.size() > count) {

            for (auto i = count; i < blocks.size(); i++) {
                deallocateBlock(blocks[i]);
            }
            blocks.resize(count);

        } else {

            blocks.reserve(count);
        }
    };

    isize dataBlocksNeeded = 0;
    auto ensureDataBlocks = [&](isize n) {

        dataBlocksNeeded += n;
        while (dataBlocks.size() < dataBlocksNeeded) allocate(1, dataBlocks);
    };

    isize listBlocksNeeded = 0;
    auto ensureListBlocks = [&](isize n) {

        listBlocksNeeded += n;
        while (listBlocks.size() < listBlocksNeeded) allocate(1, listBlocks);
    };

    isize numDataBlocks         = requiredDataBlocks(bytes);
    isize numListBlocks         = requiredFileListBlocks(bytes);
    isize refsPerBlock          = (traits.bsize / 4) - 56;
    isize refsInHeaderBlock     = std::min(numDataBlocks, refsPerBlock);
    isize refsInListBlocks      = numDataBlocks - refsInHeaderBlock;
    isize refsInLastListBlock   = refsInListBlocks % refsPerBlock;
    
    debug(FS_DEBUG, "                   Data bytes : %ld\n", bytes);
    debug(FS_DEBUG, "         Required data blocks : %ld\n", numDataBlocks);
    debug(FS_DEBUG, "         Required list blocks : %ld\n", numListBlocks);
    debug(FS_DEBUG, "         References per block : %ld\n", refsPerBlock);
    debug(FS_DEBUG, "   References in header block : %ld\n", refsInHeaderBlock);
    debug(FS_DEBUG, "    References in list blocks : %ld\n", refsInListBlocks);
    debug(FS_DEBUG, "References in last list block : %ld\n", refsInLastListBlock);

    // Free the surplus list blocks
    freeSurplus(listBlocks, numListBlocks);
    freeSurplus(dataBlocks, numDataBlocks);

    if (traits.ofs()) {

        // Header block -> Data blocks -> List block -> Data blocks ... List block -> Data blocks
        ensureDataBlocks(refsInHeaderBlock);

        for (isize i = 0; i < numListBlocks; i++) {

            ensureListBlocks(1);
            ensureDataBlocks(i < numListBlocks - 1 ? refsPerBlock : refsInLastListBlock);
        }
    }
    
    if (traits.ffs()) {
        
        // Header block -> Data blocks -> All list block -> All remaining data blocks
        ensureDataBlocks(refsInHeaderBlock);
        ensureListBlocks(numListBlocks);
        ensureDataBlocks(refsInListBlocks);
    }

    // Rectify checksums
    for (auto &it : bmBlocks) at(it).updateChecksum();
    for (auto &it : bmExtBlocks) at(it).updateChecksum();
}

void
MutableFileSystem::importVolume(const u8 *src, isize size)
{
    assert(src != nullptr);

    debug(FS_DEBUG, "Importing file system...\n");

    // Only proceed if the (predicted) block size matches
    if (size % traits.bsize != 0) throw AppError(Fault::FS_WRONG_BSIZE);

    // Only proceed if the source buffer contains the right amount of data
    if (numBytes() != size) throw AppError(Fault::FS_WRONG_CAPACITY);

    // Only proceed if all partitions contain a valid file system
    if (traits.dos == FSFormat::NODOS) throw AppError(Fault::FS_UNSUPPORTED);

    // Import all blocks
    for (isize i = 0; i < numBlocks(); i++) {
        
        const u8 *data = src + i * traits.bsize;

        // Determine the type of the new block
        if (FSBlockType type = predictType((Block)i, data); type != FSBlockType::EMPTY) {

            // Create new block
            storage[i].init(type);
            storage[i].importBlock(data, traits.bsize);
        }
    }
    
    // Print some debug information
    debug(FS_DEBUG, "Success\n");
}

void
MutableFileSystem::import(const fs::path &path, bool recursive, bool contents)
{
    import(pwd(), path, recursive, contents);
}

void
MutableFileSystem::import(FSBlock &top, const fs::path &path, bool recursive, bool contents)
{
    fs::directory_entry dir;

    // Get the directory item
    try { dir = fs::directory_entry(path); } catch (...) {
        throw AppError(Fault::FILE_CANT_READ);
    }

    if (dir.is_directory() && contents) {

        // Add the directory contents
        for (const auto& it : fs::directory_iterator(dir)) import(top, it, recursive);

    } else {

        // Add the file or directory as a whole
        import(top, dir, recursive);
    }

    // Rectify the checksums of all blocks
    updateChecksums();

    // Verify the result
    if (FS_DEBUG) doctor.xray(true, std::cout, false);
}

void
MutableFileSystem::import(FSBlock &top, const fs::directory_entry &entry, bool recursive)
{
    auto isHidden = [&](const fs::path &path) {

        string s = path.filename().string();
        return !s.empty() && s[0] == '.';
    };

    const auto path = entry.path().string();
    const auto name = entry.path().filename();
    FSName fsname = FSName(name);

    // Skip hidden files
    if (isHidden(name)) return;

    if (entry.is_regular_file()) {

        debug(FS_DEBUG > 1, "  Importing file %s\n", path.c_str());

        Buffer<u8> buffer(entry.path());
        if (buffer) {
            createFile(top, fsname, buffer.ptr, buffer.size);
        } else {
            createFile(top, fsname);
        }

    } else {

        debug(FS_DEBUG > 1, "Importing directory %s\n", fsname.c_str());

        // Create new directory
        auto &subdir = createDir(top, fsname);

        // Import all items
        for (const auto& it : fs::directory_iterator(entry)) {

            if (it.is_regular_file() || recursive) import(subdir, it, recursive);
        }
    }
}

bool
MutableFileSystem::exportVolume(u8 *dst, isize size) const
{
    return exportBlocks(0, (Block)(numBlocks() - 1), dst, size);
}

bool
MutableFileSystem::exportVolume(u8 *dst, isize size, Fault *err) const
{
    return exportBlocks(0, (Block)(numBlocks() - 1), dst, size, err);
}

bool
MutableFileSystem::exportBlock(Block nr, u8 *dst, isize size) const
{
    return exportBlocks(nr, nr, dst, size);
}

bool
MutableFileSystem::exportBlock(Block nr, u8 *dst, isize size, Fault *error) const
{
    return exportBlocks(nr, nr, dst, size, error);
}

bool
MutableFileSystem::exportBlocks(Block first, Block last, u8 *dst, isize size) const
{
    Fault error;
    bool result = exportBlocks(first, last, dst, size, &error);
    
    assert(result == (error == Fault::OK));
    return result;
}

bool
MutableFileSystem::exportBlocks(Block first, Block last, u8 *dst, isize size, Fault *err) const
{
    assert(last < (Block)numBlocks());
    assert(first <= last);
    assert(dst);
    
    isize count = last - first + 1;
    
    debug(FS_DEBUG, "Exporting %ld blocks (%d - %d)\n", count, first, last);

    // Only proceed if the (predicted) block size matches
    if (size % traits.bsize != 0) {
        if (err) *err = Fault::FS_WRONG_BSIZE;
        return false;
    }

    // Only proceed if the source buffer contains the right amount of data
    if (count * traits.bsize != size) {
        if (err) *err = Fault::FS_WRONG_CAPACITY;
        return false;
    }

    // Wipe out the target buffer
    std::memset(dst, 0, size);
    
    // Export all blocks
    for (auto &block: storage.keys(first, last)) {

        storage.read(block)->exportBlock(dst + (block - first) * traits.bsize, traits.bsize);
    }

    debug(FS_DEBUG, "Success\n");
    if (err) *err = Fault::OK;
    return true;
}

void
MutableFileSystem::exportBlock(Block nr, const fs::path &path) const
{
    exportBlocks(nr, nr, path);
}

void
MutableFileSystem::exportBlocks(Block first, Block last, const fs::path &path) const
{
    std::ofstream stream(path, std::ios::binary);

    if (!stream.is_open()) {
        throw AppError(Fault::FILE_CANT_CREATE, path);
    }

    for (Block i = first; i <= last; i++) {

        auto *data = at(i).data();
        stream.write((const char *)data, traits.bsize);
    }

    if (!stream) {
        throw AppError(Fault::FILE_CANT_WRITE, path);
    }
}

void
MutableFileSystem::exportBlocks(const fs::path &path) const
{
    if (traits.blocks) {
        exportBlocks(0, Block(traits.blocks - 1), path);
    }
}

void
MutableFileSystem::exportFiles(Block nr, const fs::path &path, bool recursive, bool contents) const
{
    const FSBlock *block = read(nr);
    exportFiles(*block, path, recursive, contents);

}

void
MutableFileSystem::exportFiles(const FSBlock &item, const fs::path &path, bool recursive, bool contents) const
{
    fs::path hostPath;

    if (item.isDirectory()) {

        hostPath = contents ? path : path / item.cppName();
        if (!fs::exists(hostPath)) fs::create_directories(hostPath);

    } else if (item.isFile())  {

        hostPath = fs::is_directory(path) ? path / item.cppName() : path;
    }

    debug(FS_DEBUG, "Exporting %s to %s\n", item.absName().c_str(), hostPath.string().c_str());
    FSTree tree(item, { .recursive = recursive });
    tree.save(hostPath, { .recursive = recursive });
}

void
MutableFileSystem::exportFiles(const fs::path &path, bool recursive, bool contents) const
{
    exportFiles(pwd(), path, recursive, contents);
}

void
MutableFileSystem::importBlock(Block nr, const fs::path &path)
{
    std::ifstream stream(path, std::ios::binary);

    if (!stream.is_open()) {
        throw AppError(Fault::FILE_CANT_READ, path);
    }

    auto *data = at(nr).data();
    stream.read((char *)data, traits.bsize);

    if (!stream) {
        throw AppError(Fault::FILE_CANT_READ, path);
    }
}

}
