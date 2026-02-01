// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

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
    @IBOutlet weak var numBlocksInfo: NSTextField!
    @IBOutlet weak var usedBlocksInfo: NSTextField!
    @IBOutlet weak var cachedBlocksInfo: NSTextField!

    @IBOutlet weak var blockImageButton: NSButton!
    @IBOutlet weak var blockSlider: NSSlider!
    @IBOutlet weak var bootBlockButton: NSButton!
    @IBOutlet weak var rootBlockButton: NSButton!
    @IBOutlet weak var bmBlockButton: NSButton!
    @IBOutlet weak var bmExtBlockButton: NSButton!
    @IBOutlet weak var fileHeaderBlockButton: NSButton!
    @IBOutlet weak var fileListBlockButton: NSButton!
    @IBOutlet weak var userDirBlockButton: NSButton!
    @IBOutlet weak var dataBlockButton: NSButton!

    @IBOutlet weak var allocImageButton: NSButton!
    @IBOutlet weak var allocSlider: NSSlider!
    @IBOutlet weak var allocInfo: NSTextField!
    @IBOutlet weak var allocGreenButton: NSButton!
    @IBOutlet weak var allocYellowButton: NSButton!
    @IBOutlet weak var allocRedButton: NSButton!
    @IBOutlet weak var allocRectifyInfo: NSTextField!
    @IBOutlet weak var allocRectifyButton: NSButton!

    @IBOutlet weak var diagnoseImageButton: NSButton!
    @IBOutlet weak var diagnoseSlider: NSSlider!
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
    
    var info: VolumeInfo?
    var proxy: FuseDeviceProxy? { return app.manager.proxy(device: device) }
    
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
    
    let palette: [ NSColor] = [
        
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
    
    var oldReads: Int = 0
    var oldWrites: Int = 0

    // Result of the consistency checker
    var erroneousBlocks: [NSNumber] = []
    var bitMapErrors: [NSNumber] = []

    var selection: Int?
    var selectedRow: Int? { return selection == nil ? nil : selection! / 16 }
    var selectedCol: Int? { return selection == nil ? nil : selection! % 16 }
    var strict: Bool { return strictButton.state == .on }

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
    
    
    override func viewDidLoad() {

        let click = NSClickGestureRecognizer(target: self, action: #selector(buttonClicked(_:)))
        blockImageButton.addGestureRecognizer(click)
    }

    @objc func buttonClicked(_ sender: NSClickGestureRecognizer) {

        let point = sender.location(in: sender.view)
        let x = point.x / blockImageButton.bounds.width
    
        print("Clicked \(x)")
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

    override func refresh() {

        guard let device = device else { return }
        guard let volume = volume else { return }
        info = app.manager.info(device: device, volume: volume)
        guard let info = info else { return }

        let r = app.manager.proxy(device: self.device)?.bytesRead(volume) ?? 0
        let w = app.manager.proxy(device: self.device)?.bytesWritten(volume) ?? 0
        let rkb = Int(Double(r) / 1024.0)
        let wkb = Int(Double(w) / 1024.0)
        
        icon.image = info.icon()
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = info.capacityString
        subTitle2.stringValue = ""
        subTitle3.stringValue = ""

        readInfo.stringValue = "\(rkb) KB"
        writeInfo.stringValue = "\(wkb) KB"
        fillInfo.stringValue = info.fillString
        numBlocksInfo.stringValue = "\(info.blocks) Blocks"
        usedBlocksInfo.stringValue = "\(info.usedBlocks) Blocks"
        cachedBlocksInfo.stringValue = "\(info.dirtyBlocks) Blocks"
    }
}
