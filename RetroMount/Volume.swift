// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import MetalKit
import MetalPerformanceShaders

@MainActor
struct Binding {

    let key: String
    let get: () -> Float
    let set: (Float) -> Void

    init(key: String, get: @escaping () -> Float, set: @escaping (Float) -> Void) {

        self.key = key
        self.get = get
        self.set = set
    }
}

@MainActor
class Volume {

    // Volume name
    var title: String

    // Write protection status
    var protected: Bool = false

    // Mount point
    var mounter: DeviceManager?

    // Optional help string
    let help: String?

    init(title: String = "", help: String? = nil) {

        self.title = title
        self.help = help
    }
}

@MainActor
class Device : Volume {

    // The cell view associated with this group
    var view: TableCell?
    
    // The settings in this group
    var children: [Volume]

    init(title: String = "", help: String? = nil, _ children: [Volume]) {

        self.children = children
        super.init(title: title, help: help)
    }

    /*
    func findSetting(key: String) -> Volume? {

        // Check this setting's bindings
        if enableKey == key || valueKey == key { return self }

        // Recurse into children
        for child in children {
            if child.enableKey == key || child.valueKey == key { return child }
        }

        return nil
    }
     */
    /*
    var dictionary: [String: String] {

        var result: [String: String] = [:]

        if enableKey != "" { result[enableKey] = (enabled ?? true) ? "1" : "0" }
        if valueKey != "" { result[valueKey] = String(floatValue ?? 0) }

        for child in children {
            if child.enableKey != "" { result[child.enableKey] = (child.enabled ?? true) ? "1" : "0" }
            if child.valueKey != "" { result[child.valueKey] = String(child.floatValue ?? 0) }
        }
        return result
    }
     */
}
