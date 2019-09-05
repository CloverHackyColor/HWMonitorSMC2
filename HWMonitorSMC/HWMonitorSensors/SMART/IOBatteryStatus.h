//
//  IOBatteryStatus.h
//  HWSensors
//
//  Created by Navi on 04.01.13.
//
//

#import <Foundation/Foundation.h>

@interface IOBatteryStatus : NSObject

+ (BOOL)keyboardAvailable;
+ (BOOL)trackpadAvailable;
+ (BOOL)mouseAvailable;

+ (NSString *)getKeyboardName;
+ (NSString *)getTrackpadName;
+ (NSString *)getMouseName;

+ (NSInteger )getKeyboardBatteryLevel;
+ (NSInteger )getTrackpadBatteryLevel;
+ (NSInteger )getMouseBatteryLevel;

+ (NSDictionary *)getIOPMPowerSource;
+ (int)getBatteryVoltageFrom:(NSDictionary *)IOPMPowerSource;
+ (int)getBatteryAmperageFrom:(NSDictionary *)IOPMPowerSource;

+ (NSDictionary *)getAllBatteriesLevel;

@end
