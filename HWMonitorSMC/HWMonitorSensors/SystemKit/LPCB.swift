//
//  LPCB.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 16/05/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import IOKit

public struct LPCB {
  
  public func getLPCBInfo() -> String {
    var log : String = ""
    let LPCBcode = Data([0x00, 0x01, 0x06, 0x00])
    
    if let info = PCIControllers.getPCIControllersInfo(with: LPCBcode) {
      if let IOName = getStringFrom(info.object(forKey: "IOName")) {
        log += "\tIOName:\t\t\t\(IOName)\n"
      }
      if let name = getStringFrom(info.object(forKey: "name")) {
        /*
         user can have this injected has a string instead of raw data,
         so when is data.. it print bytes. Anyway is equal to the IOName above
         */
        log += "\tname:\t\t\t\(name)\n"
      }
      if let did = getStringFrom(info.object(forKey: "device-id")) {
        log += "\tdevice-id:\t\t\t\(did)\n"
      }
      if let vid = getStringFrom(info.object(forKey: "vendor-id")) {
        log += "\tvendor-id:\t\t\t\(vid)\n"
      }
      if let rid = getStringFrom(info.object(forKey: "revision-id")) {
        log += "\trevision-id:\t\t\(rid)\n"
      }
      if let ssid = getStringFrom(info.object(forKey: "subsystem-id")) {
        log += "\tsubsystem-id:\t\t\(ssid)\n"
      }
      if let ssvid = getStringFrom(info.object(forKey: "subsystem-vendor-id")) {
        log += "\tsubsystem-vendor-id:\t\(ssvid)\n"
      }
    }
    return log
  }
  
  fileprivate func getStringFrom(_ raw: Any?) -> String? {
    var value : String? = nil
    if (raw != nil) {
      if raw is NSString {
        value = (raw as! String)
      } else if raw is NSData {
        let data : Data = (raw as! Data)
        value = "\(data.hexadecimal())"
      } else if raw is NSNumber {
        value = "\((raw as! NSNumber).intValue)"
      }
    }
    return value
  }
  
  }
