// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MySplitViewController: NSSplitViewController {

    func instantiate(_ identifier: String) -> Any {

        let main = NSStoryboard(name: "Main", bundle: nil)
        return main.instantiateController(withIdentifier: identifier)
    }

    var windowController: MyWindowController? {
        view.window?.windowController as? MyWindowController
    }

    private var sidebarVC: SidebarViewController? {
        return splitViewItems.first?.viewController as? SidebarViewController
    }

    lazy var generalVC = instantiate("Canvas") as! MyViewController

    var current: MyViewController?

    override func viewDidLoad() {

        super.viewDidLoad()
        sidebarVC?.selectionHandler = { [weak self] item in
            self?.showContent(for: item)
        }
        splitView.delegate = self
    }

    override func splitView(_ splitView: NSSplitView,
                            canCollapseSubview subview: NSView) -> Bool {
        return false
    }

    override func splitView(_ splitView: NSSplitView,
                            constrainSplitPosition proposedPosition: CGFloat,
                            ofSubviewAt dividerIndex: Int) -> CGFloat {

        return splitView.subviews[dividerIndex].frame.size.width
    }

    func showContent(for item: SidebarItem) {

        showContent(title: item.title)
    }

    func showContent(title: String) {

        current = generalVC

        // Remove the old content pane
        removeSplitViewItem(splitViewItems[1])

        // Create a new split view item for the new content
        let newItem = NSSplitViewItem(viewController: current!)
        addSplitViewItem(newItem)
        // current!.activate()
    }

    override func keyDown(with event: NSEvent) {

        current?.keyDown(with: event)
    }

    override func flagsChanged(with event: NSEvent) {

        current?.flagsChanged(with: event)
    }
}
