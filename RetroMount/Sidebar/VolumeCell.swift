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

    var device = 0
    var volume = 0

    func setup(device: Int, partition: Int) {

        self.device = device
        self.volume = partition

        update()
    }

    /*
    var shaderSetting: Volume! {

        didSet {

            update()
        }
    }

    var value: Float! { didSet { update() } }
    */
    
    func update() {

        let info = app.manager.info(device: device, volume: volume)

        imageView?.image = info.icon()
        textField?.stringValue = info.mountPoint
    }

    @IBAction func unmountAction(_ sender: NSButton) {

        print("unmountAction")
        app.manager.unmount(device: device, volume: volume)
        print("Unmounted")
        
        outlineView.reloadData()
    }
}
