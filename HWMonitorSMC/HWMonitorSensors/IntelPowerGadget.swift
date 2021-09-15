//
//  IntelPowerGadget.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 07/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

class IntelPG: NSObject {
  var newMode      : Bool = true
  var inited       : Bool = false
  var packageCore  : Bool = false
  var packageTotal : Bool = false
  var packageIgpu  : Bool = false
  
  var sampleID1 : PGSampleID = 0
  var sampleID2 : PGSampleID = 0
  var sampleGT  : PGSampleID = 0
  
  var numPkg  : Int32 = 0
  var numCore : Int32 = 0
  
  var pkgIndex : Int32 = 0
  
  var gtAvailable         : Bool = false
  var IAEAvailable        : Bool = false
  var DRAMEAvailable      : Bool = false
  var PlatformEAvailable  : Bool = false
  //var reset               : Bool = false
  
  deinit {
    if self.sampleGT > 0 {
      PGSample_Release(self.sampleGT)
    }

    if self.sampleID1 > 0 {
      PGSample_Release(self.sampleID1)
    }
    
    if self.sampleID2 > 0 {
      PGSample_Release(self.sampleID2)
    }
    
    if self.inited {
      if self.newMode {
        PG_Shutdown()
      } else {
        IntelEnergyLibShutdown()
      }
    }
  }
  
  override init() {
    super.init()
    let forceOldMode = FileManager.default.fileExists(atPath: "\(NSHomeDirectory())/Desktop/IPGOLD")
    let newLib = "/Library/Frameworks/IntelPowerGadget.framework/Versions/A/Headers/PowerGadgetLib.h"
    let oldLib = "/Library/Frameworks/IntelPowerGadget.framework/Versions/A/Headers/EnergyLib.h"
    
    if forceOldMode {
      print("WARNING: forcing old Intel Power Gadget headers is enabled.")
      self.initOLD()
    } else {
      if FileManager.default.fileExists(atPath:newLib) {
        self.initNEW()
      } else if FileManager.default.fileExists(atPath: oldLib) {
        self.initOLD()
      }
    }
  }
  
  private func initNEW() {
    if PG_Initialize() {
      self.newMode = true
      self.inited = true
    
      let useIPGPMU : Bool = (UDs.object(forKey: kUseIPGPMU) == nil || UDs.bool(forKey: kUseIPGPMU))
      self.pmu(on: useIPGPMU)
      
      PG_GetNumPackages(&self.numPkg)
      /*
       Xeon motherboards only accept twin CPUs
       Xeon doesn't have the IGPU
       */
      PG_IsGTAvailable(0, &self.gtAvailable)
      PG_GetNumCores(0, &self.numCore)
      PG_IsIAEnergyAvailable(0, &self.IAEAvailable)
      PG_IsDRAMEnergyAvailable(0, &self.DRAMEAvailable)
      PG_IsPlatformEnergyAvailable(0, &self.PlatformEAvailable)
    }
  }
  
  private func initOLD() {
    if IntelEnergyLibInitialize() {
      self.newMode = false
      self.inited = true
      
      // ReadSample reads a set of MSRs, the data can be accessed by calling GetPowerData
      // Note that GetPowerData requires at least 2 preceding calls to ReadSample, as these metrics require the delta between 2 samples to calculate their values
      ReadSample()
      ReadSample()
    }
  }
  
  public func pmu(on: Bool) {
    if self.inited {
      PG_UsePMU(0, on)
    }
  }
  
  /// get CPU Sensors from Intel Power Gadget
  public func getIntelPowerGadgetCPUSensors() -> (Bool,
    [HWMonitorSensor],
    [HWMonitorSensor]?,
    [HWMonitorSensor]?) {
    
    if self.newMode {
      let (mode, packages, coresFreq, coresTemp) = self.getIntelPowerGadgetCPUSensorsNew()
      return (mode, packages, coresFreq, coresTemp)
    } else {
      return (false, self.getIntelPowerGadgetCPUSensorsOld(), nil, nil)
    }
  }
  
  /// get GPU Sensors from Intel Power Gadget
  public func getIntelPowerGadgetGPUSensors() -> [HWMonitorSensor] {
    return self.newMode
      ? self.getIntelPowerGadgetGPUSensorsNew()
      : self.getIntelPowerGadgetGPUSensorsOld()
  }
  
  // MARK: Old header EnergyLib.h
  /// get GPU Sensors from Intel Power Gadget (old header EnergyLib.h)
  private func getIntelPowerGadgetGPUSensorsOld() -> [HWMonitorSensor] {
    var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
    
    if IsGTAvailable() {
      /*
       var gpuutil : Float = 0
       if GetGPUUtilization(&gpuutil) {
       let sensor = HWMonitorSensor(key: "IGPU Utilization",
       unit: .Percent,
       type: "IPG",
       sensorType: .percent,
       title: "Utilization".locale,
       canPlot: AppSd.sensorsInited ? false : true)
       sensor.actionType = .cpuLog;
       sensor.stringValue = String(format: "%.2f", Double(gpuutil))
       sensor.doubleValue = Double(gpuutil)
       sensor.favorite = UDs.bool(forKey: sensor.key)
       sensors.append(sensor)
       }
       */
      
      var gtFreq : Int32 = 0
      if GetGTFrequency(&gtFreq) {
        let sensor = HWMonitorSensor(key: "IGPU Frequency",
                                     unit: .GHz,
                                     type: "IPG IGPU",
                                     sensorType: .intelGPUFrequency,
                                     title: (AppSd.useIOAcceleratorForGPUs ? "Frequency".locale : "IGPU Frequency".locale),
                                     canPlot: AppSd.sensorsInited ? false : true)
        
        
        sensor.actionType = .cpuLog;
        sensor.stringValue = String(format: "%.3f", Double(gtFreq) / 1000)
        sensor.doubleValue = Double(gtFreq)
        sensor.favorite = UDs.bool(forKey: sensor.key)
        sensors.append(sensor)
      }
      
      var gtMaxFreq : Int32 = 0
      if GetGpuMaxFrequency(&gtMaxFreq) {
        if gtMaxFreq >= 0 {
          let sensor = HWMonitorSensor(key: "Max Frequency",
                                       unit: .GHz,
                                       type: "IPG IGPU",
                                       sensorType: .intelGPUFrequency,
                                       title: (AppSd.useIOAcceleratorForGPUs ? "Max Frequency".locale : "IGPU Max Frequency".locale),
                                       canPlot: AppSd.sensorsInited ? false : true)
          
          sensor.isInformativeOnly = true
          sensor.actionType = .cpuLog;
          sensor.stringValue = String(format: "%.3f", Double(gtMaxFreq) / 1000)
          sensor.doubleValue = Double(gtMaxFreq)
          sensor.favorite = UDs.bool(forKey: sensor.key)
          sensors.append(sensor)
        }
      }
      
      var numMsrs : Int32 = 0
      
      GetNumMsrs(&numMsrs)
      ReadSample()
      
      for j in 0..<numMsrs {
        var funcID : Int32 = 0
        let szName = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
        GetMsrFunc(j, &funcID)
        GetMsrName(j, szName)
        var nData: Int32 = 0
        let data = UnsafeMutablePointer<Double>.allocate(capacity: 3)
        GetPowerData(0, j, data, &nData)
        
        if funcID == MSR_FUNC_POWER {
          var name : String = String(format: "%s", szName)
          let power : Double = data[0]
          
          if name == "GT" {
            if gShowBadSensors || (power >= 0 && power <= 100) {
              name = "Package IGPU"
              let sensor = HWMonitorSensor(key: name,
                                           unit: .Watt,
                                           type: "IPG IGPU",
                                           sensorType: .igpuPowerWatt,
                                           title: name.locale,
                                           canPlot: AppSd.sensorsInited ? false : true)
              
              
              sensor.actionType = .cpuLog;
              sensor.stringValue = String(format: "%.2f", power)
              sensor.doubleValue = power
              sensor.favorite = UDs.bool(forKey: sensor.key)
              sensors.append(sensor)
              self.packageIgpu = true
              break
            }
            self.packageIgpu = true
            break
          }
        }
        
        szName.deallocate()
        data.deallocate()
      }
      
    }
    return sensors
  }
  
  /// get CPU Sensors from Intel Power Gadget (old header EnergyLib.h)
  private func getIntelPowerGadgetCPUSensorsOld() -> [HWMonitorSensor] {
    var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
    var cpuFrequency      : Double = 0
    var packageTemp       : Double = 0
    var packagePowerLimit : Double = 0
    
    /*
     // Returns true if we have platform energy MSRs available
     bool IsPlatformEnergyAvailable();
     
     // Returns true if we have platform energy MSRs available
     bool IsDramEnergyAvailable();
     */
    //let dramEnergy : Bool = IsDramEnergyAvailable() || IsPlatformEnergyAvailable()
    
    var numMsrs : Int32 = 0
    
    GetNumMsrs(&numMsrs)
    ReadSample()
    
    for j in 0..<numMsrs {
      var funcID : Int32 = 0
      let szName = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
      GetMsrFunc(j, &funcID)
      GetMsrName(j, szName)
      var nData: Int32 = 0
      let data = UnsafeMutablePointer<Double>.allocate(capacity: 3)
      GetPowerData(0, j, data, &nData)
      
      if funcID == MSR_FUNC_FREQ {
        cpuFrequency = data[0]
      } else if (funcID == MSR_FUNC_POWER /*&& dramEnergy*/) {
        var name : String = String(format: "%s", szName)
        let power : Double = data[0]
        
        if name == "Processor" {
          name = "Package Total"
          self.packageTotal = true
        } else if name == "IA" {
          name = "Package Core"
          self.packageCore = true
        }
        
        if name != "GT" && (gShowBadSensors || (power >= 0 && power <= 1000)) {
          let sensor = HWMonitorSensor(key: name,
                                       unit: .Watt,
                                       type: "IPG CPU",
                                       sensorType: .intelWatt,
                                       title: name.locale,
                                       canPlot: AppSd.sensorsInited ? false : true)
          
          
          sensor.actionType = .cpuLog;
          sensor.stringValue = String(format: "%.2f", power)
          sensor.doubleValue = power
          sensor.favorite = UDs.bool(forKey: sensor.key)
          sensors.append(sensor)
        }
      } else if funcID == MSR_FUNC_TEMP {
        packageTemp = data[0]
      } else if funcID == MSR_FUNC_LIMIT {
        packagePowerLimit = data[0]
      }
      
      szName.deallocate()
      data.deallocate()
    }
    
    /*
     var TDP : Double = 0
     GetTDP(0, &TDP)*/
    
    var maxTemp : Int32 = 0
    GetMaxTemperature(0, &maxTemp);
    
    var temp : Int32 = 0
    GetTemperature(0, &temp);
    
    var degree1C : Int32 = 0
    var degree2C : Int32 = 0
    GetThresholds(0, &degree1C, &degree2C)
    
    var baseFrequency : Double = 0
    GetBaseFrequency(0, &baseFrequency)
    
    var cpuutil : Int32 = 0
    GetCpuUtilization(0, &cpuutil)
    
    var sensor = HWMonitorSensor(key: "CPU Frequency",
                                 unit: .GHz,
                                 type: "IPG CPU",
                                 sensorType: .intelCPUFrequency,
                                 title: "Frequency".locale,
                                 canPlot: AppSd.sensorsInited ? false : true)
    
    if gShowBadSensors || (cpuFrequency >= 0 && cpuFrequency <= 9000) {
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", Double(cpuFrequency) / 1000)
      sensor.doubleValue = cpuFrequency
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
    }
    
    if gShowBadSensors || (baseFrequency >= 0 && baseFrequency <= 9000) {
      sensor = HWMonitorSensor(key: "Base Frequency",
                               unit: .GHz,
                               type: "IPG CPU",
                               sensorType: .intelCPUFrequency,
                               title: "Base Frequency".locale,
                               canPlot: false)
      
      
      sensor.isInformativeOnly = true
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", Double(baseFrequency) / 1000)
      sensor.doubleValue = baseFrequency
      sensor.favorite = false
      sensors.append(sensor)
    }
    
    
    sensor = HWMonitorSensor(key: "CPU Utilization",
                             unit: .Percent,
                             type: "IPG CPU",
                             sensorType: .percent,
                             title: "Utilization".locale,
                             canPlot: AppSd.sensorsInited ? false : true)
    
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", Double(cpuutil))
    sensor.doubleValue = Double(cpuutil)
    
    sensor.favorite = UDs.bool(forKey: sensor.key)
    sensors.append(sensor)
    
    if gShowBadSensors || (packageTemp > -15 && packageTemp <= 125) {
      sensor = HWMonitorSensor(key: "Package Temp",
                               unit: .C,
                               type: "IPG CPU",
                               sensorType: .intelTemp,
                               title: "Package Temperature".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.f", packageTemp)
      sensor.doubleValue = packageTemp
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
    }
    
    sensor = HWMonitorSensor(key: "Max Temperature",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "Max Temperature".locale,
                             canPlot: false)
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%d", maxTemp)
    sensor.doubleValue = Double(maxTemp)
    sensor.favorite = false
    sensors.append(sensor)
    
    sensor = HWMonitorSensor(key: "Thresholds",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "Thresholds".locale,
                             canPlot: false)
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%d/%d", degree1C, degree2C)
    sensor.doubleValue = Double(degree2C)
    sensor.favorite = false
    sensors.append(sensor)
    
    if gShowBadSensors || packagePowerLimit >= 0 {
      sensor = HWMonitorSensor(key: "Package Power Limit (TDP)",
                               unit: .Watt,
                               type: "IPG CPU",
                               sensorType: .intelWatt,
                               title: "Package Power Limit (TDP)".locale,
                               canPlot: false)
      
      sensor.isInformativeOnly = true
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.f", packagePowerLimit)
      sensor.doubleValue = packagePowerLimit
      sensor.favorite = false
      sensors.append(sensor)
    }
    
    return sensors
  }

  // MARK: New header PowerGadgetLib.h
  
  /// get CPU Sensors from Intel Power Gadget (new header PowerGadgetLib.h)
  private func getIntelPowerGadgetCPUSensorsNew() -> (Bool, [HWMonitorSensor], [HWMonitorSensor], [HWMonitorSensor]) {
    var packages : [HWMonitorSensor] = [HWMonitorSensor]()
    var coresFreq : [HWMonitorSensor] = [HWMonitorSensor]()
    var coresTemp : [HWMonitorSensor] = [HWMonitorSensor]()
    var res : Bool = false
    if self.sampleID1 > 0 {
      PGSample_Release(self.sampleID1)
      self.sampleID1 = 0
    }
    
    // save sample2 to sample1
    if self.sampleID2 > 0 {
      self.sampleID1 = self.sampleID2
    }

    // get new sample
    PG_ReadSample(self.pkgIndex, &self.sampleID2)
    
    var powerWatts : Double = 0
    var energyJoules : Double = 0
    var temp : Double = 0
    var mean : Double = 0
    var min  : Double = 0
    var max  : Double = 0
    var freq : Double = 0
    
    PG_GetIABaseFrequency(self.pkgIndex, &freq)
    
    var sensor = HWMonitorSensor(key: "Base Frequency",
                                 unit: .GHz,
                                 type: "IPG CPU",
                                 sensorType: .intelCPUFrequency,
                                 title: "Base Frequency".locale,
                                 canPlot: false)
    
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.3f", freq / 1000)
    sensor.doubleValue = freq
    sensor.favorite = false
    packages.append(sensor)
    
    PG_GetIAMaxFrequency(self.pkgIndex, &freq)
    sensor = HWMonitorSensor(key: "Max Frequency",
                             unit: .GHz,
                             type: "IPG CPU",
                             sensorType: .intelCPUFrequency,
                             title: "Max Frequency".locale,
                             canPlot: false)
    
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.3f", freq / 1000)
    sensor.doubleValue = freq
    sensor.favorite = false
    packages.append(sensor)
    
    var degreesC : UInt8 = 0
    PG_GetMaxTemperature(self.pkgIndex, &degreesC)
    sensor = HWMonitorSensor(key: "Max Temperature",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "Max Temperature".locale,
                             canPlot: false)
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%d", degreesC)
    sensor.doubleValue = Double(degreesC)
    sensor.favorite = false
    packages.append(sensor)
    
    var tdp : Double = 0
    PG_GetTDP(self.pkgIndex, &tdp)
    sensor = HWMonitorSensor(key: "Package Power Limit (TDP)",
                             unit: .Watt,
                             type: "IPG CPU",
                             sensorType: .intelWatt,
                             title: "Package Power Limit (TDP)".locale,
                             canPlot: false)
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", tdp)
    sensor.doubleValue = tdp
    sensor.favorite = false
    packages.append(sensor)
    
    var util : Double = 0
    res = PGSample_GetIAUtilization(self.sampleID1, self.sampleID2, &util)
    if res || !AppSd.sensorsInited {
      sensor = HWMonitorSensor(key: "CPU Utilization",
                               unit: .Percent,
                               type: "IPG CPU",
                               sensorType: .percent,
                               title: "Utilization".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.f", Double(util))
      sensor.doubleValue = Double(util)
      
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
    }
    
    res = PGSample_GetPackagePower(self.sampleID1, self.sampleID2, &powerWatts, &energyJoules)
    self.packageTotal = true
    if res || !AppSd.sensorsInited {
      sensor = HWMonitorSensor(key: "Package Total",
                               unit: .Watt,
                               type: "IPG CPU",
                               sensorType: .intelWatt,
                               title: "Package Total".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.2f", powerWatts)
      sensor.doubleValue = powerWatts
      
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
    }
    
    
    res = PGSample_GetIAPower(self.sampleID1, self.sampleID2, &powerWatts, &energyJoules)
    self.packageCore = true
    if res || !AppSd.sensorsInited {
      sensor = HWMonitorSensor(key: "Package Core",
                               unit: .Watt,
                               type: "IPG CPU",
                               sensorType: .intelWatt,
                               title: "Package Core".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.2f", powerWatts)
      sensor.doubleValue = powerWatts
      
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
    }
    
    PGSample_GetPackageTemperature(self.sampleID2, &temp)
    sensor = HWMonitorSensor(key: "Package Temp",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "Package Temperature".locale,
                             canPlot: AppSd.sensorsInited ? false : true)
    
    
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", temp)
    sensor.doubleValue = temp
    sensor.favorite = UDs.bool(forKey: sensor.key)
    packages.append(sensor)
    
    PGSample_GetIATemperature(self.sampleID2, &mean, &min, &max)
    sensor = HWMonitorSensor(key: "IA Temperature AVG",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "IA Temperature AVG".locale,
                             canPlot: AppSd.sensorsInited ? false : true)
    
    
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.2f", mean)
    sensor.doubleValue = mean
    sensor.favorite = UDs.bool(forKey: sensor.key)
    packages.append(sensor)
    
    sensor = HWMonitorSensor(key: "IA Temperature MIN",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "IA Temperature MIN".locale,
                             canPlot: AppSd.sensorsInited ? false : true)
    
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", min)
    sensor.doubleValue = min
    sensor.favorite = UDs.bool(forKey: sensor.key)
    packages.append(sensor)
    
    sensor = HWMonitorSensor(key: "IA Temperature MAX",
                             unit: .C,
                             type: "IPG CPU",
                             sensorType: .intelTemp,
                             title: "IA Temperature MAX".locale,
                             canPlot: AppSd.sensorsInited ? false : true)
    
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", max)
    sensor.doubleValue = max
    sensor.favorite = UDs.bool(forKey: sensor.key)
    packages.append(sensor)
      
    if self.DRAMEAvailable {
      res = PGSample_GetDRAMPower(self.sampleID1, self.sampleID2, &powerWatts, &energyJoules)
      if res || !AppSd.sensorsInited {
        sensor = HWMonitorSensor(key: "DRAM",
                                 unit: .Watt,
                                 type: "IPG CPU",
                                 sensorType: .intelWatt,
                                 title: "DRAM".locale,
                                 canPlot: false)
        
        sensor.isInformativeOnly = false
        sensor.actionType = .cpuLog;
        sensor.stringValue = String(format: "%.2f", powerWatts)
        sensor.doubleValue = powerWatts
        sensor.favorite = false
        packages.append(sensor)
      }
    }
    
    if self.PlatformEAvailable {
      res = PGSample_GetPlatformPower(self.sampleID1, self.sampleID2, &powerWatts, &energyJoules)
      if res || !AppSd.sensorsInited {
        sensor = HWMonitorSensor(key: "Platform",
                                 unit: .Watt,
                                 type: "IPG CPU",
                                 sensorType: .intelWatt,
                                 title: "Platform".locale,
                                 canPlot: false)
        
        sensor.isInformativeOnly = false
        sensor.actionType = .cpuLog;
        sensor.stringValue = String(format: "%.2f", powerWatts)
        sensor.doubleValue = powerWatts
        sensor.favorite = false
        packages.append(sensor)
      }
    }
    
    res = PGSample_GetIAFrequency(self.sampleID1, self.sampleID2, &mean, &min, &max)
    if res || !AppSd.sensorsInited {
      sensor = HWMonitorSensor(key: "IA Frequency AVG",
                               unit: .GHz,
                               type: "IPG CPU",
                               sensorType: .intelCPUFrequency,
                               title: "IA Frequency AVG".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", mean / 1000)
      sensor.doubleValue = mean
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
      
      sensor = HWMonitorSensor(key: "IA Frequency MIN",
                               unit: .GHz,
                               type: "IPG CPU",
                               sensorType: .intelCPUFrequency,
                               title: "IA Frequency MIN".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", min / 1000)
      sensor.doubleValue = min
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
      
      sensor = HWMonitorSensor(key: "IA Frequency MAX",
                               unit: .GHz,
                               type: "IPG CPU",
                               sensorType: .intelCPUFrequency,
                               title: "IA Frequency MAX".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", max / 1000)
      sensor.doubleValue = max
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
    }
    
    res = PGSample_GetIAFrequencyRequest(self.sampleID2, &mean, &min, &max)
    if res || !AppSd.sensorsInited {
      sensor = HWMonitorSensor(key: "IA Frequency REQ",
                               unit: .GHz,
                               type: "IPG CPU",
                               sensorType: .intelCPUFrequency,
                               title: "IA Frequency REQ".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.3f", mean / 1000)
      sensor.doubleValue = mean
      sensor.favorite = UDs.bool(forKey: sensor.key)
      packages.append(sensor)
    }
    
    for ci in 0..<self.numCore {
      PGSample_GetIACoreTemperature(self.sampleID2, ci, &mean, &min, &max)
      sensor = HWMonitorSensor(key: "IA \(ci) Temp",
                               unit: .C,
                               type: "IPG CPU",
                               sensorType: .intelTemp,
                               title: String(format: "Core %d".locale, ci),
                               canPlot: AppSd.sensorsInited ? false : true)
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%.f", mean)
      sensor.doubleValue = mean
      sensor.favorite = UDs.bool(forKey: sensor.key)
      coresTemp.append(sensor)
      
      res = PGSample_GetIACoreFrequency(self.sampleID1, self.sampleID2, ci, &mean, &min, &max)
      if res || !AppSd.sensorsInited {
        sensor = HWMonitorSensor(key: "IA \(ci) Freq max",
                                 unit: .GHz,
                                 type: "IPG CPU",
                                 sensorType: .intelCPUFrequency,
                                 title: String(format: "Core %d".locale, ci),
                                 canPlot: AppSd.sensorsInited ? false : true)
        
        sensor.actionType = .cpuLog;
        sensor.stringValue = String(format: "%.3f", mean / 1000)
        sensor.doubleValue = mean
        sensor.favorite = UDs.bool(forKey: sensor.key)
        coresFreq.append(sensor)
      }
    }
    
    return (true, packages, coresFreq, coresTemp)
  }
  
  /// get GPU Sensors from Intel Power Gadget (new header PowerGadgetLib.h)
  private func getIntelPowerGadgetGPUSensorsNew() -> [HWMonitorSensor] {
    var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
    var res : Bool = false
    if self.gtAvailable {
      var value : Double = 0
      PG_ReadSample(self.pkgIndex, &self.sampleGT)
     
      /* May be one day will work
      PGSample_GetGTUtilization(self.sampleGT, &value)
      var sensor = HWMonitorSensor(key: "IGPU Utilization",
                                   unit: .Percent,
                                   type: "IPG",
                                   sensorType: .percent,
                                   title: (AppSd.useIOAcceleratorForGPUs ? "Utilization".locale : "IGPU Utilization".locale),
                                   canPlot: AppSd.sensorsInited ? false : true)
      sensor.actionType = .gpuLog;
      sensor.stringValue = String(format: "%.f", value)
      sensor.doubleValue = value
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
      */
      
      res = PGSample_GetGTFrequency(self.sampleGT, &value)
      
      if res || !AppSd.sensorsInited {
        let sensor = HWMonitorSensor(key: "GT Frequency",
                                     unit: .GHz,
                                     type: "IPG IGPU",
                                     sensorType: .intelGPUFrequency,
                                     title: (AppSd.useIOAcceleratorForGPUs ? "Frequency".locale : "IGPU Frequency".locale),
                                     canPlot: AppSd.sensorsInited ? false : true)
        
        
        sensor.actionType = .gpuLog;
        sensor.stringValue = String(format: "%.3f", value / 1000)
        sensor.doubleValue = value
        sensor.favorite = UDs.bool(forKey: sensor.key)
        sensors.append(sensor)
      }
      
      res = PGSample_GetGTFrequencyRequest(self.sampleGT, &value)
      if res || !AppSd.sensorsInited {
        let sensor = HWMonitorSensor(key: "GT Frequency REQ",
                                     unit: .GHz,
                                     type: "IPG IGPU",
                                     sensorType: .intelGPUFrequency,
                                     title: "Frequency REQ".locale,
                                     canPlot: AppSd.sensorsInited ? false : true)
        
        
        sensor.actionType = .gpuLog;
        sensor.stringValue = String(format: "%.3f", value / 1000)
        sensor.doubleValue = value
        sensor.favorite = UDs.bool(forKey: sensor.key)
        sensors.append(sensor)
      }
      
      res = PG_GetGTMaxFrequency(self.pkgIndex, &value)
      if res {
        let sensor = HWMonitorSensor(key: "GT Frequency MAX",
                                     unit: .GHz,
                                     type: "IPG IGPU",
                                     sensorType: .intelGPUFrequency,
                                     title: "Frequency MAX".locale,
                                     canPlot: AppSd.sensorsInited ? false : true)
        
        sensor.actionType = .gpuLog;
        sensor.stringValue = String(format: "%.3f", value / 1000)
        sensor.doubleValue = value
        sensor.favorite = UDs.bool(forKey: sensor.key)
        sensors.append(sensor)
      }
      
      if self.sampleGT > 0 {
        PGSample_Release(self.sampleGT)
        self.sampleGT = 0
      }
    }
    
    return sensors
  }
}


