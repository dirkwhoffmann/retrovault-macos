// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MyOutlineView : NSOutlineView {

    /*
    var devices: [DeviceInfo] {

        var result: [DeviceInfo] = []
        if let ds = self.dataSource {
            let count = ds.outlineView?(self, numberOfChildrenOfItem: parent) ?? 0
            for i in 0..<count {
                if let child = ds.outlineView?(self, child: i, ofItem: parent) {
                    if let group = child as? DeviceInfo {
                        result.append(group)
                    }
                }
            }
        }
        return result
    }
    */

    override func frameOfOutlineCell(atRow row: Int) -> NSRect {

        return .zero
    }
}

class DevicesViewController: NSViewController {

    @IBOutlet weak var outlineView: MyOutlineView!

    var manager: DeviceManager { app.manager }
    
    override func viewDidLoad() {

        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.indentationPerLevel = 0
        outlineView.intercellSpacing = NSSize(width: 0, height: 2)
        outlineView.backgroundColor = .clear
        outlineView.usesAlternatingRowBackgroundColors = false
        // outlineView.gridColor = .separatorColor // .controlBackgroundColor // windowBackgroundColor
        // outlineView.gridStyleMask = [.solidHorizontalGridLineMask]
        outlineView.reloadData()

        expandAll()
    }

    func expandAll() {

        /*
        for group in outlineView.devices {
            outlineView.expandItem(group)
        }
        */
        for device in 0..<manager.count {
            outlineView.expandItem(device)
        }
    }

    func refresh() {

        outlineView.reloadData()
    }

    @IBAction func shaderSelectAction(_ sender: NSPopUpButton) {

        refresh()
        expandAll()
    }

    @IBAction func presetAction(_ sender: NSPopUpButton) {

        refresh()
    }

    @IBAction func infoAction(_ sender: Any!) {

    }

    @IBAction func cancelAction(_ sender: NSButton) {

        view.window?.close()
    }

    @IBAction func okAction(_ sender: NSButton) {

        view.window?.close()
    }
}

extension DevicesViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        if let item = item as? Int {
            return manager.info(device: item).numPartitions
        } else if let _ = item as? (Int, Int) {
            return 0
        }

        return manager.count
    }

    /*
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {

    }
    */

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {

        return 84
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        return item is Int
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        if let dev = item as? Int {
            return (dev, index)
        } else {
            return index
        }
    }
}

extension DevicesViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        if let device = item as? Int {

            print("outlineView: \(device)")

            let id = NSUserInterfaceItemIdentifier("GroupCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! TableDeviceView
            cell.setup(device: device)
            cell.updateIcon(expanded: outlineView.isItemExpanded(item))
            // group.view = cell
            return cell

        } else if let (device, volume) = item as? (Int, Int) {

            print("outlineView: \(device), \(volume)")

            let id = NSUserInterfaceItemIdentifier(rawValue: "RowCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! TableVolumeView
            cell.setup(device: device, partition: volume)
            return cell

        } else {

            return nil
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
}
