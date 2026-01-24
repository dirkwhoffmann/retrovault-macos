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
        return dlsym(RTLD_DEFAULT, "fuse_mount") != nil
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

        if AppDelegate.hasFUSE {
            showVolumeWindow()
        } else {
            showLaunchErrorWindow()
        }
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

        vc?.outlineView.reloadAndSelectLast()
        //  vc?.outlineView.reloadData()
    }

    func showLaunchErrorWindow() {

        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if let wc = storyboard.instantiateController(withIdentifier: "LaunchInfoWindowController") as? NSWindowController {

            wc.window!.center()
            wc.showWindow(self)

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showVolumeWindow() {

        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        if let _ = storyboard.instantiateController(withIdentifier: "MyWindowController") as? NSWindowController {

            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

