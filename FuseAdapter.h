//
//  FuseAdapter.h
//  vMount
//
//  Created by Dirk Hoffmann on 20.11.25.
//

#define FUSE_USE_VERSION 26

#include "Vamiga.h"
#include "fuse.h"

class FuseAdapter {

    static int my_getattr(const char *path, struct stat *st);
    static int my_readdir(const char* path, void* buf,
                          fuse_fill_dir_t filler,
                          off_t offset,
                          struct fuse_file_info *fi);
    static int my_open(const char* path, struct fuse_file_info *fi);
    static int my_read(const char* path,
                       char* buf,
                       size_t size,
                       off_t offset,
                       struct fuse_file_info *fi);

    static fuse_operations loopback_oper;

public:
    
    void myMain();
    int myMain(int argc, char *argv[]);
};
