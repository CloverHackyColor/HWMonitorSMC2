//
//  PreferencesWC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class PreferencesWC: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.backgroundColor = NSColor.clear
    self.window?.appearance = getAppearance()
  }
  
  class func loadFromNib() -> PreferencesWC {
    let wc = NSStoryboard(name: "Preferences",
                           bundle: nil).instantiateController(withIdentifier: "Preferences") as! PreferencesWC
    return wc
  }
  
  func windowWillClose(_ notification: Notification) {
    
  }
}
