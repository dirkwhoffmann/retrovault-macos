// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MySplitViewController: NSSplitViewController {

    enum SidebarKey: Hashable {
        
        case info
        case device(Int)
        case volume(device: Int, volume: Int)
        
        init(cell: (Int?, Int?)) {
            
            switch cell {
            case (nil, _):          self = .info
            case (let d?, nil):     self = .device(d)
            case (let d?, let v?):  self = .volume(device: d, volume: v)
            }
        }
    }
    
    private var canvases: [SidebarKey: CanvasViewController] = [:]
        
    var sidebarVC: SidebarViewController? {
        return splitViewItems.first?.viewController as? SidebarViewController
    }

    // The currently selected sidebar item (device or volume)
    var selection: (Int?, Int?) = (nil, nil)
    var selectedDevice: Int? { selection.0 }
    var selectedVolume: Int? { selection.1 }

    // The currently active canvas controller
    var current: CanvasViewController?

    private func makeCanvas(for key: SidebarKey) -> CanvasViewController {

        if let existing = canvases[key] { return existing }

        let main = NSStoryboard(name: "Main", bundle: nil)
        let vc: CanvasViewController

        switch key {
            
        case .info:
            vc = main.instantiateController(
                withIdentifier: "InfoCanvasViewController"
            ) as! InfoCanvasViewController

        case .device:
            vc = main.instantiateController(
                withIdentifier: "DeviceCanvasViewController"
            ) as! DeviceCanvasViewController

        case .volume:
            vc = main.instantiateController(
                withIdentifier: "VolumeCanvasViewController"
            ) as! VolumeCanvasViewController
        }

        canvases[key] = vc
        return vc
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        // Assign the selection handler
        sidebarVC?.selectionHandler = { [weak self] (i1, i2) in
            self?.selection = (i1, i2)
            self?.showContent(cell: (i1, i2))
        }
    }

    private func showContent() {

        showContent(cell: selection)
    }

    /*
    private func key(for cell: (Int?, Int?)) -> SidebarKey {

        switch cell {
            
        case (nil, _): return .info
        case (let d?, nil): return .device(d)
        case (let d?, let v?): return .volume(device: d, volume: v)
        }
    }
    */
    
    func showContent(cell: (Int?, Int?)) {
        
        let key = SidebarKey(cell: cell)
        let vc = makeCanvas(for: key)

        if current !== vc {
            
            current = vc
            
            // Remove old content pane
            if splitViewItems.count > 1 {
                removeSplitViewItem(splitViewItems[1])
            }
            
            let newItem = NSSplitViewItem(viewController: vc)
            addSplitViewItem(newItem)
            
            vc.set(device: cell.0, volume: cell.1)
        }
    }

    func refresh() {
        
        current?.refresh()
    }
    
    override func splitViewDidResizeSubviews(_ notification: Notification) {

        // User dragged the divider
        // let left = splitViewItems[0].viewController.view.frame
        // let right = splitViewItems[1].viewController.view.frame
    }
}
