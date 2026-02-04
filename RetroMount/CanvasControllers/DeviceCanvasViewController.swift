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

    var info = DeviceInfo()
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

        let description = proxy!.describe()
        info = app.manager.info(device: device!)

        icon.image = info.pictogram
        mainTitle.stringValue = info.name
        subTitle1.stringValue = description?[safe: 0] ?? ""
        subTitle2.stringValue = description?[safe: 1] ?? ""
        subTitle3.stringValue = description?[safe: 2] ?? ""
        
        cylinderStepper.maxValue = .greatestFiniteMagnitude
        headStepper.maxValue = .greatestFiniteMagnitude
        trackStepper.maxValue = .greatestFiniteMagnitude
        sectorStepper.maxValue = .greatestFiniteMagnitude
        blockStepper.maxValue = .greatestFiniteMagnitude
    }

    override func refresh() {
         
        refreshDeviceInfo()
        refreshSelection()
    }

    override func activate() {
        
    }
    
    func refreshDeviceInfo() {
                
        // guard let proxy = proxy else { return }
        // let description = proxy.describe()
        guard let device = device else { return }
        info = app.manager.info(device: device)

        // icon.image = info.icon()

        cylindersInfo.stringValue = String(format: "%d", info.numCyls)
        headsInfo.stringValue = String(format: "%d", info.numHeads)
        sectorsInfo.stringValue = String(format: "%d", info.minSectors)
        if info.minSectors != info.maxSectors {
            sectorsInfo.stringValue += String(format: " - %d", info.maxSectors)
        }
        blocksInfo.stringValue = String(format: "%d", info.numBlocks)
        bsizeInfo.stringValue = String(format: "%d", info.bsize)
        capacityInfo.stringValue = info.capacityString
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

        blockView.reloadData()
    }

    //
    // Helper methods
    //

    func clamp(_ value: Int, to range: Range<Int>) -> Int {

        return max(range.lowerBound, min(value, range.upperBound - 1))
    }

    func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {

        return max(range.lowerBound, min(value, range.upperBound))
    }

    func setCylinder(_ newValue: Int) {

        if newValue != currentCyl {

            let value = clamp(newValue, to: 0...upperCyl)

            currentCyl      = value
            currentTrack    = numHeads * currentCyl + currentHead
            currentSector   = clamp(currentSector, to: 0..<upperSector(track: currentTrack))
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setHead(_ newValue: Int) {

        if newValue != currentHead {

            let value = clamp(newValue, to: 0...upperHead)

            currentHead     = value
            currentTrack    = numHeads * currentCyl + currentHead
            currentSector   = clamp(currentSector, to: 0..<upperSector(track: currentTrack))
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setTrack(_ newValue: Int) {

        if newValue != currentTrack {

            let value = clamp(newValue, to: 0...upperTrack)

            currentTrack    = value
            currentSector   = clamp(currentSector, to: 0..<upperSector(track: currentTrack))
            currentCyl      = currentTrack / numHeads
            currentHead     = currentTrack % numHeads
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setSector(_ newValue: Int) {

        if newValue != currentSector {

            let value = clamp(newValue, to: 0...upperSector(track: currentTrack))

            currentSector   = value
            currentBlock    = proxy?.chs2b(currentCyl, h: currentHead, s: currentSector) ?? 0

            refreshSelection()
        }
    }

    func setBlock(_ newValue: Int) {

        if newValue != currentBlock {

            let value = clamp(newValue, to: 0...upperBlock)

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

//
// Data source
//

@MainActor
extension DeviceCanvasViewController: NSTableViewDataSource {

    func columnNr(_ column: NSTableColumn?) -> Int? {

        return column == nil ? nil : Int(column!.identifier.rawValue)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {

        return (proxy?.bsize ?? 0) / 16
    }

    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        switch tableColumn?.identifier.rawValue {

        case "Offset":
            return String(format: "%X", row)

        case "Ascii":
            return proxy?.readASCII(row * 16, from: currentBlock, length: 16) ?? ""

        default:
            let offset = row * 16 + columnNr(tableColumn)!
            if let byte = proxy?.readByte(offset, from: currentBlock) {
                return String(format: "%02X", byte)
            } else {
                return "--"
            }
        }
    }
}

@MainActor
extension DeviceCanvasViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
