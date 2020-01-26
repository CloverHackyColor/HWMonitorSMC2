//
//  HWScrollView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 05/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWScrollView: NSScrollView {
  private var trackingArea : NSTrackingArea?
  
  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if (self.trackingArea != nil) {
      self.removeTrackingArea(self.trackingArea!)
    }
    self.trackingArea = NSTrackingArea(rect: self.bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self, userInfo: nil)
    
    self.addTrackingArea(self.trackingArea!)
  }
  
  override func mouseExited(with event: NSEvent) {
    self.autohidesScrollers = false
    self.hasVerticalScroller = false
  }
  
  override func mouseEntered(with event: NSEvent) {
    if AppSd.hideVerticalScroller {
      self.autohidesScrollers = false
      self.hasVerticalScroller = false
    } else {
      self.autohidesScrollers = true
      self.hasVerticalScroller = true
    }
  }

}
