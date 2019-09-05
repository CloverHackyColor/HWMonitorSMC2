//
//  main.c
//  smcwrite
//
//  Created by vector sigma on 11/05/2019.
//  Copyright © 2019 vectorsigma. All rights reserved.
//

#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <IOKit/IOKitLib.h>
#include "smc.h"

int main(int argc, const char * argv[]) {
  if (argc != 3 || strlen(argv[1]) > 4) {
    printf("Usage example: ../%s F1Tg 03e8\n", "smcwrite");
    exit(1);
  }
  
  SMCVal_t val;
  memcpy(val.key, argv[1], sizeof(UInt32Char_t));
  char * value = (char *)argv[2]; // "%02x", "%02x%02x, "%02x%02x%02x%02x" etc.

  int i;
  char c[3];
  for (i = 0; i < strlen(value); i++)
  {
    sprintf(c, "%c%c", value[i * 2], value[(i * 2) + 1]);
    val.bytes[i] = (int) strtol(c, NULL, 16);
  }
  
  val.dataSize = i / 2;

  if (!val.dataSize || val.dataSize % 2 != 0 || val.dataSize > 32 || (val.dataSize * 2) != strlen(value)) {
    printf("Error: size of \"%s\" is not valid\n", value);
    exit(1);
  }

  SMCOpen(&conn);
  
  if (SMCWriteKey(val) != kIOReturnSuccess) {
    printf("Error: unable to write \"%s\" key\n", val.key);
    SMCClose(conn);
    exit(1);
  }
  SMCClose(conn);

  return 0;
}
