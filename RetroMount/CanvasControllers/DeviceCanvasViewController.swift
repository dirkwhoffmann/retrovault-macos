// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class DeviceCanvasViewController: CanvasViewController {

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

    @IBOutlet weak var cylinderField: NSTextField!
    @IBOutlet weak var cylinderStepper: NSStepper!
    @IBOutlet weak var headField: NSTextField!
    @IBOutlet weak var headStepper: NSStepper!
    @IBOutlet weak var trackField: NSTextField!
    @IBOutlet weak var trackStepper: NSStepper!
    @IBOutlet weak var sectorField: NSTextField!
    @IBOutlet weak var sectorStepper: NSStepper!
    @IBOutlet weak var blockField: NSTextField!
    @IBOutlet weak var blockStepper: NSStepper!

    @IBOutlet weak var blockScrollView: NSScrollView!
    @IBOutlet weak var blockView: NSTableView!

    var info: DeviceInfo?
    var proxy: FuseDeviceProxy? { return app.manager.proxy(device: device) }

    // Drive geometry
    var numCyls: Int { return proxy?.numCyls ?? 0 }
    var numHeads: Int { return proxy?.numHeads ?? 0 }
    func numSectors(track: Int) -> Int { return proxy?.numSectors(track) ?? 0 }
    var numTracks: Int { return proxy?.numTracks ?? 0 }
    var numBlocks: Int { return proxy?.numBlocks ?? 0 }

    var upperCyl: Int { return max(numCyls - 1, 0) }
    var upperHead: Int { return max(numHeads - 1, 0) }
    func upperSector(track: Int) -> Int { return max(numSectors(track: track) - 1, 0) }
    var upperTrack: Int { return max(numTracks - 1, 0) }
    var upperBlock: Int { return max(numBlocks - 1, 0) }

    // Current selection
    var currentCyl = 0
    var currentHead = 0
    var currentTrack = 0
    var currentSector = 0
    var currentBlock = 0

    override func viewDidLoad() {

        cylinderStepper.maxValue = .greatestFiniteMagnitude
        headStepper.maxValue = .greatestFiniteMagnitude
        trackStepper.maxValue = .greatestFiniteMagnitude
        sectorStepper.maxValue = .greatestFiniteMagnitude
        blockStepper.maxValue = .greatestFiniteMagnitude
    }

    override func refresh() {

        guard let device = device else { return }
        info = app.manager.info(device: device)
        guard let info = info else { return }

        icon.image = info.icon()
        mainTitle.stringValue = info.name
        subTitle1.stringValue = info.description
        subTitle2.stringValue = info.capacityString

        refreshSelection()
    }

    func refreshSelection() {

        cylinderField.stringValue      = String(format: "%d", currentCyl)
        cylinderStepper.integerValue   = currentCyl
        headField.stringValue          = String(format: "%d", currentHead)
        headStepper.integerValue       = currentHead
        trackField.stringValue         = String(format: "%d", currentTrack)
        trackStepper.integerValue      = currentTrack
        sectorField.stringValue        = String(format: "%d", currentSector)
        sectorStepper.integerValue     = currentSector
        blockField.stringValue         = String(format: "%d", currentBlock)
        blockStepper.integerValue      = currentBlock
    }

    //
    // Helper methods
    //

    func setCylinder(_ newValue: Int) {

        if newValue != currentCyl {

            let value = max(0, min(newValue, upperCyl))

            currentCyl      = value
            currentTrack    = 2 * currentCyl + currentHead
            currentSector   = max(0, min(newValue, numSectors(track: currentTrack)))
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setHead(_ newValue: Int) {

        if newValue != currentHead {

            let value = max(0, min(newValue, upperHead))

            currentHead     = value
            currentTrack    = 2 * currentCyl + currentHead
            currentSector   = max(0, min(newValue, numSectors(track: currentTrack)))
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setTrack(_ newValue: Int) {

        if newValue != currentTrack {

            let value = max(0, min(newValue, upperTrack))

            currentTrack    = value
            currentSector   = max(0, min(newValue, numSectors(track: currentTrack)))
            currentCyl      = currentTrack / 2
            currentHead     = currentTrack % 2
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setSector(_ newValue: Int) {

        if newValue != currentSector {

            let value = max(0, min(newValue, upperSector(track: currentTrack)))

            currentSector   = value
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setBlock(_ newValue: Int) {

        if newValue != currentBlock {

            let value = max(0, min(newValue, upperBlock))

            currentBlock    = value
            currentTrack    = proxy?.b2t(currentBlock) ?? 0
            currentCyl      = proxy?.b2c(currentBlock) ?? 0
            currentHead     = proxy?.b2h(currentBlock) ?? 0
            currentSector   = proxy?.b2s(currentBlock) ?? 0

            refreshSelection()
        }
    }

    //
    // Action methods
    //

    @IBAction func cylinderAction(_ sender: NSTextField!) {

        setCylinder(sender.integerValue)
    }

    @IBAction func cylinderStepperAction(_ sender: NSStepper!) {

        setCylinder(sender.integerValue)
    }

    @IBAction func headAction(_ sender: NSTextField!) {

        setHead(sender.integerValue)
    }

    @IBAction func headStepperAction(_ sender: NSStepper!) {

        setHead(sender.integerValue)
    }

    @IBAction func trackAction(_ sender: NSTextField!) {

        setTrack(sender.integerValue)
    }

    @IBAction func trackStepperAction(_ sender: NSStepper!) {

        setTrack(sender.integerValue)
    }

    @IBAction func sectorAction(_ sender: NSTextField!) {

        setSector(sender.integerValue)
    }

    @IBAction func sectorStepperAction(_ sender: NSStepper!) {

        setSector(sender.integerValue)
    }

    @IBAction func blockAction(_ sender: NSTextField!) {

        setBlock(sender.integerValue)
    }

    @IBAction func blockStepperAction(_ sender: NSStepper!) {

        setBlock(sender.integerValue)
    }
}
