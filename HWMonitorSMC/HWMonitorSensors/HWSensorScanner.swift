//
//  HWSensorsScanner.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 23/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

//MARK: Decoding functions
func smcFormat(_ num: Int) -> String {
  if num > 15 {
    let GZ = (0..<20).map({Character(UnicodeScalar("G".unicodeScalars.first!.value + $0)!)})
    for c in GZ {
      let i = Int(c.unicodeScalars.first!.value) - 55
      if i == num {
        return "\(c)"
      }
    }
  }
  return String(format: "%.1X", num)
}

fileprivate func swapBytes(_ value: UInt) -> UInt {
  return UInt(((Int(value) & 0xff00) >> 8) | ((Int(value) & 0xff) << 8))
}

fileprivate func getIndexOfHex(char: Character) -> Int {
  let v = Int(char.unicodeScalars.first!.value)
  return v > 96 && v < 103 ? v - 87 : v > 47 && v < 58 ? v - 48 : 0
}

public func decodeNumericValue(from data: Data, dataType: DataType) -> Double {
  if data.count > 0 {
    let type = [Character](dataType.type.toString())
    if (type[0] == "u" || type[0] == "s") && type[1] == "i" {
      let signd : Bool = type[0] == "s"
      
      switch type[2] {
      case "8":
        if data.count == 1 {
          var encoded : UInt8 = 0
          bcopy((data as NSData).bytes, &encoded, 1)
          
          if signd && (Int(encoded) & 1 << 7) > 0 {
            encoded &= ~(1 << 7)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      case "1":
        if type[3] == "6" && data.count == 2 {
          var encoded: UInt16 = 0
          
          bcopy((data as NSData).bytes, &encoded, 2)
          encoded = UInt16(bigEndian: encoded)
          
          if signd && (Int(encoded) & 1 << 15) > 0 {
            encoded &= ~(1 << 15)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      case "3":
        if type[3] == "2" && data.count == 4 {
          var encoded: UInt32 = 0
          
          bcopy((data as NSData).bytes, &encoded, 4)
          encoded = UInt32(bigEndian: encoded)
          
          if signd && (Int(encoded) & 1 << 31) > 0 {
            encoded &= ~(1 << 31)
            return -Double(encoded)
          }
          return Double(encoded)
        }
      default:
        break
      }
    } else if (type[0] == "f" || type[0] == "s") && type[1] == "p" && data.count == 2 {
      
      var encoded: UInt16 = 0
      bcopy((data as NSData).bytes, &encoded, 2)
      let i = getIndexOfHex(char: type[2])
      let f = getIndexOfHex(char: type[3])
      
      if (i + f) != ((type[0] == "s") ? 15 : 16) {
        return 0
      }
      
      var swapped = UInt16(bigEndian: encoded)
      let signd : Bool = type[0] == "s"
      let minus : Bool = (Int(swapped) & 1 << 15) > 0
      
      if signd && minus {
        swapped &= ~(1 << 15)
      }
      return (Double(swapped) / Double(1 << f)) * ((signd && minus) ? -1 : 1)
    }
  }
  return 0
}

//MARK: - HWSensorsScanner
class HWSensorsScanner: NSObject {
  func getType(_ key: String) -> DataType? {
    let type : DataType? = gSMC.getType(key: FourCharCode.init(fromString: key))
    return type
  }
  
  //MARK:  Monitoring functions
  func getMemory() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let percentage : Bool = UDs.bool(forKey: "useMemoryPercentage")
    let unit : HWUnit = percentage ? HWUnit.Percent : HWUnit.MB
    let sensorType : HWSensorType = .memory
    let actionType : ActionType = .memoryLog
    let type = "RAM"
    let format = "%.f"
    
    var s = HWMonitorSensor(key: "RAM TOTAL",
                            unit: HWUnit.MB,
                            type: type,
                            sensorType: sensorType,
                            title: "Total".locale,
                            canPlot: false)
    s.actionType = actionType
    s.format = format
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.totalMemory()
    s.stringValue = "\(NSNumber(value: s.doubleValue).intValue)"
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM ACTIVE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Active".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.activeMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM INACTIVE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Inactive".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.inactiveMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM FREE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Free".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.freeMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM USED",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Used".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.usedMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM PURGEABLE",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Purgeable".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.purgableMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    s = HWMonitorSensor(key: "RAM WIRED",
                        unit: unit,
                        type: type,
                        sensorType: sensorType,
                        title: "Wired".locale,
                        canPlot: AppSd.sensorsInited ? false : true)
    s.actionType = actionType
    s.format = format
    s.unit = unit
    s.favorite = UDs.bool(forKey: s.key)
    s.doubleValue = SSMemoryInfo.wiredMemory(percentage)
    s.stringValue = String(format: format, s.doubleValue)
    arr.append(s)
    
    // DIMM temperaturea. 16 Slots max (?)
    for i in 0..<16 {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_DIMM_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "DIMM %d".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns CPU Power/voltages/Multipliers from both SMC and Intel Power Gadget
  func get_CPU_GlobalParameters() -> ([HWMonitorSensor], [HWMonitorSensor]?, [HWMonitorSensor]?) {
    var main = [HWMonitorSensor]()
    var coresFreq : [HWMonitorSensor]? = nil
    var coresTemp : [HWMonitorSensor]? = nil
    let actionType : ActionType = .cpuLog
    let cpuCount = gCountPhisycalCores()
    
    // CPU Power
    if AppSd.ipg != nil && AppSd.ipg!.inited {
      let (_, packages, freqs, temps) = AppSd.ipg!.getIntelPowerGadgetCPUSensors()
      main.append(contentsOf: packages)
      coresFreq = freqs
      coresTemp = temps
    }
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PROXIMITY_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Proximity".locale,
                                      actionType: actionType,
                                      canPlot: AppSd.sensorsInited ? false : true,
                                      index: -1,
                                      list: &main)
    
    if !(AppSd.ipg != nil && AppSd.ipg!.packageTotal) {
      let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_TOTAL_WATT,
                                        type: DataTypes.SP78,
                                        unit: .Watt,
                                        sensorType: .cpuPowerWatt,
                                        title: "Package Total".locale,
                                        actionType: actionType,
                                        canPlot: AppSd.sensorsInited ? false : true,
                                        index: -1,
                                        list: &main)
    }
    
    if !(AppSd.ipg != nil && AppSd.ipg!.packageCore) {
      let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_CORE_WATT,
                                        type: DataTypes.SP78,
                                        unit: .Watt,
                                        sensorType: .cpuPowerWatt,
                                        title: "Package Core".locale,
                                        actionType: actionType,
                                        canPlot: AppSd.sensorsInited ? false : true,
                                        index: -1,
                                        list: &main)
    }
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_HEATSINK_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Heatsink".locale,
                                      actionType: actionType,
                                      canPlot: AppSd.sensorsInited ? false : true,
                                      index: -1,
                                      list: &main)
    
    // CPU voltages
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &main)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_VRM_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "VRM Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &main)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_CPU_PACKAGE_MULTI_F,
                                      type: DataTypes.FP4C,
                                      unit: .none,
                                      sensorType: .multiplier,
                                      title: "Package Multiplier".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &main)
    
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ =  self.addSMCSensorIfValid(key: SMC_CPU_CORE_MULTI_F.withFormat(a),
                                        type: DataTypes.FP4C,
                                        unit: .none,
                                        sensorType: .multiplier,
                                        title: String(format: "Core %d Multiplier".locale, i),
                                        actionType: actionType,
                                        canPlot: false,
                                        index: i,
                                        list: &main)
    }
    return (main, coresFreq, coresTemp)
  }
  
  /// returns CPU cores Temperatures from the SMC
  func getSMC_SingleCPUTemperatures() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .cpuLog
    let cpuCount = gCountPhisycalCores() * gCPUPackageCount()
    
    let upper : Bool = getType(SMC_CPU_CORE_TEMP_NEW.withFormat(0)) == nil // TC0C vs TC0c
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: (upper ? SMC_CPU_CORE_TEMP.withFormat(a) : SMC_CPU_CORE_TEMP_NEW.withFormat(a)),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "Core %d".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
    }
 
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_CPU_CORE_DIODE_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType: .temperature,
                                       title: String(format: "Diode %d".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns CPU cores Frequencies from the SMC (keys are not vanilla but IntelCPUMonitor stuff)
  func getSMC_SingleCPUFrequencies() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .cpuLog
    let cpuCount = gCountPhisycalCores() * gCPUPackageCount()
    
    for i in 0..<cpuCount {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_CPU_CORE_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyCPU,
                                       title: String(format: "Core %d".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
    }
    return arr
  }
  
  /// returns GPUs sensors
  func getSMCGPU() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .cpuLog
    
    for i in 0..<10 {
      let a : String = smcFormat(i)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Core".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_SHADER_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Shaders".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_MEMORY_FREQ_F.withFormat(a),
                                       type: DataTypes.FREQ,
                                       unit: .MHz,
                                       sensorType: .frequencyGPU,
                                       title: String(format: "GPU %d Memory".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_VOLT.withFormat(a),
                                       type: DataTypes.FP2E,
                                       unit: .Volt,
                                       sensorType:.voltage,
                                       title: String(format: "GPU %d Voltage".locale, i),
                                       actionType: actionType,
                                       canPlot: false,
                                       index: i,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_BOARD_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType:.temperature,
                                       title: String(format: "GPU %d Board".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
      let _ = self.addSMCSensorIfValid(key: SMC_GPU_PROXIMITY_TEMP.withFormat(a),
                                       type: DataTypes.SP78,
                                       unit: .C,
                                       sensorType:.temperature,
                                       title: String(format: "GPU %d Proximity".locale, i),
                                       actionType: actionType,
                                       canPlot: AppSd.sensorsInited ? false : true,
                                       index: i,
                                       list: &arr)
    }
    return arr
  }
  
  func getIGPUPackagePower() -> HWMonitorSensor? {
    var arr : [HWMonitorSensor] = [HWMonitorSensor]()
    if !(AppSd.ipg != nil && AppSd.ipg!.packageIgpu) {
      let _ =  self.addSMCSensorIfValid(key: SMC_IGPU_PACKAGE_WATT,
                                        type: DataTypes.SP78,
                                        unit: .Watt,
                                        sensorType: .igpuPowerWatt,
                                        title: "Package IGPU".locale,
                                        actionType: .gpuLog,
                                        canPlot: AppSd.sensorsInited ? false : true,
                                        index: -1,
                                        list: &arr)
    }
    return (arr.count > 0) ? arr[0] : nil
  }
  
  func getMotherboard() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .systemLog
    
    let _ =  self.addSMCSensorIfValid(key: SMC_NORTHBRIDGE_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "North Bridge".locale,
                                      actionType: actionType,
                                      canPlot: AppSd.sensorsInited ? false : true,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_AMBIENT_TEMP,
                                      type: DataTypes.SP78,
                                      unit: .C,
                                      sensorType: .temperature,
                                      title: "Ambient".locale,
                                      actionType: actionType,
                                      canPlot: AppSd.sensorsInited ? false : true,
                                      index: -1,
                                      list: &arr)
    
    // voltages
    let _ =  self.addSMCSensorIfValid(key: SMC_PRAM_BATTERY_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "PRAM Battery".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_12V_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "+12V Bus Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_5V_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "+5V Bus Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_12VDIFF_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "-12V Bus Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_5VDIFF_VOLT,
                                      type: DataTypes.SP4B,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "-5V Bus Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3VCC_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 VCC Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3VSB_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 VSB Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    let _ =  self.addSMCSensorIfValid(key: SMC_BUS_3_3AVCC_VOLT,
                                      type: DataTypes.FP2E,
                                      unit: .Volt,
                                      sensorType: .voltage,
                                      title: "3.3 AVCC Voltage".locale,
                                      actionType: actionType,
                                      canPlot: false,
                                      index: -1,
                                      list: &arr)
    
    
    
    return arr
  }
  
  /// get Motherboard Fans (16 bytes) like the following fan 1: 01000100 4d422046 616e2031 00000000
  /// byte 0 is the type
  /// byte 1 is the zone
  /// byte 2 is the location
  /// byte 3 is reserved for future expansion
  /// byte [4-15] (12 in total) is a utf8 string containing the name
  func getFans() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .systemLog
    let FNum: Int = 7 // FNum doesn't respect the fan index since is just a count. Just scan for keys
    /*
     if let data : Data = gSMC.read(key: SMC_FAN_NUM_INT, type: getType(SMC_FAN_NUM_INT) ?? DataTypes.UI8) {
     bcopy([data[0]], &FNum, 1)
     } else {
     // FNum not even present
     FNum = 7
     }*/
    for i in 0..<FNum {
      let data : Data? = gSMC.read(key: SMC_FAN_ID_STR.withFormat(i),
                                   type: getType(SMC_FAN_ID_STR.withFormat(i)) ?? DataTypes.FDS)
      var name : String = String(format: "Fan %d".locale, i)
      if (data != nil) && data!.count == 16 {
        name = String(data: data!.subdata(in: 4..<16), encoding: .utf8) ?? name
        //name = name.replacingOccurrences(of: "\\0", with: "", options: .literal, range: nil)
      }
   
      name = name.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
      
      var withIndex : String = name + " " + "speed".locale
      if self.addSMCSensorIfValid(key: SMC_FAN_CURR_RPM.withFormat(i),
                                  type: DataTypes.FP2E,
                                  unit: .RPM,
                                  sensorType: .tachometer,
                                  title: withIndex,
                                  actionType: actionType,
                                  canPlot: false,
                                  index: i,
                                  list: &arr) {
     
        if AppSd.showFanMinMaxSpeed {
          withIndex = name + " " + "min speed".locale
          let _ =  self.addSMCSensorIfValid(key: SMC_FAN_MIN_RPM.withFormat(i),
                                            type: DataTypes.FP2E,
                                            unit: .RPM,
                                            sensorType: .tachometer,
                                            title: withIndex,
                                            actionType: actionType,
                                            canPlot: false,
                                            index: i,
                                            list: &arr)
          
          withIndex = name + " " + "max speed".locale
          let _ =  self.addSMCSensorIfValid(key: SMC_FAN_MAX_RPM.withFormat(i),
                                            type: DataTypes.FP2E,
                                            unit: .RPM,
                                            sensorType: .tachometer,
                                            title: withIndex,
                                            actionType: actionType,
                                            canPlot: false,
                                            index: i,
                                            list: &arr)
        }
        
        if AppSd.fanControlEnabled {
          withIndex = name + " " + "target speed".locale + " 🔧"
          let _ =  self.addSMCSensorIfValid(key: SMC_FAN_CTRL.withFormat(i),
                                            type: DataTypes.FP2E,
                                            unit: .RPM,
                                            sensorType: .tachometer,
                                            title: withIndex,
                                            actionType: .fanControl,
                                            canPlot: false,
                                            index: i,
                                            list: &arr)
        }
      }
    }
    return arr
  }
  
  /// returns SMCSuperIO voltages and fans sensors from supported LPC chips
  func getSMCSuperIO(config: [String : Any]?) -> ([HWMonitorSensor], [HWMonitorSensor]) {
    var voltages = [HWMonitorSensor]()
    var fans = [HWMonitorSensor]()
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IOServiceMatching("IOPCIDevice")
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err {
        repeat {
          serviceObject = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if IORegistryEntryCreateCFProperties(serviceObject, &serviceDictionary, kCFAllocatorDefault, opt) != kIOReturnSuccess {
            IOObjectRelease(serviceObject)
            continue
          }
          
          if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
            if let cc = info.object(forKey: "class-code") as? Data {
              if cc == Data([0x00, 0x01, 0x06, 0x00]) {
                var child : io_service_t = 0
                var cit : io_iterator_t = 0
                if IORegistryEntryGetChildIterator(serviceObject, kIOServicePlane, &cit) == KERN_SUCCESS {
                  repeat {
                    child = IOIteratorNext(cit)
                    if let sensors = (IORegistryEntryCreateCFProperty(child, "Sensors" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSDictionary) {
                      IOObjectRelease(child)
                      IOObjectRelease(cit)
                      IOObjectRelease(serviceObject)
                      IOObjectRelease(iter)
                      for k in sensors.allKeys {
                        guard let key = k as? String else {
                          continue
                        }
                        
                        var multi : Double = 1
                        var name : String = key
                        if let kc = config?[key] as? [String : Any] {
                          if let skip = kc["skip"] as? Bool {
                            if skip { continue }
                          }
                          if let m = kc["multi"] as? Double {
                            multi = m
                          }
                          
                          if let n = kc["name"] as? String {
                            name = n
                          }
                        }
                        
                        if multi == 0 { multi = 1 }
                        
                        let actionType : ActionType = .systemLog
                        if key.range(of: "FAN") != nil {
                          guard let val = sensors.object(forKey: k) as? Double else {
                            continue
                          }
                          
                          let s = HWMonitorSensor(key: key,
                                                  unit: .RPM,
                                                  type: "LPCBFANS",
                                                  sensorType: .tachometer,
                                                  title: name,
                                                  canPlot: true)
                          s.actionType = actionType
                          s.stringValue = String(format: "%.f", val)
                          s.doubleValue = Double(val)
                          s.favorite = UDs.bool(forKey: s.key)
                          fans.append(s)
                        } else {
                          guard let data = sensors.object(forKey: k) as? Data else {
                            continue
                          }
                          
                          
                          let val = multi * Double(Float(bitPattern:
                            UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })))
                          
                          let s = HWMonitorSensor(key: key,
                                                  unit: .Volt,
                                                  type: "LPCBVOLTAGES",
                                                  sensorType: .voltage,
                                                  title: name,
                                                  canPlot: true)
                          s.actionType = actionType
                          s.stringValue = String(format: "%.3f", val)
                          s.doubleValue = Double(val)
                          s.favorite = UDs.bool(forKey: s.key)
                          voltages.append(s)
                        }
                      }
                      break
                    }
                    
                  } while child != 0
                  IOObjectRelease(child)
                  IOObjectRelease(cit)
                }
                
                IOObjectRelease(serviceObject)
                IOObjectRelease(iter)
                break
              }
            }
          }
          IOObjectRelease(serviceObject)
        } while serviceObject != 0
      }
      IOObjectRelease(iter)
    }
    return (voltages, fans)
  }
  
  /// returns LPC chip name under SMCSuperIO
  func getSuperIOChipName() -> String? {
    var chipName : String? = nil
    var iter : io_iterator_t = 0
    var rl : uint32 = 0
    
    var result : kern_return_t = IORegistryCreateIterator(kIOMasterPortDefault,
                                                          kIOServicePlane,
                                                          0,
                                                          &iter)
    
    if result == KERN_SUCCESS && iter != 0 {
      var entry : io_object_t
      repeat {
        entry = IOIteratorNext(iter)
        if entry != IO_OBJECT_NULL {
          if entry.name() == "SMCSuperIO" {
            let ref = IORegistryEntryCreateCFProperty(entry,
                                                      "ChipName" as CFString,
                                                      kCFAllocatorDefault, 0)
            if ref != nil {
              chipName = ref!.takeRetainedValue() as? String
              IOObjectRelease(entry)
              IOObjectRelease(iter)
              break
            }
          }
          
          rl += 1
          result = IORegistryIteratorEnterEntry(iter)
        } else {
          if rl == 0 {
            IOObjectRelease(entry)
            IOObjectRelease(iter)
            break
          }
          result = IORegistryIteratorExitEntry(iter)
          rl -= 1
        }
      } while (true)
      IOObjectRelease(iter)
    }
    
    return chipName
  }
  
  /// returns Battery voltages and amperage. Taken from the driver
  func getBattery() -> [HWMonitorSensor] {
    var arr = [HWMonitorSensor]()
    let actionType : ActionType = .batteryLog
    let pb : NSDictionary? = IOBatteryStatus.getIOPMPowerSource() as NSDictionary?
    if (pb != nil) {
      let voltage = IOBatteryStatus.getBatteryVoltage(from: pb as? [AnyHashable : Any])
      let amperage = IOBatteryStatus.getBatteryAmperage(from: pb as? [AnyHashable : Any])
      let maxmV : Int = 19000 // 19 V
      let tolerance : Int = 500 // 0.5 V
      let chargeDiffmV : Int = 3000 // during charge??
      
      if gShowBadSensors || (voltage > -1 && voltage <= (maxmV + tolerance + chargeDiffmV)) {
        let s = HWMonitorSensor(key: SMC_BATT0_VOLT,
                                unit: HWUnit.mV,
                                type: "BATT",
                                sensorType: .battery,
                                title: "Voltage".locale,
                                canPlot: false)
        s.actionType = actionType
        s.stringValue = String(format: "%d", voltage)
        s.doubleValue = Double(voltage)
        s.favorite = UDs.bool(forKey: s.key)
        arr.append(s)
      }
      
      if gShowBadSensors || (amperage > -1 && amperage <= 25000 /* a very high capacity battery Lol */) {
        let s = HWMonitorSensor(key: SMC_BATT0_AMP,
                                unit: HWUnit.mA,
                                type: "BATT",
                                sensorType: .battery,
                                title: "Amperage".locale,
                                canPlot: false)
        
        s.actionType = actionType
        s.stringValue = String(format: "%d", amperage)
        s.doubleValue = Double(amperage)
        s.favorite = UDs.bool(forKey: s.key)
        
        arr.append(s)
      }
    }
    return arr
  }
  
  //MARK: SMC keys validation functions
  func validateValue(for sensor: HWMonitorSensor, data: Data, dataType: DataType) -> Bool {
    let v : Double = decodeNumericValue(from: data, dataType: dataType)
    var valid : Bool = false
    switch sensor.sensorType {
    case .temperature:
      if gShowBadSensors || (v > -15 && v < 125) {
        /*
         -10 min temp + 5 to ensure no one start a pc this way.
         125 (110 °C it is enough) to ensure reading is correct
         */
        sensor.stringValue = String(format: "%.f", v)
        sensor.doubleValue = v
        valid = true
      }
    case .battery: fallthrough /* only if from the smc */
    case .hdSmartLife:          /* only if from the smc */
      var t: Int = 0
      (data as NSData).getBytes(&t, length: MemoryLayout<Int>.size)

      if gShowBadSensors || (t >= 0 && t <= 100) {
        sensor.stringValue = String(format: "%ld", t)
        sensor.doubleValue = v
        valid = true
      }
    case .voltage:
      sensor.stringValue = String(format: "%.3f", v)
      sensor.doubleValue = v
      // voltage sensors only refear to CPU and Motherboard's stuff
      // since Battery voltages are read directly from the IO Registry in this app.
      valid = gShowBadSensors || (v > -15 || v < 15)
    case .tachometer:
      sensor.stringValue = String(format: "%.0f", v)
      sensor.doubleValue = v
      valid = gShowBadSensors || (v >= 0 && v <= 7000)
    case .frequencyCPU:  fallthrough
    case .frequencyGPU:  fallthrough
    case .frequencyOther:
      var MHZ: UInt = 0
      bcopy((data as NSData).bytes, &MHZ, 2)
      MHZ = swapBytes(MHZ)
      if sensor.unit == .GHz {
        MHZ = MHZ / 1000
      }
      sensor.stringValue = String(format: "%d", MHZ)
      sensor.doubleValue = Double(MHZ)
      valid = gShowBadSensors || (MHZ > 0 && MHZ < 9000) // OC record is 8794 (AMD FX-8350) on Nov 10 2012
    case .igpuPowerWatt:
      sensor.stringValue = String(format: "%.2f", v)
      sensor.doubleValue = v
      valid = gShowBadSensors || (v >= 0 && v < 150) // 30 W max?
    case .intelWatt:   fallthrough
    case .cpuPowerWatt:
      sensor.stringValue = String(format: "%.2f", v)
      sensor.doubleValue = v
      valid = gShowBadSensors || (v > 0 && v < 1000) // reached from an Intel i9-7890XE in extreme OC
    case .multiplier:
      var m: UInt = 0
      bcopy((data as NSData).bytes, &m, 2)
      sensor.stringValue = String(format: "x%.f", Double(m) / 10)
      sensor.doubleValue = Double(m)
      valid = gShowBadSensors || (m > 0 && m <= 50)
    default:
      break
    }
    
    return valid
  }
  
  
  func addSMCSensorIfValid(key: String,
                           type: DataType,
                           unit: HWUnit,
                           sensorType: HWSensorType,
                           title: String,
                           actionType: ActionType,
                           canPlot: Bool,
                           index: Int,
                           list: inout [HWMonitorSensor]) -> Bool {
    
    let kcount = key.count
    if kcount >= 3 && kcount <= 4 {
      let dt : DataType = getType(key) ?? type
      if let data : Data = gSMC.read(key: key, type: dt) {
        
        let s = HWMonitorSensor(key: key,
                                unit: unit,
                                type: dt.type.toString(),
                                sensorType: sensorType,
                                title: title,
                                canPlot: canPlot)
        s.index = index
        
        if self.validateValue(for: s, data: data, dataType: dt) {
          s.actionType = actionType
          s.favorite = UDs.bool(forKey: key)
          list.append(s) // success
          return true
        }
      }
    }
    return false
  }
}
