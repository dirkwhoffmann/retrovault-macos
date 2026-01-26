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
// MediaFile
//

/*
@implementation MediaFileProxy

- (MediaFile *)file
{
    return (MediaFile *)obj;
}

+ (instancetype)make:(void *)file
{
    return file ? [[self alloc] initWith:file] : nil;
}

+ (FileType)typeOfUrl:(NSURL *)url
{
    return MediaFile::type([url fileSystemRepresentation]);
}

+ (instancetype)makeWithFile:(NSString *)path
                   exception:(ExceptionWrapper *)ex
{
    try { return [self make: MediaFile::make([path fileSystemRepresentation])]; }
    catch(Error &error) { [ex save:error]; return nil; }
}

+ (instancetype)makeWithFile:(NSString *)path
                        type:(FileType)type
                   exception:(ExceptionWrapper *)ex
{
    try { return [self make: MediaFile::make([path fileSystemRepresentation], type)]; }
    catch(Error &error) { [ex save:error]; return nil; }
}

+ (instancetype)makeWithBuffer:(const void *)buf length:(NSInteger)len
                          type:(FileType)type
                     exception:(ExceptionWrapper *)ex
{
    try { return [self make: MediaFile::make((u8 *)buf, len, type)]; }
    catch(Error &error) { [ex save:error]; return nil; }
}

- (FileType)type
{
    return [self file]->type();
}

- (u64)fnv
{
    return [self file]->fnv64();
}

- (NSInteger)size
{
    return [self file]->getSize();
}

- (Compressor)compressor
{
    return [self file]->compressor();
}

- (BOOL)compressed
{
    return [self file]->isCompressed();
}

- (u8 *)data
{
    return [self file]->getData();
}

- (void)writeToFile:(NSString *)path exception:(ExceptionWrapper *)ex
{
    try { [self file]->writeToFile(string([path fileSystemRepresentation])); }
    catch(Error &err) { [ex save:err]; }
}

- (void)writeToFile:(NSString *)path partition:(NSInteger)part exception:(ExceptionWrapper *)ex
{
    try { [self file]->writePartitionToFile(string([path fileSystemRepresentation]), part); }
    catch(Error &err) { [ex save:err]; }
}

- (NSImage *)previewImage
{
    // Return cached image (if any)
    if (preview) { return preview; }

    // Get dimensions and data
    auto size = [self file]->previewImageSize();
    auto data = (unsigned char *)[self file]->previewImageData();

    // Create preview image
    if (data) {

        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes: &data
                                 pixelsWide:size.first
                                 pixelsHigh:size.second
                                 bitsPerSample:8
                                 samplesPerPixel:4
                                 hasAlpha:true
                                 isPlanar:false
                                 colorSpaceName:NSCalibratedRGBColorSpace
                                 bytesPerRow:4*size.first
                                 bitsPerPixel:32];

        preview = [[NSImage alloc] initWithSize:[rep size]];
        [preview addRepresentation:rep];

        // image.makeGlossy()
    }
    return preview;
}

- (time_t)timeStamp
{
    return [self file]->timestamp();
}

- (DiskInfo)diskInfo
{
    return [self file]->getDiskInfo();
}

-(HDFInfo)hdfInfo
{
    return [self file]->getHDFInfo();
}

- (NSInteger)readByte:(NSInteger)b offset:(NSInteger)offset
{
    return [self file]->readByte(b, offset);
}

- (void)readSector:(NSInteger)b destination:(unsigned char *)buf
{
    [self file]->readSector(buf, b);
}

- (NSString *)hexdump:(NSInteger)b offset:(NSInteger)offset len:(NSInteger)len
{
    return @([self file]->hexdump(b, offset, len).c_str());
}

- (NSString *)asciidump:(NSInteger)b offset:(NSInteger)offset len:(NSInteger)len
{
    return @([self file]->asciidump(b, offset, len).c_str());
}

@end
*/

//
// FuseDeviceProxy
//

@implementation FuseDeviceProxy

- (FuseDevice *)adapter
{
    return (FuseDevice *)obj;
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

/*
        auto device = new AmigaDevice([url fileSystemRepresentation]);

        FuseDeviceProxy *proxy = [self make:device];
        proxy->url = url;
        return proxy;
*/

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
    return [self adapter]->image->numCyls();
}

- (NSInteger)numHeads
{
    return [self adapter]->image->numHeads();
}

- (NSInteger)numSectors:(NSInteger)t
{
    return [self adapter]->image->numSectors(t);
}

- (NSInteger)numSectors:(NSInteger)c head:(NSInteger)h
{
    return [self adapter]->image->numSectors(c, h);
}

- (NSInteger)numTracks
{
    return [self adapter]->image->numTracks();
}

- (NSInteger)numBlocks
{
    return [self adapter]->image->numBlocks();
}

- (NSInteger)bsize
{
    return [self adapter]->image->bsize();
}

- (NSInteger)numBytes
{
    return [self adapter]->image->numBytes();
}

- (NSInteger)numVolumes
{
    return [self adapter]->count();
}

-(NSInteger)b2t:(NSInteger)b
{
    return [self adapter]->image->b2ts(b).track;
}

-(NSInteger)b2c:(NSInteger)b
{
    return [self adapter]->image->b2chs(b).cylinder;
}

-(NSInteger)b2h:(NSInteger)b
{
    return [self adapter]->image->b2chs(b).head;
}

-(NSInteger)b2s:(NSInteger)b
{
    return [self adapter]->image->b2chs(b).sector;
}

-(NSInteger)ts2b:(NSInteger)t s:(NSInteger)s
{
    return [self adapter]->image->bindex(TrackDevice::TS(t,s));
}

-(NSInteger)chs2b:(NSInteger)c h:(NSInteger)h s:(NSInteger)s
{
    return [self adapter]->image->bindex(TrackDevice::CHS(c,h,s));
}

-(NSInteger)readByte:(NSInteger)offset
{
    return [self adapter]->image->readByte(offset);
}

-(NSInteger)readByte:(NSInteger)offset from:(NSInteger)block
{
    auto bsize = [self adapter]->image->bsize();
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
    auto bsize = [self adapter]->image->bsize();
    assert(offset >= 0 && offset < bsize);

    return [self readASCII: block * bsize + offset length: len];

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

- (NSString *)mountPoint:(NSInteger)v
{
    return @([self adapter]->getVolume(v).getMountPoint().string().c_str());
}

- (FSPosixStat)stat:(NSInteger)volume
{
    return [self adapter]->stat(volume);
}

- (NSInteger)bytesRead:(NSInteger)volume
{
    return [self adapter]->getVolume(volume).reads();
}

- (NSInteger)bytesWritten:(NSInteger)volume
{
    return [self adapter]->getVolume(volume).writes();
}

@end
