// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension NSToolbarItem.Identifier {
    
    static let commit = NSToolbarItem.Identifier("Commit")
    static let unmount = NSToolbarItem.Identifier("Unmount")
    static let protect = NSToolbarItem.Identifier("Protect")
}

@MainActor
class MyToolbar: NSToolbar, NSToolbarDelegate {
    
    var controller: MyWindowController!

    var commit: MyToolbarItemGroup!
    var unmount: MyToolbarItemGroup!
    var protect: MyToolbarItemGroup!

    // Set to true to gray out all toolbar items
    var globalDisable = false
    
    var svc: MySplitViewController { controller.vc! }
    var proxy: FuseDeviceProxy? { app.manager.proxy(device: svc.selectedDevice) }

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
                 .commit,
                 .unmount,
                 .protect,
                 .space,
                 .flexibleSpace ]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [ .flexibleSpace,
                 .toggleSidebar,
                 .sidebarTrackingSeparator,
                 .flexibleSpace,
                 .commit,
                 // .space,
                 .unmount,
                 .space,
                 .protect,
                 .flexibleSpace ]
    }
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
                
        switch id {
                        
        case .commit:
            
            commit = MyToolbarItemGroup(identifier: .commit,
                                      images: [.sync],
                                      actions: [#selector(commitAction)],
                                      target: self,
                                      label: "Commit")
            return commit

        case .unmount:
            
            unmount = MyToolbarItemGroup(identifier: .unmount,
                                         images: [.eject],
                                         actions: [#selector(unmountAction)],
                                         target: self,
                                         label: "Unmount")
            return unmount

        case .protect:
            
            protect = MyToolbarItemGroup(identifier: .protect,
                                      images: [.locked],
                                      actions: [#selector(protectAction)],
                                      target: self,
                                      label: "Protect")
            return protect
             
        default:
            return nil
        }
    }
    
    override func validateVisibleItems() {
        
        updateToolbar()
    }
    
    func updateToolbar() {
        
        // Take care of the global disable flag
        for item in items { item.isEnabled = !globalDisable }
        
        // Commit button
        // commit.isEnabled = svc.selectedVolume == nil

        // Unmount button

        commit.isHidden = svc.selectedDevice == nil
        unmount.isHidden = svc.selectedDevice == nil
        protect.isHidden = svc.selectedDevice == nil || svc.selectedVolume == nil
        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            protect.setImage(Symbol.get(proxy.iswriteProtected ? .unlocked : .locked), forSegment: 0)
        }
    }
    
    //
    // Action methods
    //
    
    @objc private func commitAction() {

        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            print("commit \(vol)")
            try? proxy.commit()
        } else {
            print("commit all")
            try? proxy?.commit()
        }
        svc.refresh()
    }

    @objc private func unmountAction() {
        
        if let volume = svc.selectedVolume {

            print("TODO: unmount \(volume)")
        } else {
            print("TODO: unmount all")
        }
        
    }

    @objc private func protectAction() {
        
        print("protectAction")
                        
        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            proxy.writeProtect(!proxy.iswriteProtected)
        }
        
        updateToolbar()
    }
}
