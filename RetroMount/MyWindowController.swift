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

    /*
    private var isCompact = false
    private var expandedWidth: CGFloat = 0

    private let proposedSidebarWidth = CGFloat(250)
    private let proposedCanvasWidth = CGFloat(480)
    private let proposedCanvasHeight = CGFloat(480)

    private var proposedWidth: CGFloat {

        var result = CGFloat(0.0)

        if sidebar, let sidebarWidth = vc?.splitViewItems.first?.viewController.view.frame.width {
            result += sidebarWidth + 16.0
        }

        if canvas { result += proposedCanvasWidth }

        print("proposedWidth: \(result) \(vc?.splitViewItems.first?.viewController.view.frame.width)")
        return result
    }

    private var proposedSize: CGSize {

        return CGSize(width: proposedWidth, height: proposedCanvasHeight)
    }
     */
    /*
    func resize(animate: Bool = false) {

        var left = vc?.splitViewItems[0].viewController.view.frame.width ?? 0.0
        var right = vc?.splitViewItems[1].viewController.view.frame.width ?? 0.0

        print("canvas: \(canvas)")
        if canvas {
            vc?.splitViewItems[0].viewController.view.frame.size.width = 0
            vc?.splitViewItems[1].viewController.view.frame.size.width = 400
            var newFrame = window!.frame
            newFrame.size = CGSize(width: 400,height: newFrame.height)
            window!.setFrame(newFrame, display: true, animate: animate)
        } else {
            vc?.splitViewItems[0].viewController.view.frame.size.width = 200
            vc?.splitViewItems[1].viewController.view.frame.size.width = 0
            var newFrame = window!.frame
            newFrame.size = CGSize(width: 200,height: newFrame.height)
            window!.setFrame(newFrame, display: true, animate: animate)
        }
    }
    */

    // Indicates if the main canvas is visible
    var canvas: Bool = true {

        didSet {

            /*
            if canvas {
                vc?.splitViewItems[1].isCollapsed = false
            } else {
                vc?.splitViewItems[1].isCollapsed = true
            }

            if let contentView = window!.contentView {

                // contentView.wantsLayer = true
                let layer = contentView.layer!
                layer.borderColor = NSColor.windowBackgroundColor.cgColor // systemBlue.cgColor
                layer.borderWidth = 5
                layer.cornerRadius = NSWindow.cornerRadius
            }
            */

            // resize(animate: true)
        }
    }

    // Shows or hides the sidebar
    var sidebar: Bool = true /* {

        didSet {

            // Make sure that at least one element is visible
            if (!sidebar) { canvas = true }

            guard let sidebarItem = vc?.splitViewItems.first else { return }
            sidebarItem.isCollapsed = !sidebar
            resize(animate: true)
        }
    }
                              */

    // Shows or hides the sidebar icon next to the window controls
    var sidebarIcon: Bool = false {

        didSet {
            if sidebarIcon != oldValue {

                let icons = [
                    BarIcon(
                        image: NSImage(systemSymbolName: "sidebar.left",
                                       accessibilityDescription: "Shrink or expand")!,
                        height: 20
                    ) {
                        print("Canvas")
                        self.canvas.toggle()
                    }
                ]

                window?.removeAccessory(ofType: IconBarViewController.self)
                if (sidebarIcon) {

                    let iconBar = IconBarViewController(icons: sidebarIcon ? icons : [])
                    window?.addTitlebarAccessoryViewController(iconBar)
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {

        // window!.setContentSize(NSSize(width: 300, height: 600))

        canvas = true
        sidebar = true
        // sidebarIcon = true

        window!.center()
        showWindow(self)
    }

}
