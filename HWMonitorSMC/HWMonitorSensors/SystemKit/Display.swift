//
//  Display.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 25/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import IOKit.graphics
import Cocoa

extension Data {
  var checksum: Int {
    return self.map { Int($0) }.reduce(0, +) & 0xff
  }
}

public struct Display {
  //--------------------------------------------------------------------------
  // MARK: PUBLIC INITIALIZERS
  //--------------------------------------------------------------------------
  
  
  public init() { }
  
  //--------------------------------------------------------------------------
  // MARK: EDID
  //--------------------------------------------------------------------------
  
  
  fileprivate struct TimingDescription {
    var PixelClock                    : [UInt8] = [UInt8](repeating: 0, count: 2)
    var HorizontalActive              : UInt8  = 0
    var HorizontalBlanking            : UInt8  = 0
    var HorizontalActiveHB            : UInt8  = 0
    var VerticalActive                : UInt8  = 0
    var VerticalBlanking              : UInt8  = 0
    var VerticalActiveVB              : UInt8  = 0
    var HorizontalSyncOffset          : UInt8  = 0
    var HorizontalSyncPulseWidth      : UInt8  = 0
    var VerticalSyncOffsetVSPW        : UInt8  = 0
    var HSO_HSPW_VSO_VSPW             : UInt8  = 0
    var HorizontalImageSize           : UInt8  = 0
    var VerticalImageSize             : UInt8  = 0
    var HorizontalAndVerticalImageSize: UInt8  = 0
    var HorizontalBorder              : UInt8  = 0
    var VerticalBorder                : UInt8  = 0
    var Flags                         : UInt8  = 0
  }
  fileprivate typealias EDID_TD = TimingDescription
  
  fileprivate struct EDID_BLOCK {
    var Header                        : [UInt8] = [UInt8](repeating: 0, count: 8) //EDID header "00 FF FF FF FF FF FF 00"
    var ManufactureName               : [UInt8] = [UInt8](repeating: 0, count: 2) //EISA 3-character ID
    var ProductCode                   : [UInt8] = [UInt8](repeating: 0, count: 2)//Vendor assigned code
    var SerialNumber                  : UInt32  = 0                               //32-bit serial number
    var WeekOfManufacture             : UInt8   = 0                               //Week number
    var YearOfManufacture             : UInt8   = 0                               //Year
    var EdidVersion                   : UInt8   = 0                               //EDID Structure Version
    var EdidRevision                  : UInt8   = 0                               //EDID Structure Revision
    var VideoInputDefinition          : UInt8   = 0
    var MaxHorizontalImageSize        : UInt8   = 0                               //cm
    var MaxVerticalImageSize          : UInt8   = 0                               //cm
    var DisplayTransferCharacteristic : UInt8   = 0
    var FeatureSupport                : UInt8   = 0
    var RedGreenLowBits               : UInt8   = 0                               //Rx1 Rx0 Ry1 Ry0 Gx1 Gx0 Gy1Gy0
    var BlueWhiteLowBits              : UInt8   = 0                               //Bx1 Bx0 By1 By0 Wx1 Wx0 Wy1 Wy0
    var RedX                          : UInt8   = 0                               //Red-x Bits 9 - 2
    var RedY                          : UInt8   = 0                               //Red-y Bits 9 - 2
    var GreenX                        : UInt8   = 0                               //Green-x Bits 9 - 2
    var GreenY                        : UInt8   = 0                               //Green-y Bits 9 - 2
    var BlueX                         : UInt8   = 0                               //Blue-x Bits 9 - 2
    var BlueY                         : UInt8   = 0                               //Blue-y Bits 9 - 2
    var WhiteX                        : UInt8   = 0                               //White-x Bits 9 - 2
    var WhiteY                        : UInt8   = 0                               //White-x Bits 9 - 2
    var EstablishedTimings            : [UInt8] = [UInt8](repeating: 0, count: 3)
    var StandardTimingIdentification  : [UInt8] = [UInt8](repeating: 0, count: 16)
    var DetailedTimingDescriptions = [EDID_TD](repeating: EDID_TD(), count: 4)
    var ExtensionFlag                 : UInt8   = 0                               //Number of (optional) 128-byte EDID extension blocks to follow
    var Checksum                      : UInt8   = 0
    
    // designed initializer
    init(from data: Data) {
      if data.count >= 128 {
        for i in 0..<8 {
          self.Header[i] = data[i]
        }

        self.ManufactureName[0] = data[8]
        self.ManufactureName[1] = data[9]
        self.ProductCode[0]     = data[10]
        self.ProductCode[1]     = data[11]
 
        var n32: UInt32 = 0
        let ad : NSData = Data.init([data[12],
                   data[13],
                   data[14],
                   data[15]]) as NSData
      
        ad.getBytes(&n32, length: MemoryLayout<UInt32>.size)
        self.SerialNumber = UInt32(littleEndian: n32)
        
        self.WeekOfManufacture = data[16]
        self.YearOfManufacture = data[17]
        self.EdidVersion = data[18]
        self.EdidRevision = data[19]
        self.VideoInputDefinition = data[20]
        self.MaxHorizontalImageSize = data[21]
        self.MaxVerticalImageSize = data[22]
        self.DisplayTransferCharacteristic = data[23]
        self.FeatureSupport = data[24]
        self.RedGreenLowBits = data[25]
        self.BlueWhiteLowBits = data[26]
        self.RedX = data[27]
        self.RedY = data[28]
        self.GreenX = data[29]
        self.GreenY = data[30]
        self.BlueX = data[31]
        self.BlueY = data[32]
        self.WhiteX = data[33]
        self.WhiteY = data[34]
        
        for i in 0..<3 {
          self.EstablishedTimings[i] = data[35 + i]
        }
        
        for i in 0..<16 {
          self.StandardTimingIdentification[i] = data[38 + i]
        }
        var tdi: Int = 54
        for i in 0..<4 {
          var TD : EDID_TD = EDID_TD()
          TD.PixelClock[0]                  = data[tdi]
          TD.PixelClock[1]                  = data[tdi + 1]
          TD.HorizontalActive               = data[tdi + 2]
          TD.HorizontalBlanking             = data[tdi + 3]
          TD.HorizontalActiveHB             = data[tdi + 4]
          TD.VerticalActive                 = data[tdi + 5]
          TD.VerticalBlanking               = data[tdi + 6]
          TD.VerticalActiveVB               = data[tdi + 7]
          TD.HorizontalSyncOffset           = data[tdi + 8]
          TD.HorizontalSyncPulseWidth       = data[tdi + 9]
          TD.VerticalSyncOffsetVSPW         = data[tdi + 10]
          TD.HSO_HSPW_VSO_VSPW              = data[tdi + 11]
          TD.HorizontalImageSize            = data[tdi + 12]
          TD.VerticalImageSize              = data[tdi + 13]
          TD.HorizontalAndVerticalImageSize = data[tdi + 14]
          TD.HorizontalBorder               = data[tdi + 15]
          TD.VerticalBorder                 = data[tdi + 16]
          TD.Flags                          = data[tdi + 17]
          self.DetailedTimingDescriptions[i] = TD
          tdi += 18
        }
        
        self.ExtensionFlag = data[126]
        self.Checksum = data[127]
      }
    }
  }
  fileprivate typealias EDID = EDID_BLOCK
  
  //--------------------------------------------------------------------------
  // MARK: public functions
  //--------------------------------------------------------------------------
  /**
   return detailed info about main screen only
   */
  public static func getMainScreenInfo() -> String {
    var displayLocations : [String] = [String]()
    if let screen = NSScreen.main {
      return Display.getDisplayInfo(screen: screen, displayLocations: &displayLocations)
    }
    return ""
  }
  
  /**
   return detailed info about all screens
   */
  public static func getScreensInfo() -> String {
    var displayLocations : [String] = [String]()
    var log : String = ""
    let screens = NSScreen.screens
    var count : Int = 0
    for screen in screens {
      log += "SCREEN \(count + 1):\n"
      log += Display.getDisplayInfo(screen: screen, displayLocations: &displayLocations)
      log += "\n"
      count += 1
    }
    return log
  }
  
  //--------------------------------------------------------------------------
  // MARK: Display Info
  //--------------------------------------------------------------------------
  
  /**
   function to find detailed info about NSScreen objects.
   Only one problem: users can have multiple displays with the same vendor id and product id,
   but kDisplaySerialString and kDisplaySerialNumber not always are present:
   the difference surely is the kIODisplayLocationKey (path in the IOService).
   Iterating screens the code should break only if "displayLocations" doesn't contains
   the current location.
   Hoping IOKit and NSScreen returns in the same order..but anyway.. who cares?
   */
  fileprivate static func getDisplayInfo(screen: NSScreen, displayLocations: inout [String]) -> String {
    var edid: EDID? = nil
    var edidVer : Int = 0
    var edidRev : Int = 0
    var useAppleStuff : Bool = true // default
    var statusString : String = ""
    var productName : String = "Unknown"
    let deviceDescription = screen.deviceDescription
    let screenNumber : NSNumber = deviceDescription[NSDeviceDescriptionKey.init(rawValue: "NSScreenNumber")] as! NSNumber
    let size : NSSize = deviceDescription[NSDeviceDescriptionKey.init(rawValue: "NSDeviceSize")] as! NSSize
    
    statusString += "\tFramebuffer:\t\(String(format: "0x%X", screenNumber.uint32Value))\n"
    
    if let info = Display.GetInfoFromCGDisplayID(displayID: screenNumber.uint32Value,
                                                 displayLocations: &displayLocations) {
      
      /*
       We must ensure the validity of the EDID:
       1) must be not nil :-)
       2) must be at least 128 bytes (can have extensions so additionals 128 per extensions)
       3) be sure is not version 2.0 because was suddently deprecated
       .. otherwise let search stuff published in the IOReg by Apple and by NSScreen class ...
       */
      
      let IODisplayEDID : Data? = info.object(forKey: kIODisplayEDIDKey) as? Data
      
      if (IODisplayEDID != nil) {
        edid = EDID.init(from: IODisplayEDID!)
        let dataCount : Int = (IODisplayEDID?.count)!
        edidVer = Int(edid!.EdidVersion)
        edidRev = Int(edid!.EdidRevision)
        if dataCount >= 128 && edidVer == 1 /* 2 is not good */ {
          useAppleStuff = false
        }
      }

      if useAppleStuff {
        statusString += "\tSize:\t\t\t\t\t\(Int(size.width))x\(Int(size.height))\n"
        statusString += "\tDepth bits Per Pixel:\t\t\(screen.depth.bitsPerPixel)\n"
        statusString += "\tDepth bits Per Sample:\t\t\(screen.depth.bitsPerSample)\n"
        statusString += "\tDepth is Planar:\t\t\t\(screen.depth.isPlanar)\n"
        statusString += "\tFrame:\t\t\t\t\(screen.frame)\n"
        statusString += "\tVisible Frame:\t\t\t\(screen.visibleFrame)\n"
        statusString += "\tDepth backing Scale Factor:\t\(screen.backingScaleFactor)\n"
        statusString += "\n"
        
        if let localizedNames : NSDictionary = info.object(forKey: kDisplayProductName) as? NSDictionary {
          if (localizedNames.object(forKey: "en_US") != nil) {
            productName = localizedNames.object(forKey: "en_US") as! String
          }
        }
        
        statusString += "\tName:\t\t\t\t\(productName)\n"
        if let vendorID : NSNumber = info.object(forKey: kDisplayVendorID) as? NSNumber {
          statusString += "\tVendor Id:\t\t\t\t\(String(format: "0x%X", vendorID.uint32Value)) (\(vendorID.uint32Value))\n"
        }
        if let productID : NSNumber = info.object(forKey: kDisplayProductID) as? NSNumber {
          statusString += "\tProduct Id:\t\t\t\t\(String(format: "0x%X", productID.uint32Value)) (\(productID.uint32Value))\n"
        }
        if let DisplaySerialNumber : NSNumber = info.object(forKey: kDisplaySerialNumber) as? NSNumber {
          statusString += "\tSerial Number:\t\t\t\(DisplaySerialNumber.intValue)\n"
        }
        if let DisplaySerialString : String = info.object(forKey: kDisplaySerialString) as? String {
          statusString += "\tSerial (string):\t\t\t\(DisplaySerialString)\n"
        }
        if let DisplayYearOfManufacture : NSNumber = info.object(forKey: kDisplayYearOfManufacture) as? NSNumber {
          statusString += "\tYear Of Manufacture:\t\t\(DisplayYearOfManufacture.intValue)\n"
        }
        if let DisplayWeekOfManufacture : NSNumber = info.object(forKey: kDisplayWeekOfManufacture) as? NSNumber {
          statusString += "\tWeek of Manufacture:\t\t\(DisplayWeekOfManufacture.intValue)\n"
        }
        if let DisplayBluePointX : NSNumber = info.object(forKey: kDisplayBluePointX) as? NSNumber {
          statusString += "\tBlue Point X:\t\t\t\(String(format: "%.2f", DisplayBluePointX.doubleValue))\n"
        }
        if let DisplayBluePointY : NSNumber = info.object(forKey: kDisplayBluePointY) as? NSNumber {
          statusString += "\tBlue Point Y:\t\t\t\(String(format: "%.2f", DisplayBluePointY.doubleValue))\n"
        }
        if let DisplayGreenPointX : NSNumber = info.object(forKey: kDisplayGreenPointX) as? NSNumber {
          statusString += "\tGreen Point Y:\t\t\t\(String(format: "%.2f", DisplayGreenPointX.doubleValue))\n"
        }
        if let DisplayGreenPointY : NSNumber = info.object(forKey: kDisplayGreenPointY) as? NSNumber {
          statusString += "\tGreen Point Y:\t\t\t\(String(format: "%.2f", DisplayGreenPointY.doubleValue))\n"
        }
        if let DisplayRedPointX : NSNumber = info.object(forKey: kDisplayRedPointX) as? NSNumber {
          statusString += "\tRed Point X:\t\t\t\(String(format: "%.2f", DisplayRedPointX.doubleValue))\n"
        }
        if let DisplayRedPointY : NSNumber = info.object(forKey: kDisplayRedPointY) as? NSNumber {
          statusString += "\tRed Point Y:\t\t\t\(String(format: "%.2f", DisplayRedPointY.doubleValue))\n"
        }
        if let DisplayWhitePointX : NSNumber = info.object(forKey: kDisplayWhitePointX) as? NSNumber {
          statusString += "\tWhite Point X:\t\t\t\(String(format: "%.2f", DisplayWhitePointX.doubleValue))\n"
        }
        if let DisplayWhitePointY : NSNumber = info.object(forKey: kDisplayWhitePointY) as? NSNumber {
          statusString += "\tWhite Point Y:\t\t\t\(String(format: "%.2f", DisplayWhitePointY.doubleValue))\n"
        }
        if let DisplayWhiteGamma : NSNumber = info.object(forKey: kDisplayWhiteGamma) as? NSNumber {
          statusString += "\tWhite Gamma:\t\t\t\(String(format: "%.2f", DisplayWhiteGamma.doubleValue))\n"
        }
        if let DisplayBrightnessAffectsGamma : NSNumber = info.object(forKey: kDisplayBrightnessAffectsGamma) as? NSNumber {
          statusString += "\tBrightness Affects Gamma:\t\(DisplayBrightnessAffectsGamma.boolValue)\n"
        }
        if let DisplayHorizontalImageSize : NSNumber = info.object(forKey: kDisplayHorizontalImageSize) as? NSNumber {
          statusString += "\tHorizontal Image Size:\t\t\(DisplayHorizontalImageSize.intValue)\n"
        }
        if let DisplayVerticalImageSize : NSNumber = info.object(forKey: kDisplayVerticalImageSize) as? NSNumber {
          statusString += "\tVertical Image Size:\t\t\(DisplayVerticalImageSize.intValue)\n"
        }
        if let IODisplayHasBacklight : NSNumber = info.object(forKey: kIODisplayHasBacklightKey) as? NSNumber {
          statusString += "\tHas Back light:\t\t\t\(IODisplayHasBacklight.boolValue)\n"
        }
        if let IODisplayIsDigital : NSNumber = info.object(forKey: kIODisplayIsDigitalKey) as? NSNumber {
          statusString += "\tIs Digital:\t\t\t\t\(IODisplayIsDigital.boolValue)\n"
        }
        if let IODisplayIsHDMISink : NSNumber = info.object(forKey: "IODisplayIsHDMISink") as? NSNumber {
          statusString += "\tIs HDMI Sink:\t\t\t\(IODisplayIsHDMISink.boolValue)\n"
        }
        
        if (IODisplayEDID != nil) {
          let bytes = [UInt8](IODisplayEDID!)
 
          statusString += "\n\tEDID data:\n"
          var byte8Count = 0
          var byteCount = 0
          for byte in bytes {
            byte8Count += 1
            byteCount += 1
            let indent = (byte8Count == 1) ? "\t" : ""
            let eol = (byte8Count == 8) ? "\n" : ""
            
            if byte8Count == 8 {
              byte8Count = 0
            }
            // separating bytes with a comma helps developers ;-)
            statusString += indent + String(format: "0x%02X", byte) + ((byteCount < bytes.count) ? ", " : "") + eol
          }
        }
      } else {
        /*
         embedded parser
        */
        let monitorVendor = String(bytes: IODisplayEDID!.subdata(in: 94..<106), encoding: .ascii) ?? "Unknown"
        let monitorModel = String(bytes: IODisplayEDID!.subdata(in: 112..<124), encoding: .ascii) ?? "Unknown"
        
        statusString += "\tEDID contents:\n\n"
        statusString += "\tHeader:\t\t\(Data(edid!.Header).hexadecimal())\n"
        statusString += "\tSerial number:\t\(edid!.SerialNumber.data.hexadecimal())\n"
        statusString += "\tVersion:\t\t\(edid!.EdidVersion.data.hexadecimal()) \(edid!.EdidRevision.data.hexadecimal())\n"
        statusString += "\tBasic params\t\(edid!.VideoInputDefinition.data.hexadecimal()) \(edid!.MaxHorizontalImageSize.data.hexadecimal())"
        statusString += " \(edid!.MaxVerticalImageSize.data.hexadecimal()) \(edid!.DisplayTransferCharacteristic.data.hexadecimal())"
        statusString += " \(edid!.FeatureSupport.data.hexadecimal())\n"
        
        statusString += "\tChroma info:\t\(edid!.RedGreenLowBits.data.hexadecimal()) \(edid!.BlueWhiteLowBits.data.hexadecimal())"
        statusString += " \(edid!.RedX.data.hexadecimal()) \(edid!.RedY.data.hexadecimal())"
        statusString += " \(edid!.GreenX.data.hexadecimal()) \(edid!.GreenY.data.hexadecimal())"
        statusString += " \(edid!.BlueX.data.hexadecimal()) \(edid!.BlueY.data.hexadecimal())"
        statusString += " \(edid!.WhiteX.data.hexadecimal()) \(edid!.WhiteY.data.hexadecimal())\n"
        
        statusString += "\tEstablished:\t\(Data(edid!.EstablishedTimings).hexadecimal())\n"
        
        statusString += "\tStandard:\t\t\(Data(edid!.StandardTimingIdentification).hexadecimal())\n"
        
        statusString += "\tDescriptor 1:\t\(IODisplayEDID!.subdata(in: 54..<72).hexadecimal())\n"
        statusString += "\tDescriptor 2:\t\(IODisplayEDID!.subdata(in: 72..<90).hexadecimal())\n"
        statusString += "\tDescriptor 3:\t\(IODisplayEDID!.subdata(in: 90..<108).hexadecimal())\n"
        statusString += "\tDescriptor 4:\t\(IODisplayEDID!.subdata(in: 108..<126).hexadecimal())\n"
        
        statusString += "\tExtension:\t\t\(edid!.ExtensionFlag.data.hexadecimal())\n"
        statusString += "\tChecksum:\t\t\(edid!.Checksum.data.hexadecimal())\n"
        statusString += "\n"
        
        // check the header
        for i in 0..<edid!.Header.count {
          var byte : UInt8 = 0xFF
          switch i {
          case 0: fallthrough
          case 7:
            byte = 0x00
          default:
            break
          }
          if edid!.Header[i] != byte {
            statusString += "\tHeader is not valid!\n" // wha to do? ... returning?
            break
          }
        }
        
        let ManuString = monitorVendor.trimmingCharacters(in: .whitespacesAndNewlines)
        
        statusString += "\tManufacturer: \(Data(edid!.ManufactureName).hexadecimal().replacingOccurrences(of: " ", with: "")) (\(ManuString))\n"
        statusString += "\tModel: \(Data(edid!.ProductCode).hexadecimal().replacingOccurrences(of: " ", with: ""))\n"
        statusString += "\tSerial Number: \(edid!.SerialNumber)\n"
        statusString += "\tResolution: \(Int(size.width))x\(Int(size.height))\n"
        // WeekOfManufacture can be 0, so not used!
        let week : Int = Int(edid!.WeekOfManufacture)
        if week > 0  && week < 54 {
          statusString += "\tMade week \(week) of \(Int(edid!.YearOfManufacture) + 1990)\n"
        } else {
          statusString += "\tMade in \(Int(edid!.YearOfManufacture) + 1990)\n"
        }
        
        statusString += "\tEDID version: \(edidVer).\(edidRev)\n"
        
        let isDigital = (((edid!.VideoInputDefinition >> 7)  & 0x01) == 1)
        statusString += "\t\(isDigital ? "Digital display" : "Analog display")\n"
        
        var EstablishedTimings : [String] = [String]()
        if ((edid!.EstablishedTimings[0] >> 7) & 0x01) == 1 { EstablishedTimings.append("720×400 @ 70 Hz") }
        if ((edid!.EstablishedTimings[0] >> 6) & 0x01) == 1 { EstablishedTimings.append("720×400 @ 88 Hz") }
        if ((edid!.EstablishedTimings[0] >> 5) & 0x01) == 1 { EstablishedTimings.append("640×480 @ 60 Hz") }
        if ((edid!.EstablishedTimings[0] >> 4) & 0x01) == 1 { EstablishedTimings.append("640×480 @ 67 Hz") }
        if ((edid!.EstablishedTimings[0] >> 3) & 0x01) == 1 { EstablishedTimings.append("640×480 @ 72 Hz") }
        if ((edid!.EstablishedTimings[0] >> 2) & 0x01) == 1 { EstablishedTimings.append("640×480 @ 75 Hz") }
        if ((edid!.EstablishedTimings[0] >> 1) & 0x01) == 1 { EstablishedTimings.append("800×600 @ 56 Hz") }
        if ((edid!.EstablishedTimings[0] >> 0) & 0x01) == 1 { EstablishedTimings.append("800×600 @ 60 Hz") }
        
        if ((edid!.EstablishedTimings[1] >> 7) & 0x01) == 1 { EstablishedTimings.append("800×600 @ 72 Hz") }
        if ((edid!.EstablishedTimings[1] >> 6) & 0x01) == 1 { EstablishedTimings.append("800×600 @ 75 Hz") }
        if ((edid!.EstablishedTimings[1] >> 5) & 0x01) == 1 { EstablishedTimings.append("832×624 @ 75 H") }
        if ((edid!.EstablishedTimings[1] >> 4) & 0x01) == 1 { EstablishedTimings.append("1024×768 @ 87 Hz, interlaced (1024×768i)") }
        if ((edid!.EstablishedTimings[1] >> 3) & 0x01) == 1 { EstablishedTimings.append("1024×768 @ 60 Hz") }
        if ((edid!.EstablishedTimings[1] >> 2) & 0x01) == 1 { EstablishedTimings.append("1024×768 @ 72 Hz") }
        if ((edid!.EstablishedTimings[1] >> 1) & 0x01) == 1 { EstablishedTimings.append("1024×768 @ 75 Hz") }
        if ((edid!.EstablishedTimings[1] >> 0) & 0x01) == 1 { EstablishedTimings.append("1280×1024 @ 75 Hz") }
        
        if ((edid!.EstablishedTimings[2] >> 0) & 0x01) == 1 { EstablishedTimings.append("1152x870 @ 75 Hz (Apple Macintosh II)") }
        if EstablishedTimings.count > 0 {
          statusString += "\tEstablished Timings:\n"
          for et in EstablishedTimings {
            statusString += "\t\t\(et)\n"
          }
        }
        
        //TODO: add 'Color formats supported' and 'bits per channel'
        
        let detailedTimings : [EDID_TD] = edid!.DetailedTimingDescriptions
        var TimingStrings : [String] = [String]()
        
        for i in 0..<detailedTimings.count {
          let TD = detailedTimings[i]
          let isPreferredTiming : Bool = (i == 0) // the preferred timing is always the first
          var sub : String = "\tDetailed mode (descriptor \(i + 1)):\n"
          let HorizontalActive : Int = Int(TD.HorizontalActive) + (Int(TD.HorizontalActiveHB) & 0xF0) << 4
          let VerticalActive : Int = Int(TD.VerticalActive) + (Int(TD.VerticalActiveVB) & 0xF0) << 4
          if HorizontalActive != 0x00 && VerticalActive != 0x00 {
            let HorizontalBlanking : Int = Int(TD.HorizontalBlanking) + ((Int(TD.HorizontalActiveHB) & 0x0f) << 8)
            let PixelClock : Double = Double((Int(TD.PixelClock[0]) << 8) | Int(TD.PixelClock[1])) / 100
            let VerticalBlanking : Int = Int(TD.VerticalBlanking) + ((Int(TD.VerticalActiveVB) & 0x0f) << 8)
            let HorizontalSyncOffset : Int = Int(TD.HorizontalSyncOffset | TD.HSO_HSPW_VSO_VSPW << 2)
            let HorizontalSyncPulse : Int = Int(TD.HorizontalSyncPulseWidth | (TD.HSO_HSPW_VSO_VSPW & 0x30) << 4)
            let vso = (TD.VerticalSyncOffsetVSPW & 0xF0) >> 4 | (TD.HSO_HSPW_VSO_VSPW & 0x0C) << 2
            let VerticalSyncOffset : Int = Int(vso)
            let VerticalSyncPulse = (Int(TD.VerticalSyncOffsetVSPW) & 0x0f) | ((Int(TD.HSO_HSPW_VSO_VSPW) & 0x03) << 4)
            
            let isInterlaced : Bool = (TD.Flags & 0x80) != 0
            
            sub += "\t\tPixel Clock:\t\t\(PixelClock)MHz\n"
            sub += "\t\tHorizontal Active:\t\(HorizontalActive)\n"
            sub += "\t\tHorizontal Blanking:\t\(HorizontalBlanking)\n"
            sub += "\t\tVertical Active:\t\t\(VerticalActive)\n"
            sub += "\t\tVertical Blanking:\t\(VerticalBlanking)\n"
            sub += "\t\tHorizontal Sync Offset:\t\(HorizontalSyncOffset)\n"
            sub += "\t\tHorizontal Sync Pulse:\t\(HorizontalSyncPulse)\n"
            sub += "\t\tVertical Sync Offset:\t\(VerticalSyncOffset)\n"
            sub += "\t\tVertical Sync Pulse:\t\(VerticalSyncPulse)\n"
            sub += "\t\tInterlaced:\t\t\t\(isInterlaced)\n"
            sub += "\t\tIs preferred timing:\t\(isPreferredTiming)\n"
            TimingStrings.append(sub)
          }
        }
        
        if TimingStrings.count > 0 {
          for i in 0..<TimingStrings.count {
            statusString += TimingStrings[i]
          }
        }
        statusString += "\tMaximum image size: \(Int(edid!.MaxHorizontalImageSize) * 10 )mm x \(Int(edid!.MaxVerticalImageSize) * 10)mm\n"
        
        // gamma can be FF, range 1.00 → 3.54
        let gamma = (Double(edid!.DisplayTransferCharacteristic) + 100) / 100
        if gamma >= 1 && gamma < 4 {
          statusString += "\tGamma: \(String(format: "%.2f", Double(gamma)))\n"
        }
        statusString += "\tModel: \(monitorModel.trimmingCharacters(in: .whitespacesAndNewlines))\n"
        
        let checksumOk : String = ((IODisplayEDID!.map { Int($0) }.reduce(0, +) & 0xff) == 0) ? "valid" : "invalid"
        statusString += "\tChecksum: \(String(format: "0x%X", edid!.Checksum)) (\(checksumOk))\n"
      }
      
      if (IODisplayEDID != nil) {
        if let IODisplayEDIDOriginal : Data = info.object(forKey: kIODisplayEDIDOriginalKey) as? Data {
          statusString += (IODisplayEDIDOriginal == IODisplayEDID) ? "\n\tEDID comes from EEPROM" : "\n\tEDID is overriden\n"
        } else {
          statusString += "\n\tNo original EDID found\n"
        }
      }
    }
    
    return statusString
  }
  
  //--------------------------------------------------------------------------
  // MARK: Info Dictionary from displayID
  //--------------------------------------------------------------------------
  
  fileprivate static func GetInfoFromCGDisplayID(displayID: CGDirectDisplayID,
                                      displayLocations: inout [String]) -> NSDictionary? {
    var serv : io_object_t
    var iter = io_iterator_t()
    let matching = IOServiceMatching("IODisplayConnect")
    var dict : NSDictionary? = nil
    let err = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                           matching,
                                           &iter)
    if err == KERN_SUCCESS && iter != 0 {
      if KERN_SUCCESS == err  {
        repeat {
          serv = IOIteratorNext(iter)
          let opt : IOOptionBits = IOOptionBits(0)
          if let info : NSDictionary =
            IODisplayCreateInfoDictionary(serv, opt).takeRetainedValue() as NSDictionary? {
            let vendorID : NSNumber? = info.object(forKey: kDisplayVendorID) as? NSNumber
            let productID : NSNumber? = info.object(forKey: kDisplayProductID) as? NSNumber
            let location : String? = info.object(forKey: kIODisplayLocationKey) as? String
            if (vendorID != nil) &&
              (productID != nil) &&
              (location  != nil) &&
              CGDisplayVendorNumber(displayID) == vendorID?.uint32Value &&
              CGDisplayModelNumber(displayID) == productID?.uint32Value &&
              (!displayLocations.contains(location!)) {
              displayLocations.append(location!)
              dict = info
            }
          }
          IOObjectRelease(serv)
          if (dict != nil) {
            break
          }
        } while serv != 0
      }
      IOObjectRelease(iter)
    }
    return dict
  }
}
