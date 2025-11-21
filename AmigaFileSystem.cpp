// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "AmigaFileSystem.h"
#include "VAmiga.h"
#include "Media.h"
#include "MutableFileSystem.h"
#include "FuseAdapter.h"
#include "FuseDebug.h"

using namespace vamiga;

AmigaFileSystem::AmigaFileSystem(string &filename)
{
    log("Trying to load {}...\n", filename.c_str());
    adf = new ADFFile(filename);
    assert(adf != nullptr);

    log("Extracting file system...\n");
    fs = new MutableFileSystem(*adf);
    assert(fs != nullptr);
}

int
AmigaFileSystem::mount(string &mountpoint)
{
    FuseAdapter adapter;

    adapter.delegate = this;
    printf("adapter.delegate = %p\n", adapter.delegate);
    auto err = adapter.mount(mountpoint);

    assert(false);
    return err;
}

// REMOVE ASAP
static const char* file_name = "hello.txt";
static const char* file_content = "Hello from FUSE!\n";

int
AmigaFileSystem::getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

    printf("Seeking %s in Amiga file system...\n", path);

    if (auto *node = fs->seekPtr(&fs->root(), string(path)); node) {

        auto size = node->getFileSize();
        printf("Found Amiga file %p with %d bytes\n", node, size);


    }

    if (strcmp(path, "/") == 0) {
        st->st_mode = S_IFDIR | 0755;
        st->st_nlink = 1;
        return 0;
    }

    if (strcmp(path+1, file_name) == 0) {
        st->st_mode = S_IFREG | 0444;
        st->st_nlink = 1;
        st->st_size = strlen(file_content);
        return 0;
    }

    return -ENOENT;
}

int
AmigaFileSystem::open(const char *path, struct fuse_file_info *fi)
{
    if (strcmp(path + 1, file_name) != 0)
        return -ENOENT;

    return 0;   // success
}

int
AmigaFileSystem::read(const char* path, char* buf, size_t size, off_t offset, struct fuse_file_info* fi)
{
    size_t len = strlen(file_content);
    if (strcmp(path + 1, "hello.txt") != 0)
        return -ENOENT;
    if (offset >= len)
        return 0;
    size_t to_copy = size < len - offset ? size : len - offset;
    memcpy(buf, file_content + offset, to_copy);
    return (int)to_copy;
}

int
AmigaFileSystem::readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                          off_t offset, struct fuse_file_info* fi)
{
    if (strcmp(path, "/") != 0)
        return -ENOENT;

    filler(buf, ".",  NULL, 0);
    filler(buf, "..", NULL, 0);

    // Extract the directory tree
    FSTree tree(fs->root(), { .recursive = false });

    // Walk the tree
    tree.bfsWalk( [&](const FSTree &it) {

        auto name = it.node->getName();
        printf("File: %s\n", name.c_str());
        filler(buf, name.c_str(), NULL, 0);
    });

    return 0;
}

void *
AmigaFileSystem::init(struct fuse_conn_info* conn)
{
    log([conn](std::ostream &os){ dump(os, conn); });
    return this;
}
