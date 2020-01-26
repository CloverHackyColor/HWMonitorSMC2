//
//  HWSMART.swift
//  SmarterSwift
//
//  Created by vector sigma on 25/03/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//
//  Swift port of smartmontools at https://www.smartmontools.org/browser
//
//  Thanks @fabiosun for tens of tests made with his hardware (Sata/NVMe SSD and rotational HDDs)
//
//  Released under GPLv3 license (https://www.gnu.org/licenses/gpl-3.0.en.html)
//

import Foundation
import IOKit.storage
import DiskArbitration
import IOKit.storage.ata

let kArbitrationKey                       = "Arbitration"

let kSMARTAttributesDictKey               = "SMARTAttributes"
let kSMARTDataDictKey                     = "SMARTData"
let kIOPropertyNVMeSMARTCapableKey        = "NVMe SMART Capable"
let kATASMARTUserClientClassKey           = "ATASMARTUserClient"

let kNVMeSMARTCriticalWarningKey          = "Critical Warning"
let kNVMeSMARTTemperatureKey              = "Temperature"
let kNVMeSMARTAvailableSpareKey           = "Available Spare"
let kNVMeSMARTAvailableSpareThresholdKey  = "Available Spare Threshold"
let kNVMeSMARTUnsafeShutdownsKey          = "Unsafe Shutdowns"
let kSMARTLifeKey                         = "Life"

let kATASMARTCurrentValueKey              = "CurrentValue"
let kATASMARTWorstValueKey                = "WorstValue"
let kATASMARTRawValueKey                  = "RawValue"
let kATASMARTThresholdKey                 = "Threshold"
let kATASMARTPrefailKey                   = "Pre-fail"
let kATASMARTflagKey                      = "flag"

let kIsNVMeKey                            = "isNVME"
let kSMARTStatus                          = "SMARTStatus"
let kSMARTTemperatureNotFound : Int       = 0xffff

let kIONVMeSMARTUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0xAA, 0x0F, 0xA6, 0xF9,
                                                                  0xC2, 0xD6, 0x45, 0x7F,
                                                                  0xB1, 0x0B, 0x59, 0xA1,
                                                                  0x32, 0x53, 0x29, 0x2F)

let kIONVMeSMARTInterfaceID =      CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0xCC, 0xD1, 0xDB, 0x19,
                                                                  0xFD, 0x9A, 0x4D, 0xAF,
                                                                  0xBF, 0x95, 0x12, 0x45,
                                                                  0x4B, 0x23, 0x0A, 0xB6)


let kIOATASMARTInterfaceID =       CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0x08, 0xAB, 0xE2, 0x1C,
                                                                  0x20, 0xD4, 0x11, 0xD6,
                                                                  0x8D, 0xF6, 0x00, 0x03,
                                                                  0x93, 0x5A, 0x76, 0xB2)

let kIOATASMARTUserClientTypeID =  CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0x24, 0x51, 0x4B, 0x7A,
                                                                  0x28, 0x04, 0x11, 0xD6,
                                                                  0x8A, 0x02, 0x00, 0x30,
                                                                  0x65, 0x70, 0x48, 0x66)

let kIOCFPlugInInterfaceID =       CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0xC2, 0x44, 0xE8, 0x58,
                                                                  0x10, 0x9C, 0x11, 0xD4,
                                                                  0x91, 0xD4, 0x00, 0x50,
                                                                  0xE4, 0xC6, 0x42, 0x6F)

struct ATASMARTAttribute {
  var attributeID: UInt8 = 0
  var flag: UInt16 = 0
  var currentValue: UInt8 = 0
  var worstValue: UInt8 = 0
  var rawValue = [UInt8](repeating: 0, count: 6)
  var reserved: UInt8 = 0
}

struct VendorSpecificData {
  var revisonNumber: UInt16 = 0
  var vendorAttributes = [ATASMARTAttribute](repeating: ATASMARTAttribute(), count: 30)
  init(from data: Data) {
    var byteIndex : Int = 0
    var array30Count = 0
    while byteIndex <= (data.count - 12) {
      if byteIndex == 0 {
        self.revisonNumber = UInt16(data[0] + data[1])
        byteIndex+=2
      } else {
        var sattr : ATASMARTAttribute = ATASMARTAttribute()
        sattr.attributeID = data[byteIndex]
        sattr.flag = UInt16(data[byteIndex + 1] + data[byteIndex + 2])
        sattr.currentValue = data[byteIndex + 3]
        sattr.worstValue = data[byteIndex + 4]
        /* compile time error (too complex..)
         sattr.rawValue = [
         data[byteIndex + 5],
         data[byteIndex + 6],
         data[byteIndex + 7],
         data[byteIndex + 8],
         data[byteIndex + 9],
         data[byteIndex + 10]
         ]
         */
        for n in 0...5 {
          sattr.rawValue[n] = data[(byteIndex + 5) + n]
        }
        self.vendorAttributes[array30Count] = sattr
        array30Count+=1
        sattr.reserved = data[byteIndex + 11]
        byteIndex+=12
      }
    }
  }
}

struct ThresholdAttribute {
  var attributeId: UInt8 = 0
  var thresholdValue: UInt8 = 0
  var reserved = [UInt8](repeating: 0, count: 10)
}

struct VendorSpecificDataThresholds {
  var revisonNumber: UInt16 = 0
  var thresholdEntries = [ThresholdAttribute](repeating: ThresholdAttribute(), count: 30)
  
  init(from data: Data) {
    var byteIndex : Int = 0
    var array30Count = 0
    while byteIndex <= (data.count - 12) {
      if byteIndex == 0 {
        self.revisonNumber = UInt16(
          data[0] +
            data[1]
        )
        byteIndex+=2
      } else {
        var tattr : ThresholdAttribute = ThresholdAttribute()
        tattr.attributeId = data[byteIndex]
        tattr.thresholdValue = data[byteIndex + 1]
        
        /* compile time error (too complex..)
         tattr.reserved = [
         data[byteIndex + 2],
         data[byteIndex + 3],
         data[byteIndex + 4],
         data[byteIndex + 5],
         data[byteIndex + 6],
         data[byteIndex + 7],
         data[byteIndex + 8],
         data[byteIndex + 9],
         data[byteIndex + 10],
         data[byteIndex + 11]
         ]
         */
        
        for n in 0...9 {
          tattr.reserved[n] = data[(byteIndex + 2) + n]
        }
        self.thresholdEntries[array30Count] = tattr
        array30Count+=1
        byteIndex+=12
      }
    }
  }
}

enum SMARTStatus : Int {
  case unknown = 0
  case error = 1
  case ok = 2
  case notCompatible = 3
}

class HWSmartDataScanner: NSObject {
  let suggestedInterval : TimeInterval = 600 // 10 minutes
  
  public func getSmartCapableDisks() -> [NSDictionary] {
    let disks : NSDictionary = self.getAlldisks()
    var array : [NSDictionary] = [NSDictionary]()

    let sorted = disks.allKeys.sorted{ ($0 as! String) < ($1 as! String) }
    for d in sorted {
      let bsdName : String = d as! String
      let bsdAttr : NSDictionary = disks.object(forKey: bsdName) as! NSDictionary
      /*
       Get Physical disks only
       Physical disk actually (April 2018, macOS 10.13) doesn't have the UUID key
       */
      let isWhole : NSNumber = bsdAttr.object(forKey: "Whole") as! NSNumber
      if isWhole.boolValue && (bsdAttr.object(forKey: "UUID") == nil) {
        var dict : NSMutableDictionary = NSMutableDictionary()
        let bsdUnit : Int = Int((d as! NSString).replacingOccurrences(of: "disk", with: ""))!
        var status : SMARTStatus = SMARTStatus.unknown
        if self.getSMARTAttributesForDisk(bsdUnit: bsdUnit,
                                          attributes: &dict,
                                          status: &status) == kIOReturnSuccess {
          if dict.allKeys.count > 0 {
            array.append(dict)
          }
        }
      }
    }
    return array
  }
  
  /*
   valid sensor have Temperature or life, or both (or anyway have s.m.a.r.t. datas)
   */
  func getSensors(from dictionary : NSDictionary,
                  characteristics : inout String,
                  productName : inout String,
                  serial : inout String) ->[HWMonitorSensor] {
    var sensors : [HWMonitorSensor] = [HWMonitorSensor]()
    
    if (dictionary.object(forKey: kIsNVMeKey) != nil) { // otherwise you are passing the wrong dict!
      var description : String = ""
      var key : String = ""
      
      let isNVMe = (dictionary.object(forKey: kIsNVMeKey) as! NSNumber).boolValue
      let arbitration : NSDictionary = dictionary.object(forKey: kArbitrationKey) as! NSDictionary
      let deviceCharacteristics : NSDictionary = dictionary.object(forKey: kIOPropertyDeviceCharacteristicsKey) as! NSDictionary
      let protocolCharacteristics : NSDictionary = dictionary.object(forKey: kIOPropertyProtocolCharacteristicsKey) as! NSDictionary
      let attributes : NSDictionary = dictionary.object(forKey: kSMARTAttributesDictKey) as! NSDictionary
      
      key = arbitration.object(forKey: kIOBSDNameKey) as! String
      description += "\(kIOBSDNameKey): \(key)\n"
      
      productName = (arbitration.object(forKey: kDADiskDescriptionDeviceModelKey) as! String).trimmingCharacters(in: .whitespacesAndNewlines)
      description += "\(kIOPropertyProductNameKey): \(productName)\n"
     
      let serialNum = deviceCharacteristics.object(forKey: kIOPropertyProductRevisionLevelKey) as! String
      serial = serialNum.trimmingCharacters(in: .whitespacesAndNewlines)
   
      
      description += "\(kIOPropertyProductRevisionLevelKey): \(serial)\n"
      description += "\(kIOPropertyMediumTypeKey): \(self.getMediumType(characteristics: deviceCharacteristics))\n"
      description += "Capacity: \(self.getFormattedMediaSize(characteristics: arbitration))\n"
      
      if isNVMe {
        description += "\(kIOPropertyPhysicalInterconnectTypeKey): \(self.getPhysicalInterconnect(characteristics: protocolCharacteristics)) (NVMe)\n"
      } else {
        description += "\(kIOPropertyPhysicalInterconnectTypeKey): \(self.getPhysicalInterconnect(characteristics: protocolCharacteristics))\n"
      }
      description += "\(kIOPropertyPhysicalInterconnectLocationKey): \(self.getLocation(characteristics: protocolCharacteristics))\n"
      if isNVMe {
        let temp: NSNumber = attributes.object(forKey: kNVMeSMARTTemperatureKey) as! NSNumber
        description += "\(kNVMeSMARTTemperatureKey): \(temp.intValue)\(HWUnit.C.rawValue)\n"
        
        let tempSensor = HWMonitorSensor(key: "temp" + productName + serial,
                                         unit: HWUnit.C,
                                         type: "S.M.A.R.T",
                                         sensorType: .hdSmartTemp,
                                         title: serial,
                                         canPlot: true)
        tempSensor.stringValue = "\(temp.intValue)"
        tempSensor.favorite = UDs.bool(forKey: tempSensor.key)
        tempSensor.doubleValue = temp.doubleValue
        tempSensor.actionType = .mediaLog
        sensors.append(tempSensor)
        
        
        let life: NSNumber = attributes.object(forKey: kSMARTLifeKey) as! NSNumber
        description += "\(kSMARTLifeKey): \(life.intValue)\(HWUnit.Percent.rawValue)\n"
        
        let lifeSensor = HWMonitorSensor(key: "life" + productName + serial,
                                         unit: .Percent,
                                         type: "S.M.A.R.T",
                                         sensorType: .hdSmartLife,
                                         title: serial,
                                         canPlot: true)
        
        
        lifeSensor.stringValue = "\(life.intValue)"
        lifeSensor.favorite = UDs.bool(forKey: lifeSensor.key)
        lifeSensor.doubleValue = life.doubleValue
        lifeSensor.actionType = .mediaLog
        sensors.append(lifeSensor)
        
        let cw: NSNumber = attributes.object(forKey: kNVMeSMARTCriticalWarningKey) as! NSNumber
        description += "\(kNVMeSMARTCriticalWarningKey): \(cw.intValue)\(HWUnit.Percent.rawValue)\n"
        
        let asp: NSNumber = attributes.object(forKey: kNVMeSMARTAvailableSpareKey) as! NSNumber
        description += "\(kNVMeSMARTAvailableSpareKey): \(asp.intValue)\(HWUnit.Percent.rawValue)\n"
        
        let aspt: NSNumber = attributes.object(forKey: kNVMeSMARTAvailableSpareThresholdKey) as! NSNumber
        description += "\(kNVMeSMARTAvailableSpareThresholdKey): \(aspt.intValue)\(HWUnit.Percent.rawValue)\n"
        
        let us: NSNumber = attributes.object(forKey: kNVMeSMARTUnsafeShutdownsKey) as! NSNumber
        description += "\(kNVMeSMARTUnsafeShutdownsKey): \(us.intValue)\n"
      } else {
        if (deviceCharacteristics.object(forKey: kIOPropertyMediumRotationRateKey) != nil) {
          let rpm : NSNumber = deviceCharacteristics.object(forKey: kIOPropertyMediumRotationRateKey) as! NSNumber
          description += "\(kIOPropertyMediumRotationRateKey): \(rpm.intValue)\(HWUnit.RPM.rawValue)\n"
        }
        let temperature : Int = self.getATATemperatureIn(attributes: attributes)
        
        if temperature != kSMARTTemperatureNotFound {
          description += "\(kNVMeSMARTTemperatureKey): \(temperature)\(HWUnit.C.rawValue)\n"
          
          let tempSensor = HWMonitorSensor(key: "temp" + productName + serial,
                                           unit: HWUnit.C,
                                           type: "S.M.A.R.T",
                                           sensorType: .hdSmartTemp,
                                           title: serial,
                                           canPlot: true)
          tempSensor.stringValue = "\(temperature)"
          tempSensor.favorite = UDs.bool(forKey: tempSensor.key)
          tempSensor.doubleValue = Double(temperature)
          tempSensor.actionType = .mediaLog
          sensors.append(tempSensor)
        }
        
        if self.isSolidSate(characteristics: deviceCharacteristics) {
          var lifeDict: NSDictionary? = nil
          // 177 is the attribute most used for life percentage in SATA SSDs
          if (attributes.object(forKey: "177") != nil) {
            lifeDict = (attributes.object(forKey: "177") as! NSDictionary)
          } else if (attributes.object(forKey: "173") != nil) {
            lifeDict = (attributes.object(forKey: "173") as! NSDictionary)
          }
          
          if (lifeDict != nil) {
            let life: NSNumber = lifeDict?.object(forKey: kATASMARTCurrentValueKey) as! NSNumber
            if life.intValue >= 0 && life.intValue <= 100 {
              description += "\(kSMARTLifeKey): \(life.intValue)\(HWUnit.Percent.rawValue)\n"
              
              
              let lifeSensor = HWMonitorSensor(key: "life" + productName + serial,
                                               unit: .Percent,
                                               type: "S.M.A.R.T",
                                               sensorType: .hdSmartLife,
                                               title: serial,
                                               canPlot: true)
              
              
              lifeSensor.stringValue = "\(life.intValue)"
              lifeSensor.favorite = UDs.bool(forKey: lifeSensor.key)
              lifeSensor.doubleValue = life.doubleValue
              lifeSensor.actionType = .mediaLog
              sensors.append(lifeSensor)
            }
          }
        }
      }
      
      // smart status
      var status : SMARTStatus = .unknown
      if (dictionary.object(forKey: kSMARTStatus) != nil) {
        status = SMARTStatus(rawValue: dictionary.object(forKey: kSMARTStatus) as! Int)!
      }
      
      switch status {
      case SMARTStatus.error:
        description += "S.M.A.R.T. status: Error\n"
      case SMARTStatus.ok:
        description += "S.M.A.R.T. status: Ok\n"
      case SMARTStatus.notCompatible:
        description += "S.M.A.R.T. status: Not compatible\n"
      case SMARTStatus.unknown:
        description += "S.M.A.R.T. status: Unknown\n"
      }
      characteristics = description
    }
    return sensors
  }
  
  private func getATATemperatureIn(attributes: NSDictionary) -> Int {
    var val : Int = kSMARTTemperatureNotFound
    let commonTemperatureAttributes : [String] = ["194", "190", "231"] // is sorted
    
    for a in commonTemperatureAttributes {
      if let dict : NSDictionary = attributes.object(forKey: a) as? NSDictionary {
        let rawValue : [UInt8] = dict.object(forKey: kATASMARTRawValueKey) as! [UInt8]
        let r0 : Int = Int(rawValue[0]) // lowest byte of RawValue holds the temperature
        //print("r0 = \(r0)")
        if r0 > 0 && r0 < 100 /* thermal throttle already reached or invalid */ {
          val = r0
          break
        }
      }
    }
    return val
  }
  
  private func isSolidSate(characteristics : NSDictionary) -> Bool {
    if let type : String = characteristics.object(forKey: kIOPropertyMediumTypeKey) as? String {
      return (type == kIOPropertyMediumTypeSolidStateKey)
    }
    return false
  }
  
  private func getFormattedMediaSize(characteristics : NSDictionary) -> String {
    if (characteristics.object(forKey: kDADiskDescriptionMediaSizeKey) != nil)  {
      let size : NSNumber = characteristics.object(forKey: kDADiskDescriptionMediaSizeKey) as! NSNumber
      //return "\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)) (\(size) bytes)"
      return BytesFormatter.init(bytes: size.int64Value, countStyle: 1000).stringValue() + " \(size) bytes"
    }
    return "Unknown"
  }
  
  private func getMediumType(characteristics : NSDictionary) -> String {
    if let type : String = characteristics.object(forKey: kIOPropertyMediumTypeKey) as? String {
      return (type == kIOPropertyMediumTypeSolidStateKey ? "SSD" : "HDD")
    }
    return "Unknown"
  }
  
  private func getPhysicalInterconnect(characteristics : NSDictionary) -> String {
    return characteristics.object(forKey: kIOPropertyPhysicalInterconnectTypeKey) as! String
  }
  
  private func getLocation(characteristics : NSDictionary) -> String {
    return characteristics.object(forKey: kIOPropertyPhysicalInterconnectLocationKey) as! String
  }
  
  private func getDAdiskDescription(from bsdName: String) -> NSDictionary? {
    if let session = DASessionCreate(kCFAllocatorDefault) {
      if bsdName.hasPrefix("disk") {
        if let disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, bsdName) {
          if let dict = DADiskCopyDescription(disk) {
            return (dict as NSDictionary)
          }
        }
      }
    }
    return nil
  }
  
  private func getMediaSize(from dictionary: NSDictionary) -> Int {
    // kDADiskDescriptionMediaSizeKey
    if (dictionary.object(forKey: kDADiskDescriptionMediaSizeKey) != nil) {
      return (dictionary.object(forKey: kDADiskDescriptionMediaSizeKey) as! NSNumber).intValue
    }
    return 0
  }
  
  private func getBustPath(from dictionary: NSDictionary) -> String {
    // kDADiskDescriptionBusPathKey
    if (dictionary.object(forKey: kDADiskDescriptionBusPathKey) != nil) {
      return dictionary.object(forKey: kDADiskDescriptionBusPathKey) as! String
    }
    return "Unknown"
  }
  
  private func getDeviceModel(from dictionary: NSDictionary) -> String {
    // kDADiskDescriptionDeviceModelKey
    if (dictionary.object(forKey: kDADiskDescriptionDeviceModelKey) != nil) {
      return dictionary.object(forKey: kDADiskDescriptionDeviceModelKey) as! String
    }
    return "Unknown"
  }
  
  private func getAlldisks() -> NSDictionary {
    let match_dictionary: CFMutableDictionary = IOServiceMatching(kIOMediaClass)
    var entry_iterator: io_iterator_t = 0
    let allDisks = NSMutableDictionary()
    let err =  IOServiceGetMatchingServices(kIOMasterPortDefault,
                                            match_dictionary,
                                            &entry_iterator)
    
    if err == KERN_SUCCESS && entry_iterator != 0 {
      var serviceObject : io_registry_entry_t = 0
      
      repeat {
        serviceObject = IOIteratorNext(entry_iterator)
        if serviceObject != 0 {
          var serviceDictionary : Unmanaged<CFMutableDictionary>?
          if (IORegistryEntryCreateCFProperties(serviceObject,
                                                &serviceDictionary,
                                                kCFAllocatorDefault, 0) != kIOReturnSuccess) {
            IOObjectRelease(serviceObject)
            continue
          }
          
          let d = serviceDictionary?.takeRetainedValue() as NSDictionary?
          
          if (d?.object(forKey: kIOBSDNameKey) != nil) {
            allDisks.setValue(d, forKey: (d?.object(forKey: kIOBSDNameKey ) as! String))
          }
          IOObjectRelease(serviceObject)
        }
      } while serviceObject != 0
      
      IOObjectRelease(entry_iterator)
    }
    return allDisks
  }
  
  private func getSMARTAttributesForDisk(bsdUnit : Int,
                                         attributes : inout NSMutableDictionary,
                                         status: inout SMARTStatus) -> IOReturn {
    var isNVMe : Bool = false
    var found : Bool = false
    var object : io_object_t = io_object_t(MACH_PORT_NULL)
    var parent : io_object_t = io_object_t(MACH_PORT_NULL)
    var error : IOReturn = kIOReturnError
    var smartCapable : Bool = false
    var smartCapableNVME : Bool = false
    object = IOServiceGetMatchingService(kIOMasterPortDefault,
                                         IOBSDNameMatching(kIOMasterPortDefault,
                                                           0,
                                                           "disk\(bsdUnit)".cString(using: .utf8))
    )
    
    if object == MACH_PORT_NULL {
      return kIOReturnNoResources
    }
    
    parent = object
    
    while (IOObjectConformsTo(object, kIOBlockStorageDeviceClass) == 0) {
      error = IORegistryEntryGetParentEntry(object, kIOServicePlane, &parent)
      if error != kIOReturnSuccess || parent == MACH_PORT_NULL {
        IOObjectRelease(object)
        return kIOReturnNoResources
      }
      object = parent
    }
    
    if (IOObjectConformsTo(object, kIOBlockStorageDeviceClass) > 0) {
      
      let opt = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
      if let deviceCharacteristics = IORegistryEntrySearchCFProperty(object,
                                                                     kIOServicePlane,
                                                                     kIOPropertyDeviceCharacteristicsKey as CFString,
                                                                     kCFAllocatorDefault,
                                                                     opt) as? NSDictionary {
        
        if let protocolCharacteristics = IORegistryEntrySearchCFProperty(object,
                                                                      kIOServicePlane,
                                                                      kIOPropertyProtocolCharacteristicsKey as CFString,
                                                                      kCFAllocatorDefault,
                                                                      opt) as? NSDictionary {
          let arbitration : NSMutableDictionary = NSMutableDictionary()
          arbitration.setValue("disk\(bsdUnit)", forKey: kIOBSDNameKey)
          
          if let dict : NSDictionary = getDAdiskDescription(from: "disk\(bsdUnit)") {
            arbitration.setValue(self.getMediaSize(from: dict),   forKey: kDADiskDescriptionMediaSizeKey as String)
            arbitration.setValue(self.getDeviceModel(from: dict), forKey: kDADiskDescriptionDeviceModelKey as String)
            arbitration.setValue(self.getBustPath(from: dict),    forKey: kDADiskDescriptionBusPathKey as String)
            arbitration.setValue(bsdUnit,    forKey: kDADiskDescriptionMediaBSDUnitKey as String)
          }
          
          attributes.setValue(arbitration,             forKey: kArbitrationKey)
          attributes.setValue(deviceCharacteristics,   forKey: kIOPropertyDeviceCharacteristicsKey)
          attributes.setValue(protocolCharacteristics, forKey: kIOPropertyProtocolCharacteristicsKey)
          
          let b1 = IORegistryEntryCreateCFProperty(object, kIOPropertySMARTCapableKey as CFString, kCFAllocatorDefault, 0)
          if (b1 != nil) {
            smartCapable = b1?.takeRetainedValue() as! Bool
          }
          
          
          if !smartCapable {
            let b2 = IORegistryEntryCreateCFProperty(object, kIOUserClientClassKey as CFString, kCFAllocatorDefault, 0)
            
            if (b2 != nil) {
              smartCapable = ((b2?.takeRetainedValue() as! CFString) as String) == kATASMARTUserClientClassKey
            }
          }
          
          if !smartCapable {
            let b3 = IORegistryEntryCreateCFProperty(object, kIOPropertyNVMeSMARTCapableKey as CFString, kCFAllocatorDefault, 0)
            
            if (b3 != nil) {
              smartCapableNVME = b3?.takeRetainedValue() as! Bool
            }
          }
          
          if smartCapable {
            var pluginInterface: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
            var smartInterface: UnsafeMutablePointer<UnsafeMutablePointer<IOATASMARTInterface>?>?
            var herr : HRESULT  = S_OK
            var score : Int32  = 0
            
            error = IOCreatePlugInInterfaceForService(object,
                                                      kIOATASMARTUserClientTypeID,
                                                      kIOCFPlugInInterfaceID,
                                                      &pluginInterface,
                                                      &score)
            
            if error == kIOReturnSuccess {
              // Use plug-in interface to get a device interface.
              herr = withUnsafeMutablePointer(to: &smartInterface) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                  pluginInterface?.pointee?.pointee.QueryInterface(
                    pluginInterface,
                    CFUUIDGetUUIDBytes(kIOATASMARTInterfaceID),
                    $0)
                }
                }!
              
              if (herr == S_OK) && (smartInterface != nil) {
                error = (smartInterface?.pointee?.pointee.SMARTEnableDisableOperations(smartInterface, true))!
                if error == kIOReturnSuccess {
                  error = (smartInterface?.pointee?.pointee.SMARTEnableDisableAutosave(smartInterface, true))!
                  if error == kIOReturnSuccess {
                    var ec : DarwinBoolean = false
                    error = (smartInterface?.pointee?.pointee.SMARTReturnStatus(smartInterface, &ec))!
                    if error == kIOReturnSuccess {
                      
                      if ec.boolValue {
                        status = SMARTStatus.error
                      } else {
                        status = SMARTStatus.ok
                      }
                      
                      attributes.setValue(NSNumber(value: status.rawValue), forKey: kSMARTStatus)
                      var smartdata : ATASMARTData? = nil
                      var smartThresholds : ATASMARTDataThresholds? = nil
                      
                      bzero(&smartThresholds, MemoryLayout.size(ofValue: smartThresholds))
                      bzero(&smartdata, MemoryLayout.size(ofValue: smartdata))
                      
                      error = (smartInterface?.pointee?.pointee.SMARTReadData(smartInterface, &smartdata!))!
                      
                      if error == kIOReturnSuccess {
                        error = (smartInterface?.pointee?.pointee.SMARTValidateReadData(smartInterface, &smartdata!))!
                        if error == kIOReturnSuccess {
                          error = (smartInterface?.pointee?.pointee.SMARTReadDataThresholds(smartInterface, &smartThresholds!))!
                          if error == kIOReturnSuccess {
                            // Vendor Specifics data
                            let mirror = Mirror(reflecting: (smartdata?.vendorSpecific1)!)
                            var svsdata : Data = Data()
                            for child in mirror.children {
                              svsdata.append(child.value as! UInt8)
                            }
                            
                            let dataVendorSpecific : VendorSpecificData = VendorSpecificData(from: svsdata)
                            
                            // Threshold Vendor Specifics data
                            let mirror2 = Mirror(reflecting: (smartThresholds?.vendorSpecific1)!)
                            var stvsdata : Data = Data()
                            for child in mirror2.children {
                              stvsdata.append(child.value as! UInt8)
                            }
                            let smartThresholdVendorSpecifics : VendorSpecificDataThresholds = VendorSpecificDataThresholds(from: stvsdata)
                            
                            let saDict : NSMutableDictionary = NSMutableDictionary()
                            for i in 0..<30 {
                              let attr: ATASMARTAttribute = dataVendorSpecific.vendorAttributes[i]
                              let thres: ThresholdAttribute = smartThresholdVendorSpecifics.thresholdEntries[i]
                              if attr.attributeID > 0 {
                                let threshold: UInt8 = (attr.attributeID == thres.attributeId) ? thres.thresholdValue : 0
                                saDict.setValue([kATASMARTCurrentValueKey: attr.currentValue,
                                                 kATASMARTWorstValueKey: attr.worstValue,
                                                 kATASMARTRawValueKey:   attr.rawValue,
                                                 kATASMARTThresholdKey:  threshold,
                                                 kATASMARTPrefailKey:   (attr.flag & 0x01),
                                                 kATASMARTflagKey:       ((attr.flag & 0x02) > 0 ? 1 : 0)],
                                                forKey: "\(attr.attributeID)")
                              }
                            }
                            attributes.setValue(saDict, forKey: kSMARTAttributesDictKey)
                            attributes.setValue(NSNumber(value: isNVMe), forKey: kIsNVMeKey)
                          }
                        }
                      }
                    }
                  }
                }
                _ = smartInterface?.pointee?.pointee.SMARTEnableDisableAutosave(smartInterface, false)
                _ = smartInterface?.pointee?.pointee.SMARTEnableDisableOperations(smartInterface, false)
              } else {
                //print("Unable to get Device Interface")
                error = herr
              }
              
              if (smartInterface != nil) {
                _ = pluginInterface?.pointee?.pointee.Release(smartInterface)
                smartInterface = nil
              }
            }
            if (pluginInterface != nil) {
              IODestroyPlugInInterface(pluginInterface)
            }
            found = true
          } else if smartCapableNVME {
            isNVMe = true
            var pluginInterface: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
            var smartInterface:  UnsafeMutablePointer<UnsafeMutablePointer<IONVMeSMARTInterface>?>?
            var herr : HRESULT  = S_OK
            var score : Int32  = 0
            
            error = IOCreatePlugInInterfaceForService(object,
                                                      kIONVMeSMARTUserClientTypeID,
                                                      kIOCFPlugInInterfaceID,
                                                      &pluginInterface,
                                                      &score)
            
            if error == kIOReturnSuccess {
              // Use plug-in interface to get a device interface.
              herr = withUnsafeMutablePointer(to: &smartInterface) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                  pluginInterface?.pointee?.pointee.QueryInterface(
                    pluginInterface,
                    CFUUIDGetUUIDBytes(kIONVMeSMARTInterfaceID),
                    $0)
                }
                }!
              
              if (herr == S_OK) && (smartInterface != nil) {
                var smartdata : nvme_smart_log = nvme_smart_log()
                let sdsize = MemoryLayout.size(ofValue: smartdata)
                bzero(&smartdata, sdsize)
                error = (smartInterface?.pointee?.pointee.SMARTReadData(smartInterface, &smartdata))!
                if error == kIOReturnSuccess {
                  let saDict : NSMutableDictionary = NSMutableDictionary()
                  
                  let array : [UInt8] = [UInt8(smartdata.temperature.1), UInt8(smartdata.temperature.0)]
                  var celsius : UInt16 = 0
                  let data = NSData(bytes: array, length: 2)
                  data.getBytes(&celsius, length: 2)
                  celsius = UInt16(bigEndian: celsius) - 273
                  
                  if celsius < 1 {
                    // can be.. if you put your disk in the freezer. naah, is really cold!?
                    celsius = 0
                  } else if celsius > 100 {
                    celsius = 0
                    // can be.. if you put your disk in a blast furnace (joke, so is invalid)
                  }
                  
                  // status
                  attributes.setValue((smartdata.critical_warning == 0) ?
                    NSNumber(value: SMARTStatus.ok.rawValue) :
                    NSNumber(value: SMARTStatus.error.rawValue),
                                      forKey: kSMARTStatus)
                  
                  // life remaining
                  let life: Int = 100 - Int(smartdata.percent_used) // nvme says life used otherwise
                  saDict.setValue(smartdata.critical_warning, forKey: kNVMeSMARTCriticalWarningKey)
                  saDict.setValue(celsius, forKey: kNVMeSMARTTemperatureKey)
                  saDict.setValue(smartdata.avail_spare, forKey: kNVMeSMARTAvailableSpareKey)
                  saDict.setValue(smartdata.spare_thresh, forKey: kNVMeSMARTAvailableSpareThresholdKey)
                  saDict.setValue(life, forKey: kSMARTLifeKey)
                  
                  // Unsafe Shutdowns
                  let us = UInt64(smartdata.unsafe_shutdowns.1) << 32 + UInt64(smartdata.unsafe_shutdowns.0)
                  saDict.setValue(us, forKey: kNVMeSMARTUnsafeShutdownsKey)
                  attributes.setValue(saDict, forKey: kSMARTAttributesDictKey)
                  attributes.setValue(NSNumber(value: isNVMe), forKey: kIsNVMeKey)
                } else {
                  //print(error)
                }
                
                _ = pluginInterface?.pointee?.pointee.Release(smartInterface)
                smartInterface = nil
              }
              
            } else {
              //print(error)
            }
            // Plug-in interface is no longer needed.
            if (pluginInterface != nil) {
              IODestroyPlugInInterface(pluginInterface)
            }
            
            found = true
          } else {
            // not capable
            found = false
          }
          
        }
      }
    }
    
    if object != MACH_PORT_NULL {
      IOObjectRelease(object)
    }
    
    return (found == false) ? kIOReturnNoResources : error
  }
}


