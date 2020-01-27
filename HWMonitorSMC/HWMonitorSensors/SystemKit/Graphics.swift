//
//  Graphics.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 30/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa
import IOKit
import Metal

public struct Graphics {
  fileprivate let Intel_ID  : Data = Data([0x86, 0x80, 0x00, 0x00])
  fileprivate let AMD_ID    : Data = Data([0x02, 0x10, 0x00, 0x00])
  fileprivate let NVidia_ID : Data = Data([0xDE, 0x10, 0x00, 0x00])
  
  fileprivate let kAGP_FreeBytes  = "gartFreeBytes"
  fileprivate let kAGP_UsedBytes  = "gartUsedBytes"
  fileprivate let kVRAM_FreeBytes = "vramFreeBytes"
  fileprivate let kVRAM_UsedBytes = "vramUsedBytes"
  fileprivate let kVid_UsedBytes  = "inUseVidMemoryBytes"
  
  /*
   graphicsCardsSensors() is a replacement for RadeonSensor.kext
   when possible. NVIdia doesn't publish enough information ATM.
   */
  public func graphicsCardsSensors() -> [HWTreeNode] {
    //let ipg : Bool = AppSd.ipgInited
    var nodes : [HWTreeNode] = [HWTreeNode]()
    let list = Graphics.listGraphicsCard()
    for i in 0..<list.count {
      let dict = list[i]
      //print("dict \(i):\n\(dict)\n-----------------------------------------------")
      let vendorID          : Data = dict.object(forKey: "vendor-id") as! Data
      let deviceID          : Data = dict.object(forKey: "device-id") as! Data
      var model             : String = "Unknown" // model can be String/Data
      let modelValue        : Any? = dict.object(forKey: "model")
      
      var vendorString : String = "Unknown"
      if vendorID == NVidia_ID {
        vendorString = "nvidia"
      } else if vendorID == Intel_ID {
        vendorString = "intel"
      } else if vendorID == AMD_ID {
        vendorString = "amd"
      }
      
      if (modelValue != nil) {
        if modelValue is NSString {
          model = modelValue as! String
        } else if modelValue is NSData {
          model = String(data: modelValue as! Data , encoding: .utf8) ?? model
        }
      }
      
      let primaryMatch : String = "0x" +
        String(format: "%02x", deviceID[1]) +
        String(format: "%02x", deviceID[0]) +
        String(format: "%02x", vendorID[1]) +
        String(format: "%02x", vendorID[0])
      
      if AppSd.debugGraphics { dict.writeGraphicsInfo(with: "\(primaryMatch)_\(i)") }
      
      if let PerformanceStatistics = dict.object(forKey: kIOPerformanceStatistics) as? NSDictionary {
        let gpuNode : HWTreeNode = HWTreeNode(representedObject: HWSensorData(group: model,
                                                                              sensor: nil,
                                                                              isLeaf: false))
        let unique : String = "\(primaryMatch)\(i)"
        if let coreclock = PerformanceStatistics.object(forKey: "Core Clock(MHz)") as? NSNumber {
          
          if gShowBadSensors || (coreclock.intValue > 0 && coreclock.intValue < 3000) {
            let ccSensor = HWMonitorSensor(key: "Core Clock" + unique,
                                           unit: .GHz,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_coreClock,
                                           title: "Core Clock".locale,
                                           canPlot: false)
            
            ccSensor.favorite = UDs.bool(forKey: ccSensor.key)
            ccSensor.characteristics = primaryMatch
            ccSensor.actionType = .gpuLog
            ccSensor.doubleValue = coreclock.doubleValue
            ccSensor.stringValue = String(format: "%.3f", coreclock.doubleValue / 1000)
            ccSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: ccSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        if let memclock = PerformanceStatistics.object(forKey: "Memory Clock(MHz)") as? NSNumber {
          
          if gShowBadSensors || (memclock.intValue > 0 && memclock.intValue < 3000) {
            let mcSensor = HWMonitorSensor(key: "Memory Clock" + unique,
                                           unit: .GHz,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_memoryClock,
                                           title: "Memory Clock".locale,
                                           canPlot: false)
            
            mcSensor.favorite = UDs.bool(forKey: mcSensor.key)
            mcSensor.characteristics = primaryMatch
            mcSensor.actionType = .gpuLog
            mcSensor.doubleValue = memclock.doubleValue
            mcSensor.stringValue = String(format: "%.3f", memclock.doubleValue / 1000)
            mcSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: mcSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        if let totalPower = PerformanceStatistics.object(forKey: "Total Power(W)") as? NSNumber {
          if gShowBadSensors || (totalPower.intValue > 0 && totalPower.intValue < 1000) {
            let tpSensor = HWMonitorSensor(key: "Total Power(W)" + unique,
                                           unit: HWUnit.Watt,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_Watts,
                                           title: "Total Power".locale,
                                           canPlot: true)
            tpSensor.favorite = UDs.bool(forKey: tpSensor.key)
            tpSensor.characteristics = primaryMatch
            tpSensor.actionType = .gpuLog
            tpSensor.doubleValue = totalPower.doubleValue
            tpSensor.stringValue = totalPower.stringValue
            tpSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: tpSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        if let temperature = PerformanceStatistics.object(forKey: "Temperature(C)") as? NSNumber {
          if gShowBadSensors || (temperature.intValue >= -15 && temperature.intValue <= 125) {
            let tempSensor = HWMonitorSensor(key: "Temperature" + unique,
                                             unit: HWUnit.C,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_temp,
                                             title: "Temperature".locale,
                                             canPlot: true)
            tempSensor.favorite = UDs.bool(forKey: tempSensor.key)
            tempSensor.characteristics = primaryMatch
            tempSensor.actionType = .gpuLog
            tempSensor.doubleValue = temperature.doubleValue
            tempSensor.stringValue = temperature.stringValue
            tempSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: tempSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        if let fanSpeed = PerformanceStatistics.object(forKey: "Fan Speed(RPM)") as? NSNumber {
          //if gShowBadSensors || (fanSpeed.intValue > 0 && fanSpeed.intValue < 7000) {
            let fanSensor = HWMonitorSensor(key: "Fan/Pump Speed" + unique,
                                            unit: HWUnit.RPM,
                                            type: "IOAcc",
                                            sensorType: .gpuIO_FanRPM,
                                            title: "Fan/Pump speed".locale,
                                            canPlot: true)
            
            fanSensor.favorite = UDs.bool(forKey: fanSensor.key)
            fanSensor.characteristics = primaryMatch
            fanSensor.actionType = .gpuLog
            fanSensor.doubleValue = fanSpeed.doubleValue
            fanSensor.stringValue = fanSpeed.stringValue
            fanSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: fanSensor,
                                                                                   isLeaf: true)))
          //}
        }
        
        if let fanSpeed100 = PerformanceStatistics.object(forKey: "Fan Speed(%)") as? NSNumber {
          //if gShowBadSensors || (fanSpeed100.intValue > 0 && fanSpeed100.intValue <= 100) {
            let fan100Sensor = HWMonitorSensor(key: "Fan/Pump Speed rate" + unique,
                                               unit: HWUnit.Percent,
                                               type: "IOAcc",
                                               sensorType: .gpuIO_percent,
                                               title: "Fan/Pump speed rate".locale,
                                               canPlot: true)
            
            fan100Sensor.favorite = UDs.bool(forKey: fan100Sensor.key)
            fan100Sensor.characteristics = primaryMatch
            fan100Sensor.actionType = .gpuLog
            fan100Sensor.doubleValue = fanSpeed100.doubleValue
            fan100Sensor.stringValue = fanSpeed100.stringValue
            fan100Sensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: fan100Sensor,
                                                                                   isLeaf: true)))
          //}
        }
        
        if let deviceUtilization = PerformanceStatistics.object(forKey: "Device Utilization %") as? NSNumber {
          if gShowBadSensors || (deviceUtilization.intValue >= 0 && deviceUtilization.intValue <= 100) {
            let duSensor = HWMonitorSensor(key: "Device Utilization" + unique,
                                           unit: HWUnit.Percent,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_percent,
                                           title: "Utilization".locale,
                                           canPlot: true)
            
            duSensor.favorite = UDs.bool(forKey: duSensor.key)
            duSensor.characteristics = primaryMatch
            duSensor.actionType = .gpuLog
            duSensor.doubleValue = deviceUtilization.doubleValue
            duSensor.stringValue = deviceUtilization.stringValue
            duSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: duSensor,
                                                                                   isLeaf: true)))
          }
        }
        
        if vendorID == NVidia_ID {
          if let gpuCoreUtilization = PerformanceStatistics.object(forKey: "GPU Core Utilization") as? NSNumber {
            var gcuInt = gpuCoreUtilization.intValue
            if gcuInt >= 10000000 {
              gcuInt = gcuInt / 10000000
            }
            if gShowBadSensors || (gcuInt >= 0 && gcuInt <= 100) {
              let gcuSensor = HWMonitorSensor(key: "GPU Core Utilization" + unique,
                                              unit: HWUnit.Percent,
                                              type: "IOAcc",
                                              sensorType: .gpuIO_percent,
                                              title: "Core Utilization".locale,
                                              canPlot: true)
              
              gcuSensor.favorite = UDs.bool(forKey: gcuSensor.key)
              gcuSensor.characteristics = primaryMatch
              gcuSensor.actionType = .gpuLog
              gcuSensor.doubleValue = Double(gcuInt)
              gcuSensor.stringValue = "\(gcuInt)"
              gcuSensor.vendor = vendorString
              gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                     sensor: gcuSensor,
                                                                                     isLeaf: true)))
            }
          }
        }
        
        if let gpuActivity = PerformanceStatistics.object(forKey: "GPU Activity(%)") as? NSNumber {
          if gShowBadSensors || (gpuActivity.intValue >= 0 && gpuActivity.intValue <= 100) {
            let gaSensor = HWMonitorSensor(key: "GPU Activity" + unique,
                                           unit: HWUnit.Percent,
                                           type: "IOAcc",
                                           sensorType: .gpuIO_percent,
                                           title: "Activity".locale,
                                           canPlot: true)
            
            gaSensor.favorite = UDs.bool(forKey: gaSensor.key)
            gaSensor.characteristics = primaryMatch
            gaSensor.actionType = .gpuLog
            gaSensor.doubleValue = gpuActivity.doubleValue
            gaSensor.stringValue = gpuActivity.stringValue
            gaSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: gaSensor,
                                                                                   isLeaf: true)))
          }
        }
        /*
        for i in 0..<1 /*0x0A*/ { // limited to Device Unit 0 Utilization
          if let deunUtilization = PerformanceStatistics.object(forKey: "Device Unit \(i) Utilization %") as? NSNumber {
            
            let dunuSensor = HWMonitorSensor(key: "Device Unit \(i) Utilization" + unique,
                                             unit: HWUnit.Percent,
                                             type: "IOAcc",
                                             sensorType: .gpuIO_percent,
                                             title: String(format: "Device Unit %d Utilization".locale(), i),
                                             canPlot: true)
            
            dunuSensor.favorite = UDs.bool(forKey: dunuSensor.key)
            dunuSensor.characteristics = primaryMatch
            dunuSensor.logType = .gpuLog
            dunuSensor.doubleValue = deunUtilization.doubleValue
            dunuSensor.stringValue = deunUtilization.stringValue
            dunuSensor.vendor = vendorString
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: dunuSensor,
                                                                                   isLeaf: true)))
          }
        }*/
        
        if vendorID == NVidia_ID {
          if let gpuEngineUtilization = PerformanceStatistics.object(forKey: "GPU Video Engine Utilization") as? NSNumber {
            if gShowBadSensors || (gpuEngineUtilization.intValue >= 0 && gpuEngineUtilization.intValue <= 100) {
              let gveuSensor = HWMonitorSensor(key: "GPU Video Engine Utilization" + unique,
                                               unit: HWUnit.Percent,
                                               type: "IOAcc",
                                               sensorType: .gpuIO_percent,
                                               title: "Video Engine Utilization".locale,
                                               canPlot: true)
              
              gveuSensor.favorite = UDs.bool(forKey: gveuSensor.key)
              gveuSensor.characteristics = primaryMatch
              gveuSensor.actionType =  .gpuLog
              gveuSensor.doubleValue = gpuEngineUtilization.doubleValue
              gveuSensor.stringValue = gpuEngineUtilization.stringValue
              gveuSensor.vendor = vendorString
              gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                     sensor: gveuSensor,
                                                                                     isLeaf: true)))
            }
          }
        }
        
        if let memorySensors = self.getMemorySensors(statistics: PerformanceStatistics,
                                                     unique: primaryMatch,
                                                     vendor: vendorString) {
          for ms in memorySensors {
            gpuNode.mutableChildren.add(HWTreeNode(representedObject: HWSensorData(group: model,
                                                                                   sensor: ms,
                                                                                   isLeaf: true)))
          }
        }

        if vendorID == Intel_ID {
          if (AppSd.ipg != nil && AppSd.ipg!.inited) {
            for s in AppSd.ipg!.getIntelPowerGadgetGPUSensors() {
              let ipgSensor = HWTreeNode(representedObject: HWSensorData(group: model,
                                                                         sensor: s,
                                                                         isLeaf: true))
              gpuNode.mutableChildren.add(ipgSensor)
            }
          }
          
          if !(AppSd.ipg != nil && AppSd.ipg!.packageIgpu) {
            if let ipp = AppSd.sensorScanner.getIGPUPackagePower() {
              let IGPUPackage = HWTreeNode(representedObject: HWSensorData(group: model,
                                                                           sensor: ipp,
                                                                           isLeaf: true))
              gpuNode.mutableChildren.add(IGPUPackage)
            }
          }
        }
        
        nodes.append(gpuNode)
      }
    }
    AppSd.debugGraphics = false
    return nodes
  }

  fileprivate func getMemorySensors(statistics: NSDictionary,
                                    unique: String,
                                    vendor: String) ->[HWMonitorSensor]? {
    var valid : Bool = false
    var free : Int64 = (statistics.object(forKey: kVRAM_FreeBytes) as? Int64) ?? 0
    var used : Int64 = (statistics.object(forKey: kVRAM_UsedBytes) as? Int64) ?? 0
    
    if free > 0 && used > 0 { valid = true }
    
    if !valid {
      free = (statistics.object(forKey: kVRAM_FreeBytes) as? Int64) ?? 0
      used = (statistics.object(forKey: kVid_UsedBytes) as? Int64) ?? 0
      if free > 0 && used > 0 { valid = true }
    }
    
    if !valid {
      free = (statistics.object(forKey: kAGP_FreeBytes) as? Int64) ?? 0
      used = (statistics.object(forKey: kAGP_UsedBytes) as? Int64) ?? 0
      if free > 0 && used > 0 { valid = true }
    }
    
    if gShowBadSensors || valid {
      let freeS = HWMonitorSensor(key: "Free VRAM" + unique,
                                       unit: HWUnit.none,
                                       type: "IOAcc",
                                       sensorType: .gpuIO_RamBytes,
                                       title: "Free VRAM".locale,
                                       canPlot: false)
      
      freeS.favorite = UDs.bool(forKey: freeS.key)
      freeS.characteristics = unique
      freeS.actionType = .gpuLog
      freeS.doubleValue = Double(free)
      freeS.stringValue = BytesFormatter.init(bytes: free, countStyle: 1024).stringValue()
      freeS.vendor = vendor
      
      let usedS = HWMonitorSensor(key: "Used VRAM" + unique,
                                  unit: HWUnit.none,
                                  type: "IOAcc",
                                  sensorType: .gpuIO_RamBytes,
                                  title: "Used VRAM".locale,
                                  canPlot: false)
      
      usedS.favorite = UDs.bool(forKey: usedS.key)
      usedS.characteristics = unique
      usedS.actionType = .gpuLog
      usedS.doubleValue = Double(used)
      usedS.stringValue = BytesFormatter.init(bytes: used, countStyle: 1024).stringValue()
      usedS.vendor = vendor
      
      return [freeS, usedS]
    } else {
      return nil
    }
  }
  
  public func getGraphicsInfo(acpiPathOrPrimaryMatch: String?, index: Int) -> String {
    var log : String = ""
    let list = Graphics.listGraphicsCard()
    for i in 0..<list.count {
      let path : String? = list[i].object(forKey: "acpi-path") as? String
      if (acpiPathOrPrimaryMatch != nil && path != nil) {
        if path != nil {
          if acpiPathOrPrimaryMatch?.lowercased() == path!.lowercased() && i == index {
            log += self.getVideoCardLog(from: list[i], cardNumber: i)
            break
          }
        }
        let vendorID : Data = list[i].object(forKey: "vendor-id") as! Data
        let deviceID : Data = list[i].object(forKey: "device-id") as! Data
        let pm : String = "0x" +
          String(format: "%02x", deviceID[1]) +
          String(format: "%02x", deviceID[0]) +
          String(format: "%02x", vendorID[1]) +
          String(format: "%02x", vendorID[0])
        if pm.lowercased() == acpiPathOrPrimaryMatch?.lowercased() && i == index {
          log += self.getVideoCardLog(from: list[i], cardNumber: i)
          break
        }
      } else {
        log += self.getVideoCardLog(from: list[i], cardNumber: i)
      }
    }
    return log
  }
  
  /*
   getVideoCardLog() returns a log for a specific card at index
   */
  fileprivate func getVideoCardLog(from dictionary: NSDictionary, cardNumber: Int) -> String {
    var log : String = ""
    var vramLogged : Bool = false
    log += "VIDEO CARD \(cardNumber + 1):\n"
    
    // expected values:
    var model             : String = "Unknown" // model can be String/Data
    let modelValue        : Any? = dictionary.object(forKey: "model")
    let vendorID          : Data = dictionary.object(forKey: "vendor-id") as! Data
    let deviceID          : Data = dictionary.object(forKey: "device-id") as! Data
    let classcode         : Data = dictionary.object(forKey: "class-code") as! Data
    let revisionID        : Data = dictionary.object(forKey: "revision-id") as! Data
    let subsystemID       : Data = dictionary.object(forKey: "subsystem-id") as! Data
    let subsystemVendorID : Data = dictionary.object(forKey: "subsystem-vendor-id") as! Data
    let acpiPath : String? = (dictionary.object(forKey: "acpi-path") as? String)
    
    if (modelValue != nil) {
      if modelValue is NSString {
        model = modelValue as! String
      } else if modelValue is NSData {
        model = String(data: modelValue as! Data , encoding: .utf8) ?? model
      }
    }
    
    log += "\tModel:\t\t\t\t\(model)\n"
    log += "\tVendor ID:\t\t\t\t\(vendorID.hexadecimal()) (\(vendorStringFromData(data: vendorID)))\n"
    log += "\tDevice ID:\t\t\t\t\(deviceID.hexadecimal())\n"
    log += "\tRevision ID:\t\t\t\(revisionID.hexadecimal())\n"
    log += "\tSubsystem Vendor ID:\t\t\(subsystemVendorID.hexadecimal())\n"
    log += "\tSubsystem ID:\t\t\t\(subsystemID.hexadecimal())\n"
    log += "\tclass-code:\t\t\t\t\(classcode.hexadecimal())\n"
    // optional values
    if let ioName : String = dictionary.object(forKey: "IOName") as? String {
      log += "\tIOName:\t\t\t\t\(ioName)\n"
    }
    if let pcidebug : String = dictionary.object(forKey: "pcidebug") as? String {
      log += "\tpcidebug:\t\t\t\t\(pcidebug)\n"
    }
    if let builtin : Data = dictionary.object(forKey: "built-in") as? Data {
      log += "\tbuilt-in:\t\t\t\t\(builtin.hexadecimal())\n"
    }
    if let compatible : Data = dictionary.object(forKey: "compatible") as? Data {
      log += "\tcompatible:\t\t\t\(String(data: compatible, encoding: .utf8) ?? "Unknown")\n"
    }
    
    log += "\tacpi-path:\t\t\t\t\(acpiPath ?? "unknown")\n"
    
    if let hdagfx : Data = dictionary.object(forKey: "hda-gfx") as? Data {
      log += "\thda-gfx:\t\t\t\t\(String(data: hdagfx, encoding: .utf8) ?? "Unknown")\n"
    }
    
    // NVidia property (mostly)
    if let rmBoardNm : Data = dictionary.object(forKey: "rm_board_number") as? Data {
      log += "\trm_board_number:\t\t\(rmBoardNm.hexadecimal())\n"
    }
    if let noEFI : Data = dictionary.object(forKey: "NVDA,noEFI") as? Data {
      log += "\tNVDA,noEFI:\t\t\t\(String(data: noEFI, encoding: .utf8) ?? "Unknown")\n"
    }
    if let nVArch : String = dictionary.object(forKey: "NVArch") as? String {
      log += "\tNVArch:\t\t\t\t\t\(nVArch)\n"
    }
    if let romRev : Data = dictionary.object(forKey: "rom-revision") as? Data {
      log += "\trom-revision:\t\t\t\t\(String(data: romRev, encoding: .utf8) ?? "Unknown")\n"
    }
    if let nVClass : String = dictionary.object(forKey: "NVCLASS") as? String {
      log += "\tNVCLASS:\t\t\t\t\(nVClass)\n"
    }
    if let ncCap : Data = dictionary.object(forKey: "NVCAP") as? Data {
      log += "\tNVCAP:\t\t\t\t\(ncCap.hexadecimal())\n"
    }
    if let aspm : NSNumber = dictionary.object(forKey: "pci-aspm-default") as? NSNumber {
      log += "\tpci-aspm-default:\t\t\t\t\(String(format: "0x%X", aspm.intValue))\n"
    }
    if let vram : Data = dictionary.object(forKey: "VRAM,totalMB") as? Data {
      log += "\tVRAM,totalMB:\t\t\t\(vram.hexadecimal())\n"
      vramLogged = true
    }
    if let deviceType : Data = dictionary.object(forKey: "device_type") as? Data {
      log += "\tdevice_type:\t\t\t\(String(data: deviceType, encoding: .utf8) ?? "Unknown")\n"
    }
    if let accelLoaded : Data = dictionary.object(forKey: "NVDA,accel-loaded") as? Data {
      log += "\tNVDA,accel-loaded:\t\t\(accelLoaded.hexadecimal())\n"
    }
    if let vbiosRev : Data = dictionary.object(forKey: "vbios-revision") as? Data {
      log += "\tvbios-revision:\t\t\t\(vbiosRev.hexadecimal())\n"
    }
    if let nvdaFeatures : Data = dictionary.object(forKey: "NVDA,Features") as? Data {
      log += "\tvNVDA,Features:\t\t\t\(nvdaFeatures.hexadecimal())\n"
    }
    if let nvramProperty : Bool = dictionary.object(forKey: "IONVRAMProperty") as? Bool {
      log += "\tIONVRAMProperty:\t\t\t\(nvramProperty)\n"
    }
    if let initgl : String = dictionary.object(forKey: "NVDAinitgl_created") as? String {
      log += "\tNVDAinitgl_created:\t\t\(initgl)\n"
    }
    if let pciMSImode : Bool = dictionary.object(forKey: "IOPCIMSIMode") as? Bool {
      log += "\tIOPCIMSIMode\t\t\t\(pciMSImode)\n"
    }
    if let nvdaType : String = dictionary.object(forKey: "NVDAType") as? String {
      log += "\tNVDAType:\t\t\t\t\(nvdaType)\n"
    }
    
    log += "\tAdditional Properties:\n"
    if let aapls = getProperties(with: "AAPL", in: dictionary) {
      for key in (aapls.keys) {
        log += "\(key)\(aapls[key]!)\n"
      }
    }
    if let snail = getProperties(with: "@", in: dictionary) {
      for key in (snail.keys) {
        log += "\(key)\(snail[key]!)\n"
      }
    }
    if let aty = getProperties(with: "ATY", in: dictionary) {
      for key in (aty.keys) {
        log += "\(key)\(aty[key]!)\n"
      }
    }
    
    if #available(OSX 10.11, *) {
      if let metal: MTLDevice = dictionary.object(forKey: kMetalDevice) as? MTLDevice {
        if #available(OSX 10.12, *) {
          log += "\tMetal properties:\n"
          log += "\t\tRecommended Max Working Set Size:\t\(String(format: "0x%X", metal.recommendedMaxWorkingSetSize))\n"
          log += "\t\tMax Threads Per Thread group: width \(metal.maxThreadsPerThreadgroup.width), height \(metal.maxThreadsPerThreadgroup.height), depth \(metal.maxThreadsPerThreadgroup.depth)\n"
          log += "\t\tDepth 24 Stencil 8 Pixel Format:\t\t\(metal.isDepth24Stencil8PixelFormatSupported)\n"
          if #available(OSX 10.13, *) {
            log += "\t\tMax Thread group Memory Length:\t\(metal.maxThreadgroupMemoryLength)\n"
            log += "\t\tProgrammable Sample Positions:\t\t\(metal.areProgrammableSamplePositionsSupported)\n"
            log += "\t\tRead-Write Texture:\t\t\t\t\(metal.readWriteTextureSupport.rawValue)\n"
            log += "\t\tRemovable:\t\t\t\t\t\t\(metal.isRemovable)\n"
          }
          log += "\t\tHeadless:\t\t\t\t\t\t\(metal.isHeadless)\n"
          log += "\t\tIs Low Power:\t\t\t\t\t\(metal.isLowPower)\n"
        }
      } else {
        log += "\tMetal support: false\n"
      }
    }
    
    if let PerformanceStatistics = dictionary.object(forKey: "PerformanceStatistics") as? NSDictionary {
      if let performances = getPerformanceStatistics(in: PerformanceStatistics) {
        log += "\tPerformance Statistics:\n"
        for key in (performances.keys) {
          log += "\(key)\(performances[key]!)\n"
        }
      }
    }
    if !vramLogged {
      if let vram : NSNumber = dictionary.object(forKey: "VRAM,totalMB") as? NSNumber {
        log += "\tVRAM,totalMB: \(vram.intValue)\n"
        vramLogged = true
      }
    }
    return log
  }
  /*
   getProperties() return all properties that starts with a prefix (like "AAPL")! for the given dictionary
   This ensure that all of it are shown in the log without effectively be aware of them.
   */
  fileprivate func getProperties(with prefix: String, in dict : NSDictionary) -> [String: String]? {
    // black listed keys: they are too long to be showned in the log
    //TODO: make a new method to format text with long data lenght with the possibility of truncate it or not
    let blackList : [String] = ["ATY,bin_image", "ATY,PlatformInfo", "AAPL,EMC-Display-List"]
    
    let fontAttr =  [NSAttributedString.Key.font : gLogFont] // need to count a size with proportional font
    var properties : [String: String] = [String: String]()
    let allKeys = dict.allKeys // are as [Any]
    var maxLength : Int = 0
    let sep = ": "
    let ind = "\t\t"
    
    // get the max length of the string and all the valid keys
    for k in allKeys {
      let key : String = (k as! String).trimmingCharacters(in: .whitespacesAndNewlines)
      if !blackList.contains(key) {
        if key.hasPrefix(prefix) {
          let keyL : Int = Int(key.size(withAttributes: fontAttr).width)
          if keyL > maxLength {
            maxLength = keyL
          }
          
          var value : String? = nil
          if let raw : Any = dict.object(forKey: key) {
            if raw is NSString {
              value = (raw as! String)
            } else if raw is NSData {
              let data : Data = (raw as! Data)
              value = "\(data.hexadecimal())"
            } else if raw is NSNumber {
              value = "\((raw as! NSNumber).intValue)"
            }
          }
          
          if (value != nil) {
            properties[key] = value
          }
        }
      }
    }
    
    if prefix.hasPrefix("@") {
      // don't know why, if string starts with @ needs the follow
      maxLength +=  Int("@".size(withAttributes: fontAttr).width)
    }
    
    // return with formmatted keys already
    if properties.keys.count > 0 {
      var validProperties : [String : String] = [String : String]()
      maxLength += Int(sep.size(withAttributes: fontAttr).width)
      for key in properties.keys {
        var keyPadded : String = key + sep
        while Int(keyPadded.size(withAttributes: fontAttr).width) < maxLength + 1 {
          keyPadded += " "
        }
        validProperties[ind + keyPadded + "\t"] = properties[key]
      }
      return validProperties
    }
    
    return nil
  }
  
  /*
   vendorStringFromData() return the GPU vendor name string
   */
  fileprivate func vendorStringFromData(data: Data) -> String {
    var vendor = "Unknown"
    if data ==  Intel_ID {
      vendor = "Intel"
    } else if data ==  AMD_ID {
      vendor = "ATI/AMD"
    } else if data ==  NVidia_ID {
      vendor = "NVidia"
    }
    return vendor
  }
  
  /*
   listGraphicsCard() returns all the pci-GPU in the System
   */
  fileprivate static func listGraphicsCard() -> [NSDictionary] {
    var cards : [NSDictionary] = [NSDictionary]()
    let GPU_CLASS_CODE : Data = Data([0x00, 0x00, 0x03, 0x00])
    let GPU_CLASS_CODE_OTHER : Data = Data([0x00, 0x80, 0x03, 0x00])
    let GPU_CLASS_CODE_3D : Data = Data([0x00, 0x02, 0x03, 0x00])
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IOServiceMatching("IOPCIDevice")
    
    let ret = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if ret == KERN_SUCCESS && iter != 0 {
      var metals : Any? = nil
      if #available(OSX 10.11, *) {
        metals = MTLCopyAllDevices()
      }
      repeat {
        serviceObject = IOIteratorNext(iter)
        let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
        var serviceDictionary : Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(serviceObject,
                                             &serviceDictionary,
                                             kCFAllocatorDefault, opt) != kIOReturnSuccess {
          IOObjectRelease(serviceObject)
          continue
        }
        if let info : NSMutableDictionary = serviceDictionary?.takeRetainedValue() {
          if let classcode : Data = info.object(forKey: "class-code") as? Data {
            if classcode == GPU_CLASS_CODE ||
              classcode == GPU_CLASS_CODE_3D ||
              classcode == GPU_CLASS_CODE_OTHER {
              
              var child_iter : io_iterator_t = 0
              let kr = IORegistryEntryGetChildIterator(serviceObject, kIOServicePlane, &child_iter);
              if kr == KERN_SUCCESS && child_iter != 0 {
                var child = io_registry_entry_t()
                repeat {
                  child = IOIteratorNext( child_iter )
                  if let ps : NSDictionary = IORegistryEntrySearchCFProperty(serviceObject,
                                                                             kIOServicePlane,
                                                                             kIOPerformanceStatistics as CFString,
                                                                             kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively)) as? NSDictionary {
                    info.setValue(ps, forKey: kIOPerformanceStatistics)
                    if (metals != nil) {
                      if #available(OSX 10.13, *) {
                        for c in (metals as! [MTLDevice]) {
                          if let metalDict = getInfo(with: c.registryID) {
                            if (metalDict.object(forKey: "vendor-id") != nil &&
                              metalDict.object(forKey: "device-id") != nil &&
                              metalDict.object(forKey: "subsystem-vendor-id") != nil &&
                              metalDict.object(forKey: "subsystem-id") != nil &&
                              metalDict.object(forKey: "revision-id") != nil &&
                              info.object(forKey: "vendor-id") != nil &&
                              info.object(forKey: "device-id") != nil &&
                              info.object(forKey: "subsystem-vendor-id") != nil &&
                              info.object(forKey: "subsystem-id") != nil &&
                              info.object(forKey: "revision-id") != nil) {
                              if (
                                (metalDict.object(forKey: "vendor-id") as! Data) == (info.object(forKey: "vendor-id") as! Data) &&
                                  (metalDict.object(forKey: "device-id") as! Data) == (info.object(forKey: "device-id") as! Data) &&
                                  (metalDict.object(forKey: "subsystem-vendor-id") as! Data) == (info.object(forKey: "subsystem-vendor-id") as! Data) &&
                                  (metalDict.object(forKey: "subsystem-id") as! Data) == (info.object(forKey: "subsystem-id") as! Data) &&
                                  (metalDict.object(forKey: "revision-id") as! Data) == (info.object(forKey: "revision-id") as! Data)
                                ) {
                                info.setValue(c, forKey: kMetalDevice)
                                break
                              }
                              
                            }
                          }
                        }
                      }
                    }
                    cards.append(info)
                    break
                  }
                } while child != 0
                
                IOObjectRelease(child_iter)
              }
            }
          }
        }
        IOObjectRelease(serviceObject)
      } while serviceObject != 0
      IOObjectRelease(iter)
    }
    return cards
  }
  
  fileprivate static func getInfo(with entryID : UInt64) -> NSDictionary? {
    var dict : NSDictionary? = nil
    var serviceObject : io_object_t
    var iter : io_iterator_t = 0
    let matching = IORegistryEntryIDMatching(entryID)
    let ret = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if ret == KERN_SUCCESS && iter != 0 {
      repeat {
        serviceObject = IOIteratorNext(iter)
        let opt : IOOptionBits = IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
        var serviceDictionary : Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(serviceObject,
                                             &serviceDictionary,
                                             kCFAllocatorDefault, opt) != kIOReturnSuccess {
          IOObjectRelease(serviceObject)
          continue
        }
        
        if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
          if let vendorId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                     kIOServicePlane,
                                                                     "vendor-id" as CFString,
                                                                     kCFAllocatorDefault, opt) as? NSData {
            info.setValue(vendorId, forKey: "vendor-id")
          }
          if let devId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                  kIOServicePlane,
                                                                  "device-id" as CFString,
                                                                  kCFAllocatorDefault, opt) as? NSData {
            info.setValue(devId, forKey: "device-id")
          }
          if let revId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                  kIOServicePlane,
                                                                  "revision-id" as CFString,
                                                                  kCFAllocatorDefault, opt) as? NSData {
            info.setValue(revId, forKey: "revision-id")
          }
          if let subSysId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                     kIOServicePlane,
                                                                     "subsystem-id" as CFString,
                                                                     kCFAllocatorDefault, opt) as? NSData {
            info.setValue(subSysId, forKey: "subsystem-id")
          }
          if let subSysVenId : NSData = IORegistryEntrySearchCFProperty(serviceObject,
                                                                        kIOServicePlane,
                                                                        "subsystem-vendor-id" as CFString,
                                                                        kCFAllocatorDefault, opt) as? NSData {
            info.setValue(subSysVenId, forKey: "subsystem-vendor-id")
          }
          /*
           if let model : NSString = IORegistryEntrySearchCFProperty(serviceObject, kIOServicePlane, "model" as CFString, kCFAllocatorDefault, opt) as? NSString {
           print(model)
           info.setValue(model, forKey: "model")
           }*/
          if let acpipath : NSString = IORegistryEntrySearchCFProperty(serviceObject,
                                                                       kIOServicePlane,
                                                                       "acpi-path" as CFString,
                                                                       kCFAllocatorDefault, opt) as? NSString {
            //print(acpipath)
            info.setValue(acpipath, forKey: "acpi-path")
          } else {
            info.setValue("unknown" as NSString, forKey: "acpi-path")
          }
          dict = info
        }
        IOObjectRelease(serviceObject)
      } while serviceObject != 0
      IOObjectRelease(iter)
    }
    return dict
  }
  
  /*
   getPerformanceStatistics() return a dictionary with object and keys already formatted for our log
   */
  fileprivate func getPerformanceStatistics(in dict : NSDictionary) -> [String: String]? {
    let fontAttr =  [NSAttributedString.Key.font : gLogFont] // need to count a size with proportional font
    var properties : [String: String] = [String: String]()
    let allKeys = dict.allKeys // are as [Any]
    var maxLength : Int = 0
    let sep = ": "
    let ind = "\t\t"
    
    // get the max length of the string and all the valid keys
    for k in allKeys {
      let key : String = (k as! String).trimmingCharacters(in: .whitespacesAndNewlines)
      let keyL : Int = Int(key.size(withAttributes: fontAttr).width)
      if keyL > maxLength {
        maxLength = keyL
      }
      
      var value : String? = nil
      if let raw : Any = dict.object(forKey: key) {
        if raw is NSString {
          value = (raw as! String)
        } else if raw is NSData {
          let data : Data = (raw as! Data)
          value = "\(data.hexadecimal())"
        } else if raw is NSNumber {
          value = "\((raw as! NSNumber).intValue)"
        }
      }
      
      if (value != nil) {
        properties[key] = value
      }
    }
    
    // return with formmatted keys already
    if properties.keys.count > 0 {
      var validProperties : [String : String] = [String : String]()
      maxLength += Int(sep.size(withAttributes: fontAttr).width)
      for key in properties.keys {
        var keyPadded : String = key + sep
        while Int(keyPadded.size(withAttributes: fontAttr).width) < maxLength + 1 {
          keyPadded += " "
        }
        validProperties[ind + keyPadded + "\t"] = properties[key]
      }
      return validProperties
    }
    
    return nil
  }
}

