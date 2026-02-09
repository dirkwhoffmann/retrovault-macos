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
                 .space,
                 .unmount,
                 .space,
                 .push,
                 .flexibleSpace,
                 .protect]
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
                
        if let dev = svc.selectedDevice, let vol = svc.selectedVolume {
            
            updateToolbar(device: dev, volume: vol)
            return
        }

        if let dev = svc.selectedDevice {
            
            updateToolbar(device: dev)
            return
        }

        unmount.isHidden = true
        push.isHidden = true
        protect.isHidden = true
    }
    
    func updateToolbar(device dev: Int) {
        
        unmount.isHidden = false
        unmount.isEnabled = !globalDisable
        unmount.toolTip = "Unmount the device"

        push.isHidden = !app.manager.needsSaving(device: dev)
        push.isEnabled = !globalDisable
        push.toolTip = "Write changes back to the image file"

        protect.isHidden = true
        protect.isEnabled = !globalDisable
    }

    func updateToolbar(device dev: Int, volume vol: Int) {
        
        let wenable = proxy?.volume(vol).iswriteProtected == false

        unmount.isHidden = false
        unmount.isEnabled = !globalDisable
        unmount.toolTip = "Unmount the device"

        push.isHidden = !app.manager.needsSaving(device: dev, volume: vol)
        push.isEnabled = !globalDisable
        push.toolTip = "Write changes back to the image file"

        protect.isHidden = false
        protect.setImage(Symbol.get(wenable ? .unlocked : .locked), forSegment: 0)
        protect.isEnabled = !globalDisable
    }

    //
    // Action methods
    //
    
    @objc private func pushAction() {

        if let vol = svc.selectedVolume {
            try? proxy?.save(volume: vol)
        } else {
            try? proxy?.save()
        }
        svc.refresh()
    }

    @objc private func unmountAction() {
        
        guard let device = svc.selectedDevice else { return }
        svc.sidebarVC?.unmount(item: TableItem(device: device, volume: svc.selectedVolume))
    }

    @objc private func protectAction() {

        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            proxy.writeProtect(!proxy.iswriteProtected)
        }
        updateToolbar()
    }
}
