// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class TableCell: NSTableCellView {
    
    /*
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    */
    
    @IBOutlet weak var controller: SidebarViewController!
    var outlineView: MyOutlineView { controller.outlineView }
    var proxy: FuseDeviceProxy? { app.manager.proxy(device: item.device) }
    
    var item: TableItem = TableItem.init(device: 0)
    
    func setup(item: TableItem) {

        self.item = item
        update()
    }

    func update() { }
    func updateIcon(expanded: Bool) { }
}
