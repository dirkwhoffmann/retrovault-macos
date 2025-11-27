// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var mounter = RetroMounter()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        /*
        mounter = RetroMounterProxy()

        do { try mounter?.launch() }
        catch { print("Error launching RetroMounter: \(error)") }
        */
    }

    func applicationWillTerminate(_ aNotification: Notification) {

        mounter.unmountAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {

        print("application open: urls = \(urls)")
        urls.forEach { mounter.mount(url: $0) }


    }

}

