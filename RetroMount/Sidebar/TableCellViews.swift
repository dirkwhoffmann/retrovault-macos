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

    @IBOutlet weak var controller: SidebarViewController!

    var outlineView: MyOutlineView { controller.outlineView }

    func updateIcon(expanded: Bool) {

    }
}
