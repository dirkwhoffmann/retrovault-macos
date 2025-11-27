// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class RetroMounter {

    private var mounts: [RetroMounterProxy] = []

    /*
    func prepare(proxy: RetroMounterProxy) {

        // Convert 'self' to a void pointer
        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        proxy.setListener(myself) { (ptr, msg: Int32) in

            // Convert void pointer back to 'self'
            let myself = Unmanaged<RetroMounter>.fromOpaque(ptr!).takeUnretainedValue()

            // Process message in the main thread
            Task { @MainActor in myself.process(message: Int(msg)) }
        }
    }
    */
    
    func process(message msg: Int) {

        print("Holla, die Waldfee")
    }

    func mount(url: URL) {

        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        do {

            print("Mounting \(url)...")

            let proxy = RetroMounterProxy()
            try proxy.mount(url, myself) { (ptr, msg: Int32) in

                // Convert void pointer back to 'self'
                let myself = Unmanaged<RetroMounter>.fromOpaque(ptr!).takeUnretainedValue()

                // Process message in the main thread
                Task { @MainActor in myself.process(message: Int(msg)) }
            }

            print("Success.")
            mounts.append(proxy)

        } catch { print("Error launching RetroMounter: \(error)") }
    }

    func unmount(proxy: RetroMounterProxy) {

        proxy.unmount()
        mounts.removeAll { $0 === proxy }
    }

    func unmountAll() {

        print("Unmounting all...")
        mounts.forEach { unmount(proxy: $0) }
        mounts.removeAll()
    }
}
