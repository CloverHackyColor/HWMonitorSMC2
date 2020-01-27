//
//  HWTableRowView.swift
//  HWMonitorSMC
//
//  Created by vector sigma on 03/03/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

import Cocoa

class HWTableRowView: NSTableRowView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.wantsLayer = true
    self.isEmphasized = true
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // cause column 0 to be invisible when the popover is detached in older OSes
  override var interiorBackgroundStyle: NSView.BackgroundStyle {
    if #available(OSX 10.14, *) {
      return super.interiorBackgroundStyle
    } else {
      if getAppearance().name == .vibrantDark {
        return isSelected ? .light : .dark
      } else {
        return self.isSelected ? .dark : .light
      }
    }
  }
  
  override func drawSelection(in dirtyRect: NSRect) {
    if self.selectionHighlightStyle != .none {
      let isDark : Bool = getAppearance().name == NSAppearance.Name.vibrantDark
      let roundedRect = NSInsetRect(self.bounds, 1, 1.7)
      if isDark {
        NSColor.green.setStroke()
        NSColor.darkGray.setFill()
      } else {
        NSColor.gray.setStroke()
        NSColor.gray.setFill()
      }
      
      let selectionPath = NSBezierPath.init(roundedRect: roundedRect, xRadius: 2, yRadius: 2)
      selectionPath.fill()
      selectionPath.stroke()
    }
  }
}
