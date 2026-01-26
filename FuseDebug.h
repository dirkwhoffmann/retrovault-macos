// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the Mozilla Public License v2
//
// See https://mozilla.org/MPL/2.0 for license information
// -----------------------------------------------------------------------------

#pragma once

#include "FuseAPI.h"

extern bool logging;

#define mylog(format, ...) \
if (logging) { fprintf(stderr, format __VA_OPT__(,) __VA_ARGS__); }

/*
 inline static void
 mylog(const std::function<void(std::ostream &)> &func)
 {
 if (debug) {

 std::stringstream ss;
 func(ss);
 std::cout << ss.str();
 }
 }

 template<typename... Args>
 inline void mylog(const char* fmt, Args&&... args) {

 if (debug) {

 // std::string message = std::vformat(fmt, std::make_format_args(args...));
 std::string message = "TODO";
 std::cout << message;
 }
 }

 void dump(std::ostream &os, fuse_conn_info *p);
 void dump(std::ostream &os, fuse_context *p);

 */
