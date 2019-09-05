//
//  HWTreeNode.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 25/02/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

public class HWSensorData: NSObject {
  var group    : String
  var sensor   : HWMonitorSensor?
  var isLeaf   : Bool = false
  required init(group: String, sensor: HWMonitorSensor?, isLeaf: Bool) {
    self.group    = group
    self.sensor   = sensor
    self.isLeaf   = isLeaf
    super.init()
  }
}

public class HWTreeNode: NSTreeNode {
  internal var ro: Any?
  
  override public var representedObject: Any? {
    get {
      return self.ro
    } set {
      self.ro = newValue
    }
  }
  
  var sensorData: HWSensorData? {
    get {
      return (self.representedObject as! HWSensorData)
    } set {
      self.representedObject = newValue
    }
  }
}
