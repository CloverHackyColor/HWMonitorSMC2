//
//  PopoverWindowController.swift
//  HWMonitorSMC
//
//  Created by Micky1979 on 26/07/17.
//  Copyright © 2017 Micky1979. All rights reserved.
//
// https://gist.github.com/Micky1979/4743842c4ec7cb95ea5cbbdd36beedf7
//

import Cocoa

class PopoverWindowController: NSWindowController, NSWindowDelegate {
  
  override func windowDidLoad() {
    super.windowDidLoad()
  }
  
  func setUp() {
    self.window?.appearance = getAppearance()
    self.window?.hasShadow = true
    self.window?.isMovableByWindowBackground = true
    
    self.window?.collectionBehavior = [.fullScreenAuxiliary, .fullScreenPrimary]
    self.window?.styleMask.insert([.titled,
                                   .closable,
                                   .resizable,
                                   .fullSizeContentView /*, .miniaturizable */])
    
    self.window?.titleVisibility = .hidden // the pin button works again with this
    self.window?.titlebarAppearsTransparent = false
  }
  
  func windowDidResize(_ notification: Notification) {
    if let win : HWWindow = notification.object as? HWWindow {
      let frame  = win.contentView?.bounds
      var width : CGFloat = (frame?.width)!
      var height : CGFloat = (frame?.height)!
      
      if width < kMinWidth {
        width = kMinWidth
      }
      
      if height < kMinHeight {
        height = kMinHeight
      }
      
      UDs.set(frame?.width, forKey: kPopoverWidth)
      UDs.set(frame?.height, forKey: kPopoverHeight)
      UDs.synchronize()
    }
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    
  }
  
  func windowWillEnterFullScreen(_ notification: Notification) {
  }
  
  func windowWillClose(_ notification: Notification) {
    
  }
}
