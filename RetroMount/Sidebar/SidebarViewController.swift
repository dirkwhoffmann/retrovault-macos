// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

struct TableItem {

    var device: Int
    var volume: Int?
    
    var isDevice: Bool { return volume == nil }
    var isVolume: Bool { return volume != nil }
}

class SidebarViewController: NSViewController {

    @IBOutlet weak var svc: MySplitViewController!
    @IBOutlet weak var outlineView: MyOutlineView!

    var manager: DeviceManager { app.manager }
    var selectionHandler: ((Int?, Int?) -> Void)?
    var deletionHandler: ((Int?, Int?) -> Void)?

    override func viewDidLoad() {

        app.vc = self
        
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.indentationPerLevel = 0
        outlineView.intercellSpacing = NSSize(width: 0, height: 2)
        outlineView.backgroundColor = .clear
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.doubleAction = #selector(doubleClicked(_:))
        outlineView.reloadData()

        expandAll()
    }

    func expandAll() {

        for device in 0..<manager.count {
            outlineView.expandItem(device)
        }
    }

    func refresh() {

        outlineView.reloadData()
    }
    
    @objc private func doubleClicked(_ sender: Any?) {

        let row = outlineView.clickedRow
        guard row >= 0 else { return }

        if let item = outlineView.item(atRow: row) as? TableItem {

            if let volume = item.volume {
                
                let info = app.manager.info(device: item.device, volume: volume)
                let url = URL(fileURLWithPath: info.mountPoint)
                NSWorkspace.shared.open(url)
            }
        }
    }
        
    func unmount(item: TableItem) {
        
        // Remove the device from the model
        app.manager.unmount(item: item)

        // Update the outline view
        outlineView.reloadData()

        // Select another device
        // selectionHandler!(app.manager.count > 0 ? 0 : nil, nil)
        
        if outlineView.numberOfRows > 0 {
            
            outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            outlineView.scrollRowToVisible(0)

        } else {
            
            selectionHandler!(nil, nil)
        }
    }
}

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        if let item = item as? TableItem {
            return item.isDevice ? manager.info(device: item.device).numPartitions : 0
        }

        return manager.count
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {

        return 42
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        guard let tableItem = item as? TableItem else { return false }
        return tableItem.isDevice
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        if let item = item as? TableItem {
            return TableItem(device: item.device, volume: index)
        } else {
            return TableItem(device: index)
        }
    }
}

extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        guard let item = item as? TableItem else { return nil }
        
        if item.isDevice {

            let id = NSUserInterfaceItemIdentifier("DeviceCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! DeviceCell
            cell.setup(item: item)
            return cell

        } else {

            let id = NSUserInterfaceItemIdentifier(rawValue: "VolumeCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! VolumeCell
            cell.setup(item: item)
            return cell
        }
    }

    
    func outlineViewItemDidExpand(_ notification: Notification) {

        guard let item = notification.userInfo?["NSObject"] else { return }
        if let cell = item as? Device {
            cell.view?.updateIcon(expanded: true)
        }
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {

        guard let item = notification.userInfo?["NSObject"] else { return }
        if let cell = item as? Device {
            cell.view?.updateIcon(expanded: false)
        }
    }
    
    
    func outlineViewSelectionDidChange(_ notification: Notification) {

        let selectedRow = outlineView.selectedRow
        
        if selectedRow >= 0 {
        
            if let item = outlineView.item(atRow: selectedRow) as? TableItem {
                selectionHandler?(item.device, item.volume)
            } else {
                selectionHandler?(nil, nil)
            }
        }
    }
}
