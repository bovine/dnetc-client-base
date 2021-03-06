/*
* Copyright distributed.net 2009 - All Rights Reserved
* For use in distributed.net projects only.
* Any other distribution or use of this source violates copyright.
*
* $Id: 
*/

#ifndef OCL_COMMON_H
#define OCL_COMMON_H

#include <CL/cl.h>
#include "ccoreio.h"
#include "logstuff.h"  // LogScreen()
#include "triggers.h"
#include "ocl_context.h"

#define P 0xB7E15163
#define Q 0x9E3779B9

#define SHL(x, s) ((u32) ((x) << ((s) & 31)))
#define SHR(x, s) ((u32) ((x) >> (32 - ((s) & 31))))
#define ROTL(x, s) ((u32) (SHL((x), (s)) | SHR((x), (s))))
#define ROTL3(x) ROTL(x, 3)
 
void key_incr(u32 *hi, u32 *mid, u32 *lo, u32 incr);
u32 sub72(u32 m1, u32 h1, u32 m2, u32 h2);
inline u32 swap32(u32 a);
void OCLReinitializeDevice(int device);
int getNumDevices();

s32 rc5_72_unit_func_ansi_ref (RC5_72UnitWork *rc5_72unitwork);
cl_int ocl_diagnose(cl_int result, const char *where, u32 DeviceIndex);
char* clStrError(cl_int status);
bool BuildCLProgram(unsigned deviceID, const char* programText, const char *kernelName);

#endif //OCL_COMMON_H