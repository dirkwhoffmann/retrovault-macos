// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "DosFileSystem.h"

namespace vamiga {

DosFileSystem::DosFileSystem(MutableFileSystem &fs) : fs(fs)
{

}

FSStat
DosFileSystem::getStat(Block nr) const
{
    return fs.getStat(nr);
}

FSStat
DosFileSystem::getStat(const FSBlock &fhd) const
{
    return fs.getStat(fhd);
}

NodeMeta *
DosFileSystem::getMeta(Block nr)
{
    auto it = meta.find(nr);
    return it == meta.end() ? nullptr : &it->second;
}

NodeMeta &
DosFileSystem::ensureMeta(Block nr)
{
    auto [it, inserted] = meta.try_emplace(nr);
    return it->second;
}

HandleRef
DosFileSystem::open(const fs::path &path, u32 flags)
{
    // Resolve node (may throw)
    auto &node = fs.seek(fs.root(), path);

    // Create a unique identifier
    auto ref = nextHandle++;

    // Create a new file handle
    handles[ref] = Handle {

        .id = ref,
        .headerBlock = node.nr,
        .offset = 0,
        .flags = flags
    };
    auto &handle = handles[ref];
    auto &info = ensureMeta(node.nr);
    info.openHandles.insert(ref);

    // Evaluate flags
    if ((flags & O_TRUNC) && (flags & (O_WRONLY | O_RDWR))) {
        fs.truncate(node, 0);
    }
    if (flags & O_APPEND) {
        handle.offset = lseek(ref, 0, SEEK_END);
    }

    return ref;
}

void
DosFileSystem::close(HandleRef ref)
{
    // Lookup handle
    auto &handle = getHandle(ref);
    auto header = handle.headerBlock;

    // Remove from metadata
    auto &info = ensureMeta(header);
    info.openHandles.erase(ref);

    // Remove from global handle table
    handles.erase(ref);

    // Attempt deletion after all references are gone
    tryReclaim(fs.at(header));
}

void
DosFileSystem::unlink(const fs::path &path)
{
    auto &node = fs.seek(fs.root(), path);

    if (auto *info = getMeta(node); info) {

        // Remove directory entry
        fs.unlink(node);

        // Decrement link count
        if (info->linkCount > 0) info->linkCount--;

        // Maybe delete
        tryReclaim(node);
    }
}

void
DosFileSystem::tryReclaim(const FSBlock &node)
{
    if (auto *info = getMeta(node); info) {

        if (info->linkCount == 0 && info->openCount() == 0) {

            // Delete file
            fs.reclaim(node);

            // Trash meta data
            meta.erase(node.nr);
        }
    }
}

Handle &
DosFileSystem::getHandle(HandleRef ref)
{
    auto it = handles.find(ref);

    if (it == handles.end()) {
        throw AppError(Fault::FS_NOT_FOUND, ref); // TODO: Throw FS_INVALID_HANDLE
    }

    return it->second;
}

void
DosFileSystem::create(const fs::path &path)
{
    auto parent = path.parent_path();
    auto name   = path.filename();

    // Lookup destination directory
    auto &node  = fs.seek(fs.root(), parent);

    // Create file
    auto &fhb = fs.link(node, FSName(name));

    // Create meta info
    auto &info = ensureMeta(fhb);
    info.linkCount = 1;
}

isize
DosFileSystem::lseek(HandleRef ref, isize offset, u16 whence)
{
    auto &handle  = getHandle(ref);
    auto &node    = fs.at(handle.headerBlock);
    auto fileSize = isize(node.getFileSize());

    isize newOffset;

    switch (whence) {

        case SEEK_SET:  newOffset = offset; break;
        case SEEK_CUR:  newOffset = handle.offset + offset; break;
        case SEEK_END:  newOffset = fileSize + offset; break;

        default:
            throw AppError(Fault::FS_UNKNOWN); // TODO: Throw, e.g., FS_INVALID_FLAG
    }

    // Ensure that the offset is not negative
    newOffset = std::max(newOffset, (isize)0);

    // Update the file handle and return
    handle.offset = newOffset;
    return newOffset;
}

}
