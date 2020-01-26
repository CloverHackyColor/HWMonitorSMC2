//
//  PCI.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 20/05/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import IOKit

public struct PCIControllers {
  
  public init() { }
  
  /// - Returns: The PCI info dictionary for the given class code.
  public static func getPCIControllersInfo(with classcode: Data) -> NSDictionary? {
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
            if (info.object(forKey: "class-code") != nil) {
              if let cc : Data = info.object(forKey: "class-code") as? Data {
                if cc == classcode {
                  IOObjectRelease(serviceObject)
                  IOObjectRelease(iter)
                  return info
                }
              }
            }
          }
          IOObjectRelease(serviceObject)
        } while serviceObject != 0
      }
      IOObjectRelease(iter)
    }
    return nil
  }
}
