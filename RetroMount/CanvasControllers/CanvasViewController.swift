// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class CanvasViewController: NSViewController {

    // Displayed device and volume
    var device: Int?
    var volume: Int?

    var deviceProxy: FuseDeviceProxy? {
        
        return app.manager.proxy(device: device)
    }
    
    var volumeProxy: FuseVolumeProxy? {
        
        guard let volume = volume else { return nil }
        return deviceProxy?.volume(volume)
    }

    func activate(device: Int?, volume: Int?) {
        
        self.device = device
        self.volume = volume
        activate()
    }
    
    func activate() {

    }
    
    func refresh() { }
}
