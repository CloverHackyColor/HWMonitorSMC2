//
//  IntelPowerGadget.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 07/10/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

struct IPG {
  var inited       : Bool = false
  var packageCore  : Bool = false
  var packageTotal : Bool = false
  var packageIgpu  : Bool = false
}

func getIntelPowerGadgetGPUSensors() -> [HWMonitorSensor] {
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
                               unit: .MHz,
                               type: "IPG",
                               sensorType: .intelGPUFrequency,
                               title: (AppSd.useIOAcceleratorForGPUs ? "Frequency".locale : "IGPU Frequency".locale),
                               canPlot: AppSd.sensorsInited ? false : true)
      
      
      sensor.actionType = .cpuLog;
      sensor.stringValue = String(format: "%d", gtFreq)
      sensor.doubleValue = Double(gtFreq)
      sensor.favorite = UDs.bool(forKey: sensor.key)
      sensors.append(sensor)
    }
    
    var gtMaxFreq : Int32 = 0
    if GetGpuMaxFrequency(&gtMaxFreq) {
      if gtMaxFreq >= 0 {
        let sensor = HWMonitorSensor(key: "Max Frequency",
                                 unit: .MHz,
                                 type: "IPG",
                                 sensorType: .intelGPUFrequency,
                                 title: (AppSd.useIOAcceleratorForGPUs ? "Max Frequency".locale : "IGPU Max Frequency".locale),
                                 canPlot: AppSd.sensorsInited ? false : true)
        
        sensor.isInformativeOnly = true
        sensor.actionType = .cpuLog;
        sensor.stringValue = String(format: "%d", gtMaxFreq)
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
                                         type: "IPG",
                                         sensorType: .igpuPowerWatt,
                                         title: name.locale,
                                         canPlot: AppSd.sensorsInited ? false : true)
            
            
            sensor.actionType = .cpuLog;
            sensor.stringValue = String(format: "%.2f", power)
            sensor.doubleValue = power
            sensor.favorite = UDs.bool(forKey: sensor.key)
            sensors.append(sensor)
            AppSd.ipgStatus.packageIgpu = true
            break
          }
          AppSd.ipgStatus.packageIgpu = true
          break
        }
      }
      
      szName.deallocate()
      data.deallocate()
    }

  }
  return sensors
}

func getIntelPowerGadgetCPUSensors() -> [HWMonitorSensor] {
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
        AppSd.ipgStatus.packageTotal = true
      } else if name == "IA" {
        name = "Package Core"
        AppSd.ipgStatus.packageCore = true
      }
      
      if name != "GT" && (gShowBadSensors || (power >= 0 && power <= 1000)) {
        let sensor = HWMonitorSensor(key: name,
                                     unit: .Watt,
                                     type: "IPG",
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
                               unit: .MHz,
                               type: "IPG",
                               sensorType: .intelCPUFrequency,
                               title: "Frequency".locale,
                               canPlot: AppSd.sensorsInited ? false : true)
  
  if gShowBadSensors || (cpuFrequency >= 0 && cpuFrequency <= 9000) {
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", cpuFrequency)
    sensor.doubleValue = cpuFrequency
    sensor.favorite = UDs.bool(forKey: sensor.key)
    sensors.append(sensor)
  }
  
  if gShowBadSensors || (baseFrequency >= 0 && baseFrequency <= 9000) {
    sensor = HWMonitorSensor(key: "Base Frequency",
                             unit: .MHz,
                             type: "IPG",
                             sensorType: .intelCPUFrequency,
                             title: "Base Frequency".locale,
                             canPlot: false)
    
    
    sensor.isInformativeOnly = true
    sensor.actionType = .cpuLog;
    sensor.stringValue = String(format: "%.f", baseFrequency)
    sensor.doubleValue = baseFrequency
    sensor.favorite = false
    sensors.append(sensor)
  }
  
  
  sensor = HWMonitorSensor(key: "CPU Utilization",
                           unit: .Percent,
                           type: "IPG",
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
                             type: "IPG",
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
                           type: "IPG",
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
                           type: "IPG",
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
                             type: "IPG",
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

