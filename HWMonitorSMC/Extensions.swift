//
//  Extensions.swift
//  HWMonitorSMC2
//
//  Created by vector sigma on 25/04/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

extension String {
  var locale: String {
    get {
      return NSLocalizedString(self, comment: "")
    }
  }
  
  public func locale(_ localized: Bool) -> String {
    return (localized ? self.locale : self)
  }
  
  public func noSpaces() -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespaces)
  }
  
  // require
  public func withFormat(_ arg: Any) -> String {
    return String(format: self, "\(arg)")
  }
}
  

extension Data {
  public func hexadecimal() -> String {
    var hex : String = ""
    for i in 0..<self.count {
      hex += String(format: "%02x ", self[i])
    }
    return hex.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension UInt8 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt8>.size)
  }
}

extension UInt16 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt16>.size)
  }
}

extension UInt32 {
  var data: Data {
    var p = self
    return Data(bytes: &p, count: MemoryLayout<UInt32>.size)
  }
}

extension UserDefaults {
  private func archive(font: NSFont) {
    var data : Data? = nil
    if #available(OSX 10.13, *) {
      do {
        data = try NSKeyedArchiver.archivedData(withRootObject: font,
                                                requiringSecureCoding: false)
      } catch  {}
    } else {
      if #available(OSX 10.11, *) {
        data = NSKeyedArchiver.archivedData(withRootObject: font)
      }
    }
    if (data != nil) { self.set(data, forKey: kTopBarFont) }
  }
  
  private func unarchiveFont(key: String) -> NSFont? {
    var font : NSFont? = nil
    guard let data = data(forKey: key) else {
      return nil
    }
    
    if #available(OSX 10.13, *) {
      do {
        try font = NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSFont.self], from: data)  as? NSFont
      } catch  { }
    } else {
      font = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSFont
    }
    
    return font
  }
  
  private func archive(color: NSColor, key: String) {
    var data : Data? = nil
    if #available(OSX 10.13, *) {
      do {
        data = try NSKeyedArchiver.archivedData(withRootObject: color,
                                                requiringSecureCoding: false)
      } catch  {}
    } else {
      if #available(OSX 10.11, *) {
        data = NSKeyedArchiver.archivedData(withRootObject: color)
      }
    }
    if (data != nil) { self.set(data, forKey: key) }
  }
  
  private func unarchiveColor(key: String) -> NSColor? {
    var color : NSColor? = nil
    guard let data = data(forKey: key) else {
      return nil
    }
    
    if #available(OSX 10.13, *) {
      do {
        try color = NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSColor.self], from: data)  as? NSColor
      } catch  { }
    } else {
      color = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSColor
    }
    
    return color
  }
  
  func saveTopBar(font: NSFont) {
    self.archive(font: font)
  }
  
  func topBarFont() -> NSFont? {
    return self.unarchiveFont(key: kTopBarFont)
  }

  func darkGridColor() -> NSColor {
    if let color = self.unarchiveColor(key: "darkGridColor") {
      return color
    }
    return .gridColor
  }
  
  func resetDarkGridColor() {
    removeObject(forKey: "darkGridColor")
  }
  
  func lightGridColor() -> NSColor {
    if let color = self.unarchiveColor(key: "lightGridColor") {
      return color
    }
    return .gridColor
  }
  
  func resetLightGridColor() {
    removeObject(forKey: "lightGridColor")
  }
  
  func darkGrid(color: NSColor) {
    self.archive(color: color, key: "darkGridColor")
  }
  
  func lightGrid(color: NSColor) {
    self.archive(color: color, key: "lightGridColor")
  }
  
  func darkPlotColor() -> NSColor {
    if let color = self.unarchiveColor(key: "darkPlotColor") {
      return color
    }
    return .green
  }
  
  func resetDarkPlotColor() {
    removeObject(forKey: "darkPlotColor")
  }
  
  func lightPlotColor() -> NSColor {
    if let color = self.unarchiveColor(key: "lightPlotColor") {
      return color
    }
    return .cyan
  }
  
  func resetLightPlotColor() {
    removeObject(forKey: "lightPlotColor")
  }
  
  func darkPlot(color: NSColor) {
    self.archive(color: color, key: "darkPlotColor")
  }
  
  func lightPlot(color: NSColor) {
    self.archive(color: color, key: "lightPlotColor")
  }
}

// HWMonitorSMC2 debug
extension NSDictionary {
  public func writeGraphicsInfo(with name: String) {
    // MTLDevice object cannot be written to a plist, make a copy
    let dir = NSHomeDirectory() + "/Desktop/HWGraphics"
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Desktop/HWGraphics") {
      let copy : NSMutableDictionary = NSMutableDictionary.init(dictionary: self)
      if (copy.object(forKey: kMetalDevice) != nil) {
        copy.setValue(true, forKey: kMetalDevice)
      }
      copy.write(toFile: "\(dir)/Inf_\(name).plist", atomically: true)
    }
  }
}

public extension NSView {
  @IBInspectable var cornerRadius: CGFloat {
    get {
      return self.layer?.cornerRadius ?? 0
    } set {
      self.wantsLayer = true
      self.layer?.masksToBounds = true
      self.layer?.cornerRadius = CGFloat(Int(newValue * 100)) / 100
    }
  }
}

extension Notification.Name {
  static let appearanceDidChange = Notification.Name("Appearance Did Change")
  static let updatePlotLine = Notification.Name("Update Plot Line")
  static let outlineNeedsDisplay = Notification.Name("Outline Needs Display")
  static let terminate = Notification.Name("Terminate")
}
