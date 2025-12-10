// -----------------------------------------------------------------------------
// This file is part of vAmiga
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

class MyViewController: NSViewController {

    @IBOutlet weak var presetPopup: NSPopUpButton!
    @IBOutlet weak var lockImage: NSButton!
    @IBOutlet weak var lockInfo1: NSTextField!
    @IBOutlet weak var lockInfo2: NSTextField!

    func refresh() {

    }

    override func keyDown(with event: NSEvent) { }
    override func flagsChanged(with event: NSEvent) { }
}

class CanvasView: NSView {

    private var bgLayer: CALayer?

    override func viewDidMoveToSuperview() {

        super.viewDidMoveToSuperview()
        wantsLayer = true

        /*
        if let layer = self.layer, bgLayer == nil {

            let background = CALayer()
            background.contents = NSImage(named: "vAmigaBg")
            background.contentsGravity = .resizeAspectFill
            background.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.insertSublayer(background, at: 0)
            bgLayer = background
        }
        */
    }

    override func layout() {

        super.layout()
        bgLayer?.frame = CGRect(x: 0, y: 0,
                                width: bounds.width,
                                height: bounds.height - 32)
    }
}
