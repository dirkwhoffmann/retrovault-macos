//
//  AppDelegate.swift
//  vMount
//
//  Created by Dirk Hoffmann on 19.11.25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var mounter: RetroMounterProxy?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        mounter = RetroMounterProxy()

        try? mounter?.launch()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

