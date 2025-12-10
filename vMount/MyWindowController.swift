// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MyWindowController: NSWindowController {

    var splitViewController: MySplitViewController? {
        self.contentViewController as? MySplitViewController
    }
    var currentVC: MyViewController? { splitViewController?.current }
    var isVisible: Bool { window?.isVisible ?? false }

    required init?(coder: NSCoder) {

        super.init(coder: coder)
    }

    override func windowDidLoad() {

        super.windowDidLoad()
    }

    func show() {

        self.showWindow(nil)
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refresh() {

        currentVC?.refresh()
    }
}
