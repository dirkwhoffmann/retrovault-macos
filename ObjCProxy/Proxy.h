// -----------------------------------------------------------------------------
// This file is part of RetroVault
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
// FuseVolumeProxy
//

@interface FuseVolumeProxy : Proxy { }

- (NSArray<NSString *> *)describe __attribute__((deprecated));

/*
@property (readonly) NSURL *mountPoint __attribute__((deprecated));
@property (readonly) BOOL iswriteProtected __attribute__((deprecated));
- (void)writeProtect:(BOOL)wp __attribute__((deprecated));
*/
// - (void)push:(ExceptionWrapper *)ex;

// Properties
/*
@property (readonly) FSPosixStat stat __attribute__((deprecated));
@property (readonly) NSInteger bytesRead __attribute__((deprecated));
@property (readonly) NSInteger bytesWritten __attribute__((deprecated));
*/

// Data
/*
-(NSInteger)readByte:(NSInteger)offset __attribute__((deprecated));
-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block __attribute__((deprecated));

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len __attribute__((deprecated));
-(NSString *)readASCII:(NSInteger)offset from:(NSInteger)block length:(NSInteger)len __attribute__((deprecated));
*/

// Analysis
/*
@property (readonly) NSArray<NSString *> *blockTypes __attribute__((deprecated));
- (NSString *)typeOf:(NSInteger)blockNr __attribute__((deprecated));
- (NSString *)typeOf:(NSInteger)blockNr pos:(NSInteger)pos __attribute__((deprecated));
*/
// Doctor
/*
@property (readonly) NSArray<NSNumber *> *blockErrors __attribute__((deprecated));
@property (readonly) NSArray<NSNumber *> *usedButUnallocated __attribute__((deprecated));
@property (readonly) NSArray<NSNumber *> *unusedButAllocated __attribute__((deprecated));
- (void)xrayBitmap:(BOOL)strict __attribute__((deprecated));
- (void)xray:(BOOL)strict __attribute__((deprecated));
- (NSString *)xray:(NSInteger)nr pos:(NSInteger)pos expected:(unsigned char *)exp strict:(BOOL)strict __attribute__((deprecated));
- (void)rectifyAllocationMap:(BOOL)strict __attribute__((deprecated));
- (void)rectify:(BOOL)strict __attribute__((deprecated));
*/
// Images
/*
- (void)createUsageMap:(u8 *)buf length:(NSInteger)len __attribute__((deprecated));
- (void)createAllocationMap:(u8 *)buf length:(NSInteger)len __attribute__((deprecated));
- (void)createHealthMap:(u8 *)buf length:(NSInteger)len __attribute__((deprecated));
*/
@end


//
// FuseDeviceProxy
//

@interface FuseDeviceProxy : Proxy {

    NSURL *url;
}

+ (instancetype)make:(NSURL *)url exception:(ExceptionWrapper *)ex;

- (void)setListener:(const void *)listener function:(AdapterCallback *)func;

-(FuseVolumeProxy *) volume:(NSInteger)nr; // DEPRECATED

//
// Querying device properties
//

- (NSArray<NSString *> *)describe;

@property (readonly, strong) NSURL *url;
@property (readonly) ImageInfo info;
@property (readonly) BOOL needsSaving;
@property (readonly) NSInteger numCyls;
@property (readonly) NSInteger numHeads;
-(NSInteger)numSectors:(NSInteger)t;
-(NSInteger)numSectors:(NSInteger)c head:(NSInteger)h;
@property (readonly) NSInteger numTracks;
@property (readonly) NSInteger numBlocks;
@property (readonly) NSInteger bsize;
@property (readonly) NSInteger numBytes;
@property (readonly) NSInteger numVolumes;

//
// Translating cylinders, heads, sectors, tracks, and blocks
//

-(NSInteger)b2t:(NSInteger)b;
-(NSInteger)b2c:(NSInteger)b;
-(NSInteger)b2h:(NSInteger)b;
-(NSInteger)b2s:(NSInteger)b;
-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s;
-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s;
-(NSInteger)b2b:(NSInteger)b volume:(NSInteger)v;


//
// Device actions
//

- (void)save:(ExceptionWrapper *)ex;
- (void)save:(NSInteger)volume exception:(ExceptionWrapper *)ex;
- (void)saveAs:(NSURL *)url exception:(ExceptionWrapper *)ex;
- (void)saveAs:(NSURL *)url volume:(NSInteger)volume exception:(ExceptionWrapper *)ex;
- (void)revert:(ExceptionWrapper *)ex;
- (void)revert:(NSInteger)volume exception:(ExceptionWrapper *)ex;

- (void)mount:(NSURL *)url exception:(ExceptionWrapper *)ex;
- (void)unmount:(NSInteger)volume;
- (void)unmountAll;

- (void)flush;
- (void)invalidate;

//
// Querying volume properties
//

- (NSArray<NSString *> *)describe:(NSInteger)v;
-(NSURL *)mountPoint:(NSInteger)v;

-(FSPosixStat)stat:(NSInteger)v;
-(NSInteger)bytesRead:(NSInteger)v;
-(NSInteger)bytesWritten:(NSInteger)v;

-(BOOL)iswriteProtected:(NSInteger)v;
-(void)toggleWriteProtection:(NSInteger)v;
-(void)writeProtect:(BOOL)wp volume:(NSInteger)v;


//
// Querying block properties
//

-(NSArray<NSString *> *)blockTypes:(NSInteger)v;
-(NSString *)typeOf:(NSInteger)blockNr volume:(NSInteger)v;
-(NSString *)typeOf:(NSInteger)blockNr pos:(NSInteger)pos volume:(NSInteger)v;


//
// Accessing data
//

-(NSInteger)readByte:(NSInteger)offset;
-(NSInteger)readByte:(NSInteger)offset block:(NSInteger)block;
-(NSInteger)readByte:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)volume;

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len;
-(NSString *)readASCII:(NSInteger)offset block:(NSInteger)block length:(NSInteger)len;
-(NSString *)readASCII:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)volume length:(NSInteger)len;;

-(void)writeByte:(NSInteger)offset value:(NSInteger)value;
-(void)writeByte:(NSInteger)offset block:(NSInteger)block value:(NSInteger)value;
-(void)writeByte:(NSInteger)offset volume:(NSInteger)volume value:(NSInteger)value;
-(void)writeByte:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)volume value:(NSInteger)value;

//
// Doctor
//

-(NSArray<NSNumber *> *)blockErrors:(NSInteger)v;
-(NSArray<NSNumber *> *)usedButUnallocated:(NSInteger)v;
-(NSArray<NSNumber *> *)unusedButAllocated:(NSInteger)v;
-(void)xrayBitmap:(NSInteger)v strict:(BOOL)strict;
-(void)xray:(NSInteger)v strict:(BOOL)strict;
-(NSString *)xray:(NSInteger)v block:(NSInteger)b pos:(NSInteger)pos expected:(unsigned char *)exp strict:(BOOL)strict;
-(void)rectifyAllocationMap:(NSInteger)v strict:(BOOL)strict;
-(void)rectify:(NSInteger)v strict:(BOOL)strict;


//
// Creating images
//

- (void)createUsageMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len;
- (void)createAllocationMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len;
- (void)createHealthMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len;

@end
