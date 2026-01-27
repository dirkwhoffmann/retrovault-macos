// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension FuseDeviceProxy {

    static func make(with url: URL) throws -> FuseDeviceProxy {

        let exception = ExceptionWrapper()
        let result = FuseDeviceProxy.make(url, exception: exception)
        if exception.fault != 0 { throw AppError(exception) }

        return result!
    }

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
    
    func save() throws {

        let exception = ExceptionWrapper()
        save(exception)
        if exception.fault != 0 { throw AppError(exception) }
    }
}
