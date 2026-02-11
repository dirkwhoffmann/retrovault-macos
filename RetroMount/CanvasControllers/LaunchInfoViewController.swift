// -----------------------------------------------------------------------------
// This file is part of RetroVault
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class LaunchInfoViewController: NSViewController {

    @IBOutlet var textField: NSTextField!
    @IBOutlet var exitButton: NSButton!

    override func viewDidLoad() {

        super.viewDidLoad()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let url = URL(string: "https://osxfuse.github.io/")!
        let attr = NSAttributedString(
            string: textField.stringValue,
            attributes: [ .link: url,
                          .paragraphStyle: paragraph ]
        )
        textField.attributedStringValue = attr
        // view.window?.defaultButtonCell = exitButton.cell as? NSButtonCell
    }
    
    @IBAction func exit(_ sender: Any? = nil) {

        NSApplication.shared.terminate(sender)
    }

    @IBAction func openMacFUSEWebsite(_ sender: Any? = nil) {

        guard let url = URL(string: "https://macfuse.github.io/") else { return }
        NSWorkspace.shared.open(url)
    }
}
