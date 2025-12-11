// -----------------------------------------------------------------------------
// This file is part of RetroVisor
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

class ShaderTableCellView: NSTableCellView {

    @IBOutlet weak var controller: ShaderPreferencesViewController!

    var shader: DeviceLibrary { controller.devices }
    var outlineView: MyOutlineView { controller.outlineView }

    func updateIcon(expanded: Bool) {

    }
}

class ShaderGroupView: ShaderTableCellView {

    @IBOutlet weak var disclosureButton: NSButton!
    @IBOutlet weak var protected: NSButton!
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var sublabel: NSTextField!

    var group: Device!

    func setup(with group: Device) {

        /*
        func reposition(_ label: NSTextField, over button: NSButton) {

            var frame = label.frame
            frame.origin.x = button.frame.origin.x
            label.frame = frame
        }
        */

        self.group = group
        textField?.stringValue = group.title
        label.stringValue = "The label"
        sublabel.stringValue = "The sublabel"
    }

    override func updateIcon(expanded: Bool) {

        disclosureButton.state = expanded ? .on : .off
        disclosureButton.image = expanded ? .chevronDown() : .chevronRight()
    }

    override func draw(_ dirtyRect: NSRect) {

        // NSColor.controlAccentColor.withAlphaComponent(0.25).setFill()
        NSColor.separatorColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }

    @IBAction func disclosureAction(_ sender: NSButton) {

        if sender.state == .on {
            outlineView.expandItem(group)
        } else {
            outlineView.collapseItem(group)
        }

        outlineView.reloadData()
    }

    @IBAction func enableAction(_ sender: NSButton) {

        /*
        group.enabled = sender.state == .on
        shader.delegate?.settingDidChange(setting: group)
         */
        outlineView.reloadData()
    }
}

class ShaderSettingView: ShaderTableCellView {

    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var sublabel: NSTextField!
    @IBOutlet weak var infoButton: NSButton!

    var shaderSetting: Volume! {

        didSet {

            textField?.stringValue = shaderSetting.title
            label.stringValue = "Label"
            sublabel.stringValue = "Sub label"

            update()
        }
    }

    var value: Float! { didSet { update() } }

    func update() {

    }

    @IBAction func helpAction(_ sender: NSButton) {

        // Not implemented yet
    }
}
