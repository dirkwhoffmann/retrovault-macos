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

    func mount(url: URL) {

        do {

            let proxy = RetroMounterProxy()
            print("Mounting \(url)...")
            try proxy.mount(url: url)
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
