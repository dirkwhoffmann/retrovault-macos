// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import MetalKit
import MetalPerformanceShaders

@MainActor
protocol ShaderDelegate {

    func title(setting: Volume) -> String
    func isHidden(setting: Volume) -> Bool
    func settingDidChange(setting: Volume)
}

extension ShaderDelegate {

    func title(setting: Volume) -> String { setting.title }
    func isHidden(setting: Volume) -> Bool { false }
    func settingDidChange(setting: Volume) { }
}

@MainActor
class DeviceLibrary : Loggable {

    // Enables debug output to the console
    nonisolated static let logging: Bool = true

    // Name of this shader
    // var name: String = ""

    // Shader settings
    var settings: [Device] = []

    // Delegate
    var delegate: ShaderDelegate?

    var tmp = 0

    init() {

        // Remove after testing...
        settings = [

            Device(title: "Defender of the Crown", [

                Volume(
                    title: "OFS",
                    items: [("BILINEAR", 0), ("LANCZOS", 1)],
                    value: nil),
            ]),

            Device(title: "My hard drive",

                   enable: Binding(
                    key: "FILTER_ENABLE",
                    get: { [unowned self] in Float(tmp) },
                    set: { [unowned self] in self.tmp = Int($0) }),

                   [ Volume(
                    title: "Partition 1",
                    items: [("COLOR", 0), ("BLACK_WHITE", 1), ("PAPER_WHITE", 2),
                            ("GREEN", 3), ("AMBER", 4), ("SEPIA", 5)],
                    value: Binding(
                        key: "PALETTE",
                        get: { [unowned self] in Float(tmp) },
                        set: { [unowned self] in self.tmp = Int($0) })),

                     Volume(
                        title: "Partition 2",
                        items: [("BOX", 0), ("TENT", 1), ("GAUSS", 2)],
                        value: Binding(
                            key: "BLUR_FILTER",
                            get: { [unowned self] in Float(tmp) },
                            set: { [unowned self] in self.tmp = Int($0) })),

                     Volume(
                        title: "Partition 3",
                        range: 0.1...20.0,
                        step: 0.1,
                        value: Binding(
                            key: "BLUR_RADIUS_X",
                            get: { [unowned self] in Float(tmp) },
                            set: { [unowned self] in self.tmp = Int($0) })),

                     Volume(
                        title: "Partition 4",
                        range: 0.1...20.0,
                        step: 0.1,
                        value: Binding(
                            key: "BLUR_RADIUS_Y",
                            get: { [unowned self] in Float(tmp) },
                            set: { [unowned self] in self.tmp = Int($0) })),

                     Volume(
                        title: "Partition 5",
                        range: 0.1...1.0,
                        step: 0.01,
                        value: Binding(
                            key: "RESAMPLE_SCALE_X",
                            get: { [unowned self] in Float(tmp) },
                            set: { [unowned self] in self.tmp = Int($0) })),

                     Volume(
                        title: "Partition 6",
                        range: 0.1...1.0,
                        step: 0.01,
                        value: Binding(
                            key: "RESAMPLE_SCALE_Y",
                            get: { [unowned self] in Float(tmp) },
                            set: { [unowned self] in self.tmp = Int($0) }))
                   ])
        ]

    }

    // Returns the names of all available presets
    var presets: [String] { return ["Default"] }

    // Reverts the settings to the selected preset
    func revertToPreset(nr: Int) { }

    // Called once when the user selects this shader
    // func activate() { log("Activating \(name)") }

    // Called once when the user selects another shader
    // func retire() { log("Retiring \(name)") }

    // Runs the shader
    /*
     func apply(commandBuffer: MTLCommandBuffer,
     in input: MTLTexture, out output: MTLTexture, rect: CGRect = .unity) {

     fatalError("To be implemented by a subclass")
     }
     */
}

//
// Utilities
//

extension DeviceLibrary {

    /*
     static func makeTexture(_ name: String = "unnamed", width: Int, height: Int,
     mipmaps: Int = 0, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {

     log("Creating \(name) texture (\(width)x\(height), format: \(pixelFormat.rawValue) mipmaps: \(mipmaps))")

     let desc = MTLTextureDescriptor.texture2DDescriptor(
     pixelFormat: pixelFormat,
     width: width,
     height: height,
     mipmapped: mipmaps > 0
     )
     desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
     if mipmaps > 0 { desc.mipmapLevelCount = mipmaps }

     return ShaderLibrary.device.makeTexture(descriptor: desc)
     }
     */
}

//
// Loading and saving options
//

extension DeviceLibrary {

    // Searches a setting by name
    func findSetting(key: String) -> Volume? {

        for group in settings { if let match = group.findSetting(key: key) { return match } }
        return nil
    }

    var dictionary: [String: [String: String]] {

        get {
            var result: [String: [String: String]] = [:]

            for group in settings {
                result[group.title] = group.dictionary
            }
            return result
        }
        set {

            for (_, keyValues) in newValue {

                for (key, value) in keyValues {

                    guard let setting = findSetting(key: key) else {

                        log("Setting \(key) not found", .warning)
                        continue
                    }
                    guard let value = Float(value) else {

                        log("Failed to parse string \(value)", .warning)
                        continue
                    }
                    if setting.enableKey == key { setting.enabled = value != 0 }
                    if setting.valueKey == key { setting.floatValue = value }
                }
            }
        }
    }

    func saveSettings(url: URL) throws {

        // try Parser.save(url: url, dict: dictionary)
    }
}
