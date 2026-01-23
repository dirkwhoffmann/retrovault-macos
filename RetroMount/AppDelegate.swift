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
    static var hasFUSE: Bool {

        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)!
        // return dlsym(RTLD_DEFAULT, "fuse_mount") != nil
        return dlsym(RTLD_DEFAULT, "fuse_mount") == nil // REMOVE ASAP
    }

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

        print("hasFUSE: \(AppDelegate.hasFUSE)")
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

    func showVolumeWindow() {

        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if let wc = storyboard.instantiateController(withIdentifier: "LaunchInfoWindowController") as? NSWindowController {

            // wc.window!.setContentSize(NSSize(width: 480, height: 480))

            wc.window!.center()
            wc.showWindow(self)

            NSApp.activate(ignoringOtherApps: true)
        }

        else if let _ = storyboard.instantiateController(withIdentifier: "MyWindowController") as? NSWindowController {

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

