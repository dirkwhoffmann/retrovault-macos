// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

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
    var cachedBlocks = 0
    var dirtyBlocks = 0
    var fill = 0.0

    // Root block metadata
    var name = ""
    var bDate = ""
    var mDate = ""

    // Access statistics
    var reads = 0
    var writes = 0
    var generation = 0
    
    var bytes: Int { return blocks * bsize; }
    var kb: Double { return Double(bytes) / Double(1024); }
    var mb: Double { return kb / Double(1024); }
    var gb: Double { return mb / Double(1024); }

    var capacityString: String {

        var result = "\(blocks) Block" + (blocks != 1 ? "s " : " ")

        if gb > 1.0 { result += String(format: "(%.2f GB)", gb) }
        else if mb > 1.0 { result += String(format: "(%.2f MB)", mb) }
        else if kb > 1.0 { result += String(format: "(%d KB)", Int(round(kb))) }
        else { result += "(\(bytes) Bytes)" }

        return result
    }

    var fillString: String {

        (fill * 100).formatted(.number.precision(.fractionLength(0))) + "%"
    }

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

        let img = NSImage(named: name)
        img?.isTemplate = false
        
        return img
    }
}

class DeviceManager {
    
    private var devices: [FuseDeviceProxy] = []
    
    var count: Int { devices.count }
    
    func proxy(device: Int?) -> FuseDeviceProxy? {
        
        guard let device = device else { return nil }
        return devices[device]
    }
    
    func info(device: Int) -> DeviceInfo {
        
        let result = DeviceInfo.init()
        let dev = devices[device]
        
        result.name = dev.url?.lastPathComponent ?? ""
        
        result.numBlocks = dev.numBlocks
        result.bsize = dev.bsize
        
        result.numCyls = dev.numCyls
        result.numHeads = dev.numHeads
        result.minSectors = dev.numSectors(0)
        result.maxSectors = dev.numSectors(dev.numTracks - 1)
        result.numPartitions = dev.numVolumes
        result.info = dev.info
        
        for i in 0..<result.numTracks {
            result.numSectors.append(dev.numSectors(i))
        }
        
        return result
    }
    
    func info(device: Int, volume: Int) -> VolumeInfo {
        
        let result = VolumeInfo.init()
        
        guard let proxy = proxy(device: device) else { return result }
        
        let stat = proxy.stat(volume)
        let mp = proxy.mountPoint(volume)
        
        // Mount point
        result.mountPoint = mp?.relativePath ?? ""
        
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
        result.cachedBlocks = stat.cachedBlocks
        result.dirtyBlocks = stat.dirtyBlocks
        result.fill = Double(stat.usedBlocks) / Double(stat.blocks)
        
        // Root block metadata
        let bt = Date(timeIntervalSince1970: TimeInterval(stat.btime))
        let mt = Date(timeIntervalSince1970: TimeInterval(stat.mtime))
        result.name = String(cString: c_str(stat.name))
        result.bDate = bt.formatted(date: .numeric, time: .standard)
        result.mDate = mt.formatted(date: .numeric, time: .standard)
        
        // Access statistics
        result.reads = proxy.bytesRead(volume)
        result.writes = proxy.bytesWritten(volume)
        result.generation = stat.generation
        
        return result
    }
    
    func process(message msg: Int) {
        
        // print("Holla, die Waldfee")
    }
    
    func mount(url: URL) {
        
        let myself = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        do {
            
            let proxy = try FuseDeviceProxy.make(with: url)            
            let traits = proxy.stat(0)
            
            print("Blocks: \(traits.blocks)")
            print("Bsize: \(traits.bsize)")
            
            if app.hasFuse {
                
                let mountPoint = URL(fileURLWithPath: "/Volumes")
                    .appendingPathComponent(url.deletingPathExtension().lastPathComponent)
                
                print("Mounting file system at \(mountPoint)...")
                try proxy.mount(at: mountPoint, myself) { (ptr, msg: Int32) in
                    
                    // Convert void pointer back to 'self'
                    let myself = Unmanaged<DeviceManager>.fromOpaque(ptr!).takeUnretainedValue()
                    
                    // Process message in the main thread
                    Task { @MainActor in myself.process(message: Int(msg)) }
                }
            }
            
            print("Success.")
            devices.append(proxy)
            
        } catch { print("Error launching DeviceManager: \(error)") }
    }
    
    func unmount(item: TableItem) {
        
        if let volume = item.volume {
            unmount(device: item.device, volume: volume)
        } else {
            unmount(device: item.device)
        }
    }
    
    func unmount(device: Int, volume: Int) {
        
        guard devices.indices.contains(device) else { return }
        
        print("Unmounting device \(device) volume: \(volume)")
        if app.hasFuse {
            devices[device].unmount(volume)
        }
        
        if devices[device].numVolumes == 0 {
            devices.remove(at: device)
        }
    }
    
    func unmount(device: Int) {
        
        print("Unmounting device \(device)")
        let numVolumes = devices[device].numVolumes
        for i in 0 ..< numVolumes { unmount(device: device, volume: i) }
    }
    
    func unmountAll() {
        
        print("Unmounting all devices...")
        let numDevices = devices.count
        for i in 0 ..< numDevices { unmount(device: i) }
    }
}
