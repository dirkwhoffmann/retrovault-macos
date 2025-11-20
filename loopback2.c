//
//  loopback2.c
//  vMount
//
//  Created by Dirk Hoffmann on 20.11.25.
//

#if 0

#include <AvailabilityMacros.h>

#define HAVE_ACCESS 0

#define FUSE_USE_VERSION 26

#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fuse.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/attr.h>
#include <sys/mount.h>
#include <sys/param.h>
#include <sys/time.h>
#include <sys/vnode.h>
#include <sys/xattr.h>
#include <unistd.h>

static const char* file_name = "hello.txt";
static const char* file_content = "Hello FUSE!\n";

static int my_getattr(const char *path, struct stat *st)
{
    memset(st, 0, sizeof(*st));

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

static int my_readdir(const char* path,
                      void* buf,
                      fuse_fill_dir_t filler,
                      off_t offset,
                      struct fuse_file_info *fi)
{
    if (strcmp(path, "/") != 0)
        return -ENOENT;

    filler(buf, ".",  NULL, 0);
    filler(buf, "..", NULL, 0);
    filler(buf, file_name, NULL, 0);
    return 0;
}

static int my_open(const char* path, struct fuse_file_info *fi)
{
    if (strcmp(path + 1, file_name) != 0)
        return -ENOENT;

    return 0;   // success
}

//
// read – return actual fake file contents.
//
static int my_read(const char* path,
                   char* buf,
                   size_t size,
                   off_t offset,
                   struct fuse_file_info *fi)
{
    if (strcmp(path + 1, file_name) != 0)
        return -ENOENT;

    size_t len = strlen(file_content);

    if (offset >= len)
        return 0;

    size_t to_copy = size < len - offset ? size : len - offset;
    memcpy(buf, file_content + offset, to_copy);

    return (int)to_copy;
}

static struct fuse_operations loopback_oper = {

    .getattr     = my_getattr,
    .readdir     = my_readdir,
    .open        = my_open,
    .read        = my_read,
};

struct loopback {

    uint32_t blocksize;
    bool case_insensitive;
};
static struct loopback loopback;

static const struct fuse_opt loopback_opts[] = {

    { "fsblocksize=%u", offsetof(struct loopback, blocksize), 0 },
    { "case_insensitive", offsetof(struct loopback, case_insensitive), true },
    FUSE_OPT_END
};

int
loopback2Main(int argc, char *argv[])
{
    int res = 0;
    struct fuse_args args = FUSE_ARGS_INIT(argc, argv);

    loopback.blocksize = 4096;
    loopback.case_insensitive = 0;
    if (fuse_opt_parse(&args, &loopback, loopback_opts, NULL) == -1) {
        exit(1);
    }

    umask(0);

    printf("Calling fuse_main\n");
    res = fuse_main(args.argc, args.argv, &loopback_oper, NULL);

    fuse_opt_free_args(&args);
    return res;
}
#endif

