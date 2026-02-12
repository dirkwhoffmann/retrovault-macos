// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#import "config.h"
#import "EmulatorProxy.h"
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
// FuseVolumeProxy
//

@implementation FuseVolumeProxy

- (FuseVolume *)volume
{
    return (FuseVolume *)obj;
}

+ (instancetype)make:(FuseVolume *)volume
{
    if (volume == nullptr) { return nil; }

    FuseVolumeProxy *proxy = [[self alloc] initWith: volume];
    return proxy;
}

- (NSArray<NSString *> *)describe
{
    const auto vec = [self volume]->describe();

    NSMutableArray<NSString *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (const auto &s : vec) {
        [result addObject:[NSString stringWithUTF8String:s.c_str()]];
    }

    return result;
}

- (BOOL)iswriteProtected
{
    return [self volume]->isWriteProtected();
}

- (void)writeProtect:(BOOL)wp
{
    [self volume]->writeProtect(wp);
}

- (NSURL *)mountPoint
{
    auto nsPath = @([self volume]->getMountPoint().string().c_str());
    return [NSURL fileURLWithPath:nsPath];
}

/*
- (void)push:(ExceptionWrapper *)ex
{
    try { [self volume]->push(); }
    catch (Error &error) { [ex save:error]; }
}
*/

- (FSPosixStat)stat
{
    return [self volume]->stat();
}

- (NSInteger)bytesRead
{
    return [self volume]->reads();
}

- (NSInteger)bytesWritten
{
    return [self volume]->writes();
}

-(NSInteger)readByte:(NSInteger)offset
{
    return [self volume]->getVolume().readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block
{
    auto bsize = [self volume]->getVolume().bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readByte: block * bsize + offset];
}

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len
{
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

-(NSString *)readASCII:(NSInteger)offset from:(NSInteger)block length:(NSInteger)len
{
    auto bsize = [self volume]->getVolume().bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readASCII: block * bsize + offset length: len];

}

/*
-(void)writeByte:(NSInteger)offset value:(NSInteger)value
{
    [self volume]->getVolume().writeByte(offset, value);
}

-(void)writeByte:(NSInteger)offset to:(NSInteger)block value:(NSInteger)value
{
    auto bsize = [self volume]->getVolume().bsize();
    assert(offset >= 0 && offset < bsize);

    [self writeByte: block * bsize + offset value: value];
}
*/

- (NSArray<NSString *> *)blockTypes
{
    const auto vec = [self volume]->blockTypes();

    NSMutableArray<NSString *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (const auto &s : vec) {
        [result addObject:[NSString stringWithUTF8String:s.c_str()]];
    }

    return result;
}

- (NSArray<NSNumber *> *)blockErrors
{
    const auto vec = [self volume]->blockErrors();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

- (NSArray<NSNumber *> *)usedButUnallocated
{
    const auto vec = [self volume]->usedButUnallocated();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

- (NSArray<NSNumber *> *)unusedButAllocated
{
    const auto vec = [self volume]->unusedButAllocated();

    NSMutableArray<NSNumber *> *result =
        [NSMutableArray arrayWithCapacity:vec.size()];

    for (auto b : vec) {
        [result addObject:@(b)];
    }

    return result;
}

- (void)xrayBitmap:(BOOL)strict
{
    [self volume]->xrayBitmap(strict);
}

- (void)xray:(BOOL)strict
{
    [self volume]->xray(strict);
}

- (NSString *)xray:(NSInteger)nr pos:(NSInteger)pos expected:(unsigned char *)exp strict:(BOOL)strict
{
    std::optional<u8> expected;
    auto result = [self volume]->xray(nr, pos, strict, expected);
    if (expected) *exp = *expected;

    return @(result.c_str());
}

- (NSString *)typeOf:(NSInteger)blockNr
{
    return @([self volume]->blockType(blockNr).c_str());
}

- (NSString *)typeOf:(NSInteger)blockNr pos:(NSInteger)pos
{
    return @([self volume]->typeOf(blockNr, pos).c_str());
}

- (void)createUsageMap:(u8 *)buf length:(NSInteger)len
{
    [self volume]->createUsageMap((u8 *)buf, len);
}

- (void)createAllocationMap:(u8 *)buf length:(NSInteger)len
{
    [self volume]->createAllocationMap((u8 *)buf, len);
}

- (void)createHealthMap:(u8 *)buf length:(NSInteger)len
{
    [self volume]->createHealthMap((u8 *)buf, len);
}

- (NSInteger)nextBlockOfType:(FSBlockType)type after:(NSInteger)after
{
    // return [self fs]->doctor.nextBlockOfType(type, BlockNr(after));
    return 0;
}

- (void)rectifyAllocationMap:(BOOL)strict;
{
    [self volume]->rectifyAllocationMap(strict);
}

- (void)rectify:(BOOL)strict;
{
    [self volume]->rectify(strict);
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

-(FuseVolumeProxy *)volume:(NSInteger)nr
{
    return [FuseVolumeProxy make: &[self device]->getVolume(nr)];
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
    return [self device]->getImage()->numCyls();
}

- (NSInteger)numHeads
{
    return [self device]->getImage()->numHeads();
}

- (NSInteger)numSectors:(NSInteger)t
{
    return [self device]->getImage()->numSectors(t);
}

- (NSInteger)numSectors:(NSInteger)c head:(NSInteger)h
{
    return [self device]->getImage()->numSectors(c, h);
}

- (NSInteger)numTracks
{
    return [self device]->getImage()->numTracks();
}

- (NSInteger)numBlocks
{
    return [self device]->getImage()->numBlocks();
}

- (NSInteger)bsize
{
    return [self device]->getImage()->bsize();
}

- (NSInteger)numBytes
{
    return [self device]->getImage()->numBytes();
}

- (NSInteger)numVolumes
{
    return [self device]->count();
}

-(NSInteger)b2t:(NSInteger)b
{
    return [self device]->getImage()->b2ts(b).track;
}

-(NSInteger)b2c:(NSInteger)b
{
    return [self device]->getImage()->b2chs(b).cylinder;
}

-(NSInteger)b2h:(NSInteger)b
{
    return [self device]->getImage()->b2chs(b).head;
}

-(NSInteger)b2s:(NSInteger)b
{
    return [self device]->getImage()->b2chs(b).sector;
}

-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s
{
    return [self device]->getImage()->bindex(TrackDevice::TS(t,s));
}

-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s
{
    return [self device]->getImage()->bindex(TrackDevice::CHS(c,h,s));
}

-(NSInteger)readByte:(NSInteger)offset
{
    return [self device]->getImage()->readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block
{
    auto bsize = [self device]->getImage()->bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readByte: block * bsize + offset];
}

-(NSString *)readASCII:(NSInteger)offset length:(NSInteger)len
{
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

-(NSString *)readASCII:(NSInteger)offset from:(NSInteger)block length:(NSInteger)len
{
    auto bsize = [self device]->getImage()->bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readASCII: block * bsize + offset length: len];
}

-(void)writeByte:(NSInteger)offset value:(NSInteger)value
{
    [self device]->writeByte(offset, value);
}

-(void)writeByte:(NSInteger)offset block:(NSInteger)block value:(NSInteger)value
{
    auto bsize = [self device]->getImage()->bsize();
    assert(offset >= 0 && offset < bsize);

    [self device]->writeByte(block * bsize + offset, value);
}

-(void)writeByte:(NSInteger)offset volume:(NSInteger)volume value:(NSInteger)value
{
    [self device]->writeByte(offset, value, volume);
}

-(void)writeByte:(NSInteger)offset volume:(NSInteger)volume block:(NSInteger)block value:(NSInteger)value
{
    auto bsize = [self device]->getImage()->bsize();
    assert(offset >= 0 && offset < bsize);

    [self device]->writeByte(block * bsize + offset, value, volume);
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

- (void)saveAs:(NSURL *)url volume:(NSInteger)volume exception:(ExceptionWrapper *)ex
{
    try { [self device]->saveAs([url fileSystemRepresentation], volume); }
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

- (NSString *)mountPoint:(NSInteger)v
{
    return @([self device]->getVolume(v).getMountPoint().string().c_str());
}

@end
