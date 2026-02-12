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
    @IBOutlet var fuseIcon: NSImageView!
    @IBOutlet var fuseInfoText: NSTextField!

    override func viewDidLoad() {

        if app.hasFuse {
            
            fuseInfoText.stringValue = "macFUSE enabled"
            fuseInfoText.textColor = .secondaryLabelColor
            fuseIcon.image = NSImage(named: "LEDgreen")
            
        } else {

            fuseInfoText.stringValue = "macFUSE is not installed. Mounted volumes won't appear in Finder."
            fuseIcon.image = NSImage(named: "LEDred")
            fuseInfoText.textColor = .labelColor
        }
        
        splashImage.unregisterDraggedTypes()
        refresh()
    }

    override func refresh() {

    }
    
    @IBAction private func gitHubAction(_ sender: Any) {
        
        if let url = URL(string: "https://github.com/dirkwhoffmann/retrovault-macos") {
            NSWorkspace.shared.open(url)
        }
    }
}
