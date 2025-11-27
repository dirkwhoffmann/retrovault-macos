// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#include "FuseDebug.h"
#include "IOUtils.h"
#include <sstream>
#include <iostream>

using namespace vamiga::util;
using namespace vamiga;

bool logging = true;

/*
void
dump(std::ostream &os, fuse_conn_info *p)
{
    os << "fuse_conn_info {" << std::endl;

    if (p) {

        os << "    .proto_major          = " << dec(p->proto_major) << std::endl;
        os << "    .proto_minor          = " << dec(p->proto_minor) << std::endl;
        os << "    .async_read           = " << dec(p->async_read) << std::endl;
        os << "    .max_write            = " << dec(p->max_write) << std::endl;
        os << "    .max_readahead        = " << dec(p->max_readahead) << std::endl;
        os << "    .capable              = " << hex(p->capable) << std::endl;
        os << "    .want                 = " << hex(p->want) << std::endl;
        os << "    .max_background       = " << dec(p->max_background) << std::endl;
        os << "    .congestion_threshold = " << dec(p->congestion_threshold) << std::endl;
    }
    os << "}" << std::endl;
}

void
dump(std::ostream os, fuse_context *p)
{
    os << "fuse_context {" << std::endl;

    if (p) {

        os << "    .fuse  = " << hex(u64(p->fuse)) << std::endl;
        os << "    .uid   = " << dec(p->uid) << std::endl;
        os << "    .gid   = " << dec(p->gid) << std::endl;
        os << "    .pid   = " << dec(p->pid) << std::endl;
        os << "    .umask = " << dec(p->uid) << std::endl;
    }
    os << "}" << std::endl;
}
*/
