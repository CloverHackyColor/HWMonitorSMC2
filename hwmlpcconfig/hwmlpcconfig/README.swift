//
//  READMI.swift
//  hwmlcpconfig
//
//  Created by vector sigma on 26/01/2020.
//  Copyright © 2020 vectorsigma. All rights reserved.
//

import Foundation

let kReadme = """
The generate configuration is merely an example and needs to be adjusted.

ABOUT FANS

The LPC chip may manage more fans than connectors your motherboards actually has. That’s why it’s important that you mark all unused connectors as skipped within your configuration file.
For example, if the AUXFAN3 connector is not physically present (and the reported value is 0 rpm), then the AUXFAN3 dictionary should contain the following boolean key/value:

  <key>skip</key>
  <true/>

… and the AUXFAN3 will not show up in HWMonitorSMC.app!
Note: if your motherboard has some unused fan connectors, it’s better to create a configuration that doesn't skip them, so other users will see their fans up and running.

ABOUT VOLTAGES

As for the fans not all the voltages reported may be connected to a real sensor:
`skip = true` is your friend.

The LPC chip returns standard values that must be adjusted. Why?
Because the resistors values and kinds for each motherboards vendor/model may differ.
To adjust the value, you have to use the `multi` key set to a number to multiply the value returned by default:

For example, VBAT returns 1.670 Volts which is just the half of what it should be. So multi must be set to 2:

  <key>multi</key>
  <integer>2</integer>

(2 * 1.670) = 3,340 Volts!

`multi` is 1 by default and you should not set this key if 1 is the right value… to keep the file small.
Note: `multi` can be a floating point number (64 bit double). Negative numbers are allowed as well.
Zero is treated as 1.


RENAMING SENSORS

To rename a key, e.g. VIN0 to Vcore (or FAN1 to CPU_FAN), you have to modify the `name` value:

name = Vcore
or
name = FAN1
… an so on.

If the sensor name is already a name that suits you well, then the name key should be removed to keep
the file as small as possible.


HELP
Programs like Aida64 (https://www.aida64.com/downloads) and HWInfo64 (https://www.hwinfo.com/download/)
in Windows can be a big help in comparing values.

IMPORTANT
The generated plist is to let you understand how to edit the file, but before opening a pull request on github please ensure that you:

- do not include sensors with "multi = 1" because multi is 1 per default.
- do not include sensors with "skip = false" because `skip` is taken into account only if "skip = true".
- do not include sensors with "name = SensorName".. if "SensorName" is already SensorName, as in this example:

  <key>SensorName</key>
  <dict>
    <key>name</key>
    <string>SensorName</string>
  </dict>

- do not include sensors if empty. If, for example, VBAT is ok as is, i.e with out multi or name:
  <key>SensorName</key>
  <dict>
  </dict>
  
  … just remove the Dictionary entirely and the sensor will show up normally.

Doing that will assure a clean and light database, thanks!

SHARE!
Once your configuration is complete and fixed, please open a pull request it at:

https://github.com/CloverHackyColor/HWMonitorSMC2

so that you and all the users with same motherboard as you, can enjoy working and accurate sensors values across updates!
"""
