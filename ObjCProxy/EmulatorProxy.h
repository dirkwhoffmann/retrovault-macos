// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#import "config.h"
#import "DeviceTypes.h"
#import "ImageTypes.h"
#import "FileSystems/Amiga/FSObjects.h"
#import "FileSystems/Amiga/FSTypes.h"
#import "FileSystems/PosixViewTypes.h"
#import "FuseFileSystemTypes.h"
#import "utl/abilities/Compressible.h"
#import <Cocoa/Cocoa.h>

using namespace retro::vault;
using namespace retro::vault::amiga;

inline const char *c_str(const std::string &s)
{
    return s.c_str();
}

//
// Exception wrapper
//

@interface ExceptionWrapper : NSObject {
    
    long fault;
    NSString *what;
}

@property long fault;
@property NSString *what;

@end


//
// Base proxies
//

@interface Proxy : NSObject {
    
    // Reference to the wrapped C++ object
    @public void *obj;    
}

- (instancetype) initWith:(void *)ref;

@end


//
// MediaFile
//

/*
@interface MediaFileProxy : Proxy
{
    NSImage *preview;
}

+ (FileType) typeOfUrl:(NSURL *)url;

+ (instancetype)make:(void *)file;
+ (instancetype)makeWithFile:(NSString *)path exception:(ExceptionWrapper *)ex;
+ (instancetype)makeWithFile:(NSString *)path type:(FileType)t exception:(ExceptionWrapper *)ex;
+ (instancetype)makeWithBuffer:(const void *)buf length:(NSInteger)len type:(FileType)t exception:(ExceptionWrapper *)ex;

@property (readonly) FileType type;
@property (readonly) NSInteger size;
@property (readonly) u64 fnv;
@property (readonly) Compressor compressor;
@property (readonly) BOOL compressed;

@property (readonly) u8 *data;

- (void)writeToFile:(NSString *)path exception:(ExceptionWrapper *)ex;
- (void)writeToFile:(NSString *)path partition:(NSInteger)part exception:(ExceptionWrapper *)ex;

@property (readonly, strong) NSImage *previewImage;
@property (readonly) time_t timeStamp;
@property (readonly) DiskInfo diskInfo;
@property (readonly) HDFInfo hdfInfo;
@property (readonly) NSString *describeCapacity;

- (NSInteger)readByte:(NSInteger)b offset:(NSInteger)offset;
- (void)readSector:(NSInteger)b destination:(unsigned char *)buf;

- (NSString *)hexdump:(NSInteger)b offset:(NSInteger)offset len:(NSInteger)len;
- (NSString *)asciidump:(NSInteger)b offset:(NSInteger)offset len:(NSInteger)len;

@end
*/


//
// FuseDeviceProxy
//

@interface FuseDeviceProxy : Proxy {

    NSURL *url;
}

+ (instancetype)make:(NSURL *)url exception:(ExceptionWrapper *)ex;

@property (readonly, strong) NSURL *url;
@property (readonly) ImageInfo info;
@property (readonly) NSInteger numCyls;
@property (readonly) NSInteger numHeads;
-(NSInteger)numSectors:(NSInteger)t;
-(NSInteger)numSectors:(NSInteger)c head:(NSInteger)h;
@property (readonly) NSInteger numTracks;
@property (readonly) NSInteger numBlocks;
@property (readonly) NSInteger bsize;
@property (readonly) NSInteger numBytes;
@property (readonly) NSInteger numVolumes;

-(NSInteger)b2t:(NSInteger)b;
-(NSInteger)b2c:(NSInteger)b;
-(NSInteger)b2h:(NSInteger)b;
-(NSInteger)b2s:(NSInteger)b;
-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s;
-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s;

-(NSInteger)readByte:(NSInteger)offset;
-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block;

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len;
-(NSString *)readASCII:(NSInteger)offset from:(NSInteger)block length:(NSInteger)len;

- (void)save:(ExceptionWrapper *)ex;

- (void)mount:(NSURL *)url exception:(ExceptionWrapper *)ex;
- (void)unmount:(NSInteger)volume;
- (void)unmountAll;
- (void)setListener:(const void *)listener function:(AdapterCallback *)func;

- (NSString *)mountPoint:(NSInteger)volume;
- (FSPosixStat)stat:(NSInteger)volume;

- (NSInteger)bytesRead:(NSInteger)volume;
- (NSInteger)bytesWritten:(NSInteger)volume;

@end
