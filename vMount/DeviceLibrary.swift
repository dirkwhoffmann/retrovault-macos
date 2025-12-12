// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

/*
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

    // Shader settings
    var settings: [Device] = []

    // Delegate
    var delegate: ShaderDelegate?

    var tmp = 0

    init() {

        // Remove after testing...
        settings = [

            Device(title: "Defender of the Crown", [

                Volume(title: "OFS"),
            ]),

            Device(title: "My hard drive",

                   [ Volume(
                    title: "Partition 1",
                   ),

                     Volume(
                        title: "Partition 2",
                     ),

                     Volume(
                        title: "Partition 3",
                     ),

                     Volume(
                        title: "Partition 4",
                     ),

                     Volume(
                        title: "Partition 5",
                     ),

                     Volume(
                        title: "Partition 6",
                     )
                   ])
        ]
    }

    // Returns the names of all available presets
    var presets: [String] { return ["Default"] }

    // Reverts the settings to the selected preset
    func revertToPreset(nr: Int) { }
}
*/
