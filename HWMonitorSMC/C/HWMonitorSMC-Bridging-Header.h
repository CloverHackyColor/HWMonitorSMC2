//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#import "SSMemoryInfo.h"
#import "NVMe.h"
#include <sys/sysctl.h>

#import "IOBatteryStatus.h"
#import "SSMemoryInfo.h"

#import <mach/host_info.h>
#import <mach/mach_host.h>
#import <mach/task_info.h>
#import <mach/task.h>

#include <IntelPowerGadget/EnergyLib.h> // optional link
