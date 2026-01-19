// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class TableCellView: NSTableCellView {

    @IBOutlet weak var controller: DevicesViewController!

    var outlineView: MyOutlineView { controller.outlineView }

    func updateIcon(expanded: Bool) {

    }
}

class TableDeviceView: TableCellView {

    @IBOutlet weak var disclosureButton: NSButton!
    @IBOutlet weak var protected: NSButton!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var sublabel: NSTextField!
    @IBOutlet weak var subsublabel: NSTextField!

    var device = 0

    func setup(device: Int) {

        self.device = device

        update()
    }

    func update() {

        // let traits = app.manager.traits(device: device, volume: volume)
        let info = app.manager.info(device: device)
        let volumes = info.numPartitions

        label.stringValue = info.name
        sublabel.stringValue = "Amiga Floppy Disk"
        subsublabel.stringValue = "\(volumes) " + (volumes == 1 ? "volume" : "volumes")
    }

    override func updateIcon(expanded: Bool) {

        disclosureButton.state = expanded ? .on : .off
        disclosureButton.image = expanded ? .chevronDown() : .chevronRight()
    }

    override func draw(_ dirtyRect: NSRect) {

        // NSColor.controlAccentColor.withAlphaComponent(0.25).setFill()
        NSColor.separatorColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }

    @IBAction func disclosureAction(_ sender: NSButton) {

        print("disclosureAction")

        if sender.state == .on {
            outlineView.expandItem(device)
        } else {
            outlineView.collapseItem(device)
        }

        outlineView.reloadData()
    }

    @IBAction func enableAction(_ sender: NSButton) {

        outlineView.reloadData()
    }
}

class TableVolumeView: TableCellView {

    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var sublabel: NSTextField!
    @IBOutlet weak var infoButton: NSButton!

    var device = 0
    var volume = 0

    func setup(device: Int, partition: Int) {

        self.device = device
        self.volume = partition

        update()
    }

    var shaderSetting: Volume! {

        didSet {

            update()
        }
    }

    var value: Float! { didSet { update() } }

    func update() {

        let info = app.manager.info(device: device, volume: volume)

        textField?.stringValue = info.mountPoint
        label.stringValue = "\(info.blocks) block"
        sublabel.stringValue = "\(info.fill)% full"
    }

    @IBAction func helpAction(_ sender: NSButton) {

        // Not implemented yet
    }
}
