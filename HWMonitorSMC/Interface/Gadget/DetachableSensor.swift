//
//  HWSView.swift
//  viewtester
//
//  Created by vector sigma on 01/02/2020.
//  Copyright © 2020 vector. All rights reserved.
//

import Cocoa

class HWSWC: NSWindowController {
  convenience init(sensor: HWMonitorSensor) {
    let vc = HWSVC()
    self.init(window: NSWindow(contentViewController: vc))
    ((contentViewController as? HWSVC)?.view as? HWSView)?.sensor = sensor
    ((contentViewController as? HWSVC)?.view as? HWSView)?.setUp()
    self.window?.hasShadow = true
    self.window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    self.window?.isMovable = true
    self.window?.isMovableByWindowBackground = true
    self.window?.level = .statusBar
    self.window?.collectionBehavior = .canJoinAllSpaces
    self.window?.contentMaxSize = NSSize(width: 382, height: 32)
    self.window?.backgroundColor = NSColor.clear

    self.window?.styleMask = []
    
    self.window?.titleVisibility = .hidden // the pin button works again with this
    self.window?.titlebarAppearsTransparent = true
  }
}

class HWSVC: NSViewController {
  override func loadView() {
    let v = HWSView()
    self.view = v
  }
}

class HWFieldCell: NSTextFieldCell {
  override func titleRect(forBounds rect: NSRect) -> NSRect {
    var titleRect = super.titleRect(forBounds: rect)
    
    let minimumHeight = self.cellSize(forBounds: rect).height
    titleRect.origin.y += (titleRect.height - minimumHeight) / 2
    titleRect.size.height = minimumHeight
    
    return titleRect
  }
  
  override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
    super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
  }
}

class HWSView: NSView {
  var sensor : HWMonitorSensor?
  private var nf : NSTextField?
  private var vf : NSTextField?
  private var iv : NSImageView?
  
  convenience init() {
    let fr = NSRect(x: 0, y: 0, width: 382, height: 32)
    
    self.init(frame: fr)
    self.wantsLayer = true
    
    let vev = NSVisualEffectView(frame: fr)
    vev.wantsLayer = true
    
    self.iv = NSImageView(frame: NSRect(x: 0, y: 0, width: 32, height: 32))
    self.iv?.image = NSImage(named: "temperature_small")
    self.iv?.image?.isTemplate = true
    vev.addSubview(self.iv!)
    
    self.nf = customField(frame: NSRect(x: 32, y: 0, width: 250, height: 32), alignment: .left)
    vev.addSubview(self.nf!)
    
    self.vf = customField(frame: NSRect(x: 282, y: 0, width: 100, height: 32), alignment: .right)
    vev.addSubview(self.vf!)
    self.addSubview(vev)
  }
  
  func update() {
    self.vf?.stringValue = "\(self.sensor!.stringValue) \(self.sensor!.unit.rawValue.locale)"
  }
  
  private func customField(frame : NSRect, alignment: NSTextAlignment) -> NSTextField {
    let f = NSTextField(frame: frame)
    f.cell = HWFieldCell()
    f.font = NSFont.systemFont(ofSize: 18)
    f.lineBreakMode = .byTruncatingTail
    f.drawsBackground = false
    f.isBordered = false
    f.isEditable = false
    f.alignment = alignment
    return f
  }
  
  func setUp() {
    if self.sensor?.sensorType == .hdSmartLife {
      self.nf?.stringValue = "Life".locale
    } else if self.sensor?.sensorType == .hdSmartTemp {
      self.nf?.stringValue = "Temperature".locale
    } else {
      self.nf?.stringValue = self.sensor!.title
    }

    var imageName = "temperature_small"
    switch self.sensor!.sensorType {
    case .battery:
      imageName = "modern-battery-icon"
    case .percent:
      if self.sensor?.type == "IOAcc" {
        imageName = "GPU"
      } else {
        imageName = "CPU"
      }
    case .intelCPUFrequency:
      imageName = "cpu_freq_small"
    case .intelGPUFrequency:
      imageName = "GPU_freq"
    case .intelmWh:
      imageName = "CPU"
    case .intelJoule:
      imageName = "CPU"
    case .intelWatt:
      if self.sensor?.type == "IPG IGPU" {
        imageName = "GPU"
      } else {
        imageName = "CPU"
      }
    case .intelTemp:
      imageName = "cpu_temp_small"
    case .cpuPowerWatt:
      imageName = "CPU"
    case .igpuPowerWatt:
      imageName = "GPU"
    case .temperature:
      imageName = "cpu_temp_small"
    case .voltage:
      imageName = "voltage_small"
    case .tachometer:
      imageName = "fan_small"
    case .frequencyCPU:
      imageName = "cpu_freq_small"
    case .frequencyGPU:
      imageName = "GPU_freq"
    case .frequencyOther:
      imageName = "freq_small"
    case .multiplier:
      imageName = "CPU"
    case .hdSmartTemp:
      imageName = "hd_small"
    case .hdSmartLife:
      imageName = "hd_small"
    case .mediaSMARTContenitor:
      imageName = "hd_small"
    case .genericBattery:
      imageName = "modern-battery-icon"
    case .gpuIO_coreClock:
      imageName = "GPU_freq"
    case .gpuIO_memoryClock:
      imageName = "GPU_freq"
    case .gpuIO_temp:
      imageName = "GPU_temp"
    case .gpuIO_FanRPM:
      imageName = "GPU_fan"
    case .gpuIO_percent:
      imageName = "GPU"
    case .gpuIO_RamBytes:
      imageName = "GPU"
    case .gpuIO_Watts:
      imageName = "GPU"
    case .memory:
      imageName = "ram_small"
    case .usb:
      break
    }
    
    self.iv?.image = NSImage(named: imageName)
    self.iv?.image?.isTemplate = true
    
    self.update()
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
  }
  
  override func menu(for event: NSEvent) -> NSMenu? {
    let menu = NSMenu(title: "HWSView")
    menu.addItem(withTitle: "Close", action: #selector(self.exit), keyEquivalent: "")
    return menu
  }
  
  @objc func exit() {
    self.sensor?.dethachableSensor = nil
    self.window?.close()
  }
}
