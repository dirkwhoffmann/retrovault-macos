// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MyWindowController: NSWindowController {

    var vc: MySplitViewController? { contentViewController as? MySplitViewController }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {
        
        // Create toolbar
        window!.toolbarStyle = .unified
        window!.toolbar = MyToolbar(controller: self)
        
        // Show window
        window!.center()
        showWindow(self)
    }
}
