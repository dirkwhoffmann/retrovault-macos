// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

extension NSToolbarItem.Identifier {
    
    static let save = NSToolbarItem.Identifier("Save")
    static let eject = NSToolbarItem.Identifier("Eject")
    static let folder = NSToolbarItem.Identifier("Folder")
    static let protect = NSToolbarItem.Identifier("Protect")
}

@MainActor
class MyToolbar: NSToolbar, NSToolbarDelegate {
    
    var controller: MyWindowController!

    var save: MyToolbarItemGroup!
    var eject: MyToolbarItemGroup!
    var folder: MyToolbarItemGroup!
    var protect: MyToolbarItemGroup!

    // Set to true to gray out all toolbar items
    var globalDisable = false
    
    var svc: MySplitViewController { controller.vc! }
    var proxy: FuseDeviceProxy? { app.manager.proxy(device: svc.selectedDevice) }

    /*
    init() {
        
        super.init(identifier: "MyToolbar")
        self.delegate = self
        self.allowsUserCustomization = false
        self.displayMode = .iconOnly
    }
    */
    
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
                 .save,
                 .folder,
                 .eject,
                 .protect,
                 .space,
                 .flexibleSpace ]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        return [ .flexibleSpace,
                 .toggleSidebar,
                 .sidebarTrackingSeparator,
                 .space,
                 .folder,
                 .eject,
                 .save,
                 .flexibleSpace,
                 .protect]
    }
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
                
        switch id {
                        
        case .save:
            
            save = MyToolbarItemGroup(identifier: .save,
                                      images: [.sync],
                                      actions: [#selector(saveAction)],
                                      target: self,
                                      label: "Save")
            return save

        case .eject:
            
            eject = MyToolbarItemGroup(identifier: .eject,
                                         images: [.eject],
                                         actions: [#selector(ejectAction)],
                                         target: self,
                                         label: "Eject")
            return eject

        case .folder:
            
            folder = MyToolbarItemGroup(identifier: .folder,
                                        images: [.folder],
                                        actions: [#selector(finderAction)],
                                        target: self,
                                        label: "Finder")
            return folder
            
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
           
        let dev = svc.selectedDevice
        let vol = svc.selectedVolume
        
        if dev == nil && vol == nil {
            
            eject.isHidden = true
            save.isHidden = true
            folder.isHidden = true
            protect.isHidden = true
            return
        }
        
        eject.isHidden = false
        eject.isEnabled = !globalDisable
        eject.toolTip = "Unmount the device"
        
        folder.isHidden = !app.hasFuse
        folder.isEnabled = !globalDisable
        folder.toolTip = "Open in Finder"

        save.isHidden = proxy?.needsSaving == false
        save.isEnabled = !globalDisable
        save.toolTip = "Write changes back to the image file"

        protect.isHidden = vol == nil
        if vol != nil {
            
            let wenable = proxy?.volume(vol!).iswriteProtected == false
            protect.setImage(Symbol.get(wenable ? .unlocked : .locked), forSegment: 0)
            protect.isEnabled = !globalDisable
        }
    }
    
    
    //
    // Action methods
    //
    
    @objc private func saveAction() {

        if let vol = svc.selectedVolume {
            try? proxy?.save(volume: vol)
        } else {
            try? proxy?.save()
        }
        svc.refresh()
    }

    @objc private func ejectAction() {

        guard let device = svc.selectedDevice else { return }

        if proxy?.needsSaving == true {
            
            let item = svc.selectedVolume != nil ? "Volume" : "Device"
            
            let alert = NSAlert()
            
            alert.messageText = "Unmount \(item)?"
            alert.informativeText = "All changes that you made will be lost."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Unmount")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() != .alertFirstButtonReturn { return }
        }
        
        svc.sidebarVC?.unmount(item: TableItem(device: device, volume: svc.selectedVolume))
    }

    @objc private func finderAction() {

        if let proxy = proxy?.volume(svc.selectedVolume ?? 0) {
            
            if let url = proxy.mountPoint {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc private func protectAction() {

        if let vol = svc.selectedVolume, let proxy = proxy?.volume(vol) {
            proxy.writeProtect(!proxy.iswriteProtected)
        }
        updateToolbar()
    }
}
