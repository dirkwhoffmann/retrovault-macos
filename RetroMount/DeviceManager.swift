// -----------------------------------------------------------------------------
// This file is part of vMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class DeviceInfo {

    var name = ""
    var numPartitions = 0
}

class VolumeInfo {

    // Mount point
    var mountPoint = ""

    // Usage information
    var freeBlocks = 0
    var freeBytes = 0
    var usedBlocks = 0
    var usedBytes = 0
    var fill = 0.0

    // Root block metadata
    var name = ""
    var bDate = ""
    var mDate = ""

    // Access statistics
    var reads = 0
    var writes = 0
}

class DeviceManager {

    private var devices: [AmigaDeviceProxy] = []

    var count: Int { devices.count }

    func info(device: Int) -> DeviceInfo {

        let result = DeviceInfo.init()

        result.name = devices[device].url?.lastPathComponent ?? ""
        result.numPartitions = devices[device].numVolumes

        return result
    }

    func info(device: Int, volume: Int) -> VolumeInfo {

        let result = VolumeInfo.init()

        let stat = devices[device].stat(volume)
        let mp = devices[device].mountPoint(volume)
        
        // let stat = devices[device].info(volume)

        // Mount point
        result.mountPoint = mp ?? ""

        // Usage date
        result.freeBlocks = stat.freeBlocks
        result.freeBytes = stat.freeBlocks * stat.bsize
        result.usedBlocks = stat.usedBlocks
        result.usedBytes = stat.usedBlocks * stat.bsize
        result.fill = Double(stat.freeBlocks) / Double(stat.blocks)

        // Root block metadata
        let bt = Date(timeIntervalSince1970: TimeInterval(stat.btime))
        let mt = Date(timeIntervalSince1970: TimeInterval(stat.mtime))
        result.name  = String(cString: c_str(stat.name))
        result.bDate = bt.formatted(date: .numeric, time: .standard)
        result.mDate = mt.formatted(date: .numeric, time: .standard)

        // Access statistics
        result.reads = stat.blockReads
        result.writes = stat.blockWrites

        return result
    }

    func traits(device: Int, volume: Int = 0) -> FSTraits {

        return devices[device].traits(volume)
    }
    
    func process(message msg: Int) {

        print("Holla, die Waldfee")
    }

    func mount(url: URL) {

        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        do {

            print("Creating device proxy for \(url)...")
            let proxy = try AmigaDeviceProxy.make(with: url)


            let traits = proxy.traits(0)

            print("DOS: \(traits.dos)")
            print("Blocks: \(traits.blocks)")
            print("Bytes: \(traits.bytes)")
            print("Bsize: \(traits.bsize)")
            print("Reserved: \(traits.reserved)")

            let mountPoint = URL(fileURLWithPath: "/Volumes")
                .appendingPathComponent(url.deletingPathExtension().lastPathComponent)

            print("Mounting file system at \(mountPoint)...")
            try proxy.mount(at: mountPoint, myself) { (ptr, msg: Int32) in

                // Convert void pointer back to 'self'
                let myself = Unmanaged<DeviceManager>.fromOpaque(ptr!).takeUnretainedValue()

                // Process message in the main thread
                Task { @MainActor in myself.process(message: Int(msg)) }
            }

            print("Success.")
            devices.append(proxy)

        } catch { print("Error launching DeviceManager: \(error)") }
    }

    func unmount(proxy: AmigaDeviceProxy) {

        proxy.unmount()
        devices.removeAll { $0 === proxy }
    }

    func unmountAll() {

        print("Unmounting all...")
        devices.forEach { unmount(proxy: $0) }
        devices.removeAll()
    }
}
