// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class DeviceCell: TableCell {

    @IBOutlet weak var syncButton: NSButton!

    var device = 0

    func setup(device: Int) {

        self.device = device

        update()
    }

    func update() {

        let info = app.manager.info(device: device)

        imageView?.image = info.icon()
        textField?.stringValue = info.name
    }

    override func updateIcon(expanded: Bool) {

    }

    /*
    @IBAction func disclosureAction(_ sender: NSButton) {

        print("disclosureAction")

        if sender.state == .on {
            outlineView.expandItem(device)
        } else {
            outlineView.collapseItem(device)
        }

        outlineView.reloadData()
    }
    */

    @IBAction func syncAction(_ sender: NSButton) {

        print("syncAction")
    }
}
