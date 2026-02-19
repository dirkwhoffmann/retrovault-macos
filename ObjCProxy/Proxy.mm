// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#import "config.h"
#import "Proxy.h"
#import "FuseDevice.h"
#import "FileSystem.h"

using namespace vamiga;
using namespace utl;

@implementation ExceptionWrapper

@synthesize fault;
@synthesize what;

- (instancetype)init {

    if (self = [super init]) {

        fault = 0;
        what = @"";
    }
    return self;
}

- (void)save:(const Error &)exception
{
    fault = exception.fault();
    what = @(exception.what());
}

@end

//
// Base Proxy
//

@implementation Proxy

- (instancetype)initWith:(void *)ref
{
    if (ref == nil) {
        return nil;
    }
    if (self = [super init]) {
        obj = ref;
    }
    return self;
}

@end


//
// FuseDeviceProxy
//

@implementation FuseDeviceProxy

- (FuseDevice *)device
{
    return (FuseDevice *)obj;
}

- (DiskImage *)image
{
    return [self device]->getImage();
}

- (FuseVolume &)volume:(NSInteger)nr
{
    return [self device]->getVolume(nr);
}

+ (instancetype)make:(FuseDevice *)device
{
    if (device == nullptr) { return nil; }

    FuseDeviceProxy *proxy = [[self alloc] initWith: device];
    return proxy;
}

+ (instancetype)make:(NSURL *)url exception:(ExceptionWrapper *)ex
{
    try {

        auto device = std::make_unique<FuseDevice>([url fileSystemRepresentation]);

        FuseDeviceProxy *proxy = [self make:device.get()];
        device.release();
        proxy->url = url;
        return proxy;

    }  catch (Error &error) {

        [ex save:error];
        return nil;
    }
}

- (NSArray<NSString *> *)describe
{
    const auto vec = [self device]->describe();

    NSMutableArray<NSString *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (const auto &s : vec) {
        [result addObject:[NSString stringWithUTF8String:s.c_str()]];
    }

    return result;
}

- (NSArray<NSString *> *)describe:(NSInteger)v
{
    const auto vec = [self volume:v].describe();

    NSMutableArray<NSString *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (const auto &s : vec) {
        [result addObject:[NSString stringWithUTF8String:s.c_str()]];
    }

    return result;
}
- (NSURL *)mountPoint:(NSInteger)v
{
    auto nsPath = @([self volume:v].getMountPoint().string().c_str());
    return [NSURL fileURLWithPath:nsPath];
}

- (BOOL)iswriteProtected:(NSInteger)v
{
    return [self volume:v].isWriteProtected();
}

- (void)toggleWriteProtection:(NSInteger)v
{
    [self volume:v].writeProtect(![self iswriteProtected:v]);
}

- (void)writeProtect:(BOOL)wp volume:(NSInteger)v
{
    [self volume:v].writeProtect(wp);
}

- (NSArray<NSString *> *)blockTypes:(NSInteger)v
{
    const auto vec = [self volume:v].blockTypes();

    NSMutableArray<NSString *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (const auto &s : vec) {
        [result addObject:[NSString stringWithUTF8String:s.c_str()]];
    }

    return result;
    
}

- (NSString *)typeOf:(NSInteger)blockNr volume:(NSInteger)v
{
    return @([self volume:v].blockType(blockNr).c_str());
}

- (NSString *)typeOf:(NSInteger)blockNr pos:(NSInteger)pos volume:(NSInteger)v
{
    return @([self volume:v].typeOf(blockNr, pos).c_str());
}

- (NSURL *)url
{
    return url;
}

- (ImageInfo)info
{
    return [self device]->imageInfo();
}

- (BOOL)needsSaving
{
    return [self device]->needsSaving();
}

- (NSInteger)numCyls
{
    return [self image]->numCyls();
}

- (NSInteger)numHeads
{
    return [self image]->numHeads();
}

- (NSInteger)numSectors:(NSInteger)t
{
    return [self image]->numSectors(t);
}

- (NSInteger)numSectors:(NSInteger)c head:(NSInteger)h
{
    return [self image]->numSectors(c, h);
}

- (NSInteger)numTracks
{
    return [self image]->numTracks();
}

- (NSInteger)numBlocks
{
    return [self image]->numBlocks();
}

- (NSInteger)bsize
{
    return [self image]->bsize();
}

- (NSInteger)numBytes
{
    return [self image]->numBytes();
}

- (NSInteger)numVolumes
{
    return [self device]->count();
}

-(NSInteger)b2t:(NSInteger)b
{
    return [self image]->b2ts(b).track;
}

-(NSInteger)b2c:(NSInteger)b
{
    return [self image]->b2chs(b).cylinder;
}

-(NSInteger)b2h:(NSInteger)b
{
    return [self image]->b2chs(b).head;
}

-(NSInteger)b2s:(NSInteger)b
{
    return [self image]->b2chs(b).sector;
}

-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s
{
    return [self image]->bindex(TrackDevice::TS(t,s));
}

-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s
{
    return [self image]->bindex(TrackDevice::CHS(c,h,s));
}

-(NSInteger)b2b:(NSInteger)b volume:(NSInteger)v
{
    return b + [self volume:v].getVolume().getRange().lower;
}

-(NSInteger)readByte:(NSInteger)offset
{
    assert(offset >= 0);
    return [self image]->readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset block:(NSInteger)block
{
    assert(offset >= 0 && offset < [self bsize]);
    return [self image]->readByte(block * [self bsize] + offset);
}

-(NSInteger)readByte:(NSInteger)offset volume:(NSInteger)v
{
    assert(offset >= 0);
    return [self volume:v].getVolume().readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)v
{
    assert(offset >= 0 && offset < [self bsize]);
    return [self volume:v].getVolume().readByte(block * [self bsize] + offset);
}

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len
{
    assert(offset >= 0);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:len];

    for (NSInteger i = 0; i < len; i++) {

        unsigned char byte = (unsigned char)[self readByte:offset + i];

        if (isprint(byte)) {
            [result appendFormat:@"%c", byte];
        } else {
            [result appendString:@"."];
        }
    }

    return result;
}

-(NSString *)readASCII:(NSInteger)offset block:(NSInteger)block length:(NSInteger)len
{
    return [self readASCII: block * [self bsize] + offset length: len];
}

-(NSString *)readASCII:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)v length:(NSInteger)len
{
    auto lower = [self volume:v].getVolume().getRange().lower;
    return [self readASCII: (lower + block) * [self bsize] + offset length: len];
}


-(void)writeByte:(NSInteger)offset value:(NSInteger)value
{
    [self device]->writeByte(offset, value);
}

-(void)writeByte:(NSInteger)offset block:(NSInteger)block value:(NSInteger)value
{
    auto bsize = [self image]->bsize();
    assert(offset >= 0 && offset < bsize);

    [self device]->writeByte(block * bsize + offset, value);
}

-(void)writeByte:(NSInteger)offset volume:(NSInteger)volume value:(NSInteger)value
{
    [self device]->writeByte(offset, value, volume);
}

-(void)writeByte:(NSInteger)offset block:(NSInteger)block volume:(NSInteger)v value:(NSInteger)value
{
    auto bsize = [self image]->bsize();
    assert(offset >= 0 && offset < bsize);

    [self device]->writeByte(block * bsize + offset, value, v);
}

-(FSPosixStat)stat:(NSInteger)v
{
    return [self volume:v].stat();
}

-(NSInteger)bytesRead:(NSInteger)v
{
    return [self volume:v].reads();
}

-(NSInteger)bytesWritten:(NSInteger)v
{
    return [self volume:v].writes();
}

- (void)save:(ExceptionWrapper *)ex
{
    try { [self device]->save(); }
    catch (Error &error) { [ex save:error]; }
}

- (void)save:(NSInteger)volume exception:(ExceptionWrapper *)ex
{
    try { [self device]->save(volume); }
    catch (Error &error) { [ex save:error]; }
}

- (void)saveAs:(NSURL *)url exception:(ExceptionWrapper *)ex
{
    try { [self device]->saveAs([url fileSystemRepresentation]); }
    catch (Error &error) { [ex save:error]; }
}

- (void)saveAs:(NSURL *)url volume:(NSInteger)v exception:(ExceptionWrapper *)ex
{
    try { [self device]->saveAs([url fileSystemRepresentation], v); }
    catch (Error &error) { [ex save:error]; }
}

- (void)revert:(ExceptionWrapper *)ex
{
    try { [self device]->revert(); }
    catch (Error &error) { [ex save:error]; }
}

- (void)revert:(NSInteger)volume exception:(ExceptionWrapper *)ex
{
    try { [self device]->revert(volume); }
    catch (Error &error) { [ex save:error]; }
}

/*
- (void)save:(ExceptionWrapper *)ex
{
    try { [self device]->save(); }
    catch (Error &error) { [ex save:error]; }
}
*/

- (void)mount:(NSURL *)mountpoint exception:(ExceptionWrapper *)ex
{
    try { [self device]->mount([mountpoint fileSystemRepresentation]); }
    catch (Error &error) { [ex save:error]; }
}

- (void)unmount:(NSInteger)volume
{
    [self device]->unmount(volume);
}

- (void)unmountAll
{
    [self device]->unmount();
}

- (void)setListener:(const void *)listener function:(AdapterCallback *)func
{
    [self device]->setListener(listener, func);
}

- (void)flush
{
    [self device]->flush();
}

- (void)invalidate
{
    [self device]->invalidate();
}

-(NSArray<NSNumber *> *)blockErrors:(NSInteger)v
{
    const auto vec = [self volume:v].blockErrors();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

-(NSArray<NSNumber *> *)usedButUnallocated:(NSInteger)v
{
    const auto vec = [self volume:v].usedButUnallocated();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

-(NSArray<NSNumber *> *)unusedButAllocated:(NSInteger)v
{
    const auto vec = [self volume:v].unusedButAllocated();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

-(void)xrayBitmap:(NSInteger)v strict:(BOOL)strict
{
    [self volume:v].xrayBitmap(strict);
}

-(void)xray:(NSInteger)v strict:(BOOL)strict
{
    [self volume:v].xray(strict);
}

-(NSString *)xray:(NSInteger)v block:(NSInteger)b pos:(NSInteger)pos expected:(unsigned char *)exp strict:(BOOL)strict
{
    std::optional<u8> expected;
    auto result = [self volume:v].xray(b, pos, strict, expected);
    if (expected) *exp = *expected;

    return @(result.c_str());
}

-(void)rectifyAllocationMap:(NSInteger)v strict:(BOOL)strict
{
    [self volume:v].rectifyAllocationMap(strict);
}

-(void)rectify:(NSInteger)v strict:(BOOL)strict
{
    [self volume:v].rectify(strict);
}

-(void)createUsageMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len
{
    [self volume:v].createUsageMap((u8 *)buf, len);
}

-(void)createAllocationMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len
{
    [self volume:v].createAllocationMap((u8 *)buf, len);
}

-(void)createHealthMap:(NSInteger)v buffer:(u8 *)buf length:(NSInteger)len
{
    [self volume:v].createHealthMap((u8 *)buf, len);
}

@end
