// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class InfoCanvasViewController: CanvasViewController {

    @IBOutlet var splashImage: NSImageView!

    override func viewDidLoad() {

        splashImage.unregisterDraggedTypes()
        refresh()
    }

    override func refresh() {

    }
    
    @IBAction private func gitHubAction(_ sender: Any) {
        
        if let url = URL(string: "https://github.com/dirkwhoffmann/vAMIGA") {
            NSWorkspace.shared.open(url)
        }
    }
}
