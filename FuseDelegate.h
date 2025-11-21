// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"

class FuseDelegate {

public:

    virtual ~FuseDelegate() = default;

    // Low-level API (raw FUSE callbacks)
    virtual t_getattr       getattr;
    virtual t_open          open;
    virtual t_read          read;
    virtual t_readdir       readdir;
    virtual t_init          init;

    // High-level API (C++ convenience)
    /*
    virtual t_getattr_cpp   getattr;
    virtual t_open_cpp      open;
    virtual t_read_cpp      read;
    virtual t_readdir_cpp   readdir;
    virtual t_init_cpp      init;
    */
    /*
    // getattr
    virtual expected<struct stat, int>
    getattr(const fs::path& path);

    // open
    virtual expected<void, int>
    open(const fs::path& path, struct fuse_file_info& fi);

    // read
    virtual expected<std::string, int>
    read(const fs::path& path, size_t size, off_t offset, const struct fuse_file_info& fi);

    // readdir
    virtual expected<std::vector<std::string>, int>
    readdir(const fs::path& path);

    // init
    virtual void *
    init(struct fuse_conn_info &info);


    std::expected<struct stat, int> getattr(const string &path);
    std::expected<struct fuse_file_info, int> open(const string &path, struct fuse_file_info* fi);
    std::expected<struct fuse_file_info, int> read(const string &path, size_t size, off_t offset);
    std::expected<std::vector<string>, int> read(const string &path);
    */
};
