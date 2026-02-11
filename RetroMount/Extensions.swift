// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import AppKit

extension Bool {

    init(_ value: Int32) { self = value > 0 }
    var floatValue: Float { self ? 1.0 : 0.0 }
}

extension Int32 {

    init(_ value: Bool) { self = value ? 1 : 0 }
    var boolValue: Bool { self > 0 }
}

extension UInt32 {

    init(rgba: (UInt8, UInt8, UInt8, UInt8)) {

        let r = UInt32(rgba.0)
        let g = UInt32(rgba.1)
        let b = UInt32(rgba.2)
        let a = UInt32(rgba.3)

        self.init(bigEndian: r << 24 | g << 16 | b << 8 | a)
    }

    init(rgba: (UInt8, UInt8, UInt8)) {

        self.init(rgba: (rgba.0, rgba.1, rgba.2, 0xFF))
     }

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8) { self.init(rgba: (r, g, b, a)) }
    init(r: UInt8, g: UInt8, b: UInt8) { self.init(rgba: (r, g, b)) }

    init(color c: NSColor) {

        let r = UInt32(c.redComponent * 255.0)
        let g = UInt32(c.greenComponent * 255.0)
        let b = UInt32(c.blueComponent * 255.0)
        let a = UInt32(c.alphaComponent * 255.0)

        self.init(bigEndian: r << 24 | g << 16 | b << 8 | a)
    }
}

extension Float {

    var boolValue: Bool { self == 0.0 ? true : false }

    func formatted(min: Int, max: Int) -> String {

        var s = String(format: "%.0\(max)f", self)

        // Trim trailing zeros, but leave at least min digits
        if let dotIndex = s.firstIndex(of: ".") {
            var fracEnd = s.index(before: s.endIndex)
            while fracEnd > dotIndex && s[fracEnd] == "0" && s.distance(from: dotIndex, to: fracEnd) > min {
                fracEnd = s.index(before: fracEnd)
            }
            s = String(s[...fracEnd])
        }

        return s
    }
}

extension Collection {
    
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension CGRect {

    static let unity = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)

    static var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
}

extension NSSize {

    static let unity = NSSize(width: 1.0, height: 1.0)
    
    func scaled(x: Float = 1.0, y: Float = 1.0) -> NSSize {
        return NSSize(width: self.width * CGFloat(x), height: self.height * CGFloat(y))
    }
}

extension NSFont {

    static func monospaced(ofSize fontSize: CGFloat, weight: Weight) -> NSFont {

        if #available(macOS 10.15, *) {
            return NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight)
        } else {
            return NSFont.systemFont(ofSize: fontSize)
        }
    }
}

extension NSColor {

    convenience init(r: Int, g: Int, b: Int, a: Int = 255) {

        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
}

extension NSScreen {

    static var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
}

extension NSWindow {

    static var cornerRadius: CGFloat {

        if #available(macOS 26, *) {
            return 24 // 16
        } else {
            return 12
        }
    }

    func removeAccessory<T: NSTitlebarAccessoryViewController>(ofType type: T.Type) {

        if let index = titlebarAccessoryViewControllers.firstIndex(where: { $0 is T }) {
            removeTitlebarAccessoryViewController(at: index)
        }
    }
}

extension CGImage {

    static func defaultBitmapInfo() -> CGBitmapInfo {

        let alpha = CGImageAlphaInfo.premultipliedLast.rawValue
        let bigEn32 = CGBitmapInfo.byteOrder32Big.rawValue

        return CGBitmapInfo(rawValue: alpha | bigEn32)
    }

    static func dataProvider(data: UnsafeMutableRawPointer, size: CGSize) -> CGDataProvider? {

        let dealloc: CGDataProviderReleaseDataCallback = {

            (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> Void in

            // Core Foundation objects are memory managed, aren't they?
            return
        }

        return CGDataProvider(dataInfo: nil,
                              data: data,
                              size: 4 * Int(size.width) * Int(size.height),
                              releaseData: dealloc)
    }

    // Creates a CGImage from a raw data stream
    static func make(data: UnsafeMutableRawPointer, size: CGSize, bitmapInfo: CGBitmapInfo? = nil) -> CGImage? {


        let w = Int(size.width)
        let h = Int(size.height)

        return CGImage(width: w, height: h,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: 4 * w,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: bitmapInfo ?? defaultBitmapInfo(),
                       provider: dataProvider(data: data, size: size)!,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: CGColorRenderingIntent.defaultIntent)
    }

    static func make(texture: MTLTexture, region: MTLRegion, bitmapInfo: CGBitmapInfo? = nil) -> CGImage? {

        let w = region.size.width
        let h = region.size.height

        // Get texture data as a byte stream
        guard let data = malloc(4 * w * h) else { return nil; }
        texture.getBytes(data,
                         bytesPerRow: 4 * region.size.width,
                         from: region, // MTLRegionMake2D(x, y, w, h),
                         mipmapLevel: 0)

        return make(data: data, size: CGSize(width: w, height: h), bitmapInfo: bitmapInfo)
    }

    // Creates a CGImage from a MTLTexture
    static func make(texture: MTLTexture, rect: CGRect, bitmapInfo: CGBitmapInfo? = nil) -> CGImage? {

        // Compute texture cutout
        let x = Int(CGFloat(texture.width) * rect.minX)
        let y = Int(CGFloat(texture.height) * rect.minY)
        let w = Int(CGFloat(texture.width) * rect.width)
        let h = Int(CGFloat(texture.height) * rect.height)

        return make(texture: texture, region: MTLRegionMake2D(x, y, w, h), bitmapInfo: bitmapInfo)
    }
}

extension NSImage {

    static func sfSymbol(name: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSImage? {

        let config = NSImage.SymbolConfiguration(pointSize: size, weight: weight)

        return NSImage(systemSymbolName: name,
                       accessibilityDescription: name)?.withSymbolConfiguration(config)
    }

    static func chevronDown(size: CGFloat = 14, weight: NSFont.Weight = .regular) -> NSImage? {

        return sfSymbol(name: "chevron.down", size: size, weight: weight)
    }

    static func chevronRight(size: CGFloat = 14, weight: NSFont.Weight = .regular) -> NSImage? {

        return sfSymbol(name: "chevron.right", size: size, weight: weight)
    }
    
    convenience init(color: NSColor, size: NSSize) {

        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        unlockFocus()
    }

    static func make(texture: MTLTexture, rect: CGRect = .unity, bitmapInfo: CGBitmapInfo? = nil) -> NSImage? {

        guard let cgImage = CGImage.make(texture: texture, rect: rect, bitmapInfo: bitmapInfo) else {
            warn("Failed to create CGImage.")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }

    static func make(texture: MTLTexture, region: MTLRegion, bitmapInfo: CGBitmapInfo? = nil) -> NSImage? {

        guard let cgImage = CGImage.make(texture: texture, region: region, bitmapInfo: bitmapInfo) else {
            warn("Failed to create CGImage.")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }

    static func make(data: UnsafeMutableRawPointer, rect: CGSize, bitmapInfo: CGBitmapInfo? = nil) -> NSImage? {

        guard let cgImage = CGImage.make(data: data, size: rect, bitmapInfo: bitmapInfo) else {
            warn("Failed to create CGImage")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    func resizeImage(width: CGFloat, height: CGFloat,
                     cutout: NSRect,
                     interpolation: NSImageInterpolation = .high) -> NSImage {

        let img = NSImage(size: CGSize(width: width, height: height))

        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = interpolation
        self.draw(in: cutout,
                  from: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                  operation: .sourceOver,
                  fraction: 1)
        img.unlockFocus()

        return img
    }

    func padImage(dx: CGFloat, dy: CGFloat,
                  interpolation: NSImageInterpolation = .high) -> NSImage {

        let cw = self.size.width
        let ch = self.size.height
        let nw = cw + 2 * dx
        let nh = ch + 2 * dy

        let img = NSImage(size: CGSize(width: nw, height: nh))

        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = interpolation
        self.draw(in: NSRect(x: dx, y: dy, width: cw, height: ch),
                  from: NSRect(x: 0, y: 0, width: cw, height: ch),
                  operation: .sourceOver,
                  fraction: 1)
        img.unlockFocus()

        return img
    }

    func resize(width: CGFloat, height: CGFloat) -> NSImage {

        let cutout = NSRect(x: 0, y: 0, width: width, height: height)
        return resizeImage(width: width, height: height,
                           cutout: cutout)
    }

    func resize(size: CGSize) -> NSImage {

        return resize(width: size.width, height: size.height)
    }
    
    func resizeSharp(width: CGFloat, height: CGFloat) -> NSImage {

        let cutout = NSRect(x: 0, y: 0, width: width, height: height)
        return resizeImage(width: width, height: height,
                           cutout: cutout,
                           interpolation: .none)
    }
}

extension Dictionary where Key == String {

    var prettify: String {

        func format(_ dict: [String: Any], level: Int) -> String {

            let maxKeyLength = dict.keys.map { $0.count }.max() ?? 0

            return dict.keys.sorted().map { key in

                let value = dict[key]!
                let paddedKey = key.padding(toLength: maxKeyLength, withPad: " ", startingAt: 0)
                let prefix = String(repeating: "  ", count: level)

                if let subDict = value as? [String: Any] {
                    return "\(prefix)\(paddedKey) :\n\(format(subDict, level: level + 1))"
                } else {
                    return "\(prefix)\(paddedKey) : \(value)"
                }
            }.joined(separator: "\n")
        }

        return format(self, level: 0)
    }
}
