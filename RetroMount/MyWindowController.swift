// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MyWindowController: NSWindowController {

    private var vc: MySplitViewController? { contentViewController as? MySplitViewController }

    private var isCompact = false
    private var expandedWidth: CGFloat = 0

    private let proposedSidebarWidth = CGFloat(250)
    private let proposedCanvasWidth = CGFloat(480)
    private let proposedCanvasHeight = CGFloat(480)

    private var proposedWidth: CGFloat {

        var result = CGFloat(0.0)

        if sidebar { result += proposedSidebarWidth }
        if canvas { result += proposedCanvasWidth }

        return result
    }

    private var proposedSize: CGSize {

        return CGSize(width: proposedWidth, height: proposedCanvasHeight)
    }

    func resize(animate: Bool = false) {

        var newFrame = window!.frame
        newFrame.size = proposedSize
        window!.setFrame(newFrame, display: true, animate: animate)
    }

    // Indicates if the main canvas is visible
    var canvas: Bool = true {

        didSet {

            // Make sure that at least one element is visible
            if (!canvas) { sidebar = true }

            resize(animate: true)
        }
    }

        // Indicates if the sidebar is visible
    var sidebar: Bool = true {

        didSet {

            // Make sure that at least one element is visible
            if (!sidebar) { canvas = true }

            guard let sidebarItem = vc?.splitViewItems.first else { return }
            sidebarItem.isCollapsed = !sidebar
            resize(animate: true)
        }
    }

    // Set to true to display a REC icon in the upper right corner
    var onAir: Bool = false {

        didSet {
            if onAir != oldValue {

                print("onAir = \(onAir)")

                let icons = [
                    BarIcon(
                        image: NSImage(systemSymbolName: "sidebar.left",
                                       accessibilityDescription: "Shrink or expand")!,
                        height: 20
                    ) {
                        print("Canvas")
                        self.canvas.toggle()
                    },
                    BarIcon(
                        image: NSImage(systemSymbolName: "sidebar.left",
                                       accessibilityDescription: "Shrink or expand")!,
                        height: 20
                    ) {
                        print("Sidebar")
                        self.sidebar.toggle()
                    }
                ]

                window?.removeAccessory(ofType: IconBarViewController.self)
                let iconBar = IconBarViewController(icons: onAir ? icons : [])
                window?.addTitlebarAccessoryViewController(iconBar)
            }
        }
    }

    /*
    func expandOrCollapsewindow() {

        guard let window else { return }

        if isCompact {

                // Expand
                var frame = window.frame
                // let delta = expandedWidth - frame.width

                // frame.origin.x -= delta
                frame.size.width = expandedWidth
                window.setFrame(frame, display: true, animate: true)

            } else {

                // Compact
                expandedWidth = window.frame.width

                var frame = window.frame
                // let delta = frame.width - sidebarWidth
                // frame.origin.x += delta
                frame.size.width = sidebarWidth

                window.setFrame(frame, display: true, animate: true)
            }

            isCompact.toggle()
    }
    */

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {

        onAir = true

        window!.setContentSize(NSSize(width: 300, height: 600))

        canvas = true
        sidebar = true

        window!.center()
        showWindow(self)
    }

    /*
    func show() {

        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    */
}
