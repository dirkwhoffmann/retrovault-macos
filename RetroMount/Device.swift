// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class DeviceInfo {

    // Name
    var name = ""

    // Capacity information
    var numBlocks = 0
    var bsize = 0

    // Layout
    var numCyls = 0
    var numHeads = 0
    var minSectors = 0
    var maxSectors = 0
    var numSectors: [Int] = []
    
    // Volumes
    var numPartitions = 0

    // Image
    var info = ImageInfo.init()

    var numTracks: Int { return numCyls * numHeads }
    var numBytes: Int { return numBlocks * bsize }
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

        return name // + " (" + capacityString + ")"
    }

    var capacityString: String {

        if gb > 1.0 { return String(format: "%.2f GB", gb) }
        if mb > 1.0 { return String(format: "%.2f MB", mb) }
        if kb > 1.0 { return String(format: "%d KB", Int(round(kb))) }
        return "\(numBytes) Bytes"
    }

    var pictogram: NSImage? {
        
        if (info.type == .HARDDISK) {

            return nil

        } else {

            switch info.format {

            case .ADF, .ADZ, .EADF, .DMS, .IMG, .ST:
                return NSImage(named: "floppy_35")
            case .D64:
                return NSImage(named: "floppy_525")
            default:
                return nil
            }
        }
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


class Device {
    
    var proxy: FuseDeviceProxy
        
    init(proxy: FuseDeviceProxy) {

        self.proxy = proxy
    }
    
    convenience init(url: URL) throws {
        
        try self.init(proxy: FuseDeviceProxy.make(with: url))
    }

    var info: DeviceInfo {

        let result = DeviceInfo.init()

        result.name = proxy.url?.lastPathComponent ?? ""

        result.numBlocks = proxy.numBlocks
        result.bsize = proxy.bsize

        result.numCyls = proxy.numCyls
        result.numHeads = proxy.numHeads
        result.minSectors = proxy.numSectors(0)
        result.maxSectors = proxy.numSectors(proxy.numTracks - 1)
        result.numPartitions = proxy.numVolumes
        result.info = proxy.info

        for i in 0..<result.numTracks {
            result.numSectors.append(proxy.numSectors(i))
        }
        
        return result
    }
}
