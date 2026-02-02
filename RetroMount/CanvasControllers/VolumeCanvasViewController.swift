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

actor DeprecatedImageRenderer {

    private var isRendering = false
    private var needsAnotherPass = false

    func render(usage: () async -> NSImage?,
                alloc: () async -> NSImage?,
                health: () async -> NSImage?,
                completion: @MainActor @escaping (_ usage: NSImage?, _ alloc: NSImage?, _ health: NSImage?) -> Void) async {

        if isRendering {
            
            needsAnotherPass = true;
            return
        }

        isRendering = true

        repeat {
            needsAnotherPass = false

            async let usageImage  = usage()
            async let allocImage  = alloc()
            async let healthImage = health()

            let images = await (usageImage, allocImage, healthImage)
            
            await completion(images.0, images.1, images.2)

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

    @IBOutlet weak var blockImageButton: NSButton!
    @IBOutlet weak var bootBlockButton: NSButton!
    @IBOutlet weak var rootBlockButton: NSButton!
    @IBOutlet weak var bmBlockButton: NSButton!
    @IBOutlet weak var bmExtBlockButton: NSButton!
    @IBOutlet weak var fileHeaderBlockButton: NSButton!
    @IBOutlet weak var fileListBlockButton: NSButton!
    @IBOutlet weak var userDirBlockButton: NSButton!
    @IBOutlet weak var dataBlockButton: NSButton!

    @IBOutlet weak var allocImageButton: NSButton!
    @IBOutlet weak var allocInfo: NSTextField!
    @IBOutlet weak var allocGreenButton: NSButton!
    @IBOutlet weak var allocYellowButton: NSButton!
    @IBOutlet weak var allocRedButton: NSButton!
    @IBOutlet weak var allocRectifyInfo: NSTextField!
    @IBOutlet weak var allocRectifyButton: NSButton!

    @IBOutlet weak var diagnoseImageButton: NSButton!
    @IBOutlet weak var diagnoseInfo: NSTextField!
    @IBOutlet weak var diagnosePassButton: NSButton!
    @IBOutlet weak var diagnoseFailButton: NSButton!
    @IBOutlet weak var diagnoseNextButton: NSButton!
    @IBOutlet weak var diagnoseNextInfo: NSTextField!

    @IBOutlet weak var previewScrollView: NSScrollView!
    @IBOutlet weak var previewTable: NSTableView!
    @IBOutlet weak var blockField: NSTextField!
    @IBOutlet weak var blockStepper: NSStepper!
    @IBOutlet weak var strictButton: NSButton!
    @IBOutlet weak var info1: NSTextField!
    @IBOutlet weak var info2: NSTextField!
    
    var proxy: FuseVolumeProxy? { return app.manager.proxy(device: device)?.volume(volume!) }
    
    // Generation counter (use inside the refresh logic)
    var generation: Int?

    // Cached volume info
    var info = VolumeInfo()

    let usageImageRenderer = ImageRenderer()
    let allocImageRenderer = ImageRenderer()
    let diagnoseImageRenderer = ImageRenderer()

    // Result of the consistency checker
    var erroneousBlocks: [NSNumber] = []
    var bitMapErrors: [NSNumber] = []

    var selection: Int?
    var selectedRow: Int? { return selection == nil ? nil : selection! / 16 }
    var selectedCol: Int? { return selection == nil ? nil : selection! % 16 }
    var strict: Bool { return strictButton.state == .on }
    
    // Displayed block in the table view
    var blockNr = 0
    
    // Cached volume properties
    var numBlocks: Int { return proxy?.stat.blocks ?? 0 }
    
    override func viewDidLoad() {

        // Register to receive mouse click events
        previewTable.action = #selector(clickAction(_:))
                
        let click = NSClickGestureRecognizer(target: self, action: #selector(buttonClicked(_:)))
        blockImageButton.addGestureRecognizer(click)
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
    
    override func refresh() {

        guard let device = device else { return }
        guard let volume = volume else { return }

        info = app.manager.info(device: device, volume: volume)
        if generation == info.generation { return }

        refreshVolumeInfo()
        refreshUsageInfo()
        refreshAllocInfo()
        refreshHealthInfo()
        refredshBlockInfo()
        previewTable.reloadData()
        
        Task {
            await usageImageRenderer.render(renderer: { await self.renderUsageImage() })
            { image in self.blockImageButton.image = image }
        }
        Task {
            await allocImageRenderer.render(renderer: { await self.renderAllocImage() })
            { image in self.allocImageButton.image = image }
        }
        Task {
            await diagnoseImageRenderer.render(renderer: { await self.renderHealthImage() })
            { image in self.diagnoseImageButton.image = image }
        }
    }
    
    func forceRefresh() {
    
        generation = nil
        refresh();
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

        let palette = VolumeCanvasViewController.palette
        let size = NSSize(width: 16, height: 16)

        // UI setup
        bootBlockButton.image       = NSImage(color: palette[2], size: size)
        rootBlockButton.image       = NSImage(color: palette[3], size: size)
        bmBlockButton.image         = NSImage(color: palette[4], size: size)
        bmExtBlockButton.image      = NSImage(color: palette[5], size: size)
        fileListBlockButton.image   = NSImage(color: palette[8], size: size)
        fileHeaderBlockButton.image = NSImage(color: palette[7], size: size)
        userDirBlockButton.image    = NSImage(color: palette[6], size: size)
        dataBlockButton.image       = NSImage(color: palette[9], size: size)
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
    
    func refreshAllocImage() {
            
        let size = NSSize(width: 16, height: 16)
        allocGreenButton.image = NSImage(color: Palette.green, size: size)
        allocYellowButton.image = NSImage(color: Palette.yellow, size: size)
        allocRedButton.image = NSImage(color: Palette.red, size: size)
    }
    
    func refreshAllocInfo() {
     
        // let total = errorReport?.bitmapErrors ?? 0
        let total = bitMapErrors.count

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
    
    /*
    func refreshHealthImage() {
            
        let size = NSSize(width: 16, height: 16)
        diagnosePassButton.image = NSImage(color: Palette.green, size: size)
        diagnoseFailButton.image = NSImage(color: Palette.red, size: size)
    }
    */
    
    func refreshHealthInfo() {

        let size = NSSize(width: 16, height: 16)
        diagnosePassButton.image = NSImage(color: Palette.green, size: size)
        diagnoseFailButton.image = NSImage(color: Palette.red, size: size)

        
        // let total = errorReport?.corruptedBlocks ?? 0
        let total = erroneousBlocks.count

        if total > 0 {
            
            let blocks = total == 1 ? "block" : "blocks"
            diagnoseInfo.stringValue = "\(total) corrupted \(blocks) found"
        }

        diagnoseInfo.isHidden = total == 0
        diagnoseNextInfo.isHidden = total == 0
        diagnoseNextButton.isHidden = total == 0
    }
   
    func refredshBlockInfo() {
                
        guard let info = proxy?.stat else { return }
        
        print("blockNr \(blockNr)")
        blockField.stringValue = String(format: "%d", blockNr)
        blockStepper.minValue = Double(0)
        blockStepper.maxValue = Double(info.blocks - 1)
        blockStepper.integerValue = blockNr

        if selection == nil {
            updateBlockInfoUnselected()
            updateErrorInfoUnselected()
        } else {
            updateBlockInfoSelected()
            updateErrorInfoSelected()
        }
    }
    
    func updateBlockInfoUnselected() {
        
        let type = proxy?.blockType(blockNr)
        info1.stringValue = type ?? "?"
    }
    
    func updateBlockInfoSelected() {
        
        // let usage = vol.itemType(blockNr, pos: selection!)
        info1.stringValue = "???" // usage.description
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
        if newValue != blockNr {
                        
            blockNr = max(0, min(newValue, numBlocks - 1))
            print("blockNr set to \(blockNr)")
            selection = nil
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
        
        setBlock(0) // x * numBlocks
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

        var low = 0
        var high = erroneousBlocks.count

        while low < high {

            let mid = (low + high) / 2
            if erroneousBlocks[mid].intValue > blockNr {
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

    @IBAction func rectifyAction(_ sender: NSButton!) {
        
        // vol.rectifyAllocationMap()
        refreshAllocImage()
        refresh()
    }

    @IBAction func strictAction(_ sender: NSButton!) {

        // Examine all blocks
        // vol.xrayBlocks(strict)
        // erroneousBlocks = vol.xrayBlocks

        // Examime the bitmap
        // vol.xrayBitmap(strict)
        // bitMapErrors = vol.xrayBitmap

        forceRefresh()
    }
    
    @IBAction func clickAction(_ sender: NSTableView!) {
        
        if sender.clickedColumn >= 1 && sender.clickedRow >= 0 {
            
            let newValue = 16 * sender.clickedRow + sender.clickedColumn - 1
            selection = selection != newValue ? newValue : nil
            refresh()
        }
    }
}

@MainActor
extension VolumeCanvasViewController: NSTableViewDataSource {
    
    func columnNr(_ column: NSTableColumn?) -> Int? {
        
        return column == nil ? nil : Int(column!.identifier.rawValue)
    }
        
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return 512 / 16
    }
    
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
                
        switch tableColumn?.identifier.rawValue {

        case "Offset":
            return String(format: "%X", row)
            
        case "Ascii":
            return "?" // vol.ascii(blockNr, offset: 16 * row, length: 16)
            
        default:
            if let col = columnNr(tableColumn) {

                let byte = col // vol.readByte(blockNr, offset: 16 * row + col)
                return String(format: "%02X", byte)
            }
        }
        fatalError()
    }
}

@MainActor
extension VolumeCanvasViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {

        // let exp = UInt8(0)
        let cell = cell as? NSTextFieldCell

        if let col = columnNr(tableColumn) {
            
            // let offset = 16 * row + col
            let error = Int.random(in: 0..<6) // = vol.check(blockNr, pos: offset, expected: &exp, strict: strict)
            
            if row == selectedRow && col == selectedCol {
                cell?.textColor = .white
                cell?.backgroundColor = error == 0 ? .selectedContentBackgroundColor : .systemRed
            } else {
                cell?.textColor = error == 0 ? .textColor : .systemRed
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
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        
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
    
    static let palette: [NSColor] = [
        
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
    
    func layoutImage(size: NSSize) -> NSImage? {
        
        var data = Data(count: Int(size.width))
                
        data.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                proxy?.createUsageMap(baseAddress, length: Int(size.width))
            }
        }
                
        return createImage(data: data, size: size, colorize: { (x: UInt8) -> NSColor in
            
            return VolumeCanvasViewController.palette[Int(x)]
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
