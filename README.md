![HWMonitorSMC2.app](https://github.com/CloverHackyColor/HWMonitorSMC2/blob/master/HWMonitorSMC/Interface/Assets.xcassets/AppIcon.appiconset/256-1.png?raw=true)

# HWMonitorSMC2

Application for monitoring hardware health in macOS <br />
Copyright (c) 2020 vector sigma, Slice and HWSensors-3 project.
---

# [Downloads](https://github.com/CloverHackyColor/HWMonitorSMC2/releases)
---

## Special thanks

> Translators:

Andrey1970 for Russian <br />
Sherloks for Korean <br />
jinbingmao for Simplified Chinese <br />
nomadturk for Turkish <br />
Amble for Finnish <br />
vector sigma for Italian

> Testers:

> all the guys at insanelymac forum and in particular:
> Slice, Andrey1970, jinbingmao, Rodion2010, Sherloks, DocXavier, Nuacho, ctich, Andres ZeroCross, rramon, biciolino, Mike Ranger, holyfield, losinka, Extreme™, Aplha22, Amble, pico joe, Jorge Max, Camillionario, Pavo, iCanaro, thenightflyer and Gen4ig and many others.

> Application icon by iParzival

---
## LPC Sensors configuration
> On non Apple hardware the LPC chip require additional kernel extensions to read values of the motherboard sensors: <br />
FakeSMC plugins require, when a configuration is not present, the editing of the Info.plist where you must specify the OEM vendor, the board and the configuration for each sensors such voltages, Fans and temperature. If the configuration it's already present you have to do nothing. <br />

> VirtualSMC,We recently added Support for SMCSuperIO.kext which, unlike FakeSMC plugins, doesn't publish SMC keys for motherboards sensors.  <br />
With the help of many users we already collected some configurations for some Asus and Gigabyte motherboards, but if this is not the case for you, consider running the hwmlpcconfig command line.
hwmlpcconfig (you can find it in the Download page) create ~/Desktop/LPC which (for supported chips) should create a raw configuration ready to be edited with the correct values.
A README.txt is created with the instruction to make your motherboard unique config. The customized configuration, then, must be place inside the app (SharedSupport/LPC directory) to make the app to apply the corrections needed. Of course, you will have to make a PR if you want this to be persistent across updates of HWMonitorSMC2.app.  <br />  <br />
On Apple hardware you have to do nothing!
---

## FAQ

- **HWMonitorSMC2 show nothing or few informations about the CPU**
- If you will to expand functionalities of the app, [Install IntelPowerGadget.framework](https://software.intel.com/en-us/comment/1844371) and ensure it is enabled in the preferences. 

- **What is the PMU option for?**
- It stands for "Performance Monitoring Unit" and allow higher accuracy data with lower overhead using the Intel Power Gadget library. Be aware that this option needs excusive access to the Power Gadget library.

- **The app no longer show the main window after installing Intel Power Gadget**
- Intel Power Gadget install a framework and a kernel extension. If one of the two crashes, HWMonitorSMC2 crash as well. To ignore it temporarily create a file to your Desktop:
```shell
$ touch ~/Desktop/IgnoreIPG
```
- and restart HWMonitorSMC2.app. That happened in my Ivy Bridge MacBook Pro, and the faster solution is to re-run the Intel Power Gadget Installer followed by a reboot.

- **HWMonitorSMC2 show nothing or few informations about the GPUs**
- go the preferences and enable "Use the IOKit monitoring for GPUs" and the app will start using the PerformancesStatistics, under the IOAccelerator class in the IO, to retrieve informations about graphics cards.
---



## License

```java
Copyright (c) 2018 vector sigma, Slice and HWSensors-3 project.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of the HWMonitorSMC2 Project nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THIRD PARTIES:

CorePlot.framework:

Copyright (c) 2012, Drew McCormack, Brad Larson, Eric Skroch, Barry Wark, Dirkjan Krijnders, Rick Maddy, Vijay Kalusani, Caleb Cannon, Jeff Buck, Thomas Elstner, Jeroen Leenarts, Craig Hockenberry, Hartwig Wiesmann, Koen van der Drift, Nino Ag, Mike Lischke, and Trevor Harmon.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of the Core Plot Project nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Intel® Power Gadget: 
HWMonitorSMC2.app doesn’t include any binaries from Intel but can use the IntelPowerGadget.framework abilities if already installed into the System. Intel® Power Gadget is property of Intel and any reference is this application is just to inform that you can display additional informations about your CPU through the IntelPowerGadget.framework.


SystemKit, SMCKit, SSMemoryInfo:

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

StatusBarDetachablePopover Copyright © 2017 Micky1979
```
