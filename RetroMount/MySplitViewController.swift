// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MySplitViewController: NSSplitViewController {

    let main = NSStoryboard(name: "Main", bundle: nil)

    private lazy var infoVC: InfoCanvasViewController = {
        return main.instantiateController(withIdentifier: "InfoCanvasViewController") as! InfoCanvasViewController
    }()
    private lazy var deviceVC: DeviceCanvasViewController = {
        return main.instantiateController(withIdentifier: "DeviceCanvasViewController") as! DeviceCanvasViewController
    }()
    private lazy var volumeVC: VolumeCanvasViewController = {
        return main.instantiateController(withIdentifier: "VolumeCanvasViewController") as! VolumeCanvasViewController
    }()

    var sidebarVC: SidebarViewController? {
        return splitViewItems.first?.viewController as? SidebarViewController
    }

    // The currently selected sidebar item (device or volume)
    var selection: (Int?, Int?) = (nil, nil)

    // The currently active canvas controller
    var current: CanvasViewController?

    override func viewDidLoad() {

        super.viewDidLoad()

        /*
        let sidebar = splitViewItems[0]
        let canvas  = splitViewItems[1]

        // Sidebar resists resizing
        sidebar.holdingPriority = .defaultHigh

        // Canvas yields to resizing
        canvas.holdingPriority = .defaultLow
         */

        // Assign the selection handler
        sidebarVC?.selectionHandler = { [weak self] (i1,i2) in

            print("Selected: (\(i1 ?? -1),\(i2 ?? -1))")
            self?.selection = (i1,i2)
            self?.showContent()
            self?.current?.set(device: i1, volume: i2)
        }
    }

    func setCanvasWidth(_ width: CGFloat, animated: Bool = true) {

        let clamped = max(0, min(400, width))

        guard splitView.isVertical else { return }

        let totalWidth = splitView.bounds.width
        let dividerThickness = splitView.dividerThickness

        // Sidebar stays fixed, so divider position = sidebar width
        let sidebarWidth = totalWidth - clamped - dividerThickness

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                splitView.setPosition(sidebarWidth, ofDividerAt: 0)
            }
        } else {
            splitView.setPosition(sidebarWidth, ofDividerAt: 0)
        }
    }

    private func showContent() {

        showContent(cell: selection)
    }

    func showContent(cell: (Int?, Int?)) {

        let isDevice = cell.0 != nil && cell.1 == nil
        let isVolume = cell.0 != nil && cell.1 != nil

        current = isDevice ? deviceVC : isVolume ? volumeVC : infoVC

        // Remove the old content pane
        removeSplitViewItem(splitViewItems[1])

        // Create a new split view item for the new content
        let newItem = NSSplitViewItem(viewController: current!)
        addSplitViewItem(newItem)
    }

    /*
    func showContent(title: String) {

        switch title {
        case "Device": current = deviceVC
        case "Volume": current = volumeVC
        default: current = infoVC
        }

        // Remove the old content pane
        removeSplitViewItem(splitViewItems[1])

        // Create a new split view item for the new content
        let newItem = NSSplitViewItem(viewController: current!)
        addSplitViewItem(newItem)
    }
    */

    override func splitViewDidResizeSubviews(_ notification: Notification) {

        // User dragged the divider
        let left = splitViewItems[0].viewController.view.frame
        let right = splitViewItems[1].viewController.view.frame

        print("Left width:", left.width)
        print("Right width:", right.width)
    }
}
