// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class MySplitViewController: NSSplitViewController {

    let main = NSStoryboard(name: "Main", bundle: nil)

    private lazy var generalVC: GeneralPreferencesViewController = {
        return main.instantiateController(withIdentifier: "GeneralPreferencesViewController") as! GeneralPreferencesViewController
    }()

    var current: SettingsViewController?

    private var sidebarVC: MySidebarViewController? {
        return splitViewItems.first?.viewController as? MySidebarViewController
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        sidebarVC?.selectionHandler = { [weak self] item in
            self?.showContent(for: item)
        }
    }

    private func showContent(for item: SidebarItem) {

        showContent(title: item.title)
    }

    func showContent(title: String) {

        switch title {
        case "General": current = generalVC
        default:
            current = generalVC // fatalError()
        }

        // Remove the old content pane
        removeSplitViewItem(splitViewItems[1])

        // Create a new split view item for the new content
        let newItem = NSSplitViewItem(viewController: current!)
        addSplitViewItem(newItem)
    }
}
