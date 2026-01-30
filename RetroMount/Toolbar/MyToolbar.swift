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
                                      images: [.sync],
                                      actions: [#selector(syncAction)],
                                      target: self,
                                      label: "Sync")
            return sync
            
        case .lock:
            
            lock = MyToolbarItemGroup(identifier: .lock,
                                      images: [.locked],
                                      actions: [#selector(lockAction)],
                                      target: self,
                                      label: "Lock")
            return lock
 
        case .github:
            
            github = MyToolbarItemGroup(identifier: .github,
                                        images: [.github],
                                        actions: [#selector(gitHubAction)],
                                        target: self,
                                        label: "GitHub")
            return github
            
        default:
            return nil
        }
    }
    
    override func validateVisibleItems() {
        
        updateToolbar()
        
            /*
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
    }
    
    func updateToolbar() {
        
        // Take care of the global disable flag
        for item in items { item.isEnabled = !globalDisable }
        
        // Sync button
        sync.isEnabled = controller.vc?.selectedVolume == nil

        // Write-protection button
        lock.isEnabled = controller.vc?.selectedVolume != nil

        
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
    
    @objc private func syncAction() {
        
        print("syncAction")
    }
    
    @objc private func lockAction() {
        
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
    
    @objc private func gitHubAction() {
        
        print("gitHubAction")
    }
}
