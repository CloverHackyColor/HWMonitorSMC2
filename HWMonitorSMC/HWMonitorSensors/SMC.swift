//
// SMC.swift
// SMCKit
//
// The MIT License
//
// Copyright (C) 2014-2017  beltex <https://beltex.github.io>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/*
 sun 21 October 2018 vector sigma:
 Added dump of all keys with detailed descriptions (key with code, size, type with code, attribute and value).
 Read of a single key (with the desired type) to return a value as Data.
 No throwing methods as this will stop reading keys in the cases some of them are unreadable.
 
 */

import IOKit
import Foundation

//------------------------------------------------------------------------------
// MARK: Type Aliases
//------------------------------------------------------------------------------
// http://stackoverflow.com/a/22383661
/// Floating point, unsigned, 14 bits exponent, 2 bits fraction
public typealias FPE2 = (UInt8, UInt8)

/// Floating point, signed, 7 bits exponent, 8 bits fraction
public typealias SP78 = (UInt8, UInt8)

public typealias SMCBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
  UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
  UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
  UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
  UInt8, UInt8, UInt8, UInt8)

//------------------------------------------------------------------------------
// MARK: Standard Library Extensions
//------------------------------------------------------------------------------
extension UInt32 {
  
  init(fromBytes bytes: (UInt8, UInt8, UInt8, UInt8)) {
    // TODO: Broken up due to "Expression was too complex" error as of
    //       Swift 4.
    let byte0 = UInt32(bytes.0) << 24
    let byte1 = UInt32(bytes.1) << 16
    let byte2 = UInt32(bytes.2) << 8
    let byte3 = UInt32(bytes.3)
    
    self = byte0 | byte1 | byte2 | byte3
  }
}

extension Bool {
  init(fromByte byte: UInt8) {
    self = byte == 1 ? true : false
  }
}

public extension Int {
  init(fromFPE2 bytes: FPE2) {
    self = (Int(bytes.0) << 6) + (Int(bytes.1) >> 2)
  }
  
  func toFPE2() -> FPE2 {
    return (UInt8(self >> 6), UInt8((self << 2) ^ ((self >> 6) << 8)))
  }
}

extension Double {
  init(fromSP78 bytes: SP78) {
    // FIXME: Handle second byte
    let sign = bytes.0 & 0x80 == 0 ? 1.0 : -1.0
    self = sign * Double(bytes.0 & 0x7F)    // AND to mask sign bit
  }
}

// Thanks to Airspeed Velocity for the great idea!
// http://airspeedvelocity.net/2015/05/22/my-talk-at-swift-summit/
public extension FourCharCode {
  init(fromString str: String) {
    precondition(str.count == 4)
    
    self = str.utf8.reduce(0) { sum, character in
      return sum << 8 | UInt32(character)
    }
  }
  
  init(fromStaticString str: StaticString) {
    precondition(str.utf8CodeUnitCount == 4)
    
    self = str.withUTF8Buffer { buffer in
      // TODO: Broken up due to "Expression was too complex" error as of
      //       Swift 4.
      let byte0 = UInt32(buffer[0]) << 24
      let byte1 = UInt32(buffer[1]) << 16
      let byte2 = UInt32(buffer[2]) << 8
      let byte3 = UInt32(buffer[3])
      
      return byte0 | byte1 | byte2 | byte3
    }
  }
  
  func toString() -> String {
    return "\(String(describing: UnicodeScalar(self >> 24 & 0xff)!))\(String(describing: UnicodeScalar(self >> 16 & 0xff)!))\(String(describing: UnicodeScalar(self >> 8  & 0xff)!))\(String(describing: UnicodeScalar(self       & 0xff)!))"
    /*
    return String(describing: UnicodeScalar(self >> 24 & 0xff)!) +
      String(describing: UnicodeScalar(self >> 16 & 0xff)!) +
      String(describing: UnicodeScalar(self >> 8  & 0xff)!) +
      String(describing: UnicodeScalar(self       & 0xff)!)*/
  }
}

public func ==(lhs: DataType, rhs: DataType) -> Bool {
  return lhs.type == rhs.type && lhs.size == rhs.size && lhs.attribute == rhs.attribute
}

/// Apple System Management Controller (SMC) user-space client for Intel-based
/// Macs. Works by talking to the AppleSMC.kext (kernel extension), the closed
/// source driver for the SMC.
public struct SMCKit {
  
  public enum SMCError: Error {
    
    /// AppleSMC driver not found
    case driverNotFound
    
    /// Failed to open a connection to the AppleSMC driver
    case failedToOpen
    
    /// This SMC key is not valid on this machine
    case keyNotFound(code: String)
    
    /// Requires root privileges
    case notPrivileged
    
    /// Fan speed must be > 0 && <= fanMaxSpeed
    case unsafeFanSpeed
    
    /// https://developer.apple.com/library/mac/qa/qa1075/_index.html
    ///
    /// - parameter kIOReturn: I/O Kit error code
    /// - parameter SMCResult: SMC specific return code
    case unknown(kIOReturn: kern_return_t, SMCResult: UInt8)
  }
  
  /// Connection to the SMC driver
  fileprivate static var connection: io_connect_t = 0
  
  /// Open connection to the SMC driver. This must be done first before any
  /// other calls
  fileprivate static func open() -> Bool {
    let service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                              IOServiceMatching("AppleSMC"))
    
    if service == 0 {
      print(SMCError.driverNotFound)
      return false
    }
    
    let result = IOServiceOpen(service, mach_task_self_, 0,
                               &SMCKit.connection)
    IOObjectRelease(service)
    
    if result != kIOReturnSuccess { print(SMCError.failedToOpen) }
    return result == kIOReturnSuccess
  }
  
  /// Close connection to the SMC driver
  @discardableResult
  fileprivate static func close() -> Bool {
    let result = IOServiceClose(SMCKit.connection)
    return result == kIOReturnSuccess ? true : false
  }
  
  /// Get information about a key
  fileprivate static func keyInformation(_ key: FourCharCode) -> DataType? {
    var inputStruct = SMCParamStruct()
    
    inputStruct.key = key
    inputStruct.data8 = SMCParamStruct.Selector.kSMCGetKeyInfo.rawValue
   
    if let outputStruct = callDriver(&inputStruct) {
      return DataType(type: outputStruct.keyInfo.dataType,
                      size: outputStruct.keyInfo.dataSize,
                      attribute: outputStruct.keyInfo.dataAttributes)
    }
    
    return nil
  }
  
  public func getType(key: FourCharCode) -> DataType? {
    var type : DataType? = nil
    if SMCKit.open() {
      type = SMCKit.keyInformation(key)
    }
    SMCKit.close()
    return type
  }
  
  /// Get information about the key at index
  fileprivate static func keyInformationAtIndex(_ index: Int) -> FourCharCode? {
    var inputStruct = SMCParamStruct()
    
    inputStruct.data8 = SMCParamStruct.Selector.kSMCGetKeyFromIndex.rawValue
    inputStruct.data32 = UInt32(index)
    
    if let outputStruct = callDriver(&inputStruct) {
      return outputStruct.key
    }
    
    return nil
  }
  
  /// Read data of a key
  fileprivate static func readData(_ key: SMCKey) -> SMCBytes? {
    var inputStruct = SMCParamStruct()
    
    inputStruct.key = key.code
    inputStruct.keyInfo.dataSize = UInt32(key.info.size)
    inputStruct.data8 = SMCParamStruct.Selector.kSMCReadKey.rawValue
    
    if let outputStruct = callDriver(&inputStruct) {
      return outputStruct.bytes
    }
    
    return nil
  }
  
  /// Write data for a key
  fileprivate static func writeData(_ key: SMCKey, data: SMCBytes) {
    var inputStruct = SMCParamStruct()
    
    inputStruct.key = key.code
    inputStruct.bytes = data
    inputStruct.keyInfo.dataSize = UInt32(key.info.size)
    inputStruct.data8 = SMCParamStruct.Selector.kSMCWriteKey.rawValue
    
    _ = callDriver(&inputStruct)
  }
  
  /// Make an actual call to the SMC driver
  fileprivate static func callDriver(_ inputStruct: inout SMCParamStruct,
                                     selector: SMCParamStruct.Selector = .kSMCHandleYPCEvent) -> SMCParamStruct? {
      assert(MemoryLayout<SMCParamStruct>.stride == 80, "SMCParamStruct size is != 80")
      var outputStruct = SMCParamStruct()
      let inputStructSize = MemoryLayout<SMCParamStruct>.stride
      var outputStructSize = MemoryLayout<SMCParamStruct>.stride
      
      let result = IOConnectCallStructMethod(SMCKit.connection,
                                             UInt32(selector.rawValue),
                                             &inputStruct,
                                             inputStructSize,
                                             &outputStruct,
                                             &outputStructSize)
      
      switch (result, outputStruct.result) {
      case (kIOReturnSuccess, SMCParamStruct.Result.kSMCSuccess.rawValue):
        return outputStruct
      case (kIOReturnSuccess, SMCParamStruct.Result.kSMCKeyNotFound.rawValue):
        break
      case (kIOReturnNotPrivileged, _):
        print("\(inputStruct.key.toString()): \(SMCError.notPrivileged)")
      default:
        break
      }
    return nil
  }
  
  /// Get all valid SMC keys for this machine
  fileprivate static func allKeys() -> [SMCKey] {
    let count = keyCount()
    var keys = [SMCKey]()
    
    for i in 0 ..< count {
      if let key = keyInformationAtIndex(i) {
        if let info = keyInformation(key) {
          keys.append(SMCKey(code: key, info: info))
        }
      }
    }
    
    return keys
  }
  
  /// Get the number of valid SMC keys for this machine
  fileprivate static func keyCount() -> Int {
    let key = SMCKey(code: FourCharCode(fromStaticString: "#KEY"),
                     info: DataTypes.KEY)
    
    if let data = readData(key) {
      return Int(UInt32(fromBytes: (data.0, data.1, data.2, data.3)))
    }
    return 0
  }
  
  /// Is this key valid on this machine?
  fileprivate static func isKeyFound(_ code: FourCharCode) -> Bool {
    return keyInformation(code) != nil
  }
  
  public func read(key: String, type: DataType) -> Data? {
    var data : Data? = nil
    if key.count != 4 { return data }
    
    if SMCKit.open() {
      let k = SMCKey(code: FourCharCode(fromString: key), info: type)
      if let bytes : SMCBytes = SMCKit.readData(k) {
        let mirror = Mirror(reflecting: bytes)
        var d : Data = Data()
        var i : Int = 0
        for c in mirror.children {
          i += 1
          d.append(c.value as! UInt8)
          if i == k.info.size {break}
        }
        data = d
        var t: String = String(k.info.type.toString())
        
        let chars = [Character](t)
        if chars[3] == "\0" { t = String(k.info.type.toString().dropLast()) }
        /*
         let type : String = "\(t)".padding(toLength: 4, withPad: " ", startingAt: 0)
         print("key: \(k.code.toString()), code: \(String(format: "%10d", k.code)), size: \(String(format: "%02d", k.info.size)), type: \(type) [\(k.info.type)], attr: \(String(format: "%02X", k.info.attribute)), value: \(d as NSData)")*/
      }
      
    }

    SMCKit.close()
    
    if (data != nil && data!.count == 0) {
      data = nil
    }
    
    return data
  }
  
  private func isPrivate(key: String) -> Bool {
    let prvt = ["RMAC", "RMSN", "RSSN" ]
    return prvt.contains(key)
  }
  
  public func dumpSMCKeys() -> String {
    var dump : String = ""
    if SMCKit.open() {
      for k in SMCKit.allKeys() {
        let key : String = k.code.toString()
        let prvt : String = self.isPrivate(key: key) ? " --> PRIVATE KEY DON'T SHARE!" : ""
        if let bytes : SMCBytes = SMCKit.readData(SMCKey(code: k.code, info: k.info)) {
          let mirror = Mirror(reflecting: bytes)
          var data : Data = Data()
          var i : Int = 0
          for c in mirror.children {
            i += 1
            data.append(c.value as! UInt8)
            if i == k.info.size {break}
          }
          var t: String = String(k.info.type.toString())
          
          let chars = [Character](t)
          if chars[3] == "\0" { t = String(k.info.type.toString().dropLast()) }
          let type : String = "\(t)".padding(toLength: 4, withPad: " ", startingAt: 0)
          let info : String = "key: \(key), size: \(String(format: "%02d", k.info.size)), type: \(type), attr: \(String(format: "%02X", k.info.attribute)), value: \(data as NSData)\(prvt)\n"
          dump += info
        }
      }
    }

    SMCKit.close()
    return dump
  }
}



