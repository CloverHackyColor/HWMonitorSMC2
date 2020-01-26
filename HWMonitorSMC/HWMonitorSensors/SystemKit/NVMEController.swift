//
//  NVMEController.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 20/05/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import IOKit

public struct NVMeControllers {
  
  public init() { }
  
  public static func getNVMeControllersInfo() -> String {
    let StandardCode = Data([0x02, 0x08, 0x01, 0x00]) // NVMe standard
    let AppleCode    = Data([0x02, 0x80, 0x01, 0x00]) // Apple (for old OSes)
    let RHBCode      = Data([0x02, 0x80, 0x01, 0x00]) // Rehabman hack (not sure this is published in the IO reg.)
    var log : String = ""
    var count : Int = 0
    
    if let std = PCIControllers.getPCIControllersInfo(with: StandardCode) {
      log += "NVMe controller:\n"
      log += NVMeControllers.getCommonKeysAndObjectsIn(dictionary: std)
      count += 1
    }
    
    if let apple = PCIControllers.getPCIControllersInfo(with: AppleCode) {
      log += (count == 0) ? "NVMe controller (Apple):\n" : "\nNVMe controller (Apple):\n"
      log += NVMeControllers.getCommonKeysAndObjectsIn(dictionary: apple)
    }
    
    if let spoofed = PCIControllers.getPCIControllersInfo(with: RHBCode) {
      log += (count == 0) ? "NVMe controller (spoofed):\n" : "\nNVMe controller (spoofed):\n"
      log += NVMeControllers.getCommonKeysAndObjectsIn(dictionary: spoofed)
    }
    
    if count > 0 {
      log += "\n"
    }
    return log
  }
  
  fileprivate static func getCommonKeysAndObjectsIn(dictionary: NSDictionary) -> String {
    var log : String = ""
    // expected values:
    var name              : String = "Unknown" // name can be String/Data
    let nameValue         : Any? = dictionary.object(forKey: "name")
    let vendorID          : Data = dictionary.object(forKey: "vendor-id") as! Data
    let deviceID          : Data = dictionary.object(forKey: "device-id") as! Data
    let classcode         : Data = dictionary.object(forKey: "class-code") as! Data
    let revisionID        : Data = dictionary.object(forKey: "revision-id") as! Data
    let subsystemID       : Data = dictionary.object(forKey: "subsystem-id") as! Data
    let subsystemVendorID : Data = dictionary.object(forKey: "subsystem-vendor-id") as! Data
    
    if (nameValue != nil) {
      if nameValue is NSString {
        name = nameValue as! String
      } else if nameValue is NSData {
        name = String(data: nameValue as! Data , encoding: .utf8) ?? name
      }
    }
    
    log += "\tName:\t\t\t\t\(name)\n"
    log += "\tVendor ID:\t\t\t\t\(vendorID.hexadecimal())\n"
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
    if let acpipath : String = dictionary.object(forKey: "acpi-path") as? String {
      log += "\tacpi-path:\t\t\t\t\(acpipath)\n"
    }
    
    return log
  }
}
