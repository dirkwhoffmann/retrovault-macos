// -----------------------------------------------------------------------------
// This file is part of RetroMount
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

- (void)commit:(ExceptionWrapper *)ex
{
    try { [self volume]->commit(); }
    catch (Error &error) { [ex save:error]; }
}

- (FSPosixStat)stat:(NSInteger)volume
{
    return [self volume]->stat();
}

- (NSInteger)bytesRead:(NSInteger)volume
{
    return [self volume]->reads();
}

- (NSInteger)bytesWritten:(NSInteger)volume
{
    return [self volume]->writes();
}

- (void)createUsageMap:(u8 *)buf length:(NSInteger)len
{
    // [self fs]->doctor.createUsageMap((u8 *)buf, len);
}

- (void)createAllocationMap:(u8 *)buf length:(NSInteger)len
{
    // [self fs]->doctor.createAllocationMap((u8 *)buf, len);
}

- (void)createHealthMap:(u8 *)buf length:(NSInteger)len
{
    // [self fs]->doctor.createHealthMap((u8 *)buf, len);
}

- (NSInteger)nextBlockOfType:(FSBlockType)type after:(NSInteger)after
{
    // return [self fs]->doctor.nextBlockOfType(type, BlockNr(after));
    return 0;
}

- (void)rectifyAllocationMap
{
    // [self fs]->doctor.rectifyBitmap();
}

@end


//
// FuseDeviceProxy
//

@implementation FuseDeviceProxy

- (FuseDevice *)adapter
{
    return (FuseDevice *)obj;
}

-(FuseVolumeProxy *)volume:(NSInteger)nr
{
    return [FuseVolumeProxy make: &[self adapter]->getVolume(nr)];
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

- (NSURL *)url
{
    return url;
}

- (ImageInfo)info
{
    return [self adapter]->imageInfo();
}

- (NSInteger)numCyls
{
    return [self adapter]->getImage()->numCyls();
}

- (NSInteger)numHeads
{
    return [self adapter]->getImage()->numHeads();
}

- (NSInteger)numSectors:(NSInteger)t
{
    return [self adapter]->getImage()->numSectors(t);
}

- (NSInteger)numSectors:(NSInteger)c head:(NSInteger)h
{
    return [self adapter]->getImage()->numSectors(c, h);
}

- (NSInteger)numTracks
{
    return [self adapter]->getImage()->numTracks();
}

- (NSInteger)numBlocks
{
    return [self adapter]->getImage()->numBlocks();
}

- (NSInteger)bsize
{
    return [self adapter]->getImage()->bsize();
}

- (NSInteger)numBytes
{
    return [self adapter]->getImage()->numBytes();
}

- (NSInteger)numVolumes
{
    return [self adapter]->count();
}

-(NSInteger)b2t:(NSInteger)b
{
    return [self adapter]->getImage()->b2ts(b).track;
}

-(NSInteger)b2c:(NSInteger)b
{
    return [self adapter]->getImage()->b2chs(b).cylinder;
}

-(NSInteger)b2h:(NSInteger)b
{
    return [self adapter]->getImage()->b2chs(b).head;
}

-(NSInteger)b2s:(NSInteger)b
{
    return [self adapter]->getImage()->b2chs(b).sector;
}

-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s
{
    return [self adapter]->getImage()->bindex(TrackDevice::TS(t,s));
}

-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s
{
    return [self adapter]->getImage()->bindex(TrackDevice::CHS(c,h,s));
}

-(NSInteger)readByte:(NSInteger)offset
{
    return [self adapter]->getImage()->readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block
{
    auto bsize = [self adapter]->getImage()->bsize();
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
    auto bsize = [self adapter]->getImage()->bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readASCII: block * bsize + offset length: len];

}

- (void)save:(ExceptionWrapper *)ex
{
    try { [self adapter]->save(); }
    catch (Error &error) { [ex save:error]; }
}

- (void)mount:(NSURL *)mountpoint exception:(ExceptionWrapper *)ex
{
    try { [self adapter]->mount([mountpoint fileSystemRepresentation]); }
    catch (Error &error) { [ex save:error]; }
}

- (void)unmount:(NSInteger)volume
{
    [self adapter]->unmount(volume);
}

- (void)unmountAll
{
    [self adapter]->unmount();
}

- (void)setListener:(const void *)listener function:(AdapterCallback *)func
{
    [self adapter]->setListener(listener, func);
}

- (void)commit:(ExceptionWrapper *)ex
{
    try { [self adapter]->commit(); }
    catch (Error &error) { [ex save:error]; }
}

- (NSString *)mountPoint:(NSInteger)v
{
    return @([self adapter]->getVolume(v).getMountPoint().string().c_str());
}

@end
