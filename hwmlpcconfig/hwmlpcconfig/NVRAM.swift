//
//  NVRAM.swift
//  Clover
//
//  Created by vector sigma on 30/10/2019.
//  Copyright © 2019 CloverHackyColor. All rights reserved.
//

import Cocoa

// MARK: Get NVRAM
func getNVRAM() -> NSMutableDictionary? {
  var ref: io_registry_entry_t
  var masterPort = mach_port_t()
  var oResult: kern_return_t
  var result: kern_return_t
  oResult = IOMasterPort(bootstrap_port, &masterPort)
  
  if oResult != KERN_SUCCESS {
    return nil
  }
  
  ref = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options")
  if ref == 0 {
    return nil
  }
  
  var dict : Unmanaged<CFMutableDictionary>?
  result = IORegistryEntryCreateCFProperties(ref, &dict, kCFAllocatorDefault, 0)

  if result != KERN_SUCCESS {
    IOObjectRelease(ref)
    return nil
  }
  IOObjectRelease(ref)
  return dict?.takeRetainedValue()
}

/// Get a single nvram variable
func getNVRAM(variable name: String) -> String? {
  var value : String? = nil
  var ref: io_registry_entry_t
  var masterPort = mach_port_t()
  var oResult: kern_return_t
  oResult = IOMasterPort(bootstrap_port, &masterPort)
  
  if oResult != KERN_SUCCESS {
    return nil
  }
  
  ref = IORegistryEntryFromPath(masterPort, "IODeviceTree:/options")
  if ref == 0 {
    return nil
  }
  
  let vref = IORegistryEntryCreateCFProperty(ref,
                                             name as CFString,
                                             kCFAllocatorDefault, 0)
  if (vref != nil) {
    let data = vref?.takeRetainedValue() as! Data
    var cleanedData = Data()
    for i in 0..<data.count {
      if data[i] != 0x00 {
        cleanedData.append(data[i])
      }
    }

    value = String(bytes: cleanedData, encoding: .utf8)
  }
  
  IOObjectRelease(ref)
  
  return value
}




