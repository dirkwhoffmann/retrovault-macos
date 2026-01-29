// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension NSToolbarItem.Identifier {
    
    static let sync = NSToolbarItem.Identifier("Sync")
    static let lock = NSToolbarItem.Identifier("Lock")
    static let github = NSToolbarItem.Identifier("GitHub")
}

@MainActor
class MyToolbar: NSToolbar, NSToolbarDelegate {
    
    var controller: MyWindowController!

    var sync: MyToolbarItemGroup!
    var lock: MyToolbarItemGroup!
    var github: MyToolbarItemGroup!

    // Set to true to gray out all toolbar items
    var globalDisable = false
    
    init() {
        
        super.init(identifier: "MyToolbar")
        self.delegate = self
        self.allowsUserCustomization = true
        self.displayMode = .iconOnly
    }
    
    override init(identifier: NSToolbar.Identifier) {
        
        super.init(identifier: identifier)
        self.delegate = self
        self.allowsUserCustomization = false
        self.displayMode = .iconOnly
    }
    
    convenience init(controller: MyWindowController) {
        
        self.init(identifier: "MyToolbar")
        self.controller = controller
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [ .toggleSidebar,
                 .sidebarTrackingSeparator,
                 .sync,
                 .lock,
                 .github,
                 .space,
                 .flexibleSpace ]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [ .flexibleSpace,
                 .toggleSidebar,
                 .sidebarTrackingSeparator,
                 .flexibleSpace,
                 .sync,
                 .lock,
                 .space,
                 .github ]
    }
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
                
        switch id {
                        
        case .sync:
            
            sync = MyToolbarItemGroup(identifier: .sync,
                                      images: [.gear],
                                      actions: [#selector(settingsAction)],
                                      target: self,
                                      label: "Sync")
            return sync
            
        case .lock:
            
            lock = MyToolbarItemGroup(identifier: .lock,
                                      images: [.keyboard],
                                      actions: [#selector(keyboardAction)],
                                      target: self,
                                      label: "Lock")
            return lock
 
        case .github:
            
            lock = MyToolbarItemGroup(identifier: .github,
                                      images: [.keyboard],
                                      actions: [#selector(keyboardAction)],
                                      target: self,
                                      label: "GitHub")
            return lock
            
        default:
            return nil
        }
    }
    
    override func validateVisibleItems() {
        
        // Take care of the global disable flag
        for item in items { item.isEnabled = !globalDisable }
        
        /*
        // Disable the keyboard button if the virtual keyboard is open
        if  controller.virtualKeyboard?.window?.isVisible == true {
            (keyboard.view as? NSButton)?.isEnabled = false
        }
        
        // Disable the snapshot revert button if no snapshots have been taken
        snapshots.setEnabled(controller.snapshotCount > 0, forSegment: 1)
        
        // Update input devices
        controller.gamePadManager.refresh(menu: port1.menu)
        controller.gamePadManager.refresh(menu: port2.menu)
        port1.selectItem(withTag: controller.config.gameDevice1)
        port2.selectItem(withTag: controller.config.gameDevice2)
        */
        /*
        port1.menuFormRepresentation = nil
        port2.menuFormRepresentation = nil
        */
        sync.menuFormRepresentation = nil
        lock.menuFormRepresentation = nil
    }
    
    func updateToolbar() {
        
        /*
        if emu.poweredOn {
            
            controls.setEnabled(true, forSegment: 0) // Pause
            controls.setEnabled(true, forSegment: 1) // Reset
            controls.setToolTip("Power off", forSegment: 2) // Power
            
        } else {
            
            controls.setEnabled(false, forSegment: 0) // Pause
            controls.setEnabled(false, forSegment: 1) // Reset
            controls.setToolTip("Power on", forSegment: 2) // Power
        }
        
        if emu.running {
            
            controls.setToolTip("Pause", forSegment: 0)
            controls.setImage(SFSymbol.get(.pause), forSegment: 0)
            
        } else {
            
            controls.setToolTip("Run", forSegment: 0)
            controls.setImage(SFSymbol.get(.play), forSegment: 0)
        }
        */
    }
    
    //
    // Action methods
    //
    
    @objc private func inspectorAction() {
        
        print("inspectorAction")
        // controller.inspectorAction(self)
    }
    
    @objc private func dashboardAction() {
        
        print("inspectorAction")
        // controller.dashboardAction(self)
    }
    
    @objc private func consoleAction() {
        
        print("consoleAction")
        // controller.consoleAction(self)
    }
    
    @objc private func takeSnapshotAction() {
        
        print("takeSnapshotAction")
        // controller.takeSnapshotAction(self)
    }
    
    @objc private func restoreSnapshotAction() {
        
        print("restoreSnapshotAction")
        // controller.restoreSnapshotAction(self)
    }
    
    @objc private func browseSnapshotAction() {
        
        print("browseSnapshotAction")
        // controller.browseSnapshotsAction(self)
    }
    
    @objc private func port1Action(_ sender: NSMenuItem) {
        
        print("port1Action")
        //controller.config.gameDevice1 = sender.tag
    }
    
    @objc private func port2Action(_ sender: NSMenuItem) {
        
        print("port2Action")
        //controller.config.gameDevice2 = sender.tag
    }
    
    @objc private func keyboardAction() {
        
        print("keyboardAction")
        /*
        if controller.virtualKeyboard == nil {
            controller.virtualKeyboard = VirtualKeyboardController.make(parent: controller)
        }
        if controller.virtualKeyboard?.window?.isVisible == false {
            controller.virtualKeyboard?.showAsSheet()
        }
        */
    }
    
    @objc private func settingsAction() {
        
        print("keyboardAction")
        // controller.settingsAction(self)
    }
    
    @objc private func runAction() {
        
        print("keyboardAction")
        // controller.stopAndGoAction(self)
    }
    
    @objc private func resetAction() {
        
        print("keyboardAction")
        // controller.resetAction(self)
    }
    
    @objc private func powerAction() {
        
        print("keyboardAction")
        // controller.powerAction(self)
    }
}
