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

    var current: CanvasViewController?

    private var sidebarVC: DevicesViewController? {
        return splitViewItems.first?.viewController as? DevicesViewController
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        sidebarVC?.selectionHandler = { [weak self] (i1,i2) in
            self?.showContent(cell: (i1,i2))
        }
    }

    private func showContent(for item: TableCellView) {

        showContent(title: "Volume")
    }

    func showContent(cell: (Int?, Int?)) {

        if let _ = cell.0, let _ = cell.1 {
            showContent(title: "Device")
        } else if let _ = cell.0 {
            showContent(title: "Volume")
        } else {
            showContent(title: "Info")
        }
    }
    
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
}
