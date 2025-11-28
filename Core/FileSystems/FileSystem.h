// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

/* The FileSystem class represents an Amiga file system (OFS or FFS).
 * It models a logical volume that can be created from either an ADF or an HDF.
 * In the case of an HDF, each partition can be converted into an independent
 * file system instance.
 *
 * The FileSystem class is organized as a layered architecture to clearly
 * separate responsibilities and to enforce downward-only dependencies.
 *
 * Layer 0: Block Storage Layer
 *
 *          Provides raw access to storage blocks and is unaware
 *          of files, directories, or paths.
 *
 * Layer 1: Read Layer
 *
 *          Interprets storage blocks as files and directories according to
 *          OFS or FFS semantics, enabling read operations and metadata access.
 *
 * Layer 2: Write Layer
 *
 *          Adds write capabilities, allowing modifications to files,
 *          directories, and metadata.
 *
 * Layer 3: Path Resolution Layer
 *
 *          Resolves symbolic and relative paths into concrete file system
 *          objects and canonicalizes paths. It depends only on the read and
 *          write layers.
 *
 * Layer 4: POSIX Layer
 *
 *          This layer wraps a Layer-3 file system and hides all lower-level
 *          access functions. It exposes a POSIX-like high-level API that
 *          provides operations such as open, close, read, write, and file
 *          handle management.
 */

#define FS_ENABLE_LAYER 4

#include "FSTypes.h"
#include "FSBlock.h"
#include "FSDescriptor.h"
#include "FSObjects.h"
#include "FSTree.h"
#include "FSStorage.h"
#include "FSDoctor.h"
#include "ADFFile.h"
#include "HDFFile.h"
#include <stack>
#include <unordered_set>

namespace vamiga {

class ADFFile;
class HDFFile;
class FloppyDrive;
class HardDrive;

class FileSystem : public CoreObject, public Inspectable<FSInfo, FSStats> {

    friend struct FSBlock;
    friend class  FSDoctor;
    friend struct FSHashTable;
    friend struct FSPartition;
    friend class  FileSystem;
    
public:

    // Disk doctor
    FSDoctor doctor = FSDoctor(*this);

private:

    // Static file system properties
    FSTraits traits;

    // Block storage
    FSStorage storage = FSStorage(this);

    // Location of the root block
    Block rootBlock = 0;

    // Location of the current directory
    Block current = 0;

    // Location of bitmap blocks and extended bitmap blocks
    std::vector<Block> bmBlocks;
    std::vector<Block> bmExtBlocks;

    // Allocation pointer (used by the allocator to select the next block)
    Block ap = 0;


    //
    // Initializing
    //
    
public:
    
    FileSystem() { stats = {}; };
    FileSystem(const MediaFile &file, isize part = 0) : FileSystem() { init(file, part); }
    FileSystem(const ADFFile &adf) : FileSystem() { init(adf); }
    FileSystem(const HDFFile &hdf, isize part = 0) : FileSystem() { init(hdf, part); }
    FileSystem(const FloppyDrive &dfn) : FileSystem() { init(dfn); }
    FileSystem(const HardDrive &hdn, isize part = 0) : FileSystem() { init(hdn, part); }

    FileSystem(isize capacity, isize bsize = 512) { init(capacity, bsize); }
    FileSystem(const FSDescriptor &layout, const fs::path &path = {}) { init(layout, path); }
    FileSystem(Diameter dia, Density den, FSFormat dos, const fs::path &path = {}) { init(dia, den, dos, path); }

    virtual ~FileSystem();

    void init(const FSDescriptor &layout, u8 *buf, isize len);
    void init(const MediaFile &file, isize part);
    void init(const ADFFile &adf);
    void init(const HDFFile &hdf, isize part);
    void init(const FloppyDrive &dfn);
    void init(const HardDrive &hdn, isize part);

    void init(isize capacity, isize bsize = 512);
    void init(const FSDescriptor &layout, const fs::path &path = {});
    void init(Diameter dia, Density den, FSFormat dos, const fs::path &path = {});
    
    bool isInitialized() const noexcept;
    bool isFormatted() const noexcept;


    //
    // Methods from CoreObject
    //
    
protected:
    
    const char *objectName() const noexcept override { return "FileSystem"; }
    void _dump(Category category, std::ostream &os) const noexcept override;


    //
    // Methods from Inspectable
    //

public:

    void cacheInfo(FSInfo &result) const noexcept override;
    void cacheStats(FSStats &result) const noexcept override;


    //
    // Querying file system properties
    //

public:

    // Returns static file system properties
    const FSTraits &getTraits() const noexcept { return traits; }

    // Returns capacity information
    isize numBlocks() const noexcept { return storage.numBlocks(); }
    isize numBytes() const noexcept { return storage.numBytes(); }
    isize blockSize() const noexcept { return storage.blockSize(); }

    // Reports usage information
    isize freeBlocks() const noexcept { return storage.freeBlocks(); }
    isize usedBlocks() const noexcept { return storage.usedBlocks(); }
    isize freeBytes() const noexcept { return storage.freeBytes(); }
    isize usedBytes() const noexcept { return storage.usedBytes(); }

    // Analyzes the root block
    FSName getName() const noexcept;
    string getCreationDate() const noexcept;
    string getModificationDate() const noexcept;

    // Analyzes the boot block
    string getBootBlockName() const noexcept;
    BootBlockType bootBlockType() const noexcept;
    bool hasVirus() const noexcept { return bootBlockType() == BootBlockType::VIRUS; }


    //
    // Querying file properties
    //

public:
    
    FSAttr getStat(Block nr) const;
    FSAttr getStat(const FSBlock &fhd) const;

private:
    
    // Returns the number of required blocks to store a file of certain size
    isize requiredBlocks(isize fileSize) const;

private:

    // Returns the number of required file list or data blocks
    isize requiredFileListBlocks(isize fileSize) const;
    isize requiredDataBlocks(isize fileSize) const;


    //
    // Querying block properties
    //

public:

    // Returns the type of a certain block or a block item
    FSBlockType typeOf(Block nr) const noexcept;
    bool is(Block nr, FSBlockType t) const noexcept { return typeOf(nr) == t; }
    FSItemType typeOf(Block nr, isize pos) const noexcept;

    // Convenience wrappers
    bool isEmpty(Block nr) const noexcept { return typeOf(nr) == FSBlockType::EMPTY; }

protected:

    // Predicts the type of a block
    FSBlockType predictType(Block nr, const u8 *buf) const noexcept;


    //
    // Accessing the block storage
    //
    
public:

    // Returns a block pointer or null if the block does not exist
    FSBlock *read(Block nr) noexcept;
    FSBlock *read(Block nr, FSBlockType type) noexcept;
    FSBlock *read(Block nr, std::vector<FSBlockType> types) noexcept;
    const FSBlock *read(Block nr) const noexcept;
    const FSBlock *read(Block nr, FSBlockType type) const noexcept;
    const FSBlock *read(Block nr, std::vector<FSBlockType> types) const noexcept;

    // Returns a reference to a stored block (throws on error)
    FSBlock &at(Block nr);
    FSBlock &at(Block nr, FSBlockType type);
    FSBlock &at(Block nr, std::vector<FSBlockType> types);
    const FSBlock &at(Block nr) const;
    const FSBlock &at(Block nr, FSBlockType type) const;
    const FSBlock &at(Block nr, std::vector<FSBlockType> types) const;

    // Operator overload
    FSBlock &operator[](size_t nr);
    const FSBlock &operator[](size_t nr) const;


    //
    // Managing the block allocation bitmap
    //

public:
    
    // Checks if a block is allocated or unallocated
    bool isUnallocated(Block nr) const noexcept;
    bool isAllocated(Block nr) const noexcept { return !isUnallocated(nr); }

    // Returns the number of allocated or unallocated blocks
    isize numUnallocated() const noexcept;
    isize numAllocated() const noexcept { return numBlocks() - numUnallocated(); }

protected:
    
    // Locates the allocation bit for a certain block
    FSBlock *locateAllocationBit(Block nr, isize *byte, isize *bit) noexcept;
    const FSBlock *locateAllocationBit(Block nr, isize *byte, isize *bit) const noexcept;

    // Translate the bitmap into to a vector with the n-bit set iff the n-th block is free
    std::vector<u32> serializeBitmap() const;


    //
    // Managing files and directories
    //

public:

    // Returns the root of the directory tree
    FSBlock &root() { return at(rootBlock); }
    const FSBlock &root() const { return at(rootBlock); }

    // Returns the working directory
    FSBlock &pwd() { return at(current); }
    const FSBlock &pwd() const { return at(current); }

    // Returns the parent directory
    FSBlock &parent(const FSBlock &block);
    FSBlock *parent(const FSBlock *block) noexcept;
    const FSBlock &parent(const FSBlock &block) const;
    const FSBlock *parent(const FSBlock *block) const noexcept;

    // Changes the working directory
    void cd(const FSName &name);
    void cd(const FSBlock &path);
    void cd(const string &path);

    // Checks if a an item exists in the directory tree
    bool exists(const FSBlock &top, const fs::path &path) const;
    bool exists(const fs::path &path) const { return exists(pwd(), path); }

    // Seeks an item in the directory tree (returns nullptr if not found)
    FSBlock *seekPtr(const FSBlock *top, const FSName &name) noexcept;
    FSBlock *seekPtr(const FSBlock *top, const fs::path &name) noexcept;
    FSBlock *seekPtr(const FSBlock *top, const string &name) noexcept;
    const FSBlock *seekPtr(const FSBlock *top, const FSName &name) const noexcept;
    const FSBlock *seekPtr(const FSBlock *top, const fs::path &name) const noexcept;
    const FSBlock *seekPtr(const FSBlock *top, const string &name) const noexcept;

    // Seeks an item in the directory tree (returns nullptr if not found)
    FSBlock &seek(const FSBlock &top, const FSName &name);
    FSBlock &seek(const FSBlock &top, const fs::path &name);
    FSBlock &seek(const FSBlock &top, const string &name);
    const FSBlock &seek(const FSBlock &top, const FSName &name) const;
    const FSBlock &seek(const FSBlock &top, const fs::path &name) const;
    const FSBlock &seek(const FSBlock &top, const string &name) const;

    // Seeks all items satisfying a predicate
    std::vector<const FSBlock *> find(const FSOpt &opt) const;
    std::vector<const FSBlock *> find(const FSBlock *root, const FSOpt &opt) const;
    std::vector<const FSBlock *> find(const FSBlock &root, const FSOpt &opt) const;
    std::vector<Block> find(Block root, const FSOpt &opt) const;

    // Seeks all items with a pattern-matching name
    std::vector<const FSBlock *> find(const FSPattern &pattern) const;
    std::vector<const FSBlock *> find(const FSBlock *top, const FSPattern &pattern) const;
    std::vector<const FSBlock *> find(const FSBlock &top, const FSPattern &pattern) const;
    std::vector<Block> find(Block root, const FSPattern &pattern) const;

    // Collects all items with a pattern-matching path
    std::vector<const FSBlock *> match(const FSPattern &pattern) const;
    std::vector<const FSBlock *> match(const FSBlock *top, const FSPattern &pattern) const;
    std::vector<const FSBlock *> match(const FSBlock &top, const FSPattern &pattern) const;
    std::vector<Block> match(Block root, const FSPattern &pattern) const;

private:

    std::vector<const FSBlock *> find(const FSBlock *top, const FSOpt &opt,
                                      std::unordered_set<Block> &visited) const;

    std::vector<const FSBlock *> match(const FSBlock *top,
                                       std::vector<FSPattern> pattern) const;


    //
    // Traversing linked lists
    //

public:
    
    // Follows a linked list and collects all blocks
    std::vector<const FSBlock *> collect(const FSBlock &block,
                                         std::function<const FSBlock *(const FSBlock *)> next) const;
    std::vector<Block> collect(const Block nr,
                               std::function<const FSBlock *(const FSBlock *)> next) const;

    // Collects blocks of a certain type
    std::vector<const FSBlock *> collectDataBlocks(const FSBlock &block) const;
    std::vector<const FSBlock *> collectListBlocks(const FSBlock &block) const;
    std::vector<const FSBlock *> collectHashedBlocks(const FSBlock &block, isize bucket) const;
    std::vector<const FSBlock *> collectHashedBlocks(const FSBlock &block) const;
    std::vector<Block> collectDataBlocks(Block nr) const;
    std::vector<Block> collectListBlocks(Block nr) const;
    std::vector<Block> collectHashedBlocks(Block nr, isize bucket) const;
    std::vector<Block> collectHashedBlocks(Block nr) const;


    //
    // Argument checkers
    //

public:

    void require_initialized() const;
    void require_formatted() const;
    void require_file_or_directory(const FSBlock &block) const;

    void ensureFile(const FSBlock &node);
    void ensureFileOrDirectory(const FSBlock &node);
    void ensureDirectory(const FSBlock &node);
    void ensureNotRoot(const FSBlock &node);
    void ensureEmptyDirectory(const FSBlock &node);


    //
    // GUI helper functions
    //

public:

    // Returns a portion of the block as an ASCII dump
    string ascii(Block nr, isize offset, isize len) const noexcept;

    // Returns a block summary for creating the block usage image
    void createUsageMap(u8 *buffer, isize len) const;

    // Returns a usage summary for creating the block allocation image
    void createAllocationMap(u8 *buffer, isize len) const;

    // Returns a block summary for creating the diagnose image
    void createHealthMap(u8 *buffer, isize len) const;
    
    // Searches the block list for a block of a specific type
    isize nextBlockOfType(FSBlockType type, Block after) const;


    //
    // LAYER 2: WRITE
    //

    //
    // Formatting
    //

public:

    // Formats the volume
    void format(string name = "");
    void format(FSFormat dos, string name = "");

    // Assigns the volume name
    void setName(FSName name);
    void setName(string name) { setName(FSName(name)); }


    //
    // Creating and deleting blocks
    //

public:

    // Returns true if at least 'count' free blocks are available
    bool allocatable(isize count) const;

    // Seeks a free block and marks it as allocated
    Block allocate();

    // Allocates multiple blocks
    void allocate(isize count, std::vector<Block> &result, std::vector<Block> prealloc = {});

    // Deallocates a block
    void deallocateBlock(Block nr);

    // Allocates multiple blocks
    void deallocateBlocks(const std::vector<Block> &nrs);

    // Updates the checksums in all blocks
    void updateChecksums() noexcept;

private:

    // Adds a new block of a certain kind
    void addFileListBlock(Block at, Block head, Block prev);
    void addDataBlock(Block at, isize id, Block head, Block prev);

    // Creates a new block of a certain kind
    FSBlock &newUserDirBlock(const FSName &name);
    FSBlock &newFileHeaderBlock(const FSName &name);


    //
    // Modifying boot blocks
    //

public:

    // Installs a boot block
    void makeBootable(BootBlockId id);

    // Removes a boot block virus from the current partition (if any)
    void killVirus();


    //
    // Editing the block allocation bitmap
    //

public:

    // Marks a block as allocated or free
    void markAsAllocated(Block nr) { setAllocationBit(nr, 0); }
    void markAsFree(Block nr) { setAllocationBit(nr, 1); }
    void setAllocationBit(Block nr, bool value);

    // Rectifies the block allocation map
    void rectifyAllocationMap();


    //
    // Managing directories and files
    //

public:

    // Creates a new directory
    FSBlock &createDir(FSBlock &at, const FSName &name);

    // Creates a directory entry
    FSBlock &link(FSBlock &at, const FSName &name);
    void link(FSBlock &at, const FSName &name, FSBlock &fhb);

    // Removes a directory entry
    void unlink(const FSBlock &fhb);

    // Frees the file header block and all related data blocks
    void reclaim(const FSBlock &fhb);

    // Creates a new file
    FSBlock &createFile(FSBlock &at, const FSName &name);
    FSBlock &createFile(FSBlock &at, const FSName &name, const Buffer<u8> &buf);
    FSBlock &createFile(FSBlock &at, const FSName &name, const string &str);
    FSBlock &createFile(FSBlock &at, const FSName &name, const u8 *buf, isize size);

private:

    // FSBlock &createFile(FSBlock &at, FSBlock &fhb, const u8 *buf, isize size);
    FSBlock &createFile(FSBlock &fhb,
                        const u8 *buf, isize size,
                        std::vector<Block> listBlocks = {},
                        std::vector<Block> dataBlocks = {});

public:

    // Changes the size of an existing file, pads with 0
    void resize(FSBlock &at, isize size);

    // Changes the size and cotents of an existing file
    void resize(FSBlock &at, const Buffer<u8> &data);

    // Update file contents with new data

    // Renames a file or directory
    void rename(FSBlock &item, const FSName &name);

    // Moves a file or directory to another location
    void move(FSBlock &item, const FSBlock &dest, const FSName &name = "");

    // Copies a file
    void copy(const FSBlock &item, FSBlock &dest);
    void copy(const FSBlock &item, FSBlock &dest, const FSName &name);

    // Delete a file
    void deleteFile(const FSBlock &at);

private:

    // Adds a hash-table entry for a given item
    void addToHashTable(const FSBlock &item);
    void addToHashTable(Block parent, Block ref);

    // Removes the hash-table entry for a given item
    void deleteFromHashTable(const FSBlock &item);
    void deleteFromHashTable(Block parent, Block ref);

    // Adds bytes to a data block
    isize addData(Block nr, const u8 *buf, isize size);
    isize addData(FSBlock &block, const u8 *buf, isize size);

    // Allocates all blocks needed for a file
    void allocateFileBlocks(isize bytes, std::vector<Block> &listBlocks, std::vector<Block> &dataBlocks);


    //
    // Importing and exporting the volume
    //

public:

    // Imports the volume from a buffer compatible with the ADF or HDF format
    void importVolume(const u8 *src, isize size) throws;

    // Imports files and folders from the host file system
    void import(const fs::path &path, bool recursive = true, bool contents = false) throws;
    void import(FSBlock &top, const fs::path &path, bool recursive = true, bool contents = false) throws;

    // Imports a single block
    void importBlock(Block nr, const fs::path &path);

    // Exports the volume to a buffer
    bool exportVolume(u8 *dst, isize size) const;
    bool exportVolume(u8 *dst, isize size, Fault *error) const;

    // Exports a single block or a range of blocks to a buffer
    bool exportBlock(Block nr, u8 *dst, isize size) const;
    bool exportBlock(Block nr, u8 *dst, isize size, Fault *error) const;
    bool exportBlocks(Block first, Block last, u8 *dst, isize size) const;
    bool exportBlocks(Block first, Block last, u8 *dst, isize size, Fault *error) const;

    // Exports a single block or a range of blocks to a file
    void exportBlock(Block nr, const fs::path &path) const;
    void exportBlocks(Block first, Block last, const fs::path &path) const;
    void exportBlocks(const fs::path &path) const;

    // Exports the volume to a buffer
    void exportFiles(Block nr, const fs::path &path, bool recursive = true, bool contents = false) const;
    void exportFiles(const FSBlock &top, const fs::path &path, bool recursive = true, bool contents = false) const;
    void exportFiles(const fs::path &path, bool recursive = true, bool contents = false) const;

private:

    void import(FSBlock &top, const fs::directory_entry &dir, bool recursive) throws;
};

}
