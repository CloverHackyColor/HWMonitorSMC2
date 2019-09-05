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
 added dump of all keys with detailed descriptions (key with code, size, type with code, attribute and value)
 read of a single key (with the desired type) to return a value as Data
 */

import Foundation

//------------------------------------------------------------------------------
// MARK: SMC Client
//------------------------------------------------------------------------------
/// SMC data type information
public struct DataTypes {
  public static let KEY =
    DataType(type: FourCharCode(fromStaticString: "#KEY"), size: 4,  attribute: 0x80)
  public static let ADR =
    DataType(type: FourCharCode(fromStaticString: "$Adr"), size: 4,  attribute: 0x80)
  public static let NUM =
    DataType(type: FourCharCode(fromStaticString: "$Num"), size: 1,  attribute: 0xD0)
  public static let BEMB =
    DataType(type: FourCharCode(fromStaticString: "BEMB"), size: 1,  attribute: 0x80)
  public static let ALI =
    DataType(type: FourCharCode(fromStaticString: "{ali"), size: 4,  attribute: 0x00)
  public static let ALV =
    DataType(type: FourCharCode(fromStaticString: "{alv"), size: 10, attribute: 0x00)
  public static let CHAR =
    DataType(type: FourCharCode(fromStaticString: "char"), size:  1, attribute: 0x00)
  public static let CH8 =
    DataType(type: FourCharCode(fromStaticString: "ch8*"), size: 32, attribute: 0x00)
  public static let CLH =
    DataType(type: FourCharCode(fromStaticString: "{clh"), size:  8, attribute: 0xD0)
  public static let FDS =
    DataType(type: FourCharCode(fromStaticString: "{fds"), size: 16, attribute: 0x00)
  public static let Flag =
    DataType(type: FourCharCode(fromStaticString: "flag"), size: 1,  attribute: 0x00)
  public static let FLT =
    DataType(type: FourCharCode(fromStaticString: "flt "), size: 4,  attribute: 0x00)
  public static let FP2E =
    DataType(type: FourCharCode(fromStaticString: "fp2e"), size: 2,  attribute: 0x00)
  public static let FP4C =
    DataType(type: FourCharCode(fromStaticString: "fp4c"), size: 2,  attribute: 0x00)
  public static let HEX =
    DataType(type: FourCharCode(fromStaticString: "hex_"), size: 2,  attribute: 0x00)
  public static let LIM =
    DataType(type: FourCharCode(fromStaticString: "{lim"), size: 5,  attribute: 0x00)
  public static let LSO =
    DataType(type: FourCharCode(fromStaticString: "{lso"), size: 2,  attribute: 0x00)
  public static let MSP =
    DataType(type: FourCharCode(fromStaticString: "{msp"), size: 2,  attribute: 0x00)
  public static let REV =
    DataType(type: FourCharCode(fromStaticString: "{rev"), size: 5,  attribute: 0x00)
  public static let SI8 =
    DataType(type: FourCharCode(fromStaticString: "si8 "), size: 1,  attribute: 0x00)
  public static let SP4B =
    DataType(type: FourCharCode(fromStaticString: "sp4b"), size: 2,  attribute: 0x00)
  public static let SP78 =
    DataType(type: FourCharCode(fromStaticString: "sp78"), size: 2,  attribute: 0x00)
  public static let SP96 =
    DataType(type: FourCharCode(fromStaticString: "sp96"), size: 2,  attribute: 0x00)
  public static let FREQ =
    DataType(type: FourCharCode(fromStaticString: "freq"), size: 2,  attribute: 0x00)
  public static let UI8 =
    DataType(type: FourCharCode(fromStaticString: "ui8 "), size: 1,  attribute: 0x00)
  public static let UI16 =
    DataType(type: FourCharCode(fromStaticString: "ui16"), size: 2,  attribute: 0x00)
  public static let UI32 =
    DataType(type: FourCharCode(fromStaticString: "ui32"), size: 4,  attribute: 0x00)
}

public struct SMCKey {
  let code: FourCharCode
  let info: DataType
}

public struct DataType: Equatable {
  let type: FourCharCode
  let size: UInt32
  let attribute: UInt8
}

//------------------------------------------------------------------------------
// MARK: Defined by AppleSMC.kext
//------------------------------------------------------------------------------
/// Defined by AppleSMC.kext
///
/// This is the predefined struct that must be passed to communicate with the
/// AppleSMC driver. While the driver is closed source, the definition of this
/// struct happened to appear in the Apple PowerManagement project at around
/// version 211, and soon after disappeared. It can be seen in the PrivateLib.c
/// file under pmconfigd. Given that it is C code, this is the closest
/// translation to Swift from a type perspective.
///
/// ### Issues
///
/// * Padding for struct alignment when passed over to C side
/// * Size of struct must be 80 bytes
/// * C array's are bridged as tuples 
///
/// http://www.opensource.apple.com/source/PowerManagement/PowerManagement-211/
public struct SMCParamStruct {
  
  /// I/O Kit function selector
  public enum Selector: UInt8 {
    case kSMCHandleYPCEvent  = 2
    case kSMCReadKey         = 5
    case kSMCWriteKey        = 6
    case kSMCGetKeyFromIndex = 8
    case kSMCGetKeyInfo      = 9
  }
  
  /// Return codes for SMCParamStruct.result property
  public enum Result: UInt8 {
    case kSMCSuccess     = 0
    case kSMCError       = 1
    case kSMCKeyNotFound = 132
  }
  
  public struct SMCVersion {
    var major: CUnsignedChar    = 0
    var minor: CUnsignedChar    = 0
    var build: CUnsignedChar    = 0
    var reserved: CUnsignedChar = 0
    var release: CUnsignedShort = 0
  }
  
  public struct SMCPLimitData {
    var version: UInt16   = 0
    var length: UInt16    = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
  }
  
  public struct SMCKeyInfoData {
    /// How many bytes written to SMCParamStruct.bytes
    var dataSize: IOByteCount = 0
    
    /// Type of data written to SMCParamStruct.bytes. This lets us know how
    /// to interpret it (translate it to human readable)
    var dataType: UInt32 = 0
    
    var dataAttributes: UInt8 = 0
  }
  
  /// FourCharCode telling the SMC what we want
  var key: UInt32 = 0
  
  var vers = SMCVersion()
  
  var pLimitData = SMCPLimitData()
  
  var keyInfo = SMCKeyInfoData()
  
  /// Padding for struct alignment when passed over to C side
  var padding: UInt16 = 0
  
  /// Result of an operation
  var result: UInt8 = 0
  
  var status: UInt8 = 0
  
  /// Method selector
  var data8: UInt8 = 0
  
  var data32: UInt32 = 0
  
  /// Data returned from the SMC
  var bytes: SMCBytes = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0))
}
