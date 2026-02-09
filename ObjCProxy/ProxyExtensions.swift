// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension FuseVolumeProxy {
    
    /*
    func push() throws {

        let exception = ExceptionWrapper()
        push(exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    */
}

extension FuseDeviceProxy {
    
    static func make(with url: URL) throws -> FuseDeviceProxy {
        
        let exception = ExceptionWrapper()
        let result = FuseDeviceProxy.make(url, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
        
        return result!
    }
 
    /*
    func open(url: URL) throws {
        
        let exception = ExceptionWrapper()
        open(url, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }

    func close() throws {
        
        let exception = ExceptionWrapper()
        close(exception)
        if exception.fault != 0 { throw AppError(exception) }
    }

    func close(volume: Int) throws {
        
        let exception = ExceptionWrapper()
        close(volume, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    */
    
    func save() throws {
        
        let exception = ExceptionWrapper()
        save(exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
 
    func save(volume: Int) throws {
        
        let exception = ExceptionWrapper()
        save(volume, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    
    func saveAs(url: URL) throws {
        
        let exception = ExceptionWrapper()
        save(as: url, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }

    func saveAs(url: URL, volume: Int) throws {
        
        let exception = ExceptionWrapper()
        save(as: url, volume: volume, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    
    func revert() throws {
        
        let exception = ExceptionWrapper()
        revert(exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
 
    func revert(volume: Int) throws {
        
        let exception = ExceptionWrapper()
        revert(volume, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    
    // DEPRECATED...
    
    
    func mount(at mountpoint: URL) throws {
        
        let exception = ExceptionWrapper()
        mount(mountpoint, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
    
    func mount(at mountpoint: URL,
               _ listener: UnsafeRawPointer,
               _ callback: @escaping @convention(c) (UnsafeRawPointer?, Int32) -> Void) throws
    {
        try mount(at: mountpoint)
        setListener(listener, function: callback)
    }
}
