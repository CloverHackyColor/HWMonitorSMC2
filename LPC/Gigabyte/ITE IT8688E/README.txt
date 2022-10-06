The generate configuration is a mere example and must be adjusted.

ABOUT FANS

The LPC chip may manage more fans than connectors your motherboards may have, so for this reason, is important that your configuration will skip all unused connectors.
For example, if the AUXFAN3 connector is not physically present (and the value reported is 0 rpm), then under the AUXFAN3 dictionary you must add the following Boolean key/value:

skip = YES

... and the AUXFAN3 will not show up in HWMonitorSMC.app!
Note: if your motherboard have some unused fan connectors, it is right instead, to create a configuration that doesn't skip them, so other users will see their fans up and running.

ABOUT VOLTAGES

As for the fans not all the voltages reported may be connected to a real sensor:
skip = YES is your friend.

The lpc chip return standard values that must be adjusted, why?
Because resistors number and kinds for each motherboards vendors/model may differ.
To udjust the value you have to use the multi key (as number) to multiply the value returned by default:

example, VBAT returns 1.670 Volts which is just the half of what should be. So multi must be set to 2:

multi = 2

(2 * 1.670) = 3,340 Volts!

multi is 1 by default and you should not set this key if 1 is the right value... to keep the file small.
Note: multi can be a floating point number (64 bit Double). Negative numbers allowed as well.
Zero is treated as 1.


RENAMING SENSORS

To rename a key, e.g. VIN0 to Vcore (or FAN1 to CPU Fan) you have to modify the name value:

name = Vcore
or
name = FAN1
... an so on.

If the sensor name is already a name that suite you well, then the name key must be removed to keep
the file smaller as possible.


HELP
Programs like Aida64 (https://www.aida64.com/downloads) and HWInfo64 (https://www.hwinfo.com/download/)
in Windows can be a big help in comparing values.

IMPORTANT
The generated plist is to let you understand how to edit the file, but before making a request please ensure to:

- do not include sensors with "multi = 1" because multi is 1 per default.
- do not include sensors with "skip = NO" because skip is taken into account only if "skip = YES".
- do not include sensors with "name = SensorName".. if "SensorName" is already SensorName, like the following:

  <key>SensorName</key>
  <dict>
    <key>name</key>
    <string>SensorName</string>
  </dict>

- do not include sensors if empty. If, for example, VBAT is ok as is, i.e with out multi or name:
  <key>SensorName</key>
  <dict>
  </dict>
  
  ... just remove the Dictionary entirely and the sensor will show up normally.

Doing that will assure a clean and light database, thanks!

SHARE!
Once your configuration is complete and fixed, please share it at:

https://github.com/CloverHackyColor/HWMonitorSMC2

so that you and all the users with same motherboard as you, will have a working and truthful sesors across updates!
