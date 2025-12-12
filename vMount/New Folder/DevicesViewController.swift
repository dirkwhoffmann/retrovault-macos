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

    var devices: [Device] {

        var result: [Device] = []
        if let ds = self.dataSource {
            let count = ds.outlineView?(self, numberOfChildrenOfItem: parent) ?? 0
            for i in 0..<count {
                if let child = ds.outlineView?(self, child: i, ofItem: parent) {
                    if let group = child as? Device {
                        result.append(group)
                    }
                }
            }
        }
        return result
    }

    override func frameOfOutlineCell(atRow row: Int) -> NSRect {

        return .zero
    }
}

class DevicesViewController: NSViewController {

    @IBOutlet weak var outlineView: MyOutlineView!

    override func viewDidLoad() {

        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.indentationPerLevel = 0
        outlineView.intercellSpacing = NSSize(width: 0, height: 2)
        outlineView.gridColor = .separatorColor // .controlBackgroundColor // windowBackgroundColor
        outlineView.gridStyleMask = [.solidHorizontalGridLineMask]
        outlineView.reloadData()

        expandAll()
    }

    func expandAll() {

        for group in outlineView.devices {
            outlineView.expandItem(group)
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

        if let group = item as? Device {

            return group.children.count
            // return group.children.filter { $0.hidden == false }.count
        } else {

            return app.devices.settings.count
        }
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {

        return 74
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {

        return item is Device
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {

        if let group = item as? Device {
            return group.children[index]
            // return group.children.filter { $0.hidden == false }[index]
        } else {
            return app.devices.settings[index]
        }
    }
}

extension DevicesViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {

        if let group = item as? Device {

            let id = NSUserInterfaceItemIdentifier("GroupCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! TableDeviceView
            cell.setup(with: group)
            cell.updateIcon(expanded: outlineView.isItemExpanded(item))
            group.view = cell
            return cell

        } else if let row = item as? Volume {

            let id = NSUserInterfaceItemIdentifier(rawValue: "RowCell")
            let cell = outlineView.makeView(withIdentifier: id, owner: self) as! TableVolumeView
            cell.shaderSetting = row
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
