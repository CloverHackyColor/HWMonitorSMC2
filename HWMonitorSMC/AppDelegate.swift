//
//  AppDelegate.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var WinMinWidth  : CGFloat = 241
  let WinMinHeight : CGFloat = 270
  let board : String? = getOEMBoard()
  let vendorShort : String? = getOEMVendorShort()
  var superIOChipName : String? = nil
  
  var mainViewSize = MainViewSize.init(rawValue: UDs.string(forKey: kViewSize) ?? MainViewSize.normal.rawValue) ?? MainViewSize.normal
  var hideVerticalScroller : Bool = UserDefaults.standard.bool(forKey: kHideVerticalScroller)
  var theme : Themes? = nil
  var topBarFont : NSFont? = getTopBarFont(saved: true)
  var sensorsInited : Bool = false
  var initialAppearance : NSAppearance = NSAppearance(named: .vibrantDark)!
  var licensed : Bool = false
  var translateUnits : Bool = true
  var useIPG : Bool = false
  var ipg : IntelPG? = nil
  let useIOAcceleratorForGPUs : Bool = UDs.bool(forKey: kUseGPUIOAccelerator)
  var sensorScanner : HWSensorsScanner = HWSensorsScanner()
  var debugGraphics: Bool = true
  
  let fanControlEnabled : Bool = UDs.bool(forKey: kEnableFansControl)
  let showFanMinMaxSpeed : Bool = UDs.bool(forKey: kShowFansMinMaxSensors)
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var statusItemLenBackup : CGFloat = 0
  var statusItemLen : CGFloat = 0
  var hwWC : HWWindowController?

  var cpuFrequencyMax : Double = Double(gCPUBaseFrequency()) // Turbo Boost frequency to be set by the user
  var cpuTDP : Double = 100 // to be set by Intel Power Gadget or by the user
  
  var licenseWC : LicenseWC?
  var gadgetWC : GadgetWC?
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    self.statusItemLenBackup = self.statusItem.length
    let pid = NSRunningApplication.current.processIdentifier
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!) {
      if app.processIdentifier != pid {
        NSApp.terminate(self)
      }
    }
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let forceDark : Bool = UserDefaults.standard.bool(forKey: kDark)
    if !forceDark {
      let appearanceName : String? = UserDefaults.standard.object(forKey: kAppleInterfaceStyle) as? String
      if (appearanceName == nil || ((appearanceName?.range(of: "Dark")) == nil)) {
        self.initialAppearance = NSAppearance(named: .vibrantLight)!
      }
    }
    
    if (UDs.object(forKey: kTranslateUnits) != nil) {
      self.translateUnits = UDs.bool(forKey: kTranslateUnits)
    }
    let icon = NSImage(named: "temperature_small")
    icon?.isTemplate = true
    self.statusItem.button?.image = icon
    self.license()
    
    if (UDs.object(forKey: kUseIPG) != nil) {
      self.useIPG = UDs.bool(forKey: kUseIPG)
    }
    self.hwWC = HWWindowController.loadFromNib()
    /*
    if (UserDefaults.standard.object(forKey: kRunAtLogin) == nil) {
      self.setLaunchAtStartup()
    }*/
  }
  
  func license() {
    if (UDs.object(forKey: kLinceseAccepted) != nil) {
      self.licensed = UDs.bool(forKey: kLinceseAccepted)
    }
    self.licensed = UDs.bool(forKey: kLinceseAccepted)
    if !self.licensed {
      licenseWC = NSStoryboard(name: "License",
                                   bundle: nil).instantiateController(withIdentifier: "License") as? LicenseWC
      licenseWC?.showWindow(self)
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
    NotificationCenter.default.post(name: .terminate, object: nil)
  }
  
  override func awakeFromNib() {
  }
  
}

