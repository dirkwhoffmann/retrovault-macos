// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

actor ImageRenderer {

    private var isRendering = false
    private var needsAnotherPass = false

    func render(renderer: () async -> NSImage?,
                completion: @MainActor @escaping (_ image: NSImage?) -> Void) async {

        if isRendering {
            
            needsAnotherPass = true;
            return
        }

        isRendering = true

        repeat {
            
            needsAnotherPass = false
            async let image = renderer()
            await completion(image)
            
        } while needsAnotherPass

        isRendering = false
    }
}

@MainActor
class VolumeCanvasViewController: CanvasViewController {

    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var mainTitle: NSTextField!
    @IBOutlet weak var subTitle1: NSTextField!
    @IBOutlet weak var subTitle2: NSTextField!
    @IBOutlet weak var subTitle3: NSTextField!
    @IBOutlet weak var readInfo: NSTextField!
    @IBOutlet weak var writeInfo: NSTextField!
    @IBOutlet weak var fillInfo: NSTextField!
    @IBOutlet weak var fillIndicator: NSLevelIndicator!
    @IBOutlet weak var numBlocksInfo: NSTextField!
    @IBOutlet weak var usedBlocksInfo: NSTextField!
    @IBOutlet weak var cachedBlocksInfo: NSTextField!

    @IBOutlet weak var tabView: NSTabView!

    @IBOutlet weak var blockImageButton: NSButton!
    @IBOutlet weak var blockType1Button: NSButton!
    @IBOutlet weak var blockType2Button: NSButton!
    @IBOutlet weak var blockType3Button: NSButton!
    @IBOutlet weak var blockType4Button: NSButton!
    @IBOutlet weak var blockType5Button: NSButton!
    @IBOutlet weak var blockType6Button: NSButton!
    @IBOutlet weak var blockType7Button: NSButton!
    @IBOutlet weak var blockType8Button: NSButton!
    @IBOutlet weak var blockType1Label: NSTextField!
    @IBOutlet weak var blockType2Label: NSTextField!
    @IBOutlet weak var blockType3Label: NSTextField!
    @IBOutlet weak var blockType4Label: NSTextField!
    @IBOutlet weak var blockType5Label: NSTextField!
    @IBOutlet weak var blockType6Label: NSTextField!
    @IBOutlet weak var blockType7Label: NSTextField!
    @IBOutlet weak var blockType8Label: NSTextField!
    
    @IBOutlet weak var allocImageButton: NSButton!
    @IBOutlet weak var allocInfo: NSTextField!
    @IBOutlet weak var allocGreenButton: NSButton!
    @IBOutlet weak var allocYellowButton: NSButton!
    @IBOutlet weak var allocRedButton: NSButton!
    @IBOutlet weak var allocScanButton: NSButton!
    @IBOutlet weak var allocStrictButton: NSButton!
    @IBOutlet weak var allocRectifyInfo: NSTextField!
    @IBOutlet weak var allocRectifyButton: NSButton!
    @IBOutlet weak var allocProgress: NSProgressIndicator!

    @IBOutlet weak var diagnoseImageButton: NSButton!
    @IBOutlet weak var diagnoseInfo: NSTextField!
    @IBOutlet weak var diagnosePassButton: NSButton!
    @IBOutlet weak var diagnoseFailButton: NSButton!
    @IBOutlet weak var diagnoseNextButton: NSButton!
    @IBOutlet weak var diagnoseNextInfo: NSTextField!
    @IBOutlet weak var diagnoseScanButton: NSButton!
    @IBOutlet weak var diagnoseStrictButton: NSButton!
    @IBOutlet weak var diagnoseRectifyInfo: NSTextField!
    @IBOutlet weak var diagnoseRectifyButton: NSButton!
    @IBOutlet weak var diagnoseProgress: NSProgressIndicator!

    @IBOutlet weak var previewScrollView: NSScrollView!
    @IBOutlet weak var previewTable: NSTableView!
    @IBOutlet weak var blockField: NSTextField!
    @IBOutlet weak var blockStepper: NSStepper!
    @IBOutlet weak var info1: NSTextField!
    @IBOutlet weak var info2: NSTextField!
    
    var proxy: FuseVolumeProxy? { volumeProxy }
    
    // Currently displayed items (used to trigger refresh actions)
    var displayedGeneration: Int?
    var displayedBlock: Int?
    var displayedTab: Int?

    // Current selection
    var selectedBlock = 0
    
    var selectedCell: Int?
    var selectedRow: Int? { return selectedCell == nil ? nil : selectedCell! / 16 }
    var selectedCol: Int? { return selectedCell == nil ? nil : selectedCell! % 16 }
    
    // Cached volume info
    var info = VolumeInfo()

    // Renderer for the block usage image
    let usageImageRenderer = ImageRenderer()

    // Color palette
    var palette: [NSColor] = []
    
    // Result of the consistency checker
    var erroneousBlocks: [NSNumber]?
    var usedButUnallocated: [NSNumber]?
    var unusedButAllocated: [NSNumber]?
    
    var numBlocks: Int { return info.blocks }
    
    override func viewDidLoad() {
        
        // Register to receive mouse click events
        previewTable.action = #selector(clickAction(_:))
                
        let click = NSClickGestureRecognizer(target: self, action: #selector(buttonClicked(_:)))
        blockImageButton.addGestureRecognizer(click)

        activate()
    }
    
    private var timer: Timer?

    override func viewWillAppear() {

        super.viewWillAppear()
        startPeriodicTask()
    }

    override func viewWillDisappear() {

        super.viewWillDisappear()
        stopPeriodicTask()
    }
    
    private func startPeriodicTask() {

        guard timer == nil else { return }

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in

            guard let self else { return }
            Task { @MainActor in self.refresh() }
        }
    }

    private func stopPeriodicTask() {

        timer?.invalidate()
        timer = nil
    }

    //
    // Updating
    //

    override func activate() {
        
        func updateBlockButton(_ button: NSButton, _ label: NSTextField,
                               _ col: NSColor = .white, _ txt: String = "") {
            
            button.image = NSImage(color: col, size: NSSize(width: 16, height: 16))
            button.isHidden = txt.isEmpty
            label.stringValue = txt
        }

        let description = proxy!.describe()
        info = app.manager.info(device: device!, volume: volume!)
        
        icon.image = info.icon()
        mainTitle.stringValue = info.name
        subTitle1.stringValue = description?[safe: 0] ?? ""
        subTitle2.stringValue = description?[safe: 1] ?? ""
        subTitle3.stringValue = description?[safe: 2] ?? ""
                        
        switch info.deviceInfo.info.format {

        case .ADF, .ADZ, .EADF, .DMS:

            palette = [
                
                Palette.white,
                Palette.gray,
                Palette.orange,
                Palette.red,
                Palette.purple,
                Palette.pink,
                Palette.yellow,
                Palette.blue,
                Palette.dgreen,
                Palette.green,
                Palette.green
            ]

            updateBlockButton(blockType1Button, blockType1Label, palette[2], "Boot Block")
            updateBlockButton(blockType2Button, blockType2Label, palette[3], "Root Block")
            updateBlockButton(blockType3Button, blockType3Label, palette[4], "Bitmap Block")
            updateBlockButton(blockType4Button, blockType4Label, palette[5], "Bitmap Extension Block")
            updateBlockButton(blockType5Button, blockType5Label, palette[6], "User Directory Block")
            updateBlockButton(blockType6Button, blockType6Label, palette[7], "File Header Block")
            updateBlockButton(blockType7Button, blockType7Label, palette[8], "File List Block")
            updateBlockButton(blockType8Button, blockType8Label, palette[9], "Data Block")

        case .D64:

            palette = [
                
                Palette.white,
                Palette.gray,
                Palette.red,
                Palette.yellow,
                Palette.green
            ]
            
            updateBlockButton(blockType1Button, blockType1Label, palette[2], "BAM")
            updateBlockButton(blockType2Button, blockType2Label, palette[3], "Directory Block")
            updateBlockButton(blockType3Button, blockType3Label, palette[4], "Data Block")
            updateBlockButton(blockType4Button, blockType4Label)
            updateBlockButton(blockType5Button, blockType5Label)
            updateBlockButton(blockType6Button, blockType6Label)
            updateBlockButton(blockType7Button, blockType7Label)
            updateBlockButton(blockType8Button, blockType8Label)

        default:
            break
        }

        let size = NSSize(width: 16, height: 16)
        allocGreenButton.image = NSImage(color: Palette.green, size: size)
        allocYellowButton.image = NSImage(color: Palette.yellow, size: size)
        allocRedButton.image = NSImage(color: Palette.red, size: size)

        displayedBlock = nil
        displayedTab = nil
        displayedGeneration = nil
        refresh()
    }
    
    override func refresh() {

        guard let device = device else { return }
        guard let volume = volume else { return }
        info = app.manager.info(device: device, volume: volume)

        // Determine dirty items
        let contentIsDirty = info.generation != displayedGeneration
        let tableViewIsDirty = displayedBlock != selectedBlock || contentIsDirty
        
        displayedGeneration = info.generation
        displayedBlock = selectedBlock
        displayedTab = selectedTab
        
        refreshVolumeInfo()
        refreshHealthInfo()
        
        if info.generation != displayedGeneration || blockImageButton.image == nil {
            
            refreshUsageInfo()
            Task {
                await usageImageRenderer.render(renderer: { await self.renderUsageImage() })
                { image in self.blockImageButton.image = image }
            }
        }
        
        if tableViewIsDirty {
            
            refreshTableViewInfo()
            previewTable.reloadData()
        }
    }
        
    func refreshVolumeInfo() {
            
        guard let proxy = proxy else { return }
        let description = proxy.describe()
        // guard let device = device else { return }
        // guard let volume = volume else { return }
        // let info = app.manager.info(device: device, volume: volume)
                
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = description?[safe: 0] ?? ""
        subTitle2.stringValue = description?[safe: 1] ?? ""
        subTitle3.stringValue = description?[safe: 2] ?? ""
        
        let r = Int(Double(proxy.bytesRead) / 1024.0)
        let w = Int(Double(proxy.bytesWritten) / 1024.0)
        readInfo.stringValue = "\(r) KB"
        writeInfo.stringValue = "\(w) KB"
        fillInfo.stringValue = info.fillString
        fillIndicator.doubleValue = (info.fill * 100.0).rounded()
        numBlocksInfo.stringValue = "\(info.blocks) Blocks"
        usedBlocksInfo.stringValue = "\(info.usedBlocks) Blocks"
        cachedBlocksInfo.stringValue = "\(info.dirtyBlocks) Blocks"
    }

    @MainActor
    func renderUsageImage() async -> NSImage? {
        
        let size = await MainActor.run {
            blockImageButton.bounds.size.scaled(x: 2.0)
        }
        return await Task(priority: .utility) {
            layoutImage(size: size)
        }.value
    }

    func refreshUsageInfo() {

        /*
        let palette = VolumeCanvasViewController.palette
        let size = NSSize(width: 16, height: 16)

        // UI setup
        blockType1Button.image = NSImage(color: palette[2], size: size)
        blockType2Button.image = NSImage(color: palette[3], size: size)
        blockType3Button.image = NSImage(color: palette[4], size: size)
        blockType4Button.image = NSImage(color: palette[5], size: size)
        blockType6Button.image = NSImage(color: palette[8], size: size)
        blockType5Button.image = NSImage(color: palette[7], size: size)
        blockType7Button.image = NSImage(color: palette[6], size: size)
        blockType8Button.image = NSImage(color: palette[9], size: size)
        */
    }
    
    @MainActor
    func renderAllocImage() async -> NSImage? {
        
        let size = await MainActor.run {
            allocImageButton.bounds.size
        }
        return await Task(priority: .utility) {
            allocImage(size: size)
        }.value
    }
        
    func refreshAllocInfo() {
     
        // let total = errorReport?.bitmapErrors ?? 0
        let total = (unusedButAllocated?.count ?? 0) + (usedButUnallocated?.count ?? 0)

        if total > 0 {
            
            let blocks = total == 1 ? "block" : "blocks"
            diagnoseInfo.stringValue = "\(total) suspicious \(blocks) found"
        }

        allocInfo.isHidden = total == 0
        allocRectifyInfo.isHidden = total == 0
        allocRectifyButton.isHidden = total == 0
    }
    
    @MainActor
    func renderHealthImage() async -> NSImage? {
        
        let size = await MainActor.run {
            diagnoseImageButton.bounds.size
        }
        return await Task(priority: .utility) {
            diagnoseImage(size: size)
        }.value
    }
        
    func refreshHealthInfo() {

        let size = NSSize(width: 16, height: 16)
        diagnosePassButton.image = NSImage(color: Palette.green, size: size)
        diagnoseFailButton.image = NSImage(color: Palette.red, size: size)

        let total = erroneousBlocks?.count ?? 0

        if total > 0 {
            
            let blocks = total == 1 ? "block" : "blocks"
            diagnoseInfo.stringValue = "\(total) corrupted \(blocks) found"
        }

        diagnoseInfo.isHidden = total == 0
        diagnoseNextInfo.isHidden = total == 0
        diagnoseNextButton.isHidden = total == 0
        diagnoseRectifyInfo.isHidden = total == 0
        diagnoseRectifyButton.isHidden = total == 0
    }
   
    func refreshTableViewInfo() {
                
        guard let info = proxy?.stat else { return }
        
        blockField.stringValue = String(format: "%d", selectedBlock)
        blockStepper.minValue = Double(0)
        blockStepper.maxValue = Double(info.blocks - 1)
        blockStepper.integerValue = selectedBlock

        if selectedCell == nil {
            updateBlockInfoUnselected()
            updateErrorInfoUnselected()
        } else {
            updateBlockInfoSelected()
            updateErrorInfoSelected()
        }
    }
    
    func updateBlockInfoUnselected() {
        
        let type = proxy?.type(of: selectedBlock)
        info1.stringValue = type ?? "?"
    }
    
    func updateBlockInfoSelected() {
        
        let usage = proxy?.type(of: selectedBlock, pos: selectedCell!)
        info1.stringValue = usage ?? "?"
    }

    func updateErrorInfoUnselected() {

        info2.stringValue = ""
    }

    func updateErrorInfoSelected() {
        
        // var exp = UInt8(0)
        // let error = vol.check(blockNr, pos: selection!, expected: &exp, strict: strict)
        info2.stringValue = "???" // error.description(expected: Int(exp))
    }
    
    //
    // Helper methods
    //
        
    func setBlock(_ newValue: Int) {
        
        print("setBlock \(newValue) \(numBlocks)")
        if newValue != selectedBlock {
                        
            selectedBlock = max(0, min(newValue, numBlocks - 1))
            print("blockNr set to \(selectedBlock)")
            selectedCell = nil
            refresh()
        }
    }
    
    //
    // Action methods
    //

    @objc func buttonClicked(_ sender: NSClickGestureRecognizer) {

        let point = sender.location(in: sender.view)
        let x = point.x / blockImageButton.bounds.width
    
        print("Clicked \(x)")
        
        setBlock(Int(x * CGFloat(numBlocks)))
    }
    
    @IBAction func blockTypeAction(_ sender: NSButton!) {
        
        // var type = FSBlockType(rawValue: sender.tag)!

        // Make sure we search the correct data block type
        // if type == .DATA_OFS && vol.isFFS { type = .DATA_FFS }
        // if type == .DATA_FFS && vol.isOFS { type = .DATA_OFS }

        // Goto the next block of the requested type
        // let nextBlock = vol.nextBlock(of: type, after: blockNr)
        // if nextBlock != -1 { setBlock(nextBlock) }
    }

    @IBAction func blockAction(_ sender: NSTextField!) {
        
        setBlock(sender.integerValue)
    }
    
    @IBAction func blockStepperAction(_ sender: NSStepper!) {
        
        print("Stepper: \(sender.integerValue)")
        setBlock(sender.integerValue)
    }
            
    @IBAction func gotoNextCorruptedBlockAction(_ sender: NSButton!) {

        guard let erroneousBlocks = erroneousBlocks else { return }
        
        var low = 0
        var high = erroneousBlocks.count

        while low < high {

            let mid = (low + high) / 2
            if erroneousBlocks[mid].intValue > selectedBlock {
                high = mid
            } else {
                low = mid + 1
            }
        }

        if low < erroneousBlocks.count {
            setBlock(erroneousBlocks[low].intValue)
        } else if erroneousBlocks.count > 0 {
            setBlock(erroneousBlocks[0].intValue)
        }
    }

    @IBAction func scanAllocationMapAction(_ sender: NSButton!) {

        Task {
            
            // UI updates must be on MainActor
            await MainActor.run {
                
                allocScanButton.isHidden = true
                allocProgress.isHidden = false
                allocProgress.startAnimation(sender)
                allocImageButton.image = nil
            }

            // Run heavy work off the main thread
            await Task.detached(priority: .userInitiated) {

                // Artificial delay for testing
                try? await Task.sleep(nanoseconds: 3_000_000_000)

                await self.proxy?.xrayBitmap(true)
            }.value

            // Back to MainActor for UI updates
            await MainActor.run {

                let size = allocImageButton.bounds.size
                allocImageButton.image = allocImage(size: size)

                allocProgress.stopAnimation(sender)
                allocProgress.isHidden = true
                allocScanButton.isHidden = false
            }
            
            usedButUnallocated = proxy?.usedButUnallocated
            unusedButAllocated = proxy?.unusedButAllocated
            refreshAllocInfo()
        }
    }
    
    @IBAction func strictAllocationMapAction(_ sender: NSButton!) {

        scanBlocksAction(sender)
    }

    @IBAction func rectifyAllocationMapAction(_ sender: NSButton!) {
        
        proxy?.rectifyAllocationMap(allocStrictButton.state == .on)
        scanAllocationMapAction(sender)
    }
    
    @IBAction func scanBlocksAction(_ sender: NSButton!) {

        Task {
            
            // UI updates must be on MainActor
            await MainActor.run {
                
                diagnoseScanButton.isHidden = true
                diagnoseProgress.isHidden = false
                diagnoseProgress.startAnimation(sender)
                diagnoseImageButton.image = nil
            }

            // Run heavy work off the main thread
            await Task.detached(priority: .userInitiated) {

                // Artificial delay for testing
                try? await Task.sleep(nanoseconds: 3_000_000_000)

                await self.proxy?.xray(self.diagnoseStrictButton.state == .on)
            }.value

            // Back to MainActor for UI updates
            await MainActor.run {

                let size = diagnoseImageButton.bounds.size
                diagnoseImageButton.image = diagnoseImage(size: size)

                diagnoseProgress.stopAnimation(sender)
                diagnoseProgress.isHidden = true
                diagnoseScanButton.isHidden = false
            }
            
            usedButUnallocated = proxy?.usedButUnallocated
            unusedButAllocated = proxy?.unusedButAllocated
            refreshHealthInfo()
        }
    }

    @IBAction func strictBlocksAction(_ sender: NSButton!) {

        scanBlocksAction(sender)
    }

    @IBAction func rectifyBlocksAction(_ sender: NSButton!) {
        
        proxy?.rectify(diagnoseStrictButton.state == .on)
        scanBlocksAction(sender)
    }
    
    @IBAction func clickAction(_ sender: NSTableView!) {
        
        if sender.clickedColumn >= 1 && sender.clickedRow >= 0 {
            
            let newValue = 16 * sender.clickedRow + sender.clickedColumn - 1
            selectedCell = selectedCell != newValue ? newValue : nil
            refresh()
        }
    }
}

//
// Data source
//

@MainActor
extension VolumeCanvasViewController: NSTableViewDataSource {
    
    func columnNr(_ column: NSTableColumn?) -> Int? {
        
        return column == nil ? nil : Int(column!.identifier.rawValue)
    }
        
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return (deviceProxy?.bsize ?? 0) / 16
    }
    
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        switch tableColumn?.identifier.rawValue {
            
        case "Offset":
            return String(format: "%X", row)
            
        case "Ascii":
            return proxy?.readASCII(row * 16, from: selectedBlock, length: 16) ?? ""
            
        default:
            
            guard let col = columnNr(tableColumn),
                  let byte = proxy?.readByte(16 * row + col, from: selectedBlock) else { return "--" }
            
            return String(format: "%02X", byte)
        }
    }
}

@MainActor
extension VolumeCanvasViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {

        var exp = UInt8(0)
        let cell = cell as? NSTextFieldCell

        if let col = columnNr(tableColumn) {
            
            let offset = 16 * row + col
            let strict = diagnoseStrictButton.state == .on
            let error = proxy?.xray(selectedBlock, pos: offset, expected: &exp, strict: strict)
            
            if row == selectedRow && col == selectedCol {
                cell?.textColor = .white
                cell?.backgroundColor = error == "" ? .selectedContentBackgroundColor : .systemRed
            } else {
                cell?.textColor = error == "" ? .textColor : .systemRed
                cell?.backgroundColor = NSColor.alternatingContentBackgroundColors[row % 2]
            }
        } else {
            cell?.backgroundColor = .windowBackgroundColor
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

@MainActor
extension VolumeCanvasViewController: NSTabViewDelegate {
    
    var selectedTab: Int? {
            
        guard let id = tabView.selectedTabViewItem?.identifier as? String else { return nil }
        return Int(id)
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        
        /*
        let id = tabViewItem?.identifier as? String
        selectedTab = Int(id ?? "") ?? 0
        forceRefresh()
        */
        refresh()
    }
}

//
// Image creation
//
    
@MainActor
extension VolumeCanvasViewController {
    
    struct Palette {
        
        static let white = NSColor.white
        static let gray = NSColor.gray
        static let black = NSColor.black
        static let red = NSColor(r: 0xff, g: 0x66, b: 0x66, a: 0xff)
        static let orange = NSColor(r: 0xff, g: 0xb2, b: 0x66, a: 0xff)
        static let yellow = NSColor(r: 0xff, g: 0xff, b: 0x66, a: 0xff)
        static let green = NSColor(r: 0x66, g: 0xff, b: 0x66, a: 0xff)
        static let dgreen = NSColor(r: 0x00, g: 0x99, b: 0x00, a: 0xff)
        static let cyan = NSColor(r: 0x66, g: 0xff, b: 0xff, a: 0xff)
        static let blue = NSColor(r: 0x66, g: 0xb2, b: 0xff, a: 0xff)
        static let purple = NSColor(r: 0xb2, g: 0x66, b: 0xff, a: 0xff)
        static let pink = NSColor(r: 0xff, g: 0x66, b: 0xff, a: 0xff)
    }
    
    func layoutImage(size: NSSize) -> NSImage? {
        
        var data = Data(count: Int(size.width))
                
        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                proxy?.createUsageMap(baseAddress, length: Int(size.width))
            }
        }
                
        return createImage(data: data, size: size, colorize: { (x: UInt8) -> NSColor in
            
            return palette[Int(x)]
        })
    }

    func allocImage(size: NSSize) -> NSImage? {
        
        var data = Data(count: Int(size.width))
                
        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                proxy?.createAllocationMap(baseAddress, length: Int(size.width))
            }
        }
        
        return createImage(data: data, size: size, colorize: { (x: UInt8) -> NSColor in
            
            switch x {
            case 0: return Palette.gray
            case 1: return Palette.green
            case 2: return Palette.yellow
            case 3: return Palette.red
            default: fatalError()
            }
        })
    }
    
    func diagnoseImage(size: NSSize) -> NSImage? {
        
        var data = Data(count: Int(size.width))
                
        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                proxy?.createHealthMap(baseAddress, length: Int(size.width))
            }
        }
        
        return createImage(data: data, size: size, colorize: { (x: UInt8) -> NSColor in
            
            switch x {
            case 0: return Palette.gray
            case 1: return Palette.green
            case 2: return Palette.red
            default: return Palette.white
            }
        })
    }
 
    func createImage(data: Data, size: NSSize, colorize: (UInt8) -> NSColor) -> NSImage? {
        
        precondition(data.count == Int(size.width))
        
        // Create image representation in memory
        let width = Int(size.width)
        let height = Int(size.height)
        let cap = width * height
        let mask = calloc(cap, MemoryLayout<UInt32>.size)!
        let ptr = mask.bindMemory(to: UInt32.self, capacity: cap)

        // Create image data
        for x in 0..<width {

            // let color = colors[vol.getDisplayType(x)]!
            let color = colorize(data[x])
            let ciColor = CIColor(color: color)!
            
            for y in 0...height-1 {
                
                var r, g, b, a: Int
                
                r = Int(ciColor.red * CGFloat(255 - 2*y))
                g = Int(ciColor.green * CGFloat(255 - 2*y))
                b = Int(ciColor.blue * CGFloat(255 - 2*y))
                a = Int(ciColor.alpha * CGFloat(255))

                let abgr = UInt32(r | g << 8 | b << 16 | a << 24)
                ptr[y*width + x] = abgr
            }
        }

        // Create image
        let image = NSImage.make(data: mask, rect: size)
        let resizedImage = image?.resizeSharp(width: CGFloat(width), height: CGFloat(height))
        return resizedImage
    }
}
