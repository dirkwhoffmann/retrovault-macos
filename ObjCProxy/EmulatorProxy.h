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
#import "DeviceTypes.h"
#import "FSTypes.h"
#import "FuseFileSystemTypes.h"
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

- (FSTraits)traits:(NSInteger)volume;

@end
