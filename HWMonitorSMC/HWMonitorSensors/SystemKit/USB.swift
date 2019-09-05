//
//  USB.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 16/05/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

public struct USBControllers {
  
  public init() { }
  
  public static func getUSBControllersInfo() -> String {
    let USB2code = Data([0x20, 0x03, 0x0C, 0x00])
    let USB3code = Data([0x30, 0x03, 0x0C, 0x00])
    var log : String = ""
    var count : Int = 0
    
    if let usb2 = PCIControllers.getPCIControllersInfo(with: USB2code) {
      log += "USB 2.0 controller:\n"
      log += USBControllers.getCommonKeysAndObjectsIn(dictionary: usb2)
      count += 1
    }
  
    if let usb3 = PCIControllers.getPCIControllersInfo(with: USB3code) {
      log += (count == 0) ? "USB 3.0 controller:\n" : "\nUSB 3.0 controller:\n"
      log += USBControllers.getCommonKeysAndObjectsIn(dictionary: usb3)
    }
    if count > 0 {
      log += "\n"
    }
    return log
  }
  
  fileprivate static func getCommonKeysAndObjectsIn(dictionary: NSDictionary) -> String {
    var log : String = ""
    // expected values:
    let vendorID          : Data = dictionary.object(forKey: "vendor-id") as! Data
    let deviceID          : Data = dictionary.object(forKey: "device-id") as! Data
    let classcode         : Data = dictionary.object(forKey: "class-code") as! Data
    let revisionID        : Data = dictionary.object(forKey: "revision-id") as! Data
    let subsystemID       : Data = dictionary.object(forKey: "subsystem-id") as! Data
    let subsystemVendorID : Data = dictionary.object(forKey: "subsystem-vendor-id") as! Data

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
    
    if let aapls = getProperties(with: "AAPL", in: dictionary) {
      log += "\tAdditional Properties:\n"
      for key in (aapls.keys) {
        log += "\(key)\(aapls[key]!)\n"
      }
    }
    
    return log
  }
  
  /*
   getProperties() return all properties that starts with a prefix (like "AAPL")! for the given dictionary
   This ensure that all of it are show in the log without effectively be aware of them.
   */
  fileprivate static func getProperties(with prefix: String, in dict : NSDictionary) -> [String: String]? {
    let fontAttr =  [NSAttributedString.Key.font : gLogFont] // need to count a size with proportional font
    var properties : [String: String] = [String: String]()
    let allKeys = dict.allKeys // are as [Any]
    var maxLength : Int = 0
    let sep = ": "
    let ind = "\t\t"
    
    // get the max length of the string and all the valid keys
    for k in allKeys {
      let key : String = (k as! String).trimmingCharacters(in: .whitespacesAndNewlines)
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
}

// https://stackoverflow.com/a/41279799
public protocol USBWatcherDelegate: class {
  /// Called on the main thread when a device is connected.
  func usbDeviceAdded(_ device: io_object_t)
  
  /// Called on the main thread when a device is disconnected.
  func usbDeviceRemoved(_ device: io_object_t)
}

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public class USBWatcher {
  private weak var delegate: USBWatcherDelegate?
  private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
  private var addedIterator: io_iterator_t = 0
  private var removedIterator: io_iterator_t = 0
  
  public init(delegate: USBWatcherDelegate) {
    self.delegate = delegate
    
    func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
      let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
      let handler: ((io_iterator_t) -> Void)?
      switch iterator {
      case watcher.addedIterator: handler = watcher.delegate?.usbDeviceAdded
      case watcher.removedIterator: handler = watcher.delegate?.usbDeviceRemoved
      default: assertionFailure("received unexpected IOIterator"); return
      }
      while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
        handler?(device)
        IOObjectRelease(device)
      }
    }
    
    let query = IOServiceMatching(kIOUSBDeviceClassName)
    let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
    
    // Watch for connected devices.
    IOServiceAddMatchingNotification(
      notificationPort, kIOMatchedNotification, query,
      handleNotification, opaqueSelf, &addedIterator)
    
    handleNotification(instance: opaqueSelf, addedIterator)
    
    // Watch for disconnected devices.
    IOServiceAddMatchingNotification(
      notificationPort, kIOTerminatedNotification, query,
      handleNotification, opaqueSelf, &removedIterator)
    
    handleNotification(instance: opaqueSelf, removedIterator)
    
    // Add the notification to the main run loop to receive future updates.
    CFRunLoopAddSource(
      CFRunLoopGetMain(),
      IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
      .defaultMode)
    
    //CFRunLoopRun()
  }
  
  deinit {
    IOObjectRelease(addedIterator)
    IOObjectRelease(removedIterator)
    IONotificationPortDestroy(notificationPort)
  }
  
}

extension io_object_t {
  /// - Returns: The device's name.
  func name() -> String? {
    let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
    defer { buf.deallocate() }
    return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
      if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
        return String(cString: $0)
      }
      return nil
    }
  }
  
  func info() -> NSDictionary? {
    var serviceDictionary : Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(self, &serviceDictionary, kCFAllocatorDefault, 0) == KERN_SUCCESS {
      if let info : NSDictionary = serviceDictionary?.takeRetainedValue() {
        return info
      }
    }
    return nil
  }
  
  func log() -> String {
    var log : String = ""
    if let info = self.info() {
      let name : String? = info.object(forKey: kUSBProductString) as? String
      let USBProductID : NSNumber? = info.object(forKey: kUSBProductID) as? NSNumber
      let USBVendorID : NSNumber? = info.object(forKey: kUSBVendorID) as? NSNumber
      if (name != nil && USBProductID != nil && USBVendorID != nil) {
        log += "Name: \(name!)\n"
        if let vendor : String = info.object(forKey: kUSBVendorString) as? String {
          log += "Vendor: \(vendor)\n"
        }
        log += "\(kUSBProductID): \(String(format: "%x", USBProductID!))\n"
        log += "\(kUSBVendorID): \(String(format: "%x", USBVendorID!))\n"
        if let portNum : NSNumber = info.object(forKey: "PortNum") as? NSNumber {
          log += "Port Num.: \(portNum.intValue)\n"
        }
        if let power : NSNumber = info.object(forKey: kUSBDevicePropertyBusPowerAvailable) as? NSNumber {
          log += "\(kUSBDevicePropertyBusPowerAvailable): \(power.intValue)\n"
        }
        if let speed : NSNumber = info.object(forKey: kUSBDevicePropertySpeed) as? NSNumber {
          log += "Speed: \(speed.intValue)\n"
        }
        if let bcdUSB : NSNumber = info.object(forKey: kUSBDevicePropertySpeed) as? NSNumber {
          log += "\(kUSBDevicePropertySpeed): \(bcdUSB.intValue)\n"
        }
        if let bcdDevice : NSNumber = info.object(forKey: kUSBDeviceReleaseNumber) as? NSNumber {
          log += "\(kUSBDeviceReleaseNumber): \(bcdDevice.intValue)\n"
        }
        if let iSerialNumber : NSNumber = info.object(forKey: kUSBSerialNumberStringIndex) as? NSNumber {
          log += "Serial Number: \(iSerialNumber.intValue)\n"
        }
        if let nonRem : String = info.object(forKey: "non-removable") as? String {
          log += "non-removable: \(nonRem)\n"
        }
      }
    }
    return log
  }
}

class USB: USBWatcherDelegate {
  private var usbWatcher: USBWatcher!
  init() {
    usbWatcher = USBWatcher(delegate: self)
  }
  
  func usbDeviceAdded(_ device: io_object_t) {
    print("device added: \(device.name() ?? "<unknown>")")
  }
  
  func usbDeviceRemoved(_ device: io_object_t) {
    print("device removed: \(device.name() ?? "<unknown>")")
  }
}


