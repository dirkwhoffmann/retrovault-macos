// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class SidebarViewController: NSViewController {

    @IBOutlet weak var svc: MySplitViewController!
    @IBOutlet weak var outlineView: MyOutlineView!

    var manager: DeviceManager { app.manager }
    var selectionHandler: ((Int?, Int?) -> Void)?

    override func viewDidLoad() {

        app.vc = self
        
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.indentationPerLevel = 0
        outlineView.intercellSpacing = NSSize(width: 0, height: 2)
        outlineView.backgroundColor = .clear
        outlineView.usesAlternatingRowBackgroundColors = false
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

    /*
    @IBAction func shaderSelectAction(_ sender: NSPopUpButton) {

        refresh()
        expandAll()
    }

    @IBAction func presetAction(_ sender: NSPopUpButton) {

        refresh()
    }

    @IBAction func infoAction(_ sender: Any!) {

    }
    */

    @IBAction func cancelAction(_ sender: NSButton) {

        view.window?.close()
    }

    @IBAction func okAction(_ sender: NSButton) {

        view.window?.close()
    }
}

extension SidebarViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        if let item = item as? Int {
            return manager.info(device: item).numPartitions
        } else if let _ = item as? (Int, Int) {
            return 0
        }

        return manager.count
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {

        return 48
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

extension SidebarViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        if let device = item as? Int {

            print("outlineView: \(device)")

            let id = NSUserInterfaceItemIdentifier("DeviceCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! DeviceCell
            cell.setup(device: device)
            return cell

        } else if let (device, volume) = item as? (Int, Int) {

            print("outlineView: \(device), \(volume)")

            let id = NSUserInterfaceItemIdentifier(rawValue: "VolumeCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! VolumeCell
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

    func outlineViewSelectionDidChange(_ notification: Notification) {

        let selectedRow = outlineView.selectedRow
        if selectedRow != -1 {
            let item = outlineView.item(atRow: selectedRow)

            if let device = item as? Int {
                print("Device")
                selectionHandler?(device, nil)
            }
            else if let (device, volume) = item as? (Int, Int) {
                print("Volume")
                selectionHandler?(device, volume)
            } else {
                print("No selection")
                selectionHandler?(nil, nil)
            }
        }
    }
}
