// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

@MainActor
var app: AppDelegate { NSApp.delegate as! AppDelegate }

@main @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // Indicates if FUSE is installed
    var hasFUSE = false

    // Device manager
    var manager = DeviceManager()

    // View controller of the devices window
    var vc: DevicesViewController?

    /*
    var windowController: WindowController? {
        return NSApplication.shared.windows.first?.windowController as? WindowController
    }
    */

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {

        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {

    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        hasFUSE = loadFUSE()
        showVolumeWindow()
    }

    /*
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    */

    func applicationWillTerminate(_ aNotification: Notification) {

        manager.unmountAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {

        print("application open: urls = \(urls)")
        urls.forEach { manager.mount(url: $0) }

        vc?.outlineView.reloadData()
    }

    func loadFUSE() -> Bool {

        let libraryPaths = [

            "/usr/lib/libfuse.2.dylib",
            "/usr/local/lib/libfuse.2.dylib"
        ]

        var handle: UnsafeMutableRawPointer?

        for path in libraryPaths {

            if FileManager.default.fileExists(atPath: path) {

                handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL)

                if handle != nil {

                    print("macFUSE loaded from \(path)")
                    return true

                } else if let err = dlerror() {

                    print("Failed to load \(path): \(String(cString: err))")
                }
            }
        }
        return false
    }

    func showVolumeWindow() {

        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let _ = storyboard.instantiateController(withIdentifier: "MyWindowController") as? NSWindowController {

            NSApp.activate(ignoringOtherApps: true)
        }

        /*
        print("showVolumeWindow")
        let sb = NSStoryboard(name: "Main", bundle: nil)
        if let wc = sb.instantiateController(withIdentifier: "Volumes") as? NSWindowController {

            vc = wc.contentViewController as? DevicesViewController

            wc.window?.setContentSize(NSSize(width: 800, height: 600))
            wc.window?.center()
            wc.showWindow(self)
        }
        */
    }

}

