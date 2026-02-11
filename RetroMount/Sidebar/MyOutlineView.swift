// -----------------------------------------------------------------------------
// This file is part of RetroVault
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
    
    @MainActor
    func reloadAndSelectLast() {

        reloadData()

        // Defer until the outline view has rebuilt its rows
        DispatchQueue.main.async {

            let lastRow = self.numberOfRows - 1
            guard lastRow >= 0 else { return }

            /*
            if let item = self.item(atRow: lastRow) {
                self.expandItem(item)
            }
            */
            
            self.selectRowIndexes(IndexSet(integer: lastRow), byExtendingSelection: false)
            self.scrollRowToVisible(lastRow)
        }
    }
}
