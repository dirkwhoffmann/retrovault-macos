// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import Cocoa

@MainActor
class VolumeCanvasViewController: CanvasViewController {

    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var mainTitle: NSTextField!
    @IBOutlet weak var subTitle1: NSTextField!
    @IBOutlet weak var subTitle2: NSTextField!
    @IBOutlet weak var subTitle3: NSTextField!
    @IBOutlet weak var cylindersInfo: NSTextField!
    @IBOutlet weak var headsInfo: NSTextField!
    @IBOutlet weak var sectorsInfo: NSTextField!
    @IBOutlet weak var blocksInfo: NSTextField!
    @IBOutlet weak var bsizeInfo: NSTextField!
    @IBOutlet weak var capacityInfo: NSTextField!

    @IBOutlet weak var readPanel: DashboardPanel!
    @IBOutlet weak var writePanel: DashboardPanel!

    var info: VolumeInfo?

    var oldReads: Int = 0
    var oldWrites: Int = 0

    override func viewDidLoad() {

    }

    private var timer: Timer?

    override func viewWillAppear() {

        print("viewWillAppear")
        super.viewWillAppear()
        startPeriodicTask()
    }

    override func viewWillDisappear() {

        print("viewWillDisappear")
        super.viewWillDisappear()
        stopPeriodicTask()
    }

    private func startPeriodicTask() {

        guard timer == nil else { return }

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in

            guard let self else { return }
            guard let volume else { return }


            Task { @MainActor in

                let r = app.manager.proxy(device: self.device)?.bytesRead(volume) ?? 0
                let w = app.manager.proxy(device: self.device)?.bytesWritten(volume) ?? 0

                let dr = r - self.oldReads; self.oldReads = r
                let dw = w - self.oldWrites; self.oldWrites = w

                self.readPanel.model.add(dr > 0 ? 1.0 : 0.0, nil)
            }
        }
    }

    private func stopPeriodicTask() {

        timer?.invalidate()
        timer = nil
    }

    override func refresh() {

        guard let device = device else { return }
        guard let volume = volume else { return }
        info = app.manager.info(device: device, volume: volume)
        guard let info = info else { return }

        icon.image = info.icon()
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = "\(info.blocks) block"
        subTitle2.stringValue = "\(info.fill)% full"
    }
}
