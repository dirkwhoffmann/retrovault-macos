// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

#import "config.h"
#import "EmulatorProxy.h"
#import "AmigaDevice.h"
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
// AmigaDeviceProxy
//

@implementation AmigaDeviceProxy

- (AmigaDevice *)adapter
{
    return (AmigaDevice *)obj;
}

+ (instancetype)make:(AmigaDevice *)device
{
    if (device == nullptr) { return nil; }

    AmigaDeviceProxy *proxy = [[self alloc] initWith: device];
    return proxy;
}

+ (instancetype)make:(NSURL *)url exception:(ExceptionWrapper *)ex
{
    try {

        auto device = new AmigaDevice([url fileSystemRepresentation]);
        return [self make:device];

    }  catch (Error &error) {

        [ex save:error];
        return nil;
    }
}

- (NSInteger)numVolumes
{
    return [self adapter]->count();
}

- (NSString *)name
{
    return @"NAME (TODO)";
}

- (void)mount:(NSURL *)mountpoint exception:(ExceptionWrapper *)ex
{
    try { [self adapter]->mount([mountpoint fileSystemRepresentation]); }
    catch (Error &error) { [ex save:error]; }
}

- (void)unmount
{
    [self adapter]->unmount();
}

- (void)setListener:(const void *)listener function:(AdapterCallback *)func
{
    [self adapter]->setListener(listener, func);
}

- (NSString *)name:(NSInteger)volume
{
    return @([self adapter]->stat(volume).name.c_str());
}

- (FSTraits)traits:(NSInteger)volume
{
    return [self adapter]->traits(volume);
}

- (FSStat)stat:(NSInteger)volume
{
    return [self adapter]->stat(volume);
}

- (FSBootStat)bootStat:(NSInteger)volume
{
    return [self adapter]->bootStat(volume);
}

@end
