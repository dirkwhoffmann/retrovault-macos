// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class VolumeCell: TableCell {

    @IBOutlet weak var unmountButton: NSButton!

   
    
    // var device = 0 // DEPRECATED
    // var volume = 0 // DEPRECATED

    /*
    func setup(device: Int, partition: Int) {

        self.item = TableItem(device: device, volume: volume)
        self.device = device
        self.volume = partition

        update()
    }
    */
    
    override func update() {

        let info = app.manager.info(device: item.device, volume: item.volume!)

        imageView?.image = info.icon()
        textField?.stringValue = info.mountPoint
    }

    @IBAction func unmountAction(_ sender: NSButton) {

        print("unmountAction")
        controller.unmount(item: item)
    }
}
