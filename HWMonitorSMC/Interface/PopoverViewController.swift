//
//  PopoverViewController.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 26/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import IOKit.usb.USBSpec
import CorePlot

class PopoverViewController: NSViewController, USBWatcherDelegate {
  var usbWatcher : USBWatcher? = nil
  @IBOutlet var outline         : HWOulineView!
  @IBOutlet var lock            : NSButton!
  @IBOutlet var attachButton    : NSButton!
  @IBOutlet var useGadgetButton : NSButton!
  @IBOutlet var versionLabel    : NSTextField!
  @IBOutlet var effectView      : NSVisualEffectView!
  
  var preferenceWC              : PreferencesWC?
  var gadgetWC                  : GadgetWC?
  
  var lastSpartUpdate           : Date?
  
  var dataSource                : NSMutableArray?
  var sensorList                : NSMutableArray?
  
  var expandCPUTemperature      : Bool = false
  var expandVoltages            : Bool = false
  var expandCPUFrequencies      : Bool = false
  var expandAll                 : Bool = false
  var dontshowEmpty             : Bool = true
  var useIOAcceleratorForGPUs   : Bool = false
  
  // nodes
  var SystemNode                : HWTreeNode?
  var CPUNode                   : HWTreeNode?
  var IPGInfoNode               : HWTreeNode?
  var CPUFrequenciesNode        : HWTreeNode?
  var CPUTemperaturesNode       : HWTreeNode?
  var RAMNode                   : HWTreeNode?
  var GPUNode                   : HWTreeNode?
  var MOBONode                  : HWTreeNode?
  var FansNode                  : HWTreeNode?
  var mediaNode                 : HWTreeNode?
  var batteriesNode             : HWTreeNode?
  var usbNode                   : HWTreeNode?
  
  var timerCPU                  : Timer? = nil
  var timerGPU                  : Timer? = nil
  var timerMotherboard          : Timer? = nil
  var timerFans                 : Timer? = nil
  var timerRAM                  : Timer? = nil
  var timerMedia                : Timer? = nil
  var timerBattery              : Timer? = nil
  
  var timeCPUInterval           : TimeInterval = 3
  var timeGPUInterval           : TimeInterval = 3
  var timeMotherBoardInterval   : TimeInterval = 3
  var timeFansInterval          : TimeInterval = 3
  var timeRAMInterval           : TimeInterval = 3
  var timeMediaInterval         : TimeInterval = 300
  var timeBatteryInterval       : TimeInterval = 3
  
  var useIntelPowerGadget       : Bool = false
  var statusIsUpdating          : Bool = false
  
  var sleeping                  : Bool = false
  var fansSMCSuperIO            : Bool = false
  var voltagesSMCSuperIO        : Bool = false
  var superIOConfig             : [String : Any]? = nil
  
  var dragSensorKey : String? = nil
  
  func usbDeviceAdded(_ device: io_object_t) {
    if (self.usbNode != nil) {
      if let info : NSDictionary = device.info() {
        let name : String? = info.object(forKey: kUSBProductString) as? String
        let USBProductID : NSNumber? = info.object(forKey: kUSBProductID) as? NSNumber
        let USBVendorID : NSNumber? = info.object(forKey: kUSBVendorID) as? NSNumber
        if (name != nil && USBProductID != nil && USBVendorID != nil) {
          let usbVidPid : String = "0x" + String(format: "%x", USBVendorID!) + String(format: "%x", USBProductID!)

          var found = false
          for i in (self.usbNode?.mutableChildren)! {
            let node : HWTreeNode = i as! HWTreeNode
            let n = (node.sensorData?.sensor)!
            if n.stringValue == usbVidPid && name == n.key {
              found = true
              break
            }
          }
          if !found {
            let s = HWMonitorSensor(key: name!,
                                    unit: HWUnit.none,
                                    type: "usb",
                                    sensorType: .usb,
                                    title: name!,
                                    canPlot: false)
            s.stringValue = usbVidPid
            s.actionType = .usbLog
            s.characteristics = device.log()
            let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.usbNode?.sensorData?.group)!,
                                                                    sensor: s,
                                                                    isLeaf: true))
            self.usbNode?.mutableChildren.add(sensor)
          }
        }
      }
    }
  }
  
  func usbDeviceRemoved(_ device: io_object_t) {
    if (self.usbNode != nil) {
      if let info : NSDictionary = device.info() {
        let name : String? = info.object(forKey: kUSBProductString) as? String
        let USBProductID : NSNumber? = info.object(forKey: kUSBProductID) as? NSNumber
        let USBVendorID : NSNumber? = info.object(forKey: kUSBVendorID) as? NSNumber
        if (name != nil && USBProductID != nil && USBVendorID != nil) {
          let usbVidPid : String = "0x" + String(format: "%x", USBVendorID!) + String(format: "%x", USBProductID!)
          for s in (self.usbNode?.mutableChildren)! {
            let sensor : HWTreeNode = s as! HWTreeNode
            if sensor.sensorData?.sensor?.stringValue == usbVidPid && name == sensor.sensorData?.sensor?.key {
              self.usbNode?.mutableChildren.remove(sensor)
              break
            }
          }
        }
      }
    }
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.attachButton.image?.isTemplate = true
    self.effectView.appearance = getAppearance()
    if let version = Bundle.main.infoDictionary?["CFBundleVersion"]  as? String {
      self.versionLabel.stringValue = "HWMonitorSMC2 v" + version + " \(kTestVersion)"
    }
    
    self.lock.state = NSControl.StateValue.off
    self.useGadgetButton.image?.isTemplate = true
    
    self.outline.headerView = nil
    self.outline.appearance = getAppearance()
    self.outline.delegate = self
    self.outline.dataSource = self
    self.outline.doubleAction = #selector(self.clicked)
    self.outline.enclosingScrollView?.verticalScroller?.controlSize = .mini
    
    self.outline.wantsLayer = true
    self.outline.enclosingScrollView?.wantsLayer = true
    
    /*
     Apply Theme
     */
    let theme : Theme = Theme(rawValue: UDs.string(forKey: kTheme) ?? "Default") ?? .Default
    AppSd.theme = Themes.init(theme: theme, outline: self.outline)
    
    /*
     Intel Power Gadget support Intel CPU only :-) (hot water),
     Family must be 6 and model must be >= 42.
     All this for 2nd generation Intel® Core™ processors and later
     
     NOTE: model 44, 46 and 47 are Xeon CPUs, usually not supported,
     but reported as working.
     */
    
    if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Desktop/HWIgnoreIPG") {
      AppSd.useIPG = false
    }
  
    if AppSd.useIPG {
      let cpuVendor = System.sysctlbynameString("machdep.cpu.vendor")
      if cpuVendor == "GenuineIntel" {
        let family : Int = System.sysctlbynameInt("machdep.cpu.family")
        let model : Int = System.sysctlbynameInt("machdep.cpu.model")
        
        if family == 6 && model >= 42 /* Xeon supported: && model != 44 && model != 46 && model != 47 */ {
          if FileManager.default.fileExists(atPath: "/Library/Frameworks/IntelPowerGadget.framework/Versions/A/Headers/EnergyLib.h")
          || FileManager.default.fileExists(atPath: "/Library/Frameworks/IntelPowerGadget.framework/Versions/A/Headers/PowerGadgetLib.h") {
            AppSd.ipg = IntelPG()
            self.useIntelPowerGadget = AppSd.ipg?.inited ?? false
          }
        }
      }
    }
    
    self.initialize()
    
    if UDs.bool(forKey: kShowGadget) {
      self.gadgetWC = GadgetWC.loadFromNib()
      self.gadgetWC?.showWindow(self)
    }
    
    self.outline.registerForDraggedTypes([.init("Sensor")])
    self.outline.setDraggingSourceOperationMask(NSDragOperation.delete, forLocal: false)
  }
  
  override func awakeFromNib() {
    
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  //MARK: - load Preferences
  func loadPreferences() {
    if (UDs.object(forKey: kShowCPUSensors) == nil) {
      UDs.set(true, forKey: kShowCPUSensors)
    }
    
    if (UDs.object(forKey: kShowGPUSensors) == nil) {
      UDs.set(true, forKey: kShowGPUSensors)
    }
    
    if (UDs.object(forKey: kShowMoBoSensors) == nil) {
      UDs.set(true, forKey: kShowMoBoSensors)
    }
    
    if (UDs.object(forKey: kShowFansSensors) == nil) {
      UDs.set(true, forKey: kShowFansSensors)
    }
    
    if (UDs.object(forKey: kShowRAMSensors) == nil) {
      UDs.set(true, forKey: kShowRAMSensors)
    }
    
    if (UDs.object(forKey: kShowMediaSensors) == nil) {
      UDs.set(true, forKey: kShowMediaSensors)
    }
    
    
    self.useIOAcceleratorForGPUs = UDs.bool(forKey: kUseGPUIOAccelerator)
    
    if (UDs.object(forKey: kExpandCPUTemperature) != nil) {
      self.expandCPUTemperature = UDs.bool(forKey: kExpandCPUTemperature)
    } else {
      self.expandCPUTemperature = true
      UDs.set(true, forKey: kExpandCPUTemperature)
    }
    
    if (UDs.object(forKey: kExpandVoltages) != nil) {
      self.expandVoltages = UDs.bool(forKey: kExpandVoltages)
    } else {
      self.expandVoltages = false
      UDs.set(false, forKey: kExpandVoltages)
    }
    
    if (UDs.object(forKey: kExpandCPUFrequencies) != nil) {
      self.expandCPUFrequencies = UDs.bool(forKey: kExpandCPUFrequencies)
    } else {
      self.expandCPUFrequencies = true
      UDs.set(true, forKey: kExpandCPUFrequencies)
    }
    
    if (UDs.object(forKey: kExpandAll) != nil) {
      self.expandAll = UDs.bool(forKey: kExpandAll)
    } else {
      self.expandAll = false
      UDs.set(false, forKey: kExpandAll)
    }
    
    if (UDs.object(forKey: kDontShowEmpty) != nil) {
      self.dontshowEmpty = UDs.bool(forKey: kDontShowEmpty)
    } else {
      self.dontshowEmpty = true
      UDs.set(true, forKey: kDontShowEmpty)
    }
    UDs.synchronize()
  }
  
  @IBAction func closeApp(sender : NSButton) {
    NSApp.terminate(self)
  }
  
  @IBAction func reattachPopover(_ sender: NSButton) {
    if let button = AppSd.statusItem.button {
      button.performClick(button)
    }
  }
  
  @IBAction func showPreferences(sender : NSButton) {
    if (self.preferenceWC == nil) {
      self.preferenceWC = PreferencesWC.loadFromNib()
    }
    DispatchQueue.main.async {
      self.preferenceWC?.showWindow(self)
    }
  }
  
  @IBAction func showGadget(sender : NSButton?) {
    AppSd.statusItemLen = 0
    if (self.gadgetWC == nil) {
      self.gadgetWC = GadgetWC.loadFromNib()
      self.gadgetWC?.showWindow(self)
    } else {
      self.gadgetWC?.window?.close()
      self.gadgetWC = nil
      UDs.set(false, forKey: kShowGadget)
    }
  }
  
  func initialize() {
    var ti : TimeInterval = UDs.double(forKey: kCPUTimeInterval)
    self.timeCPUInterval = (ti >= 0.1 && ti <= 10) ? ti : 1.5
    
    ti = UDs.double(forKey: kGPUTimeInterval)
    self.timeGPUInterval = (ti >= 0.1 && ti <= 10) ? ti : 3.0
    
    ti = UDs.double(forKey: kMoBoTimeInterval)
    self.timeMotherBoardInterval = (ti >= 0.1 && ti <= 10) ? ti : 3.0
    
    ti = UDs.double(forKey: kFansTimeInterval)
    self.timeFansInterval = (ti >= 0.1 && ti <= 10) ? ti : 3.0
    
    ti = UDs.double(forKey: kRAMTimeInterval)
    self.timeRAMInterval = (ti >= 0.1 && ti <= 10) ? ti : 3.0
    
    ti = UDs.double(forKey: kMediaTimeInterval)
    self.timeMediaInterval = (ti >= 0.1 && ti <= (60*10)) ? ti : (60*10)
    
    ti = UDs.double(forKey: kBatteryTimeInterval)
    self.timeBatteryInterval = (ti >= 0.1 && ti <= 10) ? ti : 3.0

    
    loadPreferences()
    self.sensorList = NSMutableArray()
    self.dataSource = NSMutableArray()
    // ------
    self.SystemNode = HWTreeNode(representedObject: HWSensorData(group: "System",
                                                                 sensor: nil,
                                                                 isLeaf: false))
    self.dataSource?.add(self.SystemNode!)
    // ------
    if UDs.bool(forKey: kShowCPUSensors) {
      
      var igpInfoSensors : [HWMonitorSensor] = [HWMonitorSensor]()
      
      let (main, coresFreq, coresTemp) = AppSd.sensorScanner.get_CPU_GlobalParameters()
      self.CPUNode = HWTreeNode(representedObject: HWSensorData(group: "CPU".locale,
                                                                sensor: nil,
                                                                isLeaf: false))
      
      for s in main {
        if s.isInformativeOnly {
          igpInfoSensors.append(s)
        } else {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.CPUNode?.mutableChildren.add(sensor)
        }
      }
      // ------
      self.CPUFrequenciesNode = HWTreeNode(representedObject:
        HWSensorData(group: "Core Frequencies".locale, sensor: nil, isLeaf: false))
      if (coresFreq != nil) {
        for s in coresFreq! {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUFrequenciesNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.CPUFrequenciesNode?.mutableChildren.add(sensor)
        }
      } else {
        for s in AppSd.sensorScanner.getSMC_SingleCPUFrequencies() {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUFrequenciesNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.CPUFrequenciesNode?.mutableChildren.add(sensor)
        }
      }
      
      
      if (self.CPUFrequenciesNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.CPUFrequenciesNode?.children)!)
        self.CPUNode?.mutableChildren.add(self.CPUFrequenciesNode!)
      } else {
        if self.dontshowEmpty {
          self.CPUFrequenciesNode = nil
        } else {
          self.CPUNode?.mutableChildren.add(self.CPUFrequenciesNode!)
        }
      }
      // ------
      self.CPUTemperaturesNode = HWTreeNode(representedObject: HWSensorData(group: "Core Temperatures".locale,
                                                                            sensor: nil,
                                                                            isLeaf: false))
      
      if (coresTemp != nil) {
        for s in coresTemp! {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUTemperaturesNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.CPUTemperaturesNode?.mutableChildren.add(sensor)
        }
      } else {
        for s in AppSd.sensorScanner.getSMC_SingleCPUTemperatures() {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.CPUTemperaturesNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.CPUTemperaturesNode?.mutableChildren.add(sensor)
        }
      }
      
      if (self.CPUTemperaturesNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.CPUTemperaturesNode?.children)!)
        self.CPUNode?.mutableChildren.add(self.CPUTemperaturesNode!)
      } else {
        if self.dontshowEmpty {
          self.CPUTemperaturesNode = nil
        } else {
          //self.dataSource?.add(self.CPUTemperaturesNode!)
          self.CPUNode?.mutableChildren.add(self.CPUTemperaturesNode!)
        }
      }
      
      if igpInfoSensors.count > 0 {
        let cpuname = System.sysctlbynameString("machdep.cpu.brand_string").components(separatedBy: "@")[0]
        self.IPGInfoNode = HWTreeNode(representedObject: HWSensorData(group: cpuname,
                                                                      sensor: nil,
                                                                      isLeaf: false))
        
        for s in igpInfoSensors {
          let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.IPGInfoNode?.sensorData?.group)!,
                                                                  sensor: s,
                                                                  isLeaf: true))
          self.sensorList?.add(sensor)
          self.IPGInfoNode?.mutableChildren.add(sensor)
        }
        self.CPUNode?.mutableChildren.add(self.IPGInfoNode!)
      }
      
      if (self.CPUNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.CPUNode?.children)!)
        self.dataSource?.add(self.CPUNode!)
      } else {
        if self.dontshowEmpty {
          self.CPUNode = nil
        } else {
          self.dataSource?.add(self.CPUNode!)
        }
      }
    }
    // ------
    if UDs.bool(forKey: kShowGPUSensors) {
      self.GPUNode = HWTreeNode(representedObject: HWSensorData(group: "GPUs".locale,
                                                                sensor: nil,
                                                                isLeaf: false))
      
      if self.useIOAcceleratorForGPUs {
        let IOAcc = Graphics.init().graphicsCardsSensors() // IPG included
        for sub in IOAcc {
          for s in sub.mutableChildren {
            self.sensorList?.add(s)
          }
        }
        self.GPUNode?.mutableChildren.addObjects(from: IOAcc)
      } else {
        if (AppSd.ipg != nil && AppSd.ipg!.inited) {
          for s in AppSd.ipg!.getIntelPowerGadgetGPUSensors() {
            let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.GPUNode?.sensorData?.group)!,
                                                                    sensor: s,
                                                                    isLeaf: true))
            self.sensorList?.add(sensor)
            self.GPUNode?.mutableChildren.add(sensor)
          }
        }
        
        if let ipp = AppSd.sensorScanner.getIGPUPackagePower() {
          let IGPUPackage = HWTreeNode(representedObject: HWSensorData(group: (self.GPUNode?.sensorData?.group)!, sensor: ipp, isLeaf: true))
          self.sensorList?.add(IGPUPackage)
          self.GPUNode?.mutableChildren.add(IGPUPackage)
        }
      }
      
      let smcGpu = AppSd.sensorScanner.getSMCGPU()
      
      for s in smcGpu {
        let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.GPUNode?.sensorData?.group)!,
                                                                sensor: s,
                                                                isLeaf: true))
        self.sensorList?.add(sensor)
        self.GPUNode?.mutableChildren.add(sensor)
      }
      if (self.GPUNode?.children?.count)! == 0 {
        self.GPUNode = nil
        self.useIOAcceleratorForGPUs = false // give a chance to RadeonMonitor, NVClockX, GeforceSensor etc..
      }
      
      if (self.GPUNode != nil) {
        self.dataSource?.add(self.GPUNode!)
      }
    }
    // ------
    let lpcConfigPath = Bundle.main.sharedSupportPath! + "/LPC"
    
    AppSd.superIOChipName = AppSd.sensorScanner.getSuperIOChipName()
    
    if AppSd.board != nil && AppSd.vendorShort != nil && AppSd.superIOChipName != nil{
      var confPath = "\(lpcConfigPath)/\(AppSd.vendorShort!)/\(AppSd.superIOChipName!)/\(AppSd.board!).plist"
      
      if !FileManager.default.fileExists(atPath: confPath) {
        print("../\(AppSd.vendorShort!)/\(AppSd.superIOChipName!)/\(AppSd.board!).plist not found.")
        confPath = "\(lpcConfigPath)/\(AppSd.vendorShort!)/\(AppSd.superIOChipName!)/default.plist"
        
        if !FileManager.default.fileExists(atPath: confPath) {
          print("../\(AppSd.vendorShort!)/\(AppSd.superIOChipName!)/default.plist not found.")
        }
      }
      
      if let plist = NSDictionary(contentsOfFile: confPath) as? [String : Any] {
        self.superIOConfig = plist
        print("Loading configuration from \(confPath)")
      } else {
        print("Error: unable to load \(confPath)")
      }
    } else {
      print("Board = \(AppSd.board ?? "NULL")")
      print("Vendor Short = \(AppSd.vendorShort ?? "NULL")")
      print("Chip Name = \(AppSd.superIOChipName ?? "NULL")")
    }
    
    if (self.superIOConfig == nil) {
      if let plist = NSDictionary(contentsOfFile: "\(lpcConfigPath)/lpc.plist") as? [String : Any] {
        self.superIOConfig = plist
        print("Loading configuration from lpc.plist.")
      }
    }
    
    let (voltages, fans) = AppSd.sensorScanner.getSMCSuperIO(config: self.superIOConfig)
    // ------
    if UDs.bool(forKey: kShowMoBoSensors) {
      var moboTitle = (AppSd.board != nil) ? AppSd.board! : "Motherboard".locale
      
      if AppSd.superIOChipName != nil {
        moboTitle = "\(moboTitle), \(AppSd.superIOChipName!)"
      }
      
      self.MOBONode = HWTreeNode(representedObject: HWSensorData(group: moboTitle,
                                                                 sensor: nil,
                                                                 isLeaf: false))
      var mobosensors : [HWMonitorSensor]? = nil
      if voltages.count > 0 {
        self.voltagesSMCSuperIO = true
        mobosensors = voltages
      } else {
        mobosensors = AppSd.sensorScanner.getMotherboard()
      }
      for s in mobosensors! {
        let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.MOBONode?.sensorData?.group)!,
                                                                sensor: s,
                                                                isLeaf: true))
        self.MOBONode?.mutableChildren.add(sensor)
      }
      
      if (self.MOBONode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.MOBONode?.children)!)
        self.dataSource?.add(self.MOBONode!)
      } else {
        if self.dontshowEmpty {
          self.MOBONode = nil
        } else {
          self.dataSource?.add(self.MOBONode!)
        }
      }
    }
    // ------ FansNode
    if UDs.bool(forKey: kShowFansSensors) {
      self.FansNode = HWTreeNode(representedObject: HWSensorData(group: "Fans or Pumps".locale,
                                                                 sensor: nil,
                                                                 isLeaf: false))
      var fanssensors : [HWMonitorSensor]? = nil
      if fans.count > 0 {
        self.fansSMCSuperIO = true
        fanssensors = fans
      } else {
        fanssensors = AppSd.sensorScanner.getFans()
      }
      for s in fanssensors! {
        let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.FansNode?.sensorData?.group)!,
                                                                sensor: s,
                                                                isLeaf: true))
        self.FansNode?.mutableChildren.add(sensor)
      }
      
      if (self.FansNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.FansNode?.children)!)
        self.dataSource?.add(self.FansNode!)
      } else {
        if self.dontshowEmpty {
          self.FansNode = nil
        } else {
          self.dataSource?.add(self.FansNode!)
        }
      }
    }
    // ------
    if UDs.bool(forKey: kShowRAMSensors) {
      self.RAMNode = HWTreeNode(representedObject: HWSensorData(group: "RAM".locale,
                                                                sensor: nil,
                                                                isLeaf: false))
      for s in AppSd.sensorScanner.getMemory() {
        let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.RAMNode?.sensorData?.group)!,
                                                                sensor: s,
                                                                isLeaf: true))
        self.RAMNode?.mutableChildren.add(sensor)
      }
      
      if (self.RAMNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.RAMNode?.children)!)
        self.dataSource?.add(self.RAMNode!)
      } else {
        if self.dontshowEmpty {
          self.RAMNode = nil
        } else {
          self.dataSource?.add(self.RAMNode!)
        }
      }
    }
    // ------
    if UDs.bool(forKey: kShowMediaSensors) {
      self.mediaNode =  HWTreeNode(representedObject: HWSensorData(group: "Media health".locale,
                                                                   sensor: nil,
                                                                   isLeaf: false))
      
      let smartscanner = HWSmartDataScanner()
      for d in smartscanner.getSmartCapableDisks() {
        var log : String = ""
        var productName : String = ""
        var serial : String = ""
        
        let list = smartscanner.getSensors(from: d, characteristics: &log, productName: &productName, serial: &serial)
        let smartSensorParent = HWMonitorSensor(key: productName,
                                                unit: HWUnit.none,
                                                type: "Parent",
                                                sensorType: .mediaSMARTContenitor,
                                                title: serial,
                                                canPlot: false)
        
        smartSensorParent.actionType = .mediaLog
        smartSensorParent.characteristics = log
        let smartSensorParentNode = HWTreeNode(representedObject: HWSensorData(group: productName,
                                                                               sensor: smartSensorParent,
                                                                               isLeaf: false))
        for s in list {
          let snode = HWTreeNode(representedObject: HWSensorData(group: (smartSensorParentNode.sensorData?.group)!,
                                                                 sensor: s,
                                                                 isLeaf: true))
          s.characteristics = log
          smartSensorParentNode.mutableChildren.add(snode)
          self.sensorList?.add(snode)
        }
        self.mediaNode?.mutableChildren.add(smartSensorParentNode)
      }
      
      self.addObservers()
      
      if (self.mediaNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.mediaNode?.children)!)
        self.dataSource?.add(self.mediaNode!)
      } else {
        if self.dontshowEmpty {
          self.mediaNode = nil
        } else {
          self.dataSource?.add(self.mediaNode!)
        }
      }
    } else {
      self.addObservers()
    }
    //----------------------
    if UDs.bool(forKey: kShowBatterySensors) {
      self.batteriesNode =  HWTreeNode(representedObject: HWSensorData(group: "Batteries".locale,
                                                                       sensor: nil,
                                                                       isLeaf: false))
      for s in AppSd.sensorScanner.getBattery() {
        let sensor = HWTreeNode(representedObject: HWSensorData(group: (self.batteriesNode?.sensorData?.group)!,
                                                                sensor: s,
                                                                isLeaf: true))
        self.batteriesNode?.mutableChildren.add(sensor)
      }
      
      if (self.batteriesNode?.children?.count)! > 0 {
        self.sensorList?.addObjects(from: (self.batteriesNode?.children)!)
        self.dataSource?.add(self.batteriesNode!)
      } else {
        if self.dontshowEmpty {
          self.batteriesNode = nil
        } else {
          self.dataSource?.add(self.batteriesNode!)
        }
      }
    }
    
    self.usbNode = HWTreeNode(representedObject: HWSensorData(group: "USB".locale,
                                                              sensor: nil,
                                                              isLeaf: false))
    // populate it by adding the watcher
    self.usbWatcher = USBWatcher.init(delegate: self)
    //----------------------
    
    AppSd.sensorsInited = true
    self.outline.reloadData()
    
    if (self.CPUNode != nil) && (self.expandCPUTemperature || self.expandCPUFrequencies ||  self.expandAll) {
      self.outline.expandItem(self.CPUNode)
    }
    
    if (self.CPUFrequenciesNode != nil) && (self.expandCPUFrequencies || self.expandAll) {
      self.outline.expandItem(self.CPUFrequenciesNode)
    }
    
    if (self.CPUTemperaturesNode != nil) && (self.expandCPUTemperature || self.expandAll) {
      self.outline.expandItem(self.CPUTemperaturesNode)
    }
    
    if self.expandAll {
      if (self.RAMNode != nil) {
        self.outline.expandItem(self.RAMNode)
      }
      if (self.GPUNode != nil) {
        self.outline.expandItem(self.GPUNode)
        for i in (self.GPUNode?.children)! {
          self.outline.expandItem(i)
        }
      }
      if (self.mediaNode != nil) {
        self.outline.expandItem(self.mediaNode)
        for i in (self.mediaNode?.children)! {
          self.outline.expandItem(i)
        }
      }
      if (self.MOBONode != nil) {
        self.outline.expandItem(self.MOBONode)
      }
      if (self.FansNode != nil) {
        self.outline.expandItem(self.FansNode)
      }
      if (self.batteriesNode != nil) {
        self.outline.expandItem(self.batteriesNode)
      }
    }
    
    if (self.CPUNode != nil) {
      self.timerCPU = Timer.scheduledTimer(timeInterval: self.timeCPUInterval,
                                           target: self,
                                           selector: #selector(self.updateCPUSensors),
                                           userInfo: nil,
                                           repeats: true)
      
      RunLoop.current.add(self.timerCPU!, forMode: RunLoop.Mode.default)
    }
    
    if (self.GPUNode != nil) {
      self.timerGPU = Timer.scheduledTimer(timeInterval: self.timeGPUInterval,
                                           target: self,
                                           selector: #selector(self.updateGPUSensors),
                                           userInfo: nil,
                                           repeats: true)
      
      RunLoop.current.add(self.timerGPU!, forMode: RunLoop.Mode.default)
    }
    
    if (self.MOBONode != nil) {
      self.timerMotherboard = Timer.scheduledTimer(timeInterval: self.timeMotherBoardInterval,
                                                   target: self,
                                                   selector: #selector(self.updateMotherboardSensors),
                                                   userInfo: nil,
                                                   repeats: true)
      
      RunLoop.current.add(self.timerMotherboard!, forMode: RunLoop.Mode.default)
    }
    
    if (self.FansNode != nil) {
      self.timerFans = Timer.scheduledTimer(timeInterval: self.timeFansInterval,
                                            target: self,
                                            selector: #selector(self.updateFanSensors),
                                            userInfo: nil,
                                            repeats: true)
      
      RunLoop.current.add(self.timerFans!, forMode: RunLoop.Mode.default)
    }
    
    if (self.RAMNode != nil) {
      self.timerRAM = Timer.scheduledTimer(timeInterval: self.timeRAMInterval,
                                           target: self,
                                           selector: #selector(self.updateRAMSensors),
                                           userInfo: nil,
                                           repeats: true)
      
      RunLoop.current.add(self.timerRAM!, forMode: RunLoop.Mode.default)
    }
    
    if (self.mediaNode != nil) {
      self.timerMedia = Timer.scheduledTimer(timeInterval: self.timeMediaInterval,
                                             target: self,
                                             selector: #selector(self.updateMediaSensors),
                                             userInfo: nil,
                                             repeats: true)
      
      RunLoop.current.add(self.timerMedia!, forMode: RunLoop.Mode.default)
    }
    
    if (self.batteriesNode != nil) {
      self.timerBattery = Timer.scheduledTimer(timeInterval: self.timeBatteryInterval,
                                               target: self,
                                               selector: #selector(self.updateBatterySensors),
                                               userInfo: nil,
                                               repeats: true)
      
      RunLoop.current.add(self.timerBattery!, forMode: RunLoop.Mode.default)
    }
  }
  
  
}

extension PopoverViewController: NSOutlineViewDelegate {
  func outlineViewSelectionDidChange(_ notification: Notification) {
    
  }
  
  func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
    
  }
  
  func outlineView(_ outlineView: NSOutlineView, didRemove rowView: NSTableRowView, forRow row: Int) {
  
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    return HWTableRowView()
  }
  
  @objc func clicked() {
    let selected = self.outline.clickedRow
    if selected >= 0 {
      if let node : HWTreeNode = self.outline.item(atRow: selected) as? HWTreeNode {
        if (node.sensorData?.isLeaf)! {
          let view : NSTableCellView = self.outline.view(atColumn: 0,
                                                         row: selected,
                                                         makeIfNecessary: false /* mind that is already visible */) as! NSTableCellView
          if let sensor = node.sensorData?.sensor {
            if sensor.isInformativeOnly {
              NSSound.beep()
            } else {
              AppSd.statusItemLen = 0
              if sensor.favorite {
                sensor.favorite = false
                view.imageView?.image = nil
              } else {
                sensor.favorite = true
                let image = NSImage(named: "checkbox")
                image?.isTemplate = true
                view.imageView?.image = image
              }
              UDs.set(sensor.favorite, forKey: sensor.key)
              UDs.synchronize()
              self.updateStatuBar()
            }
          }
        } else {
          if self.outline.isItemExpanded(node) {
            self.outline.collapseItem(node)
          } else {
            self.outline.expandItem(node)
          }
        }
        
      }
    }
  }
  
}

extension PopoverViewController: NSOutlineViewDataSource {
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if let node = item as? HWTreeNode {
      if !(node.sensorData?.isLeaf)! && node.sensorData?.group != "System" {
        return true
      }
    }
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if !AppSd.sensorsInited {
      return 0
    }
    if (item == nil) {
      return (self.dataSource?.count)!
    } else {
      return ((item as! HWTreeNode).children?.count)!
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView,
                   child index: Int,
                   ofItem item: Any?) -> Any {
    if item != nil {
      return (item as! HWTreeNode).children![index]
    }
    else
    {
      return self.dataSource?.object(at: index) as Any
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView,
                   viewFor tableColumn: NSTableColumn?,
                   item: Any) -> NSView? {
    var view : NSTableCellView? = nil
   
    if let node : HWTreeNode = item as? HWTreeNode {
      node.sensorData?.sensor?.outLine = outlineView as? HWOulineView
      let isGroup : Bool = !(node.sensorData?.isLeaf)!
      if (tableColumn != nil) {
        view = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView
        switch tableColumn!.identifier.rawValue {
        case "column0":
          view?.imageView?.image = getImageFor(node: node)
          view?.imageView?.appearance = getAppearance()
        case "column1":
          if isGroup {
            let gName = (node.sensorData?.group)!
            if gName == "System" {
              view?.textField?.stringValue = ProcessInfo.init().operatingSystemVersionString
            } else {
              view?.textField?.stringValue = gName
            }
            view?.textField?.appearance = getAppearance()
            view?.textField?.textColor = (getAppearance().name == NSAppearance.Name.vibrantDark) ? NSColor.green : NSColor.controlTextColor
          } else {
            if node.sensorData?.sensor?.sensorType == .hdSmartLife {
              view?.textField?.stringValue = "Life".locale
            } else if node.sensorData?.sensor?.sensorType == .hdSmartTemp {
              view?.textField?.stringValue = "Temperature".locale
            } else {
              view?.textField?.stringValue = node.sensorData!.sensor!.title
            }
            view?.textField?.appearance = getAppearance()
            view?.textField?.textColor = (getAppearance().name == NSAppearance.Name.vibrantDark) ? NSColor.white : NSColor.controlTextColor
          }
        case "column2":
          if isGroup {
            view?.textField?.stringValue = ""
          } else {
            if let value : String = node.sensorData?.sensor?.stringValue {
              var us = ""
              if node.sensorData!.sensor!.unit != .none {
                us = "\(node.sensorData!.sensor!.unit.rawValue.locale(AppSd.translateUnits))"
                if node.sensorData!.sensor!.unit != .Percent &&
                  node.sensorData!.sensor!.unit != .C {
                  us = " \(us)"
                }
              }
              view?.textField?.stringValue = value + us
            } else {
              view?.textField?.stringValue = "-"
            }
            
            view?.textField?.appearance = getAppearance()
            view?.textField?.textColor = (getAppearance().name == NSAppearance.Name.vibrantDark) ? NSColor.white : NSColor.controlTextColor
          }
        case "column3":
          if let sensor = node.sensorData?.sensor {
            return sensor.plot?.hostView
          }
        default:
          view = nil
        }
      }
    }
    view?.appearance = getAppearance()
    view?.backgroundStyle = .emphasized
    return view
  }
  
  func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
    self.dragSensorKey = nil
    if let sensor = (item as? HWTreeNode)?.sensorData?.sensor {
      self.dragSensorKey = sensor.key
      return self.dragSensorKey as NSPasteboardWriting?
    }

    return nil
  }
  
  func outlineView(_ outlineView: NSOutlineView,
                   draggingSession session: NSDraggingSession,
                   endedAt screenPoint: NSPoint,
                   operation: NSDragOperation) {
    if let key = self.dragSensorKey {
      for n in sensorList! {
        if let s = (n as! HWTreeNode).sensorData?.sensor {
          if s.key == key {
            if s.dethachableSensor != nil {
              NSSound.beep()
              break
            }
            let hw : HWSWC = HWSWC(sensor: s)
            s.dethachableSensor = hw.contentViewController?.view as? HWSView
            s.dethachableSensor!.window!.setFrameOrigin(screenPoint)
            hw.showWindow(nil)
            break
          }
        }
      }
    }
    self.dragSensorKey = nil
  }
  
  func getImageFor(node: HWTreeNode) -> NSImage? {
    var image : NSImage? = nil
    let group : String = (node.sensorData?.group)!
    
    if (node.sensorData?.isLeaf)! {
      if (node.sensorData?.sensor?.favorite)! {
        image = NSImage(named: "checkbox")
        image?.isTemplate = true
        return image
      }
    } else {
      switch group {
      case "RAM".locale:
        image = NSImage(named: "ram_small")
        break
      case "Core Temperatures".locale:
        image = NSImage(named: "temp_alt_small")
        break
      case "CPU Power".locale:
        image = NSImage(named: "Light")
        break
      case "CPU":
        image = NSImage(named: "CPU")
        break
      case "Core Frequencies".locale:
        image = NSImage(named: "freq_small")
        break
      case "Temperatures".locale:
        image = NSImage(named: "temp_alt_small")
        break
      case "GPUs".locale:
        image = NSImage(named: "GPU")
        break
      case "Fans or Pumps".locale:
        image = NSImage(named: "fan_small")
        break
      case "Frequencies".locale:
        image = NSImage(named: "freq_small")
        break
      case "Motherboard".locale:
        image = NSImage(named: "Motherboard")
        break
      case "Multipliers".locale:
        image = NSImage(named: "multiply_small")
        break
      case "Voltages".locale:
        image = NSImage(named: "voltage_small")
        break
      case "Batteries".locale:
        image = NSImage(named: "modern-battery-icon")
        break
      case "Media health".locale:
        image = NSImage(named: "hd_small.png")
        break
      case "System":
        image = NSImage(byReferencingFile: "/Applications/Utilities/System Information.app/Contents/Resources/ASP.icns")
        if (image == nil) {
          image = NSImage(named: "temperature_small")
        }
        break
      default:
        break
      }
    }
    image?.isTemplate = true
    return image
  }
}

extension PopoverViewController {
  override func mouseDragged(with theEvent: NSEvent) {
    if let popover = (AppSd.hwWC?.contentViewController as! HWViewController).popover {
      let mouseLocation = NSEvent.mouseLocation
      
      var newLocation   = mouseLocation
      let frame = NSScreen.main?.frame
      newLocation.x     = frame!.size.width - mouseLocation.x
      newLocation.y     = frame!.size.height - mouseLocation.y
      if newLocation.x < kMinWidth {
        newLocation.x = kMinWidth
      }
      
      if newLocation.y < kMinHeight {
        newLocation.y = kMinHeight
      }
      popover.contentSize = NSSize(width: newLocation.x, height: newLocation.y)
      UDs.set(newLocation.x, forKey: kPopoverWidth)
      UDs.set(newLocation.y, forKey: kPopoverHeight)
      UDs.synchronize()
    }
  }
}

extension PopoverViewController {
  /*
   we need to rescan disks when the System awake (because the user can have removed some of it),
   or just when a disk is ejected or plugged.
   */
  func addObservers() {
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.diskMounted),
                                                      name: NSWorkspace.didMountNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.diskUmounted),
                                                      name: NSWorkspace.didUnmountNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.wakeListener),
                                                      name: NSWorkspace.didWakeNotification,
                                                      object: nil)
    
    NSWorkspace.shared.notificationCenter.addObserver(self,
                                                      selector: #selector(self.powerOffListener),
                                                      name: NSWorkspace.willPowerOffNotification,
                                                      object: nil)
  }
  
  func removeObservers() {
    /*
    if #available(OSX 10.12, *) {
      //print("no need to remove the observer in 10.12 onward!")
    } else {*/
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didMountNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didUnmountNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didRenameVolumeNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.didWakeNotification,
                                                           object: nil)
      
      NSWorkspace.shared.notificationCenter.removeObserver(self,
                                                           name: NSWorkspace.willPowerOffNotification,
                                                           object: nil)
    //}
  }

  @objc func diskMounted() {
    self.updateMediaSensors()
  }
  
  @objc func diskUmounted() {
    self.updateMediaSensors()
  }
  
  @objc func powerOffListener() {
    self.removeObservers()
  }
  
  func removeAllTimers() {
    if (self.timerCPU != nil) && timerCPU!.isValid { self.timerCPU!.invalidate() }
    if (self.timerGPU != nil) && timerGPU!.isValid { self.timerGPU!.invalidate() }
    if (self.timerMotherboard != nil) && timerMotherboard!.isValid { self.timerMotherboard!.invalidate() }
    if (self.timerFans != nil) && timerFans!.isValid { self.timerFans!.invalidate() }
    if (self.timerRAM != nil) && timerRAM!.isValid { self.timerRAM!.invalidate() }
    if (self.timerMedia != nil) && timerCPU!.isValid { self.timerMedia!.invalidate() }
    if (self.timerBattery != nil) && timerCPU!.isValid { self.timerBattery!.invalidate() }
  }
  
  @objc func wakeListener() {
    self.updateCPUSensors()
    self.updateGPUSensors()
    self.updateMotherboardSensors()
    self.updateBatterySensors()
    self.updateMediaSensors()
    self.updateRAMSensors()
    self.updateFanSensors()
  }
}
