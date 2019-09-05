//
//  Themes.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 21/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Cocoa

public enum Theme : String {
  case Default    = "Default"
  case Classic    = "Classic"
  case DashedH    = "Dashed Horizontally"
  case NoGrid     = "No Grid"
  case GridClear  = "With Grid, clear background"
}

public struct Themes {
  var theme : Theme
  
  init(theme: Theme, outline: HWOulineView) {
    self.theme = theme
    let dark : Bool = getAppearance().name == .vibrantDark
    outline.window?.backgroundColor = .clear
    outline.enclosingScrollView?.borderType = NSBorderType.lineBorder
    outline.enclosingScrollView?.drawsBackground = false
    outline.enclosingScrollView?.contentView.drawsBackground = false
    switch self.theme {
    case .Default:
      outline.gridStyleMask = []
      outline.enclosingScrollView?.borderType = NSBorderType.noBorder
      outline.usesAlternatingRowBackgroundColors = false
      outline.enclosingScrollView?.contentView.drawsBackground = false
    case .Classic:
      outline.usesAlternatingRowBackgroundColors = true
      outline.gridColor = (dark ? UDs.darkGridColor() : UDs.lightGridColor())
      outline.gridStyleMask = [.solidVerticalGridLineMask, .dashedHorizontalGridLineMask ]
    case .DashedH:
      outline.usesAlternatingRowBackgroundColors = true
      outline.gridColor = (dark ? UDs.darkGridColor() : UDs.lightGridColor())
      outline.gridStyleMask = [.dashedHorizontalGridLineMask]
    case .NoGrid:
      outline.usesAlternatingRowBackgroundColors = true
      outline.gridStyleMask = []
    case .GridClear:
      outline.usesAlternatingRowBackgroundColors = false
      outline.enclosingScrollView?.borderType = NSBorderType.noBorder
      outline.gridColor = (dark ? UDs.darkGridColor() : UDs.lightGridColor())
      outline.gridStyleMask = [.dashedHorizontalGridLineMask, .solidVerticalGridLineMask]
    }
  }
}
