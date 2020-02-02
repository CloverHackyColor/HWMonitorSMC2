//
//  main.swift
//  test
//
//  Created by vector sigma on 20/01/2020.
//  Copyright © 2020 vectorsigma. All rights reserved.
//

import Foundation
import IOKit

let version = 1.2
let fm = FileManager.default

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
}

func getSuperIO(property: String) -> Any? {
  var obj : Any? = nil
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
                                                    property as CFString,
                                                    kCFAllocatorDefault,
                                                    0)
          if ref != nil {
            obj = ref!.takeRetainedValue()
            IOObjectRelease(entry)
            break
          }
        }
        
        rl += 1
        result = IORegistryIteratorEnterEntry(iter)
      } else {
        if rl == 0 {
          IOObjectRelease(entry)
          break
        }
        result = IORegistryIteratorExitEntry(iter)
        rl -= 1
      }
    } while (true)
    IOObjectRelease(iter)
  }
  
  return obj
}

let NA = "Unknown"
let vendor = getOEMVendorShort()
let board = getOEMBoard()
let chipName = (getSuperIO(property: "ChipName") as? String) ?? NA
let sensors = getSuperIO(property: "Sensors") as? [String : Any]

func printHeader() {
  print("hwmlcpconfig v\(version) by vector sigma, 2020")
  print("Super IO Chip = \(chipName)")
  print("OEM Vendor = \(vendor ?? NA)")
  print("OEM Board = \(board ?? NA)")
  print("")
}


func generate() {
  if (sensors != nil) {
    let config = NSMutableDictionary()
    for k in sensors!.keys {
      let sc = NSMutableDictionary()
      let rval = sensors![k]
      if rval is Data {
        let val = Double(Float(bitPattern:
          UInt32(littleEndian: (rval as! Data).withUnsafeBytes { $0.load(as: UInt32.self) })))
        print("\(k) = \(String(format: "%.3f", val)) V")
        sc.setValue(1, forKey: "multi")
      } else if rval is NSNumber {
        print("\(k) = \(rval!) rpm")
      }
      
      sc.setValue(k, forKey: "name")
      sc.setValue(false, forKey: "skip")
      config.setValue(sc, forKey: k)
      
    }
    print("")
    let lpc = "\(NSHomeDirectory())/Desktop/LPC"
    
    if vendor != nil && board != nil {
      let sub = "\(lpc)/\(vendor!)/\(chipName)"
      let plistPath = "\(sub)/\(board!).plist"
      let readmePath = "\(sub)/README.txt"
      if !fm.fileExists(atPath: sub) {
        do {
          try fm.createDirectory(atPath: sub, withIntermediateDirectories: true, attributes: nil)
        } catch {
          print(error.localizedDescription)
          exit(1)
        }
      }
      if config.write(toFile: plistPath, atomically: true) {
        print("Configuration generated at \(plistPath).")
        try? kReadme.write(toFile: readmePath, atomically: false, encoding: .utf8)
      } else {
        print("Error: cannot write to \(plistPath).")
        exit(1)
      }
    } else {
      if !fm.fileExists(atPath: lpc) {
        do {
          try fm.createDirectory(atPath: lpc, withIntermediateDirectories: true, attributes: nil)
        } catch {
          print(error.localizedDescription)
          exit(1)
        }
      }
      let readmePath = "\(lpc)/README.txt"
      
      if config.write(toFile: "\(lpc)/unknownOEM.plist", atomically: true) {
        print("Configuration generated at \(lpc)/unknownOEM.plist.")
        try? kReadme.write(toFile: readmePath, atomically: false, encoding: .utf8)
      } else {
        print("Error: cannot write to \(lpc)/unknownOEM.plist.")
        exit(1)
      }
    }
  } else {
    print("\nSMCSuperIO not found.")
    exit(1)
  }
}

func clean(path: String) {
  if !fm.fileExists(atPath: path) {
    print("Error: cannot found '\(path)'.")
    exit(1)
  }
  
  if !path.hasSuffix("/LPC") {
    print("Error: last path component is not 'LPC'.")
    exit(1)
  }
  
  let enumerator = fm.enumerator(atPath: path)
  
  while let file = enumerator?.nextObject() as? String {
    let fp = "\(path)/\(file)"
    if file.hasSuffix(".plist") {
      var changes : Int = 0
      guard var dict = NSMutableDictionary(contentsOfFile: fp) as? [String : Any] else {
        print("Error: cannot load '\(fp)' as a valid Dictionary.")
        exit(1)
      }
      
      for k in dict.keys {
        print("Processing \(file)/\(k) Sensor..")
        if var sensor = dict[k] as? [String : Any] {
          // name
          if let name = sensor["name"] {
            if !(name is String) {
              // remove entry because it is not a String
              print("\tremoving name as not a String.")
              sensor["name"] = nil
              changes += 1
            } else {
              if name as! String == k {
                // remove name because it's equal to sensor
                print("\tremoving name because equal to Sensor name.")
                sensor["name"] = nil
                changes += 1
              }
            }
          }
          // multi
          if let multi = sensor["multi"] {
            if !(multi is NSNumber) {
              // remove entry because it is not a NSNumber
              print("\tremoving multi as is not a Number.")
              sensor["multi"] = nil
              changes += 1
            } else {
              if multi as! NSNumber == 0 || multi as! NSNumber == 1 {
                // remove multi because it's equal to 0 (invalid) or 1 (default)
                print("\tremoving multi as 0 or 1 aren't allowed.")
                sensor["multi"] = nil
                changes += 1
              }
            }
            
            if k.uppercased().range(of: "FAN") != nil {
              // remove multi because does nothing for fans
              print("\tremoving multi as for fans does nothing.")
              sensor["multi"] = nil
              changes += 1
            }
          }
          
          // skip
          if let skip = sensor["skip"] {
            if !(skip is Bool) {
              // remove entry because it is not a Boolean
              print("\tremoving skip as is not a Bool.")
              sensor["skip"] = nil
              changes += 1
            } else {
              if skip as! Bool == false {
                // remove skip because false is already the default value
                print("\tremoving skip because false is the default value.")
                sensor["skip"] = nil
                changes += 1
              }
            }
          }
          
          for key in sensor.keys {
            if key != "name" && key != "multi" && key != "skip" {
              // remove key because is unsupported
              print("\tremoving \(key) is not a valid key.")
              sensor[key] = nil
              changes += 1
            }
          }
          
          if sensor.keys.count == 0 {
            // remove entry because it is empty
            print("\tremoving \(k) Sensor because is empty.")
            dict[k] = nil
            changes += 1
          } else {
            dict[k] = sensor
          }
        } else {
          // remove entry because it is not a Dictionary
          print("\tremoving \(k) entry because is not a Dictionary.")
          dict[k] = nil
          changes += 1
        }
      }
      
      if changes > 0 {
        print("\(changes) changes for \(fp).")
        if dict.keys.count > 0 {
          if !(dict as NSDictionary).write(toFile: fp, atomically: true) {
            print("Error: cannot write to \(file).")
            exit(1)
          }
        } else {
          print("Removig \(file) because has no Sensors.")
          try? fm.removeItem(atPath: fp)
        }
      }
    }
  }
}

func run(cmd: String, curDir: String) {
  let task = Process()
  if #available(OSX 10.13, *) {
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
  } else {
    task.launchPath = "/bin/bash"
  }
  task.environment = ProcessInfo.init().environment
  task.currentDirectoryPath = curDir
  task.arguments = ["-c", cmd]
  task.terminationHandler = { t in
    if t.terminationStatus > 0 {
      exit(1)
    }
  }
  task.launch()
  task.waitUntilExit()
}

func releaseBuild() {
  var hwm2Ver = "Unknown"
  let myPath = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
  let appPath = "\(myPath)/HWMonitorSMC2.app"
  let hwmconfPath = "\(myPath)/hwmlpcconfig"
  
  if !fm.fileExists(atPath: appPath) {
    print("Error: HWMonitorSMC2.app not found.")
    exit(1)
  }
  
  if !fm.fileExists(atPath: hwmconfPath) {
    print("Error: hwmlpcconfig not found.")
    exit(1)
  }
  
  if let ver = NSDictionary(contentsOfFile:
    "\(appPath)/Contents/Info.plist")?.object(forKey: "CFBundleShortVersionString") as? String {
    hwm2Ver = ver
  }
  
  run(cmd: "zip -q -r HWMonitorSMC2.app_v\(hwm2Ver).zip HWMonitorSMC2.app", curDir: myPath)
  run(cmd: "zip -q hwmlpcconfig_v\(version).zip hwmlpcconfig", curDir: myPath)
}

if CommandLine.arguments.count == 2 {
  if CommandLine.arguments[1] == "--release" {
    releaseBuild()
  } else {
    printHeader()
    clean(path: CommandLine.arguments[1])
  }
} else {
  printHeader()
  generate()
}


exit(0)
