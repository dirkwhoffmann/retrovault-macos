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
    var numBytes = 0
    var numPartitions = 0
    var info = ImageInfo.init()

    var kb: Double { return Double(numBytes) / Double(1024); }
    var mb: Double { return kb / Double(1024); }
    var gb: Double { return mb / Double(1024); }

    var description: String {

        var name = ""

        switch info.format {

        case .ADF, .ADZ, .EADF, .DMS:   name = "Amiga Floppy Disk"
        case .HDF, .HDZ:                name = "Amiga Hard Drive"
        case .IMG:                      name = "DOS Floppy Disk"
        case .ST:                       name = "AtariST Floppy Disk"
        case .D64:                      name = "Commodore 64 Floppy Disk"

        default:
            return ""
        }

        return name + " (" + capacityString + ")"
    }

    var capacityString: String {

        print("(numBytes = \(numBytes))")
        if gb > 1.0 { return String(format: "%.2f GB", gb) }
        if mb > 1.0 { return String(format: "%.2f MB", mb) }
        if kb > 1.0 { return String(format: "%d KB", Int(round(kb))) }
        return "\(numBytes)"
    }

    func icon(wp: Bool = false) -> NSImage? {

        var name = ""

        if (info.type == .HARDDISK) {

            name = "harddrive"

        } else {

            name = "floppy"

            switch info.format {

            case .ADF, .ADZ, .EADF, .DMS, .IMG, .ST:
                name += "_35"
            case .D64:
                name += "_525"
            default:
                return nil
            }
            name += mb > 1.0 ? "_hd" : "_dd"
        }

        if wp { name += "_wp" }

        return NSImage(named: name)
    }
}

class VolumeInfo {

    // Mount point
    var mountPoint = ""

    // Device info
    var deviceInfo = DeviceInfo.init()

    // File system properties
    var blocks = 0
    var bsize = 0

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

    func icon() -> NSImage? {

        var name = "volume"

        switch deviceInfo.info.format {

        case .ADF, .ADZ, .EADF, .DMS:
            name += "_amiga"
        case .IMG:
            name += "_dos"
        case .ST:
            name += "_st"
        case .D64:
            name += "_cbm"
        default:
            return nil
        }

        return NSImage(named: name)
    }
}

class DeviceManager {

    private var devices: [FuseDeviceProxy] = []

    var count: Int { devices.count }

    func info(device: Int) -> DeviceInfo {

        let result = DeviceInfo.init()

        result.name = devices[device].url?.lastPathComponent ?? ""
        result.numBytes = devices[device].numBytes
        result.numPartitions = devices[device].numVolumes
        result.info = devices[device].info

        return result
    }

    func info(device: Int, volume: Int) -> VolumeInfo {

        let result = VolumeInfo.init()

        let stat = devices[device].stat(volume)
        let mp = devices[device].mountPoint(volume)

        // Mount point
        result.mountPoint = mp ?? ""

        // Image info
        result.deviceInfo = info(device: device)

        // File system properties
        result.blocks = stat.blocks
        result.bsize = stat.bsize

        // Usage date
        result.freeBlocks = stat.freeBlocks
        result.freeBytes = stat.freeBlocks * stat.bsize
        result.usedBlocks = stat.usedBlocks
        result.usedBytes = stat.usedBlocks * stat.bsize
        result.fill = Double(stat.freeBlocks) / Double(stat.blocks)

        // Root block metadata
        let bt = Date(timeIntervalSince1970: TimeInterval(stat.btime))
        let mt = Date(timeIntervalSince1970: TimeInterval(stat.mtime))
        result.name = String(cString: c_str(stat.name))
        result.bDate = bt.formatted(date: .numeric, time: .standard)
        result.mDate = mt.formatted(date: .numeric, time: .standard)

        // Access statistics
        result.reads = stat.blockReads
        result.writes = stat.blockWrites

        return result
    }


    func process(message msg: Int) {

        print("Holla, die Waldfee")
    }

    func mount(url: URL) {

        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        do {

            print("Creating device proxy for \(url)...")
            let proxy = try FuseDeviceProxy.make(with: url)

            let traits = proxy.stat(0)

            print("Blocks: \(traits.blocks)")
            print("Bsize: \(traits.bsize)")

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

    func unmount(proxy: FuseDeviceProxy) {

        proxy.unmount()
        devices.removeAll { $0 === proxy }
    }

    func unmountAll() {

        print("Unmounting all...")
        devices.forEach { unmount(proxy: $0) }
        devices.removeAll()
    }
}
