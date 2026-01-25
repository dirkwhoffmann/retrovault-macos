// -----------------------------------------------------------------------------
// This file is part of RetroMount
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

    func activate() {

    }

    func set(device: Int?, volume: Int?) {

        self.device = device
        self.volume = volume
        refresh()
    }

    /*
    func setDevice(_ device: Int?) { self.device = device }
    func setVolume(_ volume: Int?) { self.volume = volume }
    */

    func refresh() { }
}
