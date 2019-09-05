//
//  IOBatteryStatus.m
//  HWSensors
//
//  Created by Navi on 04.01.13.
//
//

#import <IOKit/pwr_mgt/IOPM.h>
#import "IOBatteryStatus.h"

#define BAT0_NOT_FOUND -1

@implementation IOBatteryStatus

+ (BOOL)keyboardAvailable {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
  BOOL value = service ? YES : NO;
  IOObjectRelease(service);
  return value;
}

+ (BOOL)trackpadAvailable {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));
  BOOL value = service ? YES : NO;
  IOObjectRelease(service);
  return value;
}

+ (BOOL)mouseAvailable {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));
  BOOL value = service ? YES : NO;
  IOObjectRelease(service);
  return value;
}

+ (NSString *)getKeyboardName {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
  NSString * value = nil;
  
  if (!service ) {
    return nil;
  }
  value = CFBridgingRelease(IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return value;
}

+ (NSString *)getTrackpadName {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));
  NSString * value = nil;
  
  if (!service ) {
    return nil;
  }
  
  value = CFBridgingRelease(IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return value;
}

+ (NSString *)getMouseName {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));
  NSString * value = nil;
  
  if (!service ) {
    return nil;
  }
  
  value = CFBridgingRelease(IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return value;
}

+ (NSInteger )getKeyboardBatteryLevel {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
  
  
  if (!service ) {
    return 0; //nil;
  }
  
  NSNumber * percent = CFBridgingRelease(IORegistryEntryCreateCFProperty(service,
                                                                         CFSTR("BatteryPercent, "),
                                                                         kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return [percent integerValue];
}

+ (NSInteger )getTrackpadBatteryLevel {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));
  
  
  if (!service ) {
    return 0; //nil;
  }
  NSNumber * percent = CFBridgingRelease(IORegistryEntryCreateCFProperty(service,
                                                                         CFSTR("BatteryPercent"),
                                                                         kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return [percent integerValue];
}

+ (NSInteger )getMouseBatteryLevel {
  io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));
  
  
  if (!service ) {
    return 0; //nil;
  }
  NSNumber * percent = CFBridgingRelease(IORegistryEntryCreateCFProperty(service,
                                                                         CFSTR("BatteryPercent"),
                                                                         kCFAllocatorDefault, 0));
  
  IOObjectRelease(service);
  return [percent integerValue];
}


+ (NSDictionary *)getAllBatteriesLevel {
  NSMutableDictionary * dataset = [[NSMutableDictionary alloc] initWithCapacity:0];
  NSInteger value = 0;
  if([IOBatteryStatus keyboardAvailable]) {
    value = [IOBatteryStatus getKeyboardBatteryLevel];
    [dataset setValue:[NSData dataWithBytes:&value  length:sizeof(value)]  forKey:[IOBatteryStatus getKeyboardName]];
  }
  if([IOBatteryStatus trackpadAvailable]) {
    value = [IOBatteryStatus getTrackpadBatteryLevel];
    [dataset setValue: [NSData dataWithBytes:&value  length:sizeof(value)] forKey:[IOBatteryStatus getTrackpadName]];
  }
  if([IOBatteryStatus mouseAvailable]) {
    value = [IOBatteryStatus getMouseBatteryLevel];
    [dataset setValue:[NSData dataWithBytes:&value  length:sizeof(value)] forKey:[IOBatteryStatus getMouseName]];
  }
  return dataset;
}

+ (NSDictionary *_Nullable)getIOPMPowerSource {
  CFMutableDictionaryRef matching , properties = NULL;
  io_registry_entry_t entry = 0;
  matching = IOServiceMatching( "IOPMPowerSource" );
  entry = IOServiceGetMatchingService( kIOMasterPortDefault , matching );
  IORegistryEntryCreateCFProperties( entry , &properties , NULL , 0 );
  
  NSDictionary * dict = CFBridgingRelease(properties);
  IOObjectRelease( entry );
  return dict;
}

// Voltage measured in mV
+ (int)getBatteryVoltageFrom:(NSDictionary *)IOPMPowerSource {
  int ret = BAT0_NOT_FOUND;
  if (IOPMPowerSource && [IOPMPowerSource objectForKey:@kIOPMPSVoltageKey]) {
    if ([IOPMPowerSource objectForKey:@kIOPMPSBatteryInstalledKey] != nil &&
        [[IOPMPowerSource objectForKey:@kIOPMPSBatteryInstalledKey] boolValue] == YES) {
      ret = [[IOPMPowerSource objectForKey:@kIOPMPSVoltageKey] intValue];
    }
  }
  return ret;
}

// Capacity measured in mA
+ (int) getBatteryAmperageFrom:(NSDictionary *)IOPMPowerSource {
  int ret = BAT0_NOT_FOUND;
  if (IOPMPowerSource && [IOPMPowerSource objectForKey:@kIOPMPSAmperageKey]) {
    if ([IOPMPowerSource objectForKey:@kIOPMPSBatteryInstalledKey] != nil &&
        [[IOPMPowerSource objectForKey:@kIOPMPSBatteryInstalledKey] boolValue] == YES) {
      int mA = [[IOPMPowerSource objectForKey:@kIOPMPSAmperageKey] intValue];
      ret = (mA > 0) ? mA : (0 - mA);
    }
  }
  return ret;
}

@end


