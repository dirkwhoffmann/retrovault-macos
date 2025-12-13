// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#pragma once

#import "config.h"
#import "MediaFileTypes.h"
#import "DeviceTypes.h"
#import "FSTypes.h"
#import "FSObjects.h"
#import "FuseFileSystemTypes.h"
#import "utl/abilities/Compressible.h"
#import <Cocoa/Cocoa.h>

using namespace vamiga;

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


//
// AmigaDeviceProxy
//

@interface AmigaDeviceProxy : Proxy {

}

+ (instancetype)make:(NSURL *)url exception:(ExceptionWrapper *)ex;

@property (readonly) NSInteger numVolumes;
@property (readonly) NSString *name;

- (void)mount:(NSURL *)url exception:(ExceptionWrapper *)ex;
- (void)unmount;
- (void)setListener:(const void *)listener function:(AdapterCallback *)func;

- (NSString *)name:(NSInteger)volume;
- (FSTraits)traits:(NSInteger)volume;
- (FSStat)stat:(NSInteger)volume;
- (FSBootStat)bootStat:(NSInteger)volume;

@end
