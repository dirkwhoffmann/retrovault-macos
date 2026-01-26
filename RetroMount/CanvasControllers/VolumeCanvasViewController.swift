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
    @IBOutlet weak var readInfo: NSTextField!
    @IBOutlet weak var writeInfo: NSTextField!
    @IBOutlet weak var fillInfo: NSTextField!

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
            withTimeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in

            guard let self else { return }
            Task { @MainActor in self.refresh() }
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

        let r = app.manager.proxy(device: self.device)?.bytesRead(volume) ?? 0
        let w = app.manager.proxy(device: self.device)?.bytesWritten(volume) ?? 0
        let rkb = Int(Double(r) / 1024.0)
        let wkb = Int(Double(w) / 1024.0)

        icon.image = info.icon()
        mainTitle.stringValue = info.mountPoint
        subTitle1.stringValue = info.capacityString
        subTitle2.stringValue = ""
        subTitle3.stringValue = ""

        readInfo.stringValue = "\(rkb) KB"
        writeInfo.stringValue = "\(wkb) KB"
        fillInfo.stringValue = info.fillString
    }
}
