//
//  AppDelegate.m
//  HWMonitorSMC2 Helper
//
//  Created by vector sigma on 16/05/18.
//  Copyright © 2018 HWSensor. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSString *appID = @"org.cloverhackycolor.HWMonitorSMC2";
  BOOL running = NO;
  NSString *appPath = [self HWMonitorSMC2Path];
  
  NSArray *runnings = [[NSWorkspace sharedWorkspace] runningApplications];
  for (NSRunningApplication *app in runnings) {
    if ([app.bundleIdentifier isEqualToString:appID] && [app.bundleURL.path isEqualToString:appPath]) {
      running = YES;
    }
  }

  if (!running) {
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
  }
  [self performSelector:@selector(terminate) withObject:nil afterDelay:3];
}

- (NSString *)HWMonitorSMC2Path {
  NSURL *myUrl = [[NSBundle mainBundle] bundleURL];
  int count = 4;
  while (count > 0) {
    myUrl = myUrl.URLByDeletingLastPathComponent;
    count--;
  }
  return myUrl.path;
}

- (void)terminate {
  [NSApp terminate:nil];
}

@end

/* for when Swift will be embedded in the OS (tested)
 //
 //  AppDelegate.swift
 //  HWMonitorSMC2 Helper
 //
 //  Created by vector sigma on 14/05/18.
 //  Copyright © 2018 HWSensor. All rights reserved.
 //
 
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  let appID : String = "org.cloverhackycolor.HWMonitorSMC2"
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    var running : Bool = false
    let appPath = HWMonitorSMC2Path()
    
    for app in NSWorkspace.shared.runningApplications {
      if app.bundleIdentifier == appID
        && app.bundleURL?.path == appPath {
          running = true
          break
        }
    }
    
    if !running {
      NSWorkspace.shared.launchApplication(appPath)
    }
    NSApp.terminate(nil)
  }
  
  func HWMonitorSMC2Path() -> String {
    var myUrl = Bundle.main.bundleURL
    var count: Int = 4
    repeat {
      myUrl = myUrl.deletingLastPathComponent()
      count -= 1
    } while count > 0
      return myUrl.path
      }
  }
*/
