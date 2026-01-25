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

    var info: VolumeInfo?

    override func viewDidLoad() {

    }

    override func refresh() {

        guard let device = device else { return }
        guard let volume = volume else { return }
        info = app.manager.info(device: device, volume: volume)
        guard let info = info else { return }

        icon.image = info.icon()
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = "\(info.blocks) block"
        subTitle2.stringValue = "\(info.fill)% full"
    }
}
