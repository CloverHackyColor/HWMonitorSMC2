//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by Micky1979 on 26/07/17.
//  Copyright © 2017 Micky1979. All rights reserved.
//
// https://gist.github.com/Micky1979/4743842c4ec7cb95ea5cbbdd36beedf7
//

import Cocoa

class HWViewController: NSViewController, NSPopoverDelegate {
  var popover           : NSPopover?
  var popoverVC         : PopoverViewController?
  var popoverWC         : PopoverWindowController?
  var detachableWindow  : HWWindow?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.popoverVC =
      self.storyboard?.instantiateController(withIdentifier:"PopoverViewController") as? PopoverViewController
    
    var height : CGFloat = (self.popoverVC?.view.bounds.origin.y)!
    var width  : CGFloat = (self.popoverVC?.view.bounds.origin.x)!

    if (UserDefaults.standard.object(forKey: kPopoverHeight) != nil) {
      height = CGFloat(UserDefaults.standard.float(forKey: kPopoverHeight))
    }
    
    if (UserDefaults.standard.object(forKey: kPopoverWidth) != nil) {
      width = CGFloat(UserDefaults.standard.float(forKey: kPopoverWidth))
    }
    if width < AppSd.WinMinWidth {
      width = AppSd.WinMinWidth
    }
    
    if height < AppSd.WinMinHeight {
      height = AppSd.WinMinHeight
    }
    self.popoverVC?.view.setFrameSize(NSMakeSize(CGFloat(width), CGFloat(height)))
    
    let rect : NSRect = (self.popoverVC?.view.bounds)!

    self.detachableWindow = HWWindow(contentRect: rect,
                                     styleMask: [],
                                     backing: .buffered,
                                     defer: true)
    //---------------------
    self.popoverWC = PopoverWindowController()
    self.detachableWindow?.windowController = self.popoverWC
    self.detachableWindow?.delegate = self.popoverWC
    self.popoverWC?.window = self.detachableWindow
    self.popoverWC?.setUp()
    //---------------------
    
    self.detachableWindow?.contentViewController = self.popoverVC
    self.detachableWindow?.isReleasedWhenClosed = false
    self.detachableWindow?.titlebarAppearsTransparent = true
    self.detachableWindow?.minSize = NSMakeSize(CGFloat(AppSd.WinMinWidth), CGFloat(AppSd.WinMinHeight))
    
    self.detachableWindow?.appearance = getAppearance()
    self.detachableWindow?.backgroundColor = NSColor.clear
    if let button = AppSd.statusItem.button {
      button.target = self
      button.action = #selector(self.showPopover(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.terminate),
                                           name: .terminate,
                                           object: nil)
  }
  
  override var representedObject: Any? {
    didSet { }
  }
  
  func createPopover() {
    if (self.popover == nil) {
      self.popover = NSPopover()
      self.popover?.animates = true
      self.popover?.contentViewController = self.popoverVC
      self.popover?.behavior = .transient
      self.popover?.delegate = self
      self.popover?.appearance = getAppearance()
    }
  }
  
  @objc func showPopover(_ sender: NSStatusBarButton?) {
    if !AppSd.licensed {
      NSSound.beep()
      return
    }
    
    if  (self.detachableWindow != nil && self.detachableWindow!.isVisible) {
      if (self.detachableWindow?.styleMask.contains(.fullScreen))! {
        self.detachableWindow?.toggleFullScreen(self)
        return
      }
    }
  
    self.popoverVC?.attachButton.isEnabled = false
    self.popoverVC?.attachButton.isHidden = true
    if self.popoverVC!.sleeping {
      self.popoverVC!.wakeListener()
    }
    self.createPopover()

    self.popover?.show(relativeTo: (sender?.bounds)!, of: sender!, preferredEdge: NSRectEdge.maxY)
    NSApp.activate(ignoringOtherApps: true)
    sender?.window?.makeKey()
    self.popoverVC?.outline.update()
  }
  
  func popoverWillShow(_ notification: Notification) {
    if (self.detachableWindow?.isVisible)! {
      self.detachableWindow?.orderOut(self)
    }
  }
  
  func popoverDidShow(_ notification: Notification) {
    
  }
    
  func popoverDidClose(_ notification: Notification) {
    if (notification.userInfo![NSPopover.closeReasonUserInfoKey] != nil) {
      self.popover = nil
    }
  }
  
  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    return (self.popoverVC!.lock.state == NSControl.StateValue.off)
  }
  
  func detachableWindow(for popover: NSPopover) -> NSWindow? {
    self.popoverVC?.attachButton.isEnabled = true
    self.popoverVC?.attachButton.isHidden = false
    return self.detachableWindow
  }
  
  func popoverDidDetach(_ popover: NSPopover) {
    self.popoverVC?.outline.update()
    if self.detachableWindow?.screen != NSScreen.main {
      self.detachableWindow?.setFrameOrigin(NSScreen.main!.visibleFrame.origin)
    }
  }
  
  @objc func terminate() {
    // exit the full screen to save the correct size of the window
    if  (self.detachableWindow != nil) {
      if (self.detachableWindow?.styleMask.contains(.fullScreen))! {
        self.detachableWindow?.toggleFullScreen(self)
      }
    }
  }

}

