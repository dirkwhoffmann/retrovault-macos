// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

final class MySplitView: NSSplitView {

    @IBOutlet weak var svc: MySplitViewController!

    override func viewDidMoveToWindow() {

        registerForDraggedTypes([
            .fileURL
        ])

        print("viewDidMoveToWindow")
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {

        print("draggingEntered")
        return .copy
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {

        print("prepareForDragOperation")
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        print("performDragOperation")
        let pb = sender.draggingPasteboard
        guard let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return false
        }

        urls.forEach { app.manager.mount(url: $0) }
        svc.isCollapsed = false
        svc.sidebarVC?.outlineView.reloadAndSelectLast()

        return true
    }
}
