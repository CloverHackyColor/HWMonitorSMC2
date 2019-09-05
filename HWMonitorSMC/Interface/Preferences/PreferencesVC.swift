//
//  PreferencesVC.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class TemplateImageView: NSImageView {

}

class GenericImageView: NSImageView {
  
}

class PreferencesVC: NSViewController, NSTextFieldDelegate, NSFontChanging, NSTabViewDelegate {
  //MARK: - Vars
  @IBOutlet var cpuTDPOverrideField       : NSTextField!
  @IBOutlet var cpuFrequencyOverrideField : NSTextField!
  
  @IBOutlet var showCPUSensorsBtn       : NSButton!
  @IBOutlet var showGPUSensorsBtn       : NSButton!
  @IBOutlet var showMoBoSensorsBtn      : NSButton!
  @IBOutlet var showFansSensorsBtn      : NSButton!
  @IBOutlet var showRAMSensorsBtn       : NSButton!
  @IBOutlet var showMediaSensorsBtn     : NSButton!
  @IBOutlet var showBatterySensorsBtn   : NSButton!
  
  @IBOutlet var ramPercentageBtn        : NSButton!
  @IBOutlet var expandCPUTemperatureBtn : NSButton!
  @IBOutlet var expandCPUFrequenciesBtn : NSButton!
  @IBOutlet var expandAllBtn            : NSButton!
  @IBOutlet var dontShowEmptyBtn        : NSButton!
  @IBOutlet var darkBtn                 : NSButton!
  @IBOutlet var hideScrollerBtn         : NSButton!
  @IBOutlet var viewSizePop             : NSPopUpButton!
  @IBOutlet var themesPop               : NSPopUpButton!
  @IBOutlet var translateUnitsBtn       : NSButton!
  @IBOutlet var runAtLoginBtn           : NSButton!
  @IBOutlet var useGPUAccelerator       : NSButton!
  
  @IBOutlet var useIntelPowerGadget     : NSButton!
  
  @IBOutlet var sliderCPU               : NSSlider!
  @IBOutlet var sliderGPU               : NSSlider!
  @IBOutlet var sliderMoBo              : NSSlider!
  @IBOutlet var sliderFans              : NSSlider!
  @IBOutlet var sliderRam               : NSSlider!
  @IBOutlet var sliderMedia             : NSSlider!
  @IBOutlet var sliderBattery           : NSSlider!
  
  @IBOutlet var sliderFieldCPU          : NSTextField!
  @IBOutlet var sliderFieldGPU          : NSTextField!
  @IBOutlet var sliderFieldMoBo         : NSTextField!
  @IBOutlet var sliderFieldFans         : NSTextField!
  @IBOutlet var enableFanControlBtn     : NSButton!
  @IBOutlet var showFanMinMaxBtn        : NSButton!
  
  
  @IBOutlet var sliderFieldRam          : NSTextField!
  @IBOutlet var sliderFieldMedia        : NSTextField!
  @IBOutlet var sliderFieldBattery      : NSTextField!
  
  @IBOutlet var topBarFontBtn           : NSButton!
  
  @IBOutlet var lightGridColorWell      : NSColorWell!
  @IBOutlet var darkGridColorWell       : NSColorWell!
  
  @IBOutlet var lightPlotColorWell      : NSColorWell!
  @IBOutlet var darkPlotColorWell       : NSColorWell!
  
  @IBOutlet var tabView                 : NSTabView!
  var prevTabViewIndex                  : Int = -1
  
  private var appearanceObserver: NSKeyValueObservation?
  @IBOutlet var effectView : NSVisualEffectView!
  
  let fontManager = NSFontManager.shared
  
  var CPU_TDP_MAX : Double = 100 // fake value until Intel Power Gadget runs, or user define it. Just for the plot
  var CPU_Frequency_MAX : Double = Double(gCPUBaseFrequency()) // base frequency until user set the turbo boost value
  
  //MARK: - View Load
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tabView.delegate = self
    for v in (self.view.subviews[0] as! NSVisualEffectView).subviews {
      if v is TemplateImageView {
        (v as! TemplateImageView).image?.isTemplate = true
      }
    }
    
    self.viewSizePop.removeAllItems()
    self.viewSizePop.addItem(withTitle: MainViewSize.normal.rawValue.locale)
    self.viewSizePop.lastItem?.representedObject = MainViewSize.normal.rawValue
    self.viewSizePop.addItem(withTitle: MainViewSize.medium.rawValue.locale)
    self.viewSizePop.lastItem?.representedObject = MainViewSize.medium.rawValue
    self.viewSizePop.addItem(withTitle: MainViewSize.large.rawValue.locale)
    self.viewSizePop.lastItem?.representedObject = MainViewSize.large.rawValue
    
    self.themesPop.removeAllItems()
    self.themesPop.addItem(withTitle: Theme.Default.rawValue.locale)
    self.themesPop.lastItem?.representedObject = Theme.Default.rawValue
    self.themesPop.addItem(withTitle: Theme.Classic.rawValue.locale)
    self.themesPop.lastItem?.representedObject = Theme.Classic.rawValue
    self.themesPop.addItem(withTitle: Theme.DashedH.rawValue.locale)
    self.themesPop.lastItem?.representedObject = Theme.DashedH.rawValue
    self.themesPop.addItem(withTitle: Theme.NoGrid.rawValue.locale)
    self.themesPop.lastItem?.representedObject = Theme.NoGrid.rawValue
    self.themesPop.addItem(withTitle: Theme.GridClear.rawValue.locale)
    self.themesPop.lastItem?.representedObject = Theme.GridClear.rawValue
    
    if #available(OSX 10.11, *) {} else {
      self.fontManager.delegate = self
    }
    
    self.fontManager.target = self
    
    self.updateAppearance()
    if #available(OSX 10.14, *) {
      self.appearanceObserver = self.view.observe(\.effectiveAppearance) { [weak self] _, _  in
        self?.updateAppearance()
      }
    }
    getPreferences()
  }
  
  override func viewDidAppear() {
    super .viewDidAppear()
    self.tabView.drawsBackground = false
    self.tabView.layer?.backgroundColor = NSColor.clear.cgColor
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  //MARK: - Tab animation
  func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
    if (tabViewItem != nil) {
      
      let position = CABasicAnimation(keyPath: "position")

      if prevTabViewIndex > tabView.indexOfTabViewItem(tabViewItem!) {
        position.fromValue = NSValue(point: CGPoint(x: CGFloat(tabViewItem!.view!.frame.origin.x - 520), y: CGFloat(tabViewItem!.view!.frame.origin.y)))
      } else {
        position.fromValue = NSValue(point: CGPoint(x: CGFloat(tabViewItem!.view!.frame.origin.x + 520), y: CGFloat(tabViewItem!.view!.frame.origin.y)))
      }
      position.toValue = NSValue(point: CGPoint(x: CGFloat(tabViewItem!.view!.frame.origin.x), y: CGFloat(tabViewItem!.view!.frame.origin.y)))
      tabViewItem?.view?.layer?.add(position, forKey: "controlViewPosition")
      tabViewItem?.view?.animations = [
        "frameOrigin" : position
      ]
      
      tabViewItem?.view?.animator().frame.origin = CGPoint(x: CGFloat(tabViewItem!.view!.frame.origin.x), y: CGFloat(tabViewItem!.view!.frame.origin.y))
      prevTabViewIndex = tabView.indexOfTabViewItem(tabViewItem!)
    }
  }
  
  //MARK: - Update Appearance
  private func updateAppearance() {
    let appearance = getAppearance()
    self.view.window?.appearance = appearance
    self.view.window?.contentView?.appearance = appearance
    // Everythings below is a Fix for Apple bugs for the appearance
    self.tabView.appearance = NSAppearance(named: .aqua)

    for v in self.tabView.tabViewItems {
      for s in v.view!.subviews {
        /*if #available(OSX 10.14, *) {
          if s is NSImageView && !(s is GenericImageView) {
            let imgView = s as! NSImageView
            imgView.image?.isTemplate = true
            imgView.appearance = appearance
          } else {
            s.appearance = (getAppearance().name == .vibrantDark)
              ?
                NSAppearance(named: .darkAqua)
              :
              NSAppearance(named: .vibrantLight)
          }
        } else {*/
          if appearance.name == .vibrantDark {
             s.appearance = NSAppearance(named: .aqua)
            // set the text color
            if s is NSTextField {
              let field = s as! NSTextField
              field.drawsBackground = false
              if field.isEditable {
                field.textColor = NSColor.darkGray
              } else {
                field.textColor = NSColor.white
              }
            } else if s is NSButton {
              let button = s as! NSButton
              if button.tag != 99 {
                if let coloredTitle = button.attributedTitle.mutableCopy() as? NSMutableAttributedString {
                  coloredTitle.addAttribute(.foregroundColor,
                                            value: NSColor.white,
                                            range: NSRange(location: 0, length: coloredTitle.length))
                  button.attributedTitle = coloredTitle
                }
                button.appearance = NSAppearance(named: .vibrantDark)
              }
            } else if s is NSImageView && !(s is GenericImageView) {
              let imgView = s as! NSImageView
              imgView.image?.isTemplate = true
              imgView.appearance = appearance
            }
          } else {
            if s is NSButton {
              let button = s as! NSButton
              button.appearance = NSAppearance(named: .aqua)
              if button.tag != 99 {
                if let coloredTitle = button.attributedTitle.mutableCopy() as? NSMutableAttributedString {
                  coloredTitle.addAttribute(.foregroundColor,
                                            value: NSColor.darkGray,
                                            range: NSRange(location: 0, length: coloredTitle.length))
                  button.attributedTitle = coloredTitle
                }
              }
            } else if s is NSTextField {
              let field = s as! NSTextField
              field.drawsBackground = false
              field.textColor = .darkGray
            } else {
              s.appearance = NSAppearance(named: .vibrantLight)
            }
            
          }
        //}
      }
    }
  }
  
  deinit {
    if self.appearanceObserver != nil {
      self.appearanceObserver!.invalidate()
      self.appearanceObserver = nil
    }
  }
  
  //MARK: - Field editing
  func controlTextDidEndEditing(_ obj: Notification) {
    if let field : NSTextField = obj.object as? NSTextField {
      if field == self.cpuTDPOverrideField {
        var tdp : Double = Double(field.stringValue) ?? 0
        if tdp < 7 || tdp > 1000 {
          if AppSd.ipgStatus.inited {
            GetTDP(0, &tdp)
          } else {
            tdp = 100
          }
        }
        AppSd.cpuTDP = tdp
        UDs.set(tdp, forKey: kCPU_TDP_MAX)
        field.stringValue = String(format: "%.f", tdp)
      } else if field == self.cpuFrequencyOverrideField {
        var freq : Double = Double(field.stringValue) ?? 0
        if freq <= 0 || freq > 7000 {
          freq = Double(gCPUBaseFrequency())
        }
        AppSd.cpuFrequencyMax = freq
        UDs.set(freq, forKey: kCPU_Frequency_MAX)
        field.stringValue = String(format: "%.f", freq)
      }
      UDs.synchronize()
    }
  }
  
  //MARK: - reset preferences
  @IBAction func reset(_ sender: NSButton?) {
    if let domain = Bundle.main.bundleIdentifier {
      UDs.removePersistentDomain(forName: domain)
      UDs.synchronize()
      self.getPreferences()
    } else {
      NSSound.beep()
    }
  }
  
  //MARK: - Load Preferences
  func getPreferences() {
    self.useIntelPowerGadget.state = UDs.bool(forKey: kUseIPG) ? .on : .off
    
    /*
     The TDP is used only for CPU plots axis and can be greater of the CPU default declared
     by the CPU vendor (i.e. overclock).
     So the user should be able to set an higer value and save it to the preferences.
     If a value is not already let Intel Power Gadget to set the default value,
     otherwise set a "common" value of 100 Watts
     */
    var tdp : Double = UDs.double(forKey: kCPU_TDP_MAX)

    if (tdp < 7 || tdp >= 1000) {
      if AppSd.ipgStatus.inited {
        GetTDP(0, &tdp)
      } else {
        tdp = 100
      }
    }
   
    self.cpuTDPOverrideField.stringValue = String(format: "%.f", tdp)
    AppSd.cpuTDP = tdp
    UDs.set(tdp, forKey: kCPU_TDP_MAX)

    
    let freqMax : Double = UDs.double(forKey: kCPU_Frequency_MAX)
    self.CPU_Frequency_MAX = (freqMax > 0 && freqMax <= 7000) ? freqMax : 5000
    self.cpuFrequencyOverrideField.stringValue = String(format: "%.f", self.CPU_Frequency_MAX)
    UDs.set(freqMax, forKey: kCPU_Frequency_MAX)
    
    
    AppSd.cpuFrequencyMax = freqMax
    
    if (UDs.object(forKey: kShowCPUSensors) == nil) {
      UDs.set(true, forKey: kShowCPUSensors)
    }
    self.showCPUSensorsBtn.state = UDs.bool(forKey: kShowCPUSensors) ? .on : .off
    self.sliderCPU.isEnabled = (self.showCPUSensorsBtn.state == .on)
    
    if (UDs.object(forKey: kShowGPUSensors) == nil) {
      UDs.set(true, forKey: kShowGPUSensors)
    }
    self.showGPUSensorsBtn.state = UDs.bool(forKey: kShowGPUSensors) ? .on : .off
    self.sliderGPU.isEnabled = (self.showGPUSensorsBtn.state == .on)
    
    if (UDs.object(forKey: kShowMoBoSensors) == nil) {
      UDs.set(true, forKey: kShowMoBoSensors)
    }
    self.showMoBoSensorsBtn.state = UDs.bool(forKey: kShowMoBoSensors) ? .on : .off
    self.sliderMoBo.isEnabled = (self.showMoBoSensorsBtn.state == .on)
    
    if (UDs.object(forKey: kShowFansSensors) == nil) {
      UDs.set(true, forKey: kShowFansSensors)
    }
    self.showFansSensorsBtn.state = UDs.bool(forKey: kShowFansSensors) ? .on : .off
    self.sliderFans.isEnabled = (self.showFansSensorsBtn.state == .on)
    
    self.enableFanControlBtn.state = UDs.bool(forKey: kEnableFansControl) ? .on : .off
    self.enableFanControlBtn.isEnabled = (self.showFansSensorsBtn.state == .on)
    
    self.showFanMinMaxBtn.state = UDs.bool(forKey: kShowFansMinMaxSensors) ? .on : .off
    self.showFanMinMaxBtn.isEnabled = (self.showFansSensorsBtn.state == .on)
    
    
    if (UDs.object(forKey: kShowRAMSensors) == nil) {
      UDs.set(true, forKey: kShowRAMSensors)
    }
    self.showRAMSensorsBtn.state = UDs.bool(forKey: kShowRAMSensors) ? .on : .off
    self.sliderRam.isEnabled = (self.showRAMSensorsBtn.state == .on)
    
    if (UDs.object(forKey: kShowMediaSensors) == nil) {
      UDs.set(true, forKey: kShowMediaSensors)
    }
    self.showMediaSensorsBtn.state = UDs.bool(forKey: kShowMediaSensors) ? .on : .off
    self.sliderMedia.isEnabled = (self.showMediaSensorsBtn.state == .on)
    
    if (UDs.object(forKey: kShowBatterySensors) == nil) {
      UDs.set(true, forKey: kShowBatterySensors)
    }
    
    self.showBatterySensorsBtn.state = UDs.bool(forKey: kShowBatterySensors) ? .on : .off
    self.sliderBattery.isEnabled = (self.showBatterySensorsBtn.state == .on)
    
    if (UDs.object(forKey: kTranslateUnits) != nil) {
      self.translateUnitsBtn.state = UDs.bool(forKey: kTranslateUnits) ? .on : .off
    } else {
      self.translateUnitsBtn.state = .on
      UDs.set(true, forKey: kTranslateUnits)
    }
    
    self.runAtLoginBtn.state = UDs.bool(forKey: kRunAtLogin) ? .on : .off
    
    if (UDs.object(forKey: kUseGPUIOAccelerator) != nil) {
      self.useGPUAccelerator.state = UDs.bool(forKey: kUseGPUIOAccelerator) ? .on : .off
    } else {
      self.useGPUAccelerator.state = .on
      UDs.set(true, forKey: kUseGPUIOAccelerator)
    }
    
    self.ramPercentageBtn.state = UDs.bool(forKey: kUseMemoryPercentage) ? .on : .off
    if (UDs.object(forKey: kExpandCPUTemperature) == nil) {
      UDs.set(true, forKey: kExpandCPUTemperature)
    }
    self.expandCPUTemperatureBtn.state = UDs.bool(forKey: kExpandCPUTemperature) ? .on : .off
    
    if (UDs.object(forKey: kExpandCPUFrequencies) == nil) {
      UDs.set(true, forKey: kExpandCPUFrequencies)
    }
    self.expandCPUFrequenciesBtn.state = UDs.bool(forKey: kExpandCPUFrequencies) ? .on : .off
    
    self.expandAllBtn.state = UDs.bool(forKey: kExpandAll) ? .on : .off
    
    if (UDs.object(forKey: kDontShowEmpty) == nil) {
      UDs.set(true, forKey: kDontShowEmpty)
    }
    self.dontShowEmptyBtn.state = UDs.bool(forKey: kDontShowEmpty) ? .on : .off
    
    self.darkBtn.state = UDs.bool(forKey: kDark) ? .on : .off

    self.hideScrollerBtn.state = UDs.bool(forKey: kHideVerticalScroller) ? .on : .off
    
    self.viewSizePop.selectItem(withTitle: (UDs.string(forKey: kViewSize) ?? MainViewSize.normal.rawValue).locale)
    self.themesPop.selectItem(withTitle: (UDs.string(forKey: kTheme) ?? Theme.Default.rawValue).locale)
    
    
    self.synchronize()
    
    var ti : TimeInterval = UDs.double(forKey: kCPUTimeInterval) * 1000
    
    self.sliderCPU.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 1500
    self.sliderCPU.performClick(nil)
    
    ti = UDs.double(forKey: kGPUTimeInterval) * 1000
    self.sliderGPU.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderGPU.performClick(nil)
    
    ti = UDs.double(forKey: kMoBoTimeInterval) * 1000
    self.sliderMoBo.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderMoBo.performClick(nil)
    
    ti = UDs.double(forKey: kFansTimeInterval) * 1000
    self.sliderFans.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderFans.performClick(nil)
    
    ti = UDs.double(forKey: kRAMTimeInterval) * 1000
    self.sliderRam.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderRam.performClick(nil)
    
    ti = UDs.double(forKey: kMediaTimeInterval) * 1000
    self.sliderMedia.doubleValue = (ti >= 100 && ti <= 600000) ? ti : 300000
    self.sliderMedia.performClick(nil)
    
    ti = UDs.double(forKey: kBatteryTimeInterval) * 1000
    self.sliderBattery.doubleValue = (ti >= 100 && ti <= 10000) ? ti : 3000
    self.sliderBattery.performClick(nil)
    
    
    self.lightGridColorWell.color = UDs.lightGridColor()
    self.darkGridColorWell.color = UDs.darkGridColor()
    
    self.lightPlotColorWell.color = UDs.lightPlotColor()
    self.darkPlotColorWell.color = UDs.darkPlotColor()
  }
  
  //MARK: - Actions
  @IBAction func showCPUSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowCPUSensors)
    self.sliderCPU.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func showGPUSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowGPUSensors)
    self.sliderGPU.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func showMoBoSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowMoBoSensors)
    self.sliderMoBo.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func showFansSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowFansSensors)
    self.sliderFans.isEnabled = (sender.state == .on)
    self.enableFanControlBtn.isEnabled = (sender.state == .on)
    self.showFanMinMaxBtn.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func enableFansControl(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kEnableFansControl)
    self.synchronize()
  }
  
  @IBAction func showFansMinMaxSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowFansMinMaxSensors)
    self.synchronize()
  }
  
  @IBAction func showRAMSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowRAMSensors)
    self.sliderRam.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func showMediaSensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowMediaSensors)
    self.sliderMedia.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func showBatterySensors(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kShowBatterySensors)
    self.sliderBattery.isEnabled = (sender.state == .on)
    self.synchronize()
  }
  
  @IBAction func hideScroller(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kHideVerticalScroller)
    AppSd.hideVerticalScroller = sender.state == NSControl.StateValue.on
    self.synchronize()
  }
    
  @IBAction func useMemoryPercentage(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseMemoryPercentage)
    self.synchronize()
  }
  
  @IBAction func useIntelPowerGadget(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseIPG)
    self.synchronize()
  }
  
  @IBAction func viewSizePressed(_ sender: NSPopUpButton) {
    UDs.set(sender.selectedItem?.representedObject as! String, forKey: kViewSize)
    self.synchronize()
    AppSd.mainViewSize = MainViewSize.init(rawValue: UDs.string(forKey: kViewSize) ?? MainViewSize.normal.rawValue) ?? MainViewSize.normal
    self.redrawOutline()
  }
  
  @IBAction func themesPressed(_ sender: NSPopUpButton) {
    UDs.set(sender.selectedItem?.representedObject as! String, forKey: kTheme)
    self.synchronize()
    self.redrawOutline()
  }
  
  @IBAction func sliderCPUMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderCPU.doubleValue / 1000
    self.sliderFieldCPU.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kCPUTimeInterval)
    self.synchronize()
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.CPUNode == nil) { return }
        if (popoverVC.timerCPU != nil) {
          if popoverVC.timerCPU!.isValid { popoverVC.timerCPU!.invalidate() }
        }
        popoverVC.timeCPUInterval = val
        popoverVC.updateCPUSensors()
        popoverVC.timerCPU = Timer.scheduledTimer(timeInterval: popoverVC.timeCPUInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateCPUSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderGPUMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderGPU.doubleValue / 1000
    self.sliderFieldGPU.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kGPUTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.GPUNode == nil) { return }
        if (popoverVC.timerGPU != nil) {
          if popoverVC.timerGPU!.isValid { popoverVC.timerGPU!.invalidate() }
        }
        popoverVC.timeGPUInterval = val
        popoverVC.updateGPUSensors()
        popoverVC.timerGPU = Timer.scheduledTimer(timeInterval: popoverVC.timeGPUInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateGPUSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderMoBoMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderMoBo.doubleValue / 1000
    self.sliderFieldMoBo.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kMoBoTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.MOBONode == nil) { return }
        if (popoverVC.timerMotherboard != nil) {
          if popoverVC.timerMotherboard!.isValid { popoverVC.timerMotherboard!.invalidate() }
        }
        popoverVC.timeMotherBoardInterval = val
        popoverVC.updateMotherboardSensors()
        popoverVC.timerMotherboard = Timer.scheduledTimer(timeInterval: popoverVC.timeMotherBoardInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateMotherboardSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderFansMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderFans.doubleValue / 1000
    self.sliderFieldFans.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kFansTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.FansNode == nil) { return }
        if (popoverVC.timerFans != nil) {
          if popoverVC.timerFans!.isValid { popoverVC.timerFans!.invalidate() }
        }
        popoverVC.timeFansInterval = val
        popoverVC.updateMotherboardSensors()
        popoverVC.timerFans = Timer.scheduledTimer(timeInterval: popoverVC.timeFansInterval,
                                                          target: popoverVC,
                                                          selector: #selector(popoverVC.updateFanSensors),
                                                          userInfo: nil,
                                                          repeats: true)
      }
    }
  }
  
  @IBAction func sliderRAMMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderRam.doubleValue / 1000
    self.sliderFieldRam.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kRAMTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.RAMNode == nil) { return }
        if (popoverVC.timerRAM != nil) {
          if popoverVC.timerRAM!.isValid { popoverVC.timerRAM!.invalidate() }
        }
        popoverVC.timeRAMInterval = val
        popoverVC.updateRAMSensors()
        popoverVC.timerRAM = Timer.scheduledTimer(timeInterval: popoverVC.timeRAMInterval,
                                                   target: popoverVC,
                                                   selector: #selector(popoverVC.updateRAMSensors),
                                                   userInfo: nil,
                                                   repeats: true)
      }
    }
  }
  
  @IBAction func sliderMediaMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderMedia.doubleValue / 1000
    self.sliderFieldMedia.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kMediaTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.mediaNode == nil) { return }
        if (popoverVC.timerMedia != nil) {
          if popoverVC.timerMedia!.isValid { popoverVC.timerMedia!.invalidate() }
        }
        popoverVC.timeMediaInterval = val
        popoverVC.updateMediaSensors()
        popoverVC.timerMedia = Timer.scheduledTimer(timeInterval: popoverVC.timeMediaInterval,
                                                  target: popoverVC,
                                                  selector: #selector(popoverVC.updateMediaSensors),
                                                  userInfo: nil,
                                                  repeats: true)
      }
    }
  }
  
  @IBAction func sliderBatteryMoved(_ sender: NSSlider?) {
    let val : Double = self.sliderBattery.doubleValue / 1000
    self.sliderFieldBattery.stringValue = String(format: "%.2f''", val)
    UDs.set(val, forKey: kBatteryTimeInterval)
    self.synchronize()
    
    if (sender != nil) {
      if let popoverVC = (AppSd.hwWC?.contentViewController as? HWViewController)?.popoverVC {
        if (popoverVC.batteriesNode == nil) { return }
        if (popoverVC.timerBattery != nil) {
          if popoverVC.timerBattery!.isValid { popoverVC.timerBattery!.invalidate() }
        }
        popoverVC.timeBatteryInterval = val
        popoverVC.updateBatterySensors()
        popoverVC.timerBattery = Timer.scheduledTimer(timeInterval: popoverVC.timeBatteryInterval,
                                                    target: popoverVC,
                                                    selector: #selector(popoverVC.updateBatterySensors),
                                                    userInfo: nil,
                                                    repeats: true)
      }
    }
  }
  
  @IBAction func expandCPUTemperature(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUTemperature)
    self.synchronize()
  }
  
  
  @IBAction func expandCPUFrequencies(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandCPUFrequencies)
    self.synchronize()
  }

  @IBAction func useGPUIOAccelerator(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kUseGPUIOAccelerator)
    self.synchronize()
  }
  
  @IBAction func expandAll(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kExpandAll)
    self.synchronize()
  }
  
  @IBAction func dontshowEmpty(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kDontShowEmpty)
    self.synchronize()
  }
  
  @IBAction func startDark(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kDark)
    self.synchronize()
  }
  
  @IBAction func translateUnits(_ sender: NSButton) {
    UDs.set(sender.state == NSControl.StateValue.on, forKey: kTranslateUnits)
    AppSd.translateUnits = sender.state == NSControl.StateValue.on
    self.synchronize()
  }
  
  //MARK: - Set Login item
  @IBAction func setAsLoginItem(_ sender: NSButton) {
    if sender.state == .on {
      AppSd.setLaunchAtStartup()
    } else {
      AppSd.removeLaunchAtStartup()
    }
    self.runAtLoginBtn.state = UDs.bool(forKey: kRunAtLogin) ? .on : .off
  }
  
  //MARK: - Top bar Font
  @IBAction func fontManager(_ sender: NSButton) {
    self.fontManager.action = #selector(self.changeTopBarFont)
    
    let panel = self.fontManager.fontPanel(true)
    panel?.title = "Top Bar Font Manager".locale + " - HWMonitorSMC2"
    panel?.makeKeyAndOrderFront(self)
  }
  
  @IBAction func useDefaultTopBarFont(_ sender : NSButton!) {
    UDs.removeObject(forKey: kTopBarFont)
    UDs.synchronize()
    AppSd.topBarFont = getTopBarFont(saved: false)
  }
  /*
  func changeFont(_ sender: NSFontManager?) {

  }
  */
  
  func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
    return [.size, .collection, .face]
  }
  
  @objc func changeTopBarFont() {
    let font = self.fontManager.convert(AppSd.statusItem.button!.font!)
    AppSd.topBarFont = font
    UDs.saveTopBar(font: font)
  }
  
  //MARK: - Grid color
  @IBAction func setLighGridColor(_ sender: NSColorWell!) {
    UDs.lightGrid(color: sender.color)
    self.themesPressed(self.themesPop)
    self.redrawOutline()
  }
  
  @IBAction func setDefaultLighGridColor(_ sender: NSButton!) {
    UDs.resetLightGridColor()
    self.lightGridColorWell.color = UDs.lightGridColor()
    self.themesPressed(self.themesPop)
    self.redrawOutline()
  }
  
  @IBAction func setDarkGridColor(_ sender: NSColorWell!) {
    UDs.darkGrid(color: sender.color)
    self.themesPressed(self.themesPop)
    self.redrawOutline()
  }
  
  @IBAction func setDefaultDarkGridColor(_ sender: NSButton!) {
    UDs.resetDarkGridColor()
    self.darkGridColorWell.color = UDs.darkGridColor()
    self.themesPressed(self.themesPop)
    self.redrawOutline()
  }
  
  //MARK: - Plot color
  @IBAction func setLighPlotColor(_ sender: NSColorWell!) {
    UDs.lightPlot(color: sender.color)
    self.updatePlotLineColor()
  }
  
  @IBAction func setDefaultLighPlotColor(_ sender: NSButton!) {
    UDs.resetLightPlotColor()
    self.lightPlotColorWell.color = UDs.lightPlotColor()
    self.updatePlotLineColor()
  }
  
  @IBAction func setDarkPlotColor(_ sender: NSColorWell!) {
    UDs.darkPlot(color: sender.color)
    self.updatePlotLineColor()
  }
  
  @IBAction func setDefaultDarkPlotColor(_ sender: NSButton!) {
    UDs.resetDarkPlotColor()
    self.darkPlotColorWell.color = UDs.darkPlotColor()
    self.updatePlotLineColor()
  }
  
  func updatePlotLineColor() {
    NotificationCenter.default.post(name: NSNotification.Name.updatePlotLine, object: nil)
  }
  
  func redrawOutline() {
    NotificationCenter.default.post(name: NSNotification.Name.outlineNeedsDisplay, object: nil)
  }
  
  //MARK: - Standard User Defaults synchronize()
  func synchronize() {
    UDs.synchronize()
  }
}
