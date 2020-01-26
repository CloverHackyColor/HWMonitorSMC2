//
//  GadgetWC.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 30/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class GadgetWC: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = getAppearance()
    self.window?.isMovable = true
    self.window?.isMovableByWindowBackground = true
    self.window?.level = .statusBar
    self.window?.collectionBehavior = .canJoinAllSpaces
    self.window?.contentMaxSize = NSSize(width: 5000, height: 400)
    self.window?.backgroundColor = NSColor.clear
  }
  
  class func loadFromNib() -> GadgetWC {
    let wc = NSStoryboard(name: "Gadget",
                           bundle: nil).instantiateController(withIdentifier: "Gadget") as! GadgetWC

    return wc
  }
}
