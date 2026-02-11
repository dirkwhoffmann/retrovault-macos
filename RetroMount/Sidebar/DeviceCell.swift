// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class DeviceCell: TableCell {

    @IBOutlet weak var syncButton: NSButton!
    
    override func update() {

        let info = app.manager.info(device: item.device)

        imageView?.image = info.pictogram
        textField?.stringValue = info.name
    }

    override func updateIcon(expanded: Bool) {

    }

    @IBAction func syncAction(_ sender: NSButton) {

        print("syncAction")
        
        // TODO: Handle error
        try? proxy?.save()
    }
}
