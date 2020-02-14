//
//  globals.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 05/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

let kTestVersion            = ""

let kLinceseAccepted        = "LinceseAcceptedWithWarning"
let kRunAtLogin             = "runAtLogin"
let kUseIPG                 = "UseIPG"
let kUseIPGPMU              = "UseIPGPMU"
let kShowGadget             = "ShowGadget"
let kHideVerticalScroller   = "hideVerticalScroller"
let kAppleInterfaceStyle    = "AppleInterfaceStyle"
let kDark                   = "Dark"
let kPopoverHeight          = "popoverHeight"
let kPopoverWidth           = "popoverWidth"
let kSensorsTimeInterval    = "SensorsTimeInterval"

let kCPU_TDP_MAX            = "CPU_TDP_MAX"
let kCPU_Frequency_MAX      = "CPU_Frequency_MAX"

let kShowCPUSensors         = "ShowCPUSensors"
let kShowGPUSensors         = "ShowGPUSensors"
let kShowMoBoSensors        = "ShowMoBoSensors"

let kShowFansSensors        = "ShowFansSensors"
let kShowFansMinMaxSensors  = "ShowFansMinMaxSensors"
let kEnableFansControl      = "EnableFansControl"

let kShowRAMSensors         = "ShowRAMSensors"
let kShowMediaSensors       = "ShowMediaSensors"
let kShowBatterySensors     = "ShowBatterySensors"

let kCPUTimeInterval        = "CPUTimeInterval"
let kGPUTimeInterval        = "GPUTimeInterval"
let kMoBoTimeInterval       = "MoBoTimeInterval"
let kFansTimeInterval       = "FansTimeInterval"
let kRAMTimeInterval        = "RAMTimeInterval"
let kMediaTimeInterval      = "MediaTimeInterval"
let kBatteryTimeInterval    = "BatteryTimeInterval"

let kUseMemoryPercentage    = "useMemoryPercentage"
let kExpandCPUTemperature   = "expandCPUTemperature"
let kExpandVoltages         = "expandVoltages"
let kExpandCPUFrequencies   = "expandCPUFrequencies"
let kExpandAll              = "expandAll"
let kDontShowEmpty          = "dontshowEmpty"
let kUseGPUIOAccelerator    = "useGPUIOAccelerator"

let kTranslateUnits         = "TranslateUnits"
let kTopBarFont             = "TopBarFont"
let kTheme                  = "Theme"
let kViewSize               = "ViewSize"

let kIOPerformanceStatistics : String = "PerformanceStatistics"
let kMetalDevice : String = "MetalDevice"

let asAdmin : String        = "with administrator privileges"

let AppSd = NSApplication.shared.delegate as! AppDelegate
let UDs = UserDefaults.standard
let kMinWidth  : CGFloat = 370
let kMinHeight : CGFloat = 270

let gPopOverFont : NSFont = NSFont(name: "Lucida Grande Bold", size: 9.0) ?? NSFont.systemFont(ofSize:  9.0)
let gLogFont     : NSFont = NSFont(name: "Lucida Grande", size: 10.0)     ?? NSFont.systemFont(ofSize: 10.0)

let gHelperID : CFString = "org.slice.HWMonitorSMC2-Helper" as CFString
let gShowBadSensors : Bool =
  FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Desktop/HWBadSensors")

let gSMC = SMCKit.init()

func gCPUPackageCount() -> Int {
  var c: Int = 0
  var l: size_t = MemoryLayout<Int>.size
  sysctlbyname("hw.packages", &c, &l, nil, 0)
  return c
}

func gCountPhisycalCores() -> Int {
  var c: Int = 0
  var l: size_t = MemoryLayout<Int>.size
  sysctlbyname("machdep.cpu.core_count", &c, &l, nil, 0)
  return c
}

func gCPUBaseFrequency() -> Int64 {
  var frequency: Int64 = 0
  var size = MemoryLayout<Int64>.size
  sysctlbyname("hw.cpufrequency", &frequency, &size, nil, 0)
  return (frequency > 0) ? (frequency / 1000000) : 0
}

func getAppearance() -> NSAppearance {
  if #available(OSX 10.14, *) {
    let forceDark : Bool = UserDefaults.standard.bool(forKey: kDark)
    var appearance = NSAppearance(named: .vibrantDark)
    if !forceDark {
      let appearanceName : String? = UserDefaults.standard.object(forKey: kAppleInterfaceStyle) as? String
      if (appearanceName == nil || ((appearanceName?.range(of: "Dark")) == nil)) {
        appearance = NSAppearance(named: .vibrantLight)
      }
    }
    return appearance!
  } else {
    return AppSd.initialAppearance
  }
}

func getTopBarFont(saved: Bool) -> NSFont? {
  return saved ? UDs.topBarFont() : nil
}

// https://gist.github.com/fethica/52ef6d842604e416ccd57780c6dd28e6
public struct BytesFormatter {
  public let bytes: Int64
  public let countStyle: Int64
  
  public var kilobytes: Double {
    return Double(bytes) / Double(countStyle)
  }
  
  public var megabytes: Double {
    return kilobytes / Double(countStyle)
  }
  
  public var gigabytes: Double {
    return megabytes / Double(countStyle)
  }
  
  public init(bytes: Int64, countStyle: Int64) {
    self.bytes = bytes
    self.countStyle = countStyle
  }
  
  public func stringValue() -> String {
    
    switch bytes {
    case 0..<countStyle:
      return "\(bytes) " + "bytes".locale(AppSd.translateUnits)
    case countStyle..<(countStyle * countStyle):
      return "\(String(format: "%.2f", kilobytes)) " + "KB".locale(AppSd.translateUnits)
    case countStyle..<(countStyle * countStyle * countStyle):
      return "\(String(format: "%.2f", megabytes)) " + "MB".locale(AppSd.translateUnits)
    case (countStyle * countStyle * countStyle)...Int64.max:
      return "\(String(format: "%.2f", gigabytes)) " + "GB".locale(AppSd.translateUnits)
    default:
      return "\(bytes) " + "bytes".locale(AppSd.translateUnits)
    }
  }
}

func amIaPowerUser() -> Bool {
  let user_id: uid_t = getuid()
  let pwuid = UnsafeMutablePointer<passwd>(getpwuid(user_id)).pointee
  let pw_name = String(cString: pwuid.pw_name!)
  let admin_group = UnsafeMutablePointer<group>(getgrnam("admin")).pointee
  var i : Int = 0
  while admin_group.gr_mem[i] != nil {
    if String(cString: admin_group.gr_mem[i]!) == pw_name {
      return true
    }
    i+=1
  }
  return false
}
