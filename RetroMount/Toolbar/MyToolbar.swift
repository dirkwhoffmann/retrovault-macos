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
    static let github = NSToolbarItem.Identifier("GitHub")
}

@MainActor
class MyToolbar: NSToolbar, NSToolbarDelegate {
    
    var controller: MyWindowController!

    var commit: MyToolbarItemGroup!
    var unmount: MyToolbarItemGroup!
    var protect: MyToolbarItemGroup!
    var github: MyToolbarItemGroup!

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
                 .github,
                 .space,
                 .flexibleSpace ]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [ .flexibleSpace,
                 .toggleSidebar,
                 .sidebarTrackingSeparator,
                 .commit,
                 .unmount,
                 .space,
                 .protect,
                 .flexibleSpace,
                 .github ]
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
            
            commit = MyToolbarItemGroup(identifier: .unmount,
                                      images: [.eject],
                                      actions: [#selector(unmountAction)],
                                      target: self,
                                      label: "Unmount")
            return commit

        case .protect:
            
            protect = MyToolbarItemGroup(identifier: .protect,
                                      images: [.locked],
                                      actions: [#selector(protectAction)],
                                      target: self,
                                      label: "Protect")
            return protect
 
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
    }
    
    func updateToolbar() {
        
        // Take care of the global disable flag
        for item in items { item.isEnabled = !globalDisable }
        
        // Commit button
        // commit.isEnabled = svc.selectedVolume == nil

        // Unmount button

        // Write-protection button
        protect.isHidden = svc.selectedVolume == nil
        if let vol = svc.selectedVolume, let proxy = proxy {
            protect.setImage(Symbol.get(proxy.iswriteProtected(vol) ? .unlocked : .locked), forSegment: 0)
        }
    }
    
    //
    // Action methods
    //
    
    @objc private func commitAction() {

        if let volume = svc.selectedVolume {

            print("TODO: commit \(volume)")
        } else {
            print("TODO: commit all")
        }
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
                        
        if let vol = svc.selectedVolume, let proxy = proxy {
            proxy.writeProtect(!proxy.iswriteProtected(vol), volume: vol)
        }
        
        updateToolbar()
    }
    
    @objc private func gitHubAction() {
        
        print("gitHubAction")
        
        // TODO: Open web browser with URL https://github.com/dirkwhoffmann/vAMIGA
    }
}
