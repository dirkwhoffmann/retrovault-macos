// -----------------------------------------------------------------------------
// This file is part of RetroMount
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
    var hasFuse = false
    
    // Device manager
    var manager = DeviceManager()

    // View controller of the devices window
    var vc: SidebarViewController?

    // Split view controller
    var svc: MySplitViewController?
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {

        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {

    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Check if FUSE is installed
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)!
        hasFuse = dlsym(RTLD_DEFAULT, "fuse_mount") != nil

        // Disable the File menu (for now)
        if let fileMenuItem = NSApp.mainMenu?.item(withTitle: "File") {
            fileMenuItem.isHidden = true
        }

        if hasFuse {
            showVolumeWindow()
        } else {
            showLaunchErrorWindow()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {

        manager.unmountAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {

        urls.forEach { manager.mount(url: $0) }
        
        svc?.isCollapsed = false
        vc?.outlineView.reloadAndSelectLast()
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
    
    /*
    var needsSaving: Bool {
        
        if let dev = svc?.selectedDevice, let vol = svc?.selectedVolume {
            return manager.needsSaving(device: dev, volume: vol)
        }
        if let dev = svc?.selectedDevice {
            return manager.needsSaving(device: dev)
        }
        return false
    }
    */
}

