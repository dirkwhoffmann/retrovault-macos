// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

@MainActor
class MyOutlineView: NSOutlineView {

    @IBOutlet var sidebarViewController:  MySidebarViewController!

    var current: NSViewController? {
        sidebarViewController.splitViewController?.current
    }

    override func keyDown(with event: NSEvent) {

        current?.keyDown(with: event)
    }

    override func flagsChanged(with event: NSEvent) {

        current?.flagsChanged(with: event)
    }
}
