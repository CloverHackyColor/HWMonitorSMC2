//
//  PopoverWindowController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWWindowController: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = getAppearance()
    self.window?.titlebarAppearsTransparent = false
  }
  
  class func loadFromNib() -> HWWindowController {
    let wc = (NSStoryboard(name: "Popover",
                           bundle: nil).instantiateController(withIdentifier:"Popover") as! HWWindowController)
    return wc
  }
  
  func windowWillClose(_ notification: Notification) {
    
  }
}
