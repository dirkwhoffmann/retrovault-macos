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

    @IBOutlet var sidebarViewController: SidebarViewController!

    var manager: DeviceManager { app.manager }

    /*
    var svc: MySplitViewController? { sidebarViewController.splitViewController }
    var current: NSViewController? { svc?.current }

    override func keyDown(with event: NSEvent) {

        current?.keyDown(with: event)
    }

    override func flagsChanged(with event: NSEvent) {

        current?.flagsChanged(with: event)
    }
     */
    
    func reloadAndSelectLast() {

        reloadData()

        let lastRow = numberOfRows - 1
        if lastRow >= 0 {

            selectRowIndexes(IndexSet(integer: lastRow), byExtendingSelection: false)
            scrollRowToVisible(lastRow)
        }
    }
}
