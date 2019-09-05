//
//  SMC_Keys.swift
//  HWMonitorSMC2
//
//  Created by Vector Sigma on 09/11/2018.
//  Copyright © 2018 vector sigma. All rights reserved.
//

import Foundation

/* Simple rule to follow
 
 SMC_Aaa_Bbb, where:
 
 SMC stand for SMC key
 Aaa stand for the hardware involved (e.g. DIMM for memory DIMM on the Main Logic Board)
 BBB(...) stand for the type (linke TEMP for temperature, FREQ for frequency, VOLT for voltage and so on)
 
 An additional suffix like _F (i.e. SMC_Aaa_Bbb_F) to let understand this is a fake key
 that doesn't exist in the Apple World... maybe added by a third party driver.
 */

// CPU
let SMC_DIMM_TEMP               = "Tm%@P"
let SMC_CPU_PROXIMITY_TEMP      = "TC0P"
let SMC_CPU_PACKAGE_CORE_WATT   = "PCPC"
let SMC_CPU_PACKAGE_TOTAL_WATT  = "PCPT"
let SMC_CPU_HEATSINK_TEMP       = "Th0H"
let SMC_CPU_VOLT                = "VC0C"
let SMC_CPU_VRM_VOLT            = "VS0C"
let SMC_CPU_PACKAGE_MULTI_F     = "MPkC"
let SMC_CPU_CORE_MULTI_F        = "MC%@C"
let SMC_CPU_CORE_TEMP           = "TC%@C"
let SMC_CPU_CORE_TEMP_NEW       = "TC%@c"
let SMC_CPU_CORE_DIODE_TEMP     = "TC%@D"
let SMC_CPU_CORE_FREQ_F         = "FRC%@"

// GPU
let SMC_GPU_FREQ_F              = "CG%@C"
let SMC_GPU_SHADER_FREQ_F       = "CG%@S"
let SMC_GPU_MEMORY_FREQ_F       = "CG%@M"
let SMC_GPU_VOLT                = "VC%@G"
let SMC_GPU_BOARD_TEMP          = "TG%@H"
let SMC_GPU_PROXIMITY_TEMP      = "TG%@P"

// IGPU
let SMC_IGPU_PACKAGE_WATT       = "PCPG"

// MLB
let SMC_NORTHBRIDGE_TEMP        = "TN0P"
let SMC_PRAM_BATTERY_VOLT       = "VBAT"
let SMC_BUS_12V_VOLT            = "VP0R"
let SMC_BUS_5V_VOLT             = "Vp1C"
let SMC_BUS_12VDIFF_VOLT        = "Vp0C"
let SMC_BUS_5VDIFF_VOLT         = "Vp2C"
let SMC_BUS_3_3VCC_VOLT         = "Vp3C"
let SMC_BUS_3_3VSB_VOLT         = "Vp4C"
let SMC_BUS_3_3AVCC_VOLT        = "Vp5C"
let SMC_AMBIENT_TEMP            = "TA0P"

// Fans
let SMC_FAN_NUM_INT             = "FNum"
let SMC_FAN_MANUAL              = "FS! "
let SMC_FAN_MANUAL_NEW          = "F%@Md"
let SMC_FAN_ID_STR              = "F%@ID"
let SMC_FAN_CURR_RPM            = "F%@Ac"
let SMC_FAN_MIN_RPM             = "F%@Mn"
let SMC_FAN_MAX_RPM             = "F%@Mx"
let SMC_FAN_CTRL                = "F%@Tg"

// Laptop's battery
let SMC_BATT0_VOLT              = "B0AV"
let SMC_BATT0_AMP               = "B0AC"
