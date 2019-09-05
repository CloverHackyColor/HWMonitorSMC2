//
//  License.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 15/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class LicenseWC: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = getAppearance()
  }
}

class LicenseVC: NSViewController {
  @IBAction func acceptPressed(_ sender: NSButton) {
    UDs.set(true, forKey: kLinceseAccepted)
    AppSd.licensed = true
    self.view.window?.close()
  }
  
  @IBAction func refusePressed(_ sender: NSButton) {
    NSApp.terminate(sender)
  }
}
