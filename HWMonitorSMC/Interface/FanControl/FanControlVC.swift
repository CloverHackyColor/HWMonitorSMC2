//
//  FanControlVC.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 09/05/2019.
//  Copyright © 2019 vector sigma. All rights reserved.
//

import Cocoa

let nvram_cmd = "/usr/sbin/nvram"

class FanControlVC: NSViewController, NSTextFieldDelegate {
  @IBOutlet var unitField : NSTextField!
  @IBOutlet var rpmField  : NSTextField!
  @IBOutlet var slider    : NSSlider!
  
  @IBOutlet var pwmBtn    : NSButton!
  @IBOutlet var saveBtn   : NSButton!
  var key : String = ""
  var rpm : Int32 = 0
  
  var FSkey : UInt16 = 0
  var FSkeyNew : UInt8 = 0
  var fanForceNew : Bool = false
  
  var fanIndex : Int = -1
  
  let maxRpm : Int32 = 7000 // fake value just to stay in range
  
  /*
   NVRAM Fan control, 44 bytes in total
   First 2 bytes to store 16 bits for 16 fans enabled or disabled,
   then 16 pair of bytes, to store target fan value in rpm.
   From index 16, other 16 pair of bytes, to store min fan value in rpm.
   From index 30, other 16 pair of bytes, to store max fan value in rpm.
   
   NVRAM is persistent.. and it is a good way to remember user settings for all the users.
   */
  var nvFanControls : [UInt8] = [
    0x00, 0x00, /* 16 bits, bit at index x enable fan at index 0 if set */
    0x00, 0x00, /* UInt16 value, fan at index 0 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 1 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 2 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 3 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 4 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 5 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 6 target speed */
    0x00, 0x00, /* UInt16 value, fan at index 0 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 1 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 2 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 3 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 4 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 5 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 6 min speed    */
    0x00, 0x00, /* UInt16 value, fan at index 0 max speed    */
    0x00, 0x00, /* UInt16 value, fan at index 1 max speed    */
    0x00, 0x00, /* UInt16 value, fan at index 2 max speed    */
    0x00, 0x00, /* UInt16 value, fan at index 3 max speed    */
    0x00, 0x00, /* UInt16 value, fan at index 4 max speed    */
    0x00, 0x00, /* UInt16 value, fan at index 5 max speed    */
    0x00, 0x00  /* UInt16 value, fan at index 6 max speed    */
  ]
  
  class func loadFromNib(key : String, index: Int, target rpm: Int32) -> FanControlVC {
    let s = NSStoryboard(name: "FanControl", bundle: nil)
    let vc = s.instantiateController(withIdentifier:"FanControl") as! FanControlVC
    vc.fanIndex = index
    vc.key = key
    vc.rpm = rpm
    return vc
  }
  
  override func viewDidLoad() {
    self.unitField.stringValue = UDs.bool(forKey: kTranslateUnits) ? "rpm".locale : "rpm"
    self.rpmField.stringValue = "\(self.rpm)"
    self.slider.minValue = 20
    self.slider.maxValue = Double(maxRpm)
    self.slider.intValue = self.rpm
    self.saveBtn.isEnabled = false
    self.saveBtn.isTransparent = true
    self.saveBtn.alphaValue = 0
    
    if self.fanIndex < 0 {
      return
    }
    
    if let data : Data = gSMC.read(key: SMC_FAN_MANUAL,
                                   type: AppSd.sensorScanner.getType(SMC_FAN_MANUAL) ?? DataTypes.FP2E) {
      bcopy((data as NSData).bytes, &self.FSkey, 2)
      self.FSkey = UInt16(decodeNumericValue(from: data, dataType:AppSd.sensorScanner.getType(SMC_FAN_MANUAL) ?? DataTypes.FP2E))
    } else if let data : Data = gSMC.read(key: SMC_FAN_MANUAL_NEW.withFormat(self.fanIndex),
                                          type: AppSd.sensorScanner.getType(SMC_FAN_MANUAL_NEW.withFormat(self.fanIndex)) ?? DataTypes.UI8) {
      bcopy([data[0]], &self.FSkeyNew, 1)
      fanForceNew = true
    } else {
      self.pwmBtn.state =  .off
      self.pwmBtn.isEnabled = false
      self.slider.isEnabled = false
      self.rpmField.isEditable = false
      self.rpmField.isSelectable = false
      self.unitField.stringValue = "😢" // no force fan keys..
      return
    }
    self.pwmBtn.state =  self.isPWMON() ? .on : .off
    self.slider.isEnabled = self.pwmBtn.state == .on
    self.rpmField.isEditable = self.pwmBtn.state == .on
    self.rpmField.isSelectable = self.pwmBtn.state == .on
    
    
    if !gShowBadSensors {
      // get min speed
      var akey = SMC_FAN_MIN_RPM.withFormat(self.fanIndex)
      var aType = AppSd.sensorScanner.getType(akey) ?? DataTypes.FP2E
      if let data : Data = gSMC.read(key: akey, type:aType) {
        let r = decodeNumericValue(from: data, dataType: aType)
        if r > 0 {
          self.slider.minValue = r
        }
      }
      // get max speed
      akey = SMC_FAN_MAX_RPM.withFormat(self.fanIndex)
      aType = AppSd.sensorScanner.getType(akey) ?? DataTypes.FP2E
      if let data : Data = gSMC.read(key: akey, type: aType) {
        let r = decodeNumericValue(from: data, dataType: aType)
        if r > 0 {
          self.slider.maxValue = r
        }
      }
    }
  }
  
  func controlTextDidChange(_ obj: Notification) {
    self.rpmField.stringValue = self.rpmField.stringValue.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
    if self.saveRequired() {
      self.saveButtonFadeIn()
    }
  }
  
  func controlTextDidEndEditing(_ obj: Notification) {
    let userRPM = Int32(self.rpmField.stringValue) ?? self.rpm
    if userRPM > maxRpm {
      self.rpmField.stringValue = "\(self.maxRpm)"
      self.slider.doubleValue = Double(self.maxRpm)
    }
    if self.saveRequired() {
      self.saveButtonFadeIn()
    }
  }
  
  @IBAction func setTargetRPM(_ sender: NSSlider) {
    self.saveButtonFadeIn()
    self.rpmField.stringValue = "\(sender.intValue)"
    self.rpm = sender.intValue
  }
  
  @IBAction func pwmButtonPressed(_ sender: NSButton) {
    self.slider.isEnabled = sender.state == .on
    self.rpmField.isEditable = sender.state == .on
    self.rpmField.isSelectable = sender.state == .on
    
    if self.saveRequired() {
      self.saveButtonFadeIn()
    }
  }
  
  func isPWMON() -> Bool {
    var state : Bool = false
    if fanForceNew {
      state = self.FSkeyNew > 0x00
    } else {
      state = ((self.FSkey & (1 << self.fanIndex)) >> self.fanIndex) == 1
    }
    return state
  }
  
  func setPWMON() {
    if fanForceNew {
      self.FSkeyNew = 0x01
    } else {
      self.FSkey = self.FSkey | (1 << self.fanIndex)
    }
  }
  
  func setPWMOFF() {
    if fanForceNew {
      self.FSkeyNew = 0x00
    } else {
      self.FSkey &= ~(1 << self.fanIndex)
    }
  }
  
  @IBAction func savePressed(_ sender: NSButton) {
    self.view.window?.makeFirstResponder(nil)
    self.save()
  }
  
  func saveButtonFadeOut() {
    self.saveBtn.isEnabled = false;
    if #available(OSX 10.12, *) {
      NSAnimationContext.runAnimationGroup({ (context) in
        context.duration = 2.0
        self.saveBtn.animator().alphaValue = 0
      })
    } else  {
      self.saveBtn.animator().alphaValue = 0
    }
    self.saveBtn.isTransparent = true
  }
  
  func saveButtonFadeIn() {
    self.saveBtn.isEnabled = true;
    if #available(OSX 10.12, *) {
      NSAnimationContext.runAnimationGroup({ (context) in
        context.duration = 2.0
        self.saveBtn.animator().alphaValue = 1
      })
    } else  {
      self.saveBtn.animator().alphaValue = 1
    }
    self.saveBtn.isTransparent = false
  }
  
  func saveRequired() -> Bool {
    var required : Bool = false
    if self.pwmBtn.state == .on && !self.isPWMON() {
      self.setPWMON()
      required = true
    } else if self.pwmBtn.state == .off && self.isPWMON() {
      self.setPWMOFF()
      required = true
    }
   
    let userRPM = Int32(self.rpmField.stringValue) ?? self.rpm
    if userRPM != rpm {
      self.rpm = userRPM
      required = true
    }
    
    return required
  }
  
  func save() {
    self.saveButtonFadeOut()
    let writer = "smcwrite"
    if let execpath = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent {
      let source = execpath + "/\(writer)"
      let dest   = "/private/tmp/\(writer)"
      let fm = FileManager.default
      if fm.fileExists(atPath: dest) {
        do { try fm.removeItem(atPath: dest) } catch { }
      }
      do { try fm.copyItem(atPath: source, toPath: dest)
        if let err = writeSMC(execPath: dest) {
          let alert = NSAlert()
          alert.messageText = "😱"
          alert.informativeText =
            (err.object(forKey: "NSAppleScriptErrorMessage") as! String).replacingOccurrences(of: "/bin/sh: ", with: "")
          alert.addButton(withTitle: "OK".locale)
          alert.runModal()
        }
      } catch { }
    }
  }
  
  fileprivate func writeSMC(execPath: String) -> NSDictionary? {
    var errors: NSDictionary? = nil
    let rpmVal : String = String(format: "%02x%02x", UInt16(self.rpm).data[1], UInt16(self.rpm).data[0])
    var forceKey : String = ""
    var forceKeyVal : String = ""
    
    var cmd : String = "do shell script \""
    
    if fanForceNew {
      forceKey = SMC_FAN_MANUAL_NEW.withFormat(self.fanIndex)
      forceKeyVal = String(format: "%02x", self.FSkeyNew)
    } else {
      forceKey = SMC_FAN_MANUAL
      forceKeyVal = String(format: "%02x%02x", self.FSkey.data[1], self.FSkey.data[0])
    }
    
    /*
     In order to use nvram for saving settings the driver must publish in nvram the following key:
     HW_fanControl=%01
     (value is a single byte)
     
     Done that, a secondary key will be written to the nvram: HW_fanControlData=%02%00%00%00%07%92%00%00%00%00%00.. etc.
     
     Don't forget that your third party driver should be able to interprete the key and adjust
     the relative smc keys and/to adjust the fan speed:
     */
    var useNVRAM : Bool = false
    if let nvram = getNVRAM() {
      if let fanCtrlKey = nvram.object(forKey: "HW_fanControl") as? Data {
        useNVRAM = fanCtrlKey.count > 0 && fanCtrlKey[0] > 0
      }
      if let fanControlData = nvram.object(forKey: "HW_fanControlData") as? Data {
        if fanControlData.count == 44 {
          for i in fanControlData.indices {
            nvFanControls[i] = fanControlData[i]
          }
        }
      }
    }
 
    if useNVRAM {
      // set fan control enabled/disabled
      var ctrl : UInt16 = 0
      bcopy([nvFanControls[0], nvFanControls[1]], &ctrl, 2)
      
      if isPWMON() {
        ctrl = ctrl | (1 << self.fanIndex)
      } else {
        ctrl &= ~(1 << self.fanIndex)
      }
      nvFanControls[0] = ctrl.data[0]
      nvFanControls[1] = ctrl.data[1]
      // set fan rpm
      nvFanControls[2 + (self.fanIndex << 1)]     = UInt16(self.rpm).data[1]
      nvFanControls[2 + (self.fanIndex << 1) + 1] = UInt16(self.rpm).data[0]
      
      // create the nvram arg
      var nvArg = ""
      var bi : Int = 0
      repeat {
        nvArg += String(format: "%%%02x", nvFanControls[bi])
        bi += 1
      } while bi < 44
      
      cmd += "sudo \(nvram_cmd) HW_fanControlData=\(nvArg)" // sudo required
    } else {
      // no nvram, writing to the AppleSMC
      cmd += "\(execPath) \(key) \(rpmVal) && \(execPath) \(forceKey) \(forceKeyVal)"
      // ... but will be persistent? If not, a daemon needs to read settings across reboots
    }
    
    cmd += "\" \(asAdmin)"
    
    let script: NSAppleScript? = NSAppleScript(source: cmd)
    script?.executeAndReturnError(&errors)
    return errors
  }
}

