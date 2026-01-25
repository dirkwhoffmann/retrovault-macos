// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class VolumeCanvasViewController: CanvasViewController {

    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var mainTitle: NSTextField!
    @IBOutlet weak var subTitle1: NSTextField!
    @IBOutlet weak var subTitle2: NSTextField!
    @IBOutlet weak var subTitle3: NSTextField!
    @IBOutlet weak var cylindersInfo: NSTextField!
    @IBOutlet weak var headsInfo: NSTextField!
    @IBOutlet weak var sectorsInfo: NSTextField!
    @IBOutlet weak var blocksInfo: NSTextField!
    @IBOutlet weak var bsizeInfo: NSTextField!
    @IBOutlet weak var capacityInfo: NSTextField!
    
    override func viewDidLoad() {

    }

    override func refresh(selection: (Int?, Int?)) {

        guard let device = selection.0 else { return }
        guard let volume = selection.1 else { return }

        let info = app.manager.info(device: device, volume: volume)

        icon.image = info.icon()
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = "\(info.blocks) block"
        subTitle2.stringValue = "\(info.fill)% full"
    }
}
