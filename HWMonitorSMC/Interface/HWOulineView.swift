//
//  HWOulineView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 24/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWTextFieldCell : NSTextFieldCell {
  override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
    self.attributedStringValue.draw(in: self.titleRect(forBounds: cellFrame))
  }
  
  override func titleRect(forBounds rect: NSRect) -> NSRect {
    var titleRect = super.titleRect(forBounds: rect)
    let stringSize = self.attributedStringValue.size
    titleRect.origin.y = (rect.origin.y - 1.0 + (rect.size.height - stringSize().height)) / 2.0
    return titleRect
  }
}

class RightClickWindowController: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.appearance = getAppearance()
  }
}

class RightClickViewController: NSViewController {
  @IBOutlet var textView : NSTextView!
  @IBOutlet var graphButton: NSButton!
  var loaded : Bool = false
  var outLine: HWOulineView? = nil
  var node: HWTreeNode? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear() {
    if !self.loaded {
      if let sensor = self.node?.sensorData?.sensor {
        if sensor.canPlot {
          self.graphButton.image = NSImage(named: ((sensor.plot == nil) ? "freq_small" : "freq_small_on"))
        } else {
          self.graphButton.isEnabled = false
          self.graphButton.isHidden = true
        }
      } else {
        self.graphButton.isEnabled = false
        self.graphButton.isHidden = true
      }
      self.loaded = true
    }
  }
  
  override func viewDidDisappear() {
    if let out = self.outLine {
      let row : Int = out.row(forItem: self.node)
      if row >= 0 {
        DispatchQueue.main.async {
          out.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 3))
        }
      }
    }
  }
  
  class func loadFromNib(node: HWTreeNode, outline: HWOulineView) -> RightClickViewController {
    let s = NSStoryboard(name: "Info", bundle: nil)
    let vc = s.instantiateController(withIdentifier:"Info") as! RightClickViewController
    vc.outLine = outline
    vc.node = node
    return vc
  }
  
  @IBAction func showPlot(_ sender: Any?) {
    if let sensor = self.node?.sensorData?.sensor {
      if sensor.canPlot && sensor.hasPlot {
        sensor.removePlot()
        self.graphButton.image = NSImage(named: "freq_small")
      } else {
        sensor.addPlot()
        self.graphButton.image = NSImage(named: "freq_small_on")
      }
    }
  }
  
  @IBAction func copyToPasteboard(_ sender: Any?) {
    var log = self.textView.string

    if log.count > 0 {
      let pasteboard = NSPasteboard.general
      pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
      if let version = Bundle.main.infoDictionary?["CFBundleVersion"]  as? String {
        log = "HWMonitorSMC2 v\(version) \(kTestVersion)\n\n\(log)"
      }
      if !pasteboard.setString(log, forType: NSPasteboard.PasteboardType.string) {
        NSSound.beep()
      }
    } else {
      NSSound.beep()
    }
  }
}

enum MainViewSize: String {
  case normal   = "Default"
  case medium   = "Medium"
  case large    = "Large"
}

protocol AppearanceChangeDelegate : class {
  func appearanceDidChange()
}

class HWOulineView: NSOutlineView, NSPopoverDelegate {
  private var appearanceObserver: NSKeyValueObservation?
  weak var appearanceDelegate: AppearanceChangeDelegate?
  enum InfoViewSize : Int {
    case small      = 1
    case normal     = 2
    case medium     = 3
    case big        = 4
    case fanControl = 5
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)!
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.redraw),
                                           name: NSNotification.Name.outlineNeedsDisplay,
                                           object: nil)
    let appear = getAppearance()
    self.selectionHighlightStyle = .sourceList
    let scroller : NSScrollView? = self.enclosingScrollView
    let clipView : NSClipView? = scroller?.contentView
    scroller?.appearance = appear
    clipView?.appearance = appear
    self.appearance = appear
    self.update()
    
    if #available(OSX 10.14, *) {
      self.appearanceObserver = self.observe(\.effectiveAppearance) { [weak self] _, _  in
        self?.update()
      }
    }
  }
  
  deinit {
    if self.appearanceObserver != nil {
      self.appearanceObserver!.invalidate()
      self.appearanceObserver = nil
    }
  }
  
  override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
    let view: Any? = super.makeView(withIdentifier: identifier, owner: owner)
    if (identifier == NSOutlineView.disclosureButtonIdentifier) {
      let t: NSButton? = (view as? NSButton)
      t?.image?.isTemplate = true
      t?.alternateImage?.isTemplate = true
    }
    return view as? NSView
  }
  
  func update() {
    let appearance = getAppearance()
    for win in NSApplication.shared.windows {
      if let views = win.contentView?.subviews {
        if (win.title != "Gadget") &&
          win != AppSd.statusItem.button!.window {
          win.appearance = appearance
          win.contentView?.appearance = appearance
          for v in views {
            if v is NSVisualEffectView {
              let vev = v as! NSVisualEffectView
              if win.identifier?.rawValue != "Preferences" {
                vev.appearance = appearance
                if let themes = AppSd.theme {
                  switch themes.theme {
                  case .Classic: fallthrough
                  case .DashedH: fallthrough
                  case .NoGrid:
                    vev.blendingMode = .withinWindow
                  case .Default:fallthrough
                  case .GridClear:
                    vev.blendingMode = .behindWindow
                  }
                }
                
                vev.state = .active
                if #available(OSX 10.11, *) {
                  vev.material = .popover
                }
              }
            }
          }
        }
      }
    }
    
    let scroller : NSScrollView? = self.enclosingScrollView
    let clipView : NSClipView? = scroller?.contentView
    scroller?.appearance = appearance
    clipView?.appearance = appearance
    self.appearance = appearance
    self.gridColor = (appearance.name == .vibrantDark) ? UDs.darkGridColor() : UDs.lightGridColor()
    if let themes = AppSd.theme {
      switch themes.theme {
      case .Classic: fallthrough
      case .DashedH: fallthrough
      case .NoGrid:
        self.backgroundColor = (appearance.name == .vibrantDark) ? .black : .white
      case .Default:
        self.backgroundColor = .clear
      case .GridClear:
        self.backgroundColor = .clear
      }
    }
    
    let column1 : NSTableColumn? = self.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "column1"))
    switch AppSd.mainViewSize {
    case .normal:
      self.rowSizeStyle = .small
      column1?.width = 202
    case .medium:
      self.rowSizeStyle = .medium
      column1?.width = 215
    case .large:
      self.rowSizeStyle = .large
      column1?.width = 215
    }
    
    self.reloadData()
    NotificationCenter.default.post(name: NSNotification.Name.appearanceDidChange, object: self)
  }
  
  @objc func redraw() {
    let theme : Theme = Theme(rawValue: UDs.string(forKey: kTheme) ?? "Default") ?? .Default
    AppSd.theme = Themes.init(theme: theme, outline: self)
    self.needsDisplay = true
    self.update()
  }
  
  func popoverDidClose(_ notification: Notification) {
    if let popover = (AppSd.hwWC?.contentViewController as? HWViewController)?.popover {
      if (self.window != nil) && !(self.window?.isKeyWindow)! {
        if popover.isShown {
          popover.close()
        }
      }
    }
  }

  override public func menu(for event: NSEvent) -> NSMenu? {
    let point = self.convert(event.locationInWindow, from: nil)
    let row = self.row(at: point)
    if let item : HWTreeNode = self.item(atRow: row) as? HWTreeNode {
      self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
      var rowView : NSView? = nil
      let pop : NSPopover? = self.getLogPopOverForNode(item, at: row, rowView: &rowView)
      if (pop != nil && rowView != nil) {
        DispatchQueue.main.async {
          pop?.show(relativeTo: (rowView?.bounds)!, of: rowView!, preferredEdge: NSRectEdge.minX)
        }
      }
    }
    
    return nil
  }
  
  private func getLogPopOverForNode(_ node: HWTreeNode, at row: Int, rowView: inout NSView?) -> NSPopover? {
    var log : String? = nil
    var size : InfoViewSize = .normal
    if ((node.sensorData?.sensor?.sensorType) != nil) {
      let actionType : ActionType = (node.sensorData?.sensor?.actionType)!
      
      switch actionType {
      case .nothing: break
      case .systemLog:
        size = .big
        log = self.getSystemInfo()
      case .cpuLog:
        size = .medium
        log = self.getCPUInfo()
      case .gpuLog:
        size = .big
        let parent : HWTreeNode? = node.parent?.parent as? HWTreeNode
        
        if (parent != nil) {
          if parent?.sensorData?.group == "GPUs".locale {
            let index : Int = (node.parent?.mutableChildren.index(of: node))!
            log = Graphics.init().getGraphicsInfo(acpiPathOrPrimaryMatch: node.sensorData?.sensor?.characteristics, index: index)
          }
        }
        
        if log?.count == 0 { log = self.getGPUInfo() }
      case .mediaLog:
        size = .normal
        log = node.sensorData?.sensor?.characteristics
      case .memoryLog:
        size = .normal
        log = self.getMemoryInfo()
      case .batteryLog:
        size = .normal
        log = self.getBatteryInfo()
      case .fanControl:
        if AppSd.fanControlEnabled {
          
          let pop = NSPopover()
          pop.behavior = .transient
          pop.animates = true
          pop.delegate = self
          pop.contentSize = NSMakeSize(200, 83)
          let rpm : Int32 = Int32(node.sensorData!.sensor!.doubleValue)
          let fc = FanControlVC.loadFromNib(key: node.sensorData!.sensor!.key,
                                            index: node.sensorData!.sensor!.index,
                                            target: rpm)
          //fc.view.setFrameSize(pop.contentSize)
          pop.contentViewController = fc
          rowView = self.view(atColumn: 0, row: row, makeIfNecessary: false)
          
          return pop
        } else {
          size = .big
          log = self.getSystemInfo()
        }
      default:
        break
      }
    } else {
      //we are on a parent
      if let groupString = node.sensorData?.group {
        switch groupString {
        case "Core Temperatures".locale: fallthrough
        case "Core Frequencies".locale:  fallthrough
        case "CPU".locale:
          size = .medium
          log = self.getCPUInfo()
        case "RAM".locale:
          size = .normal
          log = self.getMemoryInfo()
        case "GPUs".locale:
          size = .medium
          log = self.getGPUInfo()
        case "Batteries".locale:
          size = .normal
          log = self.getBatteryInfo()
        case "System".locale: fallthrough
        case "Fans or Pumps".locale: fallthrough
        case "Motherboard".locale:
          size = .big
          log = self.getSystemStatus()
        case "Media health".locale:
          var allDrivesInfo : String = ""
          for diskNode in node.children! {
            if let disk : HWTreeNode = diskNode as? HWTreeNode {
              if let characteristics : String = disk.sensorData?.sensor?.characteristics {
                allDrivesInfo += characteristics
                allDrivesInfo += "\n"
              }
            }
          }
          if allDrivesInfo.count > 0 {
            size = .medium
            log = allDrivesInfo
          }
        default:
          let parent : HWTreeNode? = node.parent as? HWTreeNode
          if (parent != nil) {
            if parent?.sensorData?.group == "GPUs".locale {
              for n in node.mutableChildren {
                size = .big
                log = Graphics.init().getGraphicsInfo(acpiPathOrPrimaryMatch: (n as? HWTreeNode)?.sensorData?.sensor?.characteristics, index: 0)
                break
              }
              break
            }
          }
          break
        }
      }
    }
    if (log != nil && log!.count > 0) {
      let pop = NSPopover()
      pop.behavior = .transient
      pop.animates = true
      
      pop.delegate = self
      if size == .small {
        pop.contentSize = NSMakeSize(250, 100)
      } else if size == .normal {
        pop.contentSize = NSMakeSize(400, 200)
      } else if size == .big {
        pop.contentSize = NSMakeSize(680, 600)
      } else if size == .medium {
        pop.contentSize = NSMakeSize(400, 450)
      }
      
      
      let vc = RightClickViewController.loadFromNib(node: node, outline: self)
      vc.view.setFrameSize(pop.contentSize)
      let attrLog = NSMutableAttributedString(string: log!)
      
      //NSFont.userFixedPitchFont(ofSize: gLogFont.pointSize)
      
      attrLog.addAttributes([NSAttributedString.Key.font : gLogFont, NSAttributedString.Key.foregroundColor : (getAppearance().name == .vibrantDark ? NSColor.white : NSColor.controlTextColor)],
                            range: NSMakeRange(0, attrLog.length))
      vc.textView.textStorage?.append(attrLog)
      vc.textView.textContainerInset = NSMakeSize(0, 0)
      vc.textView.textContainer?.lineFragmentPadding = 0
      pop.contentViewController = vc
      rowView = self.view(atColumn: 0, row: row, makeIfNecessary: false)
      return pop
    }
    NSSound.beep()
    return nil
  }
  
  private func getCPUInfo() -> String {
    var statusString : String = ""
    statusString += "CPU:\n"
    statusString += "\tName:\t\t\(System.sysctlbynameString("machdep.cpu.brand_string"))\n"
    statusString += "\tVendor:\t\t\(System.sysctlbynameString("machdep.cpu.vendor"))\n"
    let pkgCount = gCPUPackageCount()
    if pkgCount > 1 {
      statusString += "\tCPU count:\t\t\(pkgCount)\n"
      statusString += "\tCores per CPU:\t\(System.physicalCores())\n"
    } else {
      statusString += "\tPhysical cores:\t\(System.physicalCores())\n"
    }
    
    statusString += "\tLogical cores:\t\(System.logicalCores())\n"
    statusString += "\tFamily:\t\t\(System.sysctlbynameInt("machdep.cpu.family"))\n"
    statusString += String(format: "\tModel:\t\t0x%X\n", System.sysctlbynameInt("machdep.cpu.model"))
    statusString += String(format: "\tExt Model:\t\t0x%X\n", System.sysctlbynameInt("machdep.cpu.extmodel"))
    statusString += "\tExt Family:\t\t\(System.sysctlbynameInt("machdep.cpu.extfamily"))\n"
    statusString += "\tStepping:\t\t\(System.sysctlbynameInt("machdep.cpu.stepping"))\n"
    statusString += String(format: "\tSignature:\t\t0x%X\n", System.sysctlbynameInt("machdep.cpu.signature"))
    statusString += "\tBrand:\t\t\(System.sysctlbynameInt("machdep.cpu.brand"))\n"
    
    statusString += "\tFeatures:"
    let feature : [String] = System.sysctlbynameString("machdep.cpu.features").components(separatedBy: " ")
    var gcount : Int = 0
    var count : Int = 0
    for f in feature {
      count += 1
      gcount += 1
      if gcount < 8 {
        if gcount == 1 {
          statusString += (count == 1) ? " ": "\t               " // "\tFeatures:"
        }
        statusString += " \(f)"
      } else {
        statusString += " \(f)\n"
        gcount = 0
      }
    }
    statusString += "\n"
    statusString += "\tExt Features:"
    let extfeature : [String] = System.sysctlbynameString("machdep.cpu.extfeatures").components(separatedBy: " ")
    var egcount : Int = 0
    var ecount : Int = 0
    for f in extfeature {
      ecount += 1
      egcount += 1
      if egcount < 8 {
        if egcount == 1 {
          statusString += (ecount == 1) ? " ": "\t                     " // "\tExt Features:"
        }
        statusString += " \(f)"
      } else {
        statusString += " \(f)\n"
        egcount = 0
      }
    }
    statusString += "\n"
    statusString += "\tMicrocode version:\t\(System.sysctlbynameInt("machdep.cpu.microcode_version"))\n"
    statusString += "\tThermal sensors:\t\t\(System.sysctlbynameInt("machdep.cpu.thermal.sensor"))\n"
    statusString += "\tThermal APIC timer:\t\(System.sysctlbynameInt("machdep.cpu.thermal.invariant_APIC_timer"))\n"
    
    var sys = System()
    let cpuUsage = sys.usageCPU()
    statusString += "\n\tSystem:\t\(Int(cpuUsage.system))%\n"
    statusString += "\tUser:\t\t\(Int(cpuUsage.user))%\n"
    statusString += "\tIdle:\t\t\(Int(cpuUsage.idle))%\n"
    statusString += "\tNice:\t\t\(Int(cpuUsage.nice))%\n"
    statusString += "\n"
    return statusString
  }
  
  private func getMemoryInfo() -> String {
    var statusString : String = ""
    statusString += "MEMORY:\n"
    statusString += "\tPhysical size:\t\(System.physicalMemory())GB\n"
    
    let memoryUsage = System.memoryUsage()
    func memoryUnit(_ value: Double) -> String {
      if value < 1.0 { return String(Int(value * 1000.0))    + "MB" }
      else           { return NSString(format:"%.2f", value) as String + "GB" }
    }
    
    statusString += "\tFree:\t\t\t\(memoryUnit(memoryUsage.free))\n"
    statusString += "\tWired:\t\t\(memoryUnit(memoryUsage.wired))\n"
    statusString += "\tActive:\t\t\(memoryUnit(memoryUsage.active))\n"
    statusString += "\tInactive:\t\t\(memoryUnit(memoryUsage.inactive))\n"
    statusString += "\tCompressed:\t\(memoryUnit(memoryUsage.compressed))\n"
    statusString += "\n"
    return statusString
  }
  
  private func getSystemInfo() -> String {
    var statusString : String = ""
    statusString += "SYSTEM:\n"
    statusString += "\tModel:\t\t\(System.modelName())\n"
    let names = System.uname()
    statusString += "\tSys name:\t\t\(names.sysname)\n"
    let os  = ProcessInfo.init().operatingSystemVersion
    statusString += "\tOS Version:\t\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)\n"
    statusString += "\tNode name:\t\(names.nodename)\n"
    statusString += "\tRelease:\t\t\(names.release)\n"
    statusString += "\tVersion:\t\t\(names.version)\n"
    statusString += "\tMachine:\t\t\(names.machine)\n"
    
    let uptime = System.uptime()
    statusString += "\tUptime:\t\t\(uptime.days)d \(uptime.hrs)h \(uptime.mins)m " + "\(uptime.secs)s\n"
    
    let counts = System.processCounts()
    statusString += "\tProcesses:\t\t\(counts.processCount)\n"
    statusString += "\tThreads:\t\t\(counts.threadCount)\n"
    
    let loadAverage = System.loadAverage().map { NSString(format:"%.2f", $0) }
    statusString += "\tLoad Average:\t\(loadAverage)\n"
    statusString += "\tMach Factor:\t\(System.machFactor())\n"
    statusString += "\n"
    return statusString
  }
  
  private func getPowerInfo() -> String {
    var statusString : String = ""
    statusString += "POWER:\n"
    let cpuThermalStatus = System.CPUPowerLimit()
    
    statusString += "\tCPU Speed limit:\t\t\(cpuThermalStatus.processorSpeed)%\n"
    statusString += "\tCPUs available:\t\t\(cpuThermalStatus.processorCount)\n"
    statusString += "\tScheduler limit:\t\t\(cpuThermalStatus.schedulerTime)%\n"
    
    statusString += "\tThermal level:\t\t\(System.thermalLevel().rawValue)\n"
    statusString += "\n"
    return statusString
  }
  
  private func getBatteryInfo() -> String {
    var statusString : String = ""
    var battery = Battery()
    if battery.open() == kIOReturnSuccess {
      statusString += "BATTERY:\n"
      statusString += "\tAC Powered:\t\(battery.isACPowered())\n"
      statusString += "\tCharged:\t\t\(battery.isCharged())\n"
      statusString += "\tCharging:\t\t\(battery.isCharging())\n"
      statusString += "\tCharge:\t\t\(battery.charge())%\n"
      statusString += "\tCapacity:\t\t\(battery.currentCapacity()) mAh\n"
      statusString += "\tMax capacity:\t\(battery.maxCapactiy()) mAh\n"
      statusString += "\tDesign capacity:\t\(battery.designCapacity()) mAh\n"
      statusString += "\tCycles:\t\t\(battery.cycleCount())\n"
      statusString += "\tMax cycles:\t\t\(battery.designCycleCount())\n"
      statusString += "\tTemperature:\t\(battery.temperature())°C\n"
      statusString += "\tTime remaining:\t\(battery.timeRemainingFormatted())\n"
      statusString += "\n"
    }
    _ = battery.close()
    
    return statusString
  }
  
  private func getGPUInfo() -> String {
    return Graphics.init().getGraphicsInfo(acpiPathOrPrimaryMatch: nil, index: 0) + "\n"
  }
  
  private func getLPCBInfo() -> String {
    var statusString : String = "LPCB:\n"
    statusString += "\(LPCB.init().getLPCBInfo())\n"
    return statusString
  }
  
  private func getSATAInfo() -> String {
    var statusString : String = ""
    /*
     I'm not aware of a system w/o SATA controllers,
     but NVMe is taking over
     */
    let sata = SATAControllers.getSATAControllersInfo()
    if sata.count > 0 {
      statusString += "\n"
      statusString += sata
    }
    return statusString
  }
  
  private func getNVMEInfo() -> String {
    var statusString : String = ""
    let nvme = NVMeControllers.getNVMeControllersInfo()
    if nvme.count > 0 {
      statusString += "\n"
      statusString += nvme
    }
    return statusString
  }
  
  private func getMediaInfo() -> String {
    var statusString : String = ""
    // try to see if "Media health" contains some info..
    if let mediaNode : HWTreeNode = (self.delegate as! PopoverViewController).mediaNode {
      var allDrivesInfo : String = ""
      for diskNode in mediaNode.children! {
        if let disk : HWTreeNode = diskNode as? HWTreeNode {
          if let characteristics : String = disk.sensorData?.sensor?.characteristics {
            allDrivesInfo += characteristics
            allDrivesInfo += "\n"
          }
        }
      }
      if allDrivesInfo.count > 0 {
        statusString += "\nMEDIA:\n"
        // doing a dirty job: add a tab for each line of this log
        let lines = allDrivesInfo.components(separatedBy: "\n")
        for line in lines {
          statusString += "\t\(line)\n"
        }
      }
    }

    return statusString
  }
  
  private func getUSBInfo() -> String {
    var statusString : String = ""
    // try to see if "USB" contains some info..
    if let usbNode : HWTreeNode = (self.delegate as! PopoverViewController).usbNode {
      var allUSBsInfo : String = ""
      for node in usbNode.children! {
        if let usb : HWTreeNode = node as? HWTreeNode {
          if let characteristics : String = usb.sensorData?.sensor?.characteristics {
            allUSBsInfo += characteristics
            allUSBsInfo += "\n"
          }
        }
      }
      if allUSBsInfo.count > 0 {
        statusString += "USB devices:\n"
        // doing a dirty job: add a tab for each line of this log
        let lines = allUSBsInfo.components(separatedBy: "\n")
        for line in lines {
          statusString += "\t\(line)\n"
        }
      }
    }
    
    return statusString
  }
  
  private func getNETInfo() -> String {
    var statusString : String = ""
    let net = NETControllers.getNETControllersInfo()
    if net.count > 0 {
      statusString += "\n"
      statusString += net
    }
    return statusString
  }
  
  private func getSMCkeys() -> String {
    var statusString : String = ""
    let keys = gSMC.dumpSMCKeys()
    if keys.count > 0 {
      statusString += "\nSMC DUMP:\n\n"
      let lines = keys.components(separatedBy: "\n")
      for line in lines {
        statusString += "\t\(line)\n"
      }
    }
    return statusString
  }
  
  private func getSystemStatus() -> String {
    var statusString : String = ""
    statusString += "MACHINE STATUS:\n\n"
    statusString += self.getCPUInfo()
    statusString += self.getLPCBInfo()
    statusString += self.getMemoryInfo()
    statusString += self.getSystemInfo()
    statusString += self.getPowerInfo()
    statusString += self.getBatteryInfo()
    statusString += self.getGPUInfo()
    statusString += Display.getScreensInfo()
    statusString += self.getSATAInfo()
    statusString += self.getNVMEInfo()
    statusString += self.getMediaInfo()
    statusString += USBControllers.getUSBControllersInfo()
    statusString += self.getUSBInfo()
    statusString += self.getNETInfo()
    statusString += self.getSMCkeys()
    return statusString
  }
}
