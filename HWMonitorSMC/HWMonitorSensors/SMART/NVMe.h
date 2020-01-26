//
//  NVMe.h
//  SmarterSwift
//
//  Created by vector sigma on 31/03/18.
//  Copyright © 2018 vector sigma. All rights reserved.
//
//
//  Thanks @fabiosun for tens of tests made with his hardware (Sata/NVMe SSD and rotational HDDs)
//
//  This is taken from smartmontools at https://www.smartmontools.org/browser
//


#ifndef NVMe_h
#define NVMe_h

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOReturn.h>
#include <IOKit/IOBSD.h>
#include <IOKit/storage/IOBlockStorageDevice.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/ata/IOATAStorageDefines.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#import <DiskArbitration/DiskArbitration.h>

/*
 int NVMeSMARTClient::QueryInterface(CFUUIDBytes, void**)(void arg0, void * * arg1) {
 r12 = rcx;
 r15 = arg0;
 rbx = 0x0;
 r14 = CFUUIDCreateFromUUIDBytes(0x0, arg1);
 rax = CFUUIDGetConstantUUIDWithBytes(*_kCFAllocatorSystemDefault, 0x0, 0x0, 0x0, 0x0, 0x0, rbx, rbx, rbx, 0xc0, rbx, rbx, rbx, rbx, rbx, rbx, 0x46);
 rsp = (rsp - 0x8) + 0x60;
 if (CFEqual(r14, rax) != 0x0) goto loc_1676;
 
 loc_1615:
 rax = CFUUIDGetConstantUUIDWithBytes(0x0, 0xc2, 0x44, 0xe8, 0x58, 0x10, 0x9c, 0x11, 0xd4, 0x91, 0xd4, 0x0, 0x50, 0xe4, 0xc6, 0x42, 0x6f);
 rsp = (rsp - 0x8) + 0x60;
 if (CFEqual(r14, rax) == 0x0) goto loc_169a;
 
 loc_1676:
 rax = r15 + 0x10;
 goto loc_167a;
 
 loc_167a:
 *r12 = rax;
 rax = *r15;
 (*(rax + 0x30))(r15);
 goto loc_1687;
 
 loc_1687:
 CFRelease(r14);
 rax = rbx;
 return rax;
 
 loc_169a:
 rbx = 0x0;
 rax = CFUUIDGetConstantUUIDWithBytes(0x0, 0xcc, 0xd1, 0xdb, 0x19, 0xfd, 0x9a, 0x4d, 0xaf, 0xbf, 0x95, 0x12, 0x45, 0x4b, 0x23, 0xa, 0xb6);
 if (CFEqual(r14, rax) == 0x0) goto loc_1706;
 
 loc_16fd:
 rax = r15 + 0x20;
 goto loc_167a;
 
 loc_1706:
 *r12 = 0x0;
 rbx = 0x80000004;
 goto loc_1687;
 }*/


/*
 kIONVMeSMARTUserClientTypeID = AA0FA6F9-C2D6-457F-B10B-59A13253292F
 kIONVMeSMARTInterfaceID      = CCD1DB19-FD9A-4DAF-BF95-12454B230AB6
 */

#define kSMARTAttributesDictKey "SMARTAttributes"
#define kSMARTDataDictKey "SMARTData"

// NVMe definitions, non documented, experimental
#define kIOPropertyNVMeSMARTCapableKey  "NVMe SMART Capable"
#define kATASMARTUserClientClassKey     "ATASMARTUserClient"

struct nvme_error_log_page {
  uint64_t        error_count;
  unsigned short  sqid;
  unsigned short  cmdid;
  unsigned short  status_field;
  unsigned short  parm_error_location;
  uint64_t        lba;
  unsigned int    nsid;
  unsigned char   vs;
  unsigned char   resv[35];
};

struct nvme_id_power_state {
  unsigned short  max_power; // centiwatts
  unsigned char   rsvd2;
  unsigned char   flags;
  unsigned int    entry_lat; // microseconds
  unsigned int    exit_lat;  // microseconds
  unsigned char   read_tput;
  unsigned char   read_lat;
  unsigned char   write_tput;
  unsigned char   write_lat;
  unsigned short  idle_power;
  unsigned char   idle_scale;
  unsigned char   rsvd19;
  unsigned short  active_power;
  unsigned char   active_work_scale;
  unsigned char   rsvd23[9];
};

struct nvme_id_ctrl {
  unsigned short  vid;
  unsigned short  ssvid;
  char            sn[20];
  char            mn[40];
  char            fr[8];
  unsigned char   rab;
  unsigned char   ieee[3];
  unsigned char   cmic;
  unsigned char   mdts;
  unsigned short  cntlid;
  unsigned int    ver;
  unsigned int    rtd3r;
  unsigned int    rtd3e;
  unsigned int    oaes;
  unsigned int    ctratt;
  unsigned char   rsvd100[156];
  unsigned short  oacs;
  unsigned char   acl;
  unsigned char   aerl;
  unsigned char   frmw;
  unsigned char   lpa;
  unsigned char   elpe;
  unsigned char   npss;
  unsigned char   avscc;
  unsigned char   apsta;
  unsigned short  wctemp;
  unsigned short  cctemp;
  unsigned short  mtfa;
  unsigned int    hmpre;
  unsigned int    hmmin;
  unsigned char   tnvmcap[16];
  unsigned char   unvmcap[16];
  unsigned int    rpmbs;
  unsigned short  edstt;
  unsigned char   dsto;
  unsigned char   fwug;
  unsigned short  kas;
  unsigned short  hctma;
  unsigned short  mntmt;
  unsigned short  mxtmt;
  unsigned int    sanicap;
  unsigned char   rsvd332[180];
  unsigned char   sqes;
  unsigned char   cqes;
  unsigned short  maxcmd;
  unsigned int    nn;
  unsigned short  oncs;
  unsigned short  fuses;
  unsigned char   fna;
  unsigned char   vwc;
  unsigned short  awun;
  unsigned short  awupf;
  unsigned char   nvscc;
  unsigned char   rsvd531;
  unsigned short  acwu;
  unsigned char   rsvd534[2];
  unsigned int    sgls;
  unsigned char   rsvd540[228];
  char            subnqn[256];
  unsigned char   rsvd1024[768];
  unsigned int    ioccsz;
  unsigned int    iorcsz;
  unsigned short  icdoff;
  unsigned char   ctrattr;
  unsigned char   msdbd;
  unsigned char   rsvd1804[244];
  struct nvme_id_power_state  psd[32];
  unsigned char   vs[1024];
};

struct nvme_lbaf {
  unsigned short  ms;
  unsigned char   ds;
  unsigned char   rp;
};

struct nvme_id_ns {
  uint64_t        nsze;
  uint64_t        ncap;
  uint64_t        nuse;
  unsigned char   nsfeat;
  unsigned char   nlbaf;
  unsigned char   flbas;
  unsigned char   mc;
  unsigned char   dpc;
  unsigned char   dps;
  unsigned char   nmic;
  unsigned char   rescap;
  unsigned char   fpi;
  unsigned char   rsvd33;
  unsigned short  nawun;
  unsigned short  nawupf;
  unsigned short  nacwu;
  unsigned short  nabsn;
  unsigned short  nabo;
  unsigned short  nabspf;
  unsigned char   rsvd46[2];
  unsigned char   nvmcap[16];
  unsigned char   rsvd64[40];
  unsigned char   nguid[16];
  unsigned char   eui64[8];
  struct nvme_lbaf  lbaf[16];
  unsigned char   rsvd192[192];
  unsigned char   vs[3712];
};

struct nvme_smart_log {
  UInt8  critical_warning;
  UInt8  temperature[2];
  UInt8  avail_spare;
  UInt8  spare_thresh;
  UInt8  percent_used;
  UInt8  rsvd6[26];
  UInt8  data_units_read[16];
  UInt8  data_units_written[16];
  UInt8  host_reads[16];
  UInt8  host_writes[16];
  UInt8  ctrl_busy_time[16];
  UInt32 power_cycles[4];
  UInt32 power_on_hours[4];
  UInt32 unsafe_shutdowns[4];
  UInt32 media_errors[4];
  UInt32 num_err_log_entries[4];
  UInt32 warning_temp_time;
  UInt32 critical_comp_time;
  UInt16 temp_sensor[8];
  UInt32 thm_temp1_trans_count;
  UInt32 thm_temp2_trans_count;
  UInt32 thm_temp1_total_time;
  UInt32 thm_temp2_total_time;
  UInt8  rsvd232[280];
};


typedef struct IONVMeSMARTInterface {
  IUNKNOWN_C_GUTS;
  
  UInt16 version;
  UInt16 revision;
  
  // NVMe smart data, returns nvme_smart_log structure
  IOReturn ( *SMARTReadData )( void *  interface, struct nvme_smart_log * NVMeSMARTData );
  
  // NVMe IdentifyData, returns nvme_id_ctrl per namespace
  IOReturn ( *GetIdentifyData )( void *  interface, struct nvme_id_ctrl * NVMeIdentifyControllerStruct, unsigned int ns );
  
  // Always getting kIOReturnDeviceError
  IOReturn ( *GetFieldCounters )( void *   interface, char * FieldCounters );
  // Returns 0
  IOReturn ( *ScheduleBGRefresh )( void *   interface);
  
  // Always returns kIOReturnDeviceError, probably expects pointer to some
  // structure as an argument
  IOReturn ( *GetLogPage )( void *  interface, void * data, unsigned int, unsigned int);
  
  
  /* GetSystemCounters Looks like a table with an attributes. Sample result:
   
   0x101022200: 0x01 0x00 0x08 0x00 0x00 0x00 0x00 0x00
   0x101022208: 0x00 0x00 0x00 0x00 0x02 0x00 0x08 0x00
   0x101022210: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x101022218: 0x03 0x00 0x08 0x00 0xf1 0x74 0x26 0x01
   0x101022220: 0x00 0x00 0x00 0x00 0x04 0x00 0x08 0x00
   0x101022228: 0x0a 0x91 0xb1 0x00 0x00 0x00 0x00 0x00
   0x101022230: 0x05 0x00 0x08 0x00 0x24 0x9f 0xfe 0x02
   0x101022238: 0x00 0x00 0x00 0x00 0x06 0x00 0x08 0x00
   0x101022240: 0x9b 0x42 0x38 0x02 0x00 0x00 0x00 0x00
   0x101022248: 0x07 0x00 0x08 0x00 0xdd 0x08 0x00 0x00
   0x101022250: 0x00 0x00 0x00 0x00 0x08 0x00 0x08 0x00
   0x101022258: 0x07 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x101022260: 0x09 0x00 0x08 0x00 0x00 0x00 0x00 0x00
   0x101022268: 0x00 0x00 0x00 0x00 0x0a 0x00 0x04 0x00
   .........
   0x101022488: 0x74 0x00 0x08 0x00 0x00 0x00 0x00 0x00
   0x101022490: 0x00 0x00 0x00 0x00 0x75 0x00 0x40 0x02
   0x101022498: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   */
  IOReturn ( *GetSystemCounters )( void *  interface, char *, unsigned int *);
  
  
  /* GetAlgorithmCounters returns mostly 0
   0x102004000: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004008: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004010: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004018: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004020: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004028: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004038: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004040: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004048: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004050: 0x00 0x00 0x00 0x00 0x80 0x00 0x00 0x00
   0x102004058: 0x80 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004060: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004068: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004070: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004078: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004080: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004088: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004090: 0x00 0x01 0x00 0x00 0x00 0x00 0x00 0x00
   0x102004098: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
   
   */
  IOReturn ( *GetAlgorithmCounters )( void *  interface, char *, unsigned int *);
} IONVMeSMARTInterface;


enum nvme_admin_opcode {
  //nvme_admin_delete_sq     = 0x00,
  //nvme_admin_create_sq     = 0x01,
  nvme_admin_get_log_page  = 0x02,
  //nvme_admin_delete_cq     = 0x04,
  //nvme_admin_create_cq     = 0x05,
  nvme_admin_identify      = 0x06,
  //nvme_admin_abort_cmd     = 0x08,
  //nvme_admin_set_features  = 0x09,
  //nvme_admin_get_features  = 0x0a,
  //nvme_admin_async_event   = 0x0c,
  //nvme_admin_ns_mgmt       = 0x0d,
  //nvme_admin_activate_fw   = 0x10,
  //nvme_admin_download_fw   = 0x11,
  //nvme_admin_ns_attach     = 0x15,
  //nvme_admin_format_nvm    = 0x80,
  //nvme_admin_security_send = 0x81,
  //nvme_admin_security_recv = 0x82,
};

#endif /* NVMe_h */
