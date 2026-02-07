// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension NSToolbarItem.Identifier {
    
    static let push = NSToolbarItem.Identifier("Push")
    static let unmount = NSToolbarItem.Identifier("Unmount")
    static let protect = NSToolbarItem.Identifier("Protect")
}

@MainActor
class MyToolbar: NSToolbar, NSToolbarDelegate {
    
    var controller: MyWindowController!

    var push: MyToolbarItemGroup!
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
                 .push,
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
                 .push,
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
                        
        case .push:
            
            push = MyToolbarItemGroup(identifier: .push,
                                      images: [.sync],
                                      actions: [#selector(pushAction)],
                                      target: self,
                                      label: "Push")
            return push

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
        
        // Push button
        // push.isEnabled = svc.selectedVolume == nil

        // Unmount button

        push.isHidden = svc.selectedDevice == nil
        unmount.isHidden = svc.selectedDevice == nil
        protect.isHidden = svc.selectedDevice == nil || svc.selectedVolume == nil
        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            protect.setImage(Symbol.get(proxy.iswriteProtected ? .unlocked : .locked), forSegment: 0)
        }
    }
    
    //
    // Action methods
    //
    
    @objc private func pushAction() {

        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            print("push \(vol)")
            try? proxy.push()
        } else {
            print("push all")
            try? proxy?.push()
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
