// Copyright distributed.net 1997-1998 - All Rights Reserved
// For use in distributed.net projects only.
// Any other distribution or use of this source violates copyright.

// $Log: selcore-conflict.cpp,v $
// Revision 1.20.2.2  1998/11/08 11:51:53  remi
// Lots of $Log tags.
//

#include "cputypes.h"
#include "client.h"   // MAXCPUS, Packet, FileHeader, Client class, etc
#include "baseincs.h" // basic (even if port-specific) #includes
#include "version.h"
#include "problem.h"  // ___unit_func()
#include "cpucheck.h" // cpu selection, GetTimesliceBaseline()
#include "clirate.h"
#include "logstuff.h"  //Log()/LogScreen()/LogScreenPercent()/LogFlush()
#include "clirate.h" //for PPC CliGetKeyrateForProblemNoSave() in SelectCore
#include "selcore.h"  //keep prototypes in sync

// --------------------------------------------------------------------------

//************************************
//"--------- max width = 34 ---------" (35 including terminating '\0')
//************************************

#if (CLIENT_CPU == CPU_X86)
static const char *cputypetable[]=
  {
  "Pentium, Am486, Cx486/5x86/MediaGX",
  "80386 & 80486",
  "Pentium Pro & Pentium II",
  "Cyrix 6x86/6x86MX/M2",
  "AMD K5",
  "AMD K6"
  //core 6 is "reserved" (was Pentium MMX)
  };
#elif (CLIENT_CPU == CPU_ARM)
static const char *cputypetable[]=
  {
  "ARM 3, 610, 700, 7500, 7500FE",
  "ARM 810, StrongARM 110",
  "ARM 2, 250",
  "ARM 710"
  };
#elif ((CLIENT_CPU == CPU_POWERPC) && \
      ((CLIENT_OS == OS_LINUX) || (CLIENT_OS == OS_AIX || (CLIENT_OS == OS_MACOS))))
static const char *cputypetable[]=
  {
  "PowerPC 601",
  "PowerPC 603/604/750"
  };
#elif (CLIENT_CPU == CPU_68K)
static const char *cputypetable[]=
  {
  "Motorola 68000", "Motorola 68010", "Motorola 68020", "Motorola 68030",
  "Motorola 68040", "Motorola 68060"
  };
#else
  #define NO_CPUTYPE_TABLE
#endif

/* *******************************************************************
   PORTER NOTE: when adding support for a new processor family, add each
   major processor type individually - *even_if_one_core_covers_more_than_
   one_processor*. This is to avoid having obsolete cputype entries
   in inis when more cores become available.
   ******************************************************************** */

// ---------------------------------------------------------------------------

const char *GetCoreNameFromCoreType( unsigned int coretype )
{
  #if (defined(NO_CPUTYPE_TABLE))
    if (coretype) return ""; //dummy to suppress unused variable warnings
  #else
    if (coretype<(sizeof(cputypetable)/sizeof(cputypetable[0])))
      return cputypetable[coretype];
  #endif
  return "";
}

// ---------------------------------------------------------------------------

int Client::SelectCore(int quietly)
{
  static s32 last_cputype = -123;
  static s32 detectedtype = -2;

  if (cputype == last_cputype) //no change, so don't bother reselecting
    return 0;                  //(cputype can change when restarted)

  #ifdef NO_CPUTYPE_TABLE
    cputype = 0;
  #else
  if (cputype<0 || cputype>=(int)(sizeof(cputypetable)/sizeof(cputypetable[0])))
    cputype = -1;
  #endif
  
  if (cputype == -1)
    {
    if (detectedtype == -2) 
      detectedtype = GetProcessorType(quietly);//returns -1 if unable to detect
    cputype = detectedtype & 0xFF;
    }
    
#if (CLIENT_CPU == CPU_POWERPC)
  #if ((CLIENT_OS == OS_BEOS) || (CLIENT_OS == OS_AMIGAOS))
    // Be OS isn't supported on 601 machines
    // There is no 601 PPC board for the Amiga
    cputype = 1; //"PowerPC 603/604/750"
  #elif (CLIENT_OS == OS_WIN32)
    //actually not supported, but just in case
    cputype = 1;
  #else
    {
    if (cputype == -1)
      {
      double fasttime = 0;
      if (!quietly)
        LogScreen("Manually selecting fastest core...\n"
                "This is a guess based on a small test of each core.\n"
                "If you know what processor this machine has, then please\n"
                "please set it in the client's configuration.\n");

      for (whichcrunch = 0; whichcrunch < 2; whichcrunch++)
        {
        const s32 benchsize = 500000L;
        Problem problem;
        ContestWork contestwork;

        contestwork.key.lo = contestwork.key.hi = htonl( 0 );
        contestwork.iv.lo = contestwork.iv.hi = htonl( 0 );
        contestwork.plain.lo = contestwork.plain.hi = htonl( 0 );
        contestwork.cypher.lo = contestwork.cypher.hi = htonl( 0 );
        contestwork.keysdone.lo = contestwork.keysdone.hi = htonl( 0 );
        contestwork.iterations.lo = htonl( benchsize );
        contestwork.iterations.hi = htonl( 0 );
        problem.LoadState( &contestwork, 0, benchsize, whichcrunch ); // RC5 core selection

        //if (!quietly)
        //  LogScreen("Benchmarking the %s core... ", ((whichcrunch)?("second"):("first")));
        problem.Run( 0 ); //threadnum
        double elapsed = CliGetKeyrateForProblemNoSave( &problem );
        //if (!quietly)
        //  LogScreen( "%.1f kkeys/sec\n", (elapsed / 1000.0) );

        if (cputype < 0 || elapsed < fasttime)
          {cputype = whichcrunch; fasttime = elapsed;}
        }
      detectedtype = cputype;
      }
    }
  #endif
  whichcrunch = cputype;
  
  if (!quietly)
    LogScreen( "Selected %s code.\n", GetCoreNameFromCoreType(cputype) ); 
#elif (CLIENT_CPU == CPU_68K)

  if (cputype == -1)
    cputype = 0;
    
  const char *corename = NULL;
  if (cputype == 4 || cputype == 5 ) // there is no 68050, so type5=060
    {
    rc5_unit_func = rc5_unit_func_040_060;
    corename = "040/060";
    }
  else //if (cputype == 0 || cputype == 1 || cputype == 2 || cputype == 3)
    {
    rc5_unit_func = rc5_unit_func_000_030;
    corename = "000/010/020/030";
    }
  if (!quietly)
    LogScreen( "Selected code optimized for the Motorola 68%s.\n", corename ); 

#elif (CLIENT_CPU == CPU_X86)
  int selppro_des = 0;
  const char *selmsg_rc5 = NULL, *selmsg_des = NULL;
  
  if (cputype == 6) /* Pentium MMX */
    cputype = 0;    /* but we need backwards compatability */
  else if (cputype == -1)
    {
    if (detectedtype == -1)
      detectedtype = GetProcessorType(quietly);
    cputype = (detectedtype & 0xFF);
    }
  if ((detectedtype == -1) || (detectedtype == -2))
    /* we need detection for mmx cores */
    detectedtype = GetProcessorType(1); /* but do it quietly */

  #if ((defined(KWAN) || defined(MEGGS)) && !defined(MMX_BITSLICER))
    #define DESUNITFUNC51 des_unit_func_slice
    #define DESUNITFUNC52 des_unit_func_slice
    #define DESUNITFUNC61 des_unit_func_slice
    #define DESUNITFUNC62 des_unit_func_slice
    selmsg_des = "Kwan bitslice";
  #else
    #define DESUNITFUNC51 p1des_unit_func_p5
    #define DESUNITFUNC52 p1des_unit_func_p5
    #define DESUNITFUNC61 p1des_unit_func_pro
    #define DESUNITFUNC62 p1des_unit_func_pro
  #endif

  if (cputype == 1) // Intel 386/486
    {
    rc5_unit_func = rc5_unit_func_486;
    des_unit_func = DESUNITFUNC51;  //p1des_unit_func_p5;
    des_unit_func2 = DESUNITFUNC52; //p2des_unit_func_p5;
    }
  else if (cputype == 2) // Ppro/PII
    {
    rc5_unit_func = rc5_unit_func_p6;
    des_unit_func =  DESUNITFUNC61;  //p1des_unit_func_pro;
    des_unit_func2 = DESUNITFUNC62;  //p2des_unit_func_pro;
    selppro_des = 1;
    }
  else if (cputype == 3) // 6x86(mx)
    {
    rc5_unit_func = rc5_unit_func_6x86;
    des_unit_func =  DESUNITFUNC61;  //p1des_unit_func_pro;
    des_unit_func2 = DESUNITFUNC62;  //p2des_unit_func_pro;
    selppro_des = 1;
    }
  else if (cputype == 4) // K5
    {
    rc5_unit_func = rc5_unit_func_k5;
    des_unit_func =  DESUNITFUNC51;  //p1des_unit_func_p5;
    des_unit_func2 = DESUNITFUNC52;  //p2des_unit_func_p5;
    }
  else if (cputype == 5) // K6/K6-2
    {
    rc5_unit_func = rc5_unit_func_k6;
    des_unit_func =  DESUNITFUNC61;  //p1des_unit_func_pro;
    des_unit_func2 = DESUNITFUNC62;  //p2des_unit_func_pro;
    selppro_des = 1;
    }
  else // Pentium (0/6) + others
    {
    rc5_unit_func = rc5_unit_func_p5;
    des_unit_func =  DESUNITFUNC51;  //p1des_unit_func_p5;
    des_unit_func2 = DESUNITFUNC52;  //p2des_unit_func_p5;
    cputype = 0;
    
    #if defined(MMX_RC5)
    if (detectedtype == 0x106) /* Pentium MMX only! */
      {
      rc5_unit_func = rc5_unit_func_p5_mmx;
      selmsg_rc5 = "Pentium MMX";
      }
    #endif
    }

  #if defined(MMX_BITSLICER)
  if (detectedtype & 0x100)   // use the MMX DES core ?
    { 
    des_unit_func = des_unit_func2 = des_unit_func_mmx;
    selmsg_des = "MMX bitslice";
    }
  #endif

  if (!selmsg_des)
    selmsg_des = ((selppro_des)?("PentiumPro optimized BrydDES"):("BrydDES"));
  if (!selmsg_rc5)
    selmsg_rc5 = GetCoreNameFromCoreType(cputype);
    
  if (!quietly)
    LogScreen( "DES: selecting %s core.\n"
               "RC5: selecting %s core.\n", selmsg_des, selmsg_rc5 );
      
  #undef DESUNITFUNC61
  #undef DESUNITFUNC62
  #undef DESUNITFUNC51
  #undef DESUNITFUNC52

#elif (CLIENT_CPU == CPU_ARM)
  if (cputype == -1)
    {
    const s32 benchsize = 50000*2; // pipeline count is 2
    double fasttime[2] = { 0, 0 };
    s32 fastcoretest[2] = { -1, -1 };
  
    if (!quietly)
      LogScreen("Manually selecting fastest core...\n"
                "This is a guess based on a small test of each core.\n"
                "If you know what processor this machine has, then please\n"
                "please set it in the client's configuration.\n");

    for (int contestid = 0; contestid < 2; contestid++)
      {
      for (int whichcrunch = 0; whichcrunch < 3; whichcrunch++)
        {
        Problem problem;
        ContestWork contestwork;
        contestwork.key.lo = contestwork.key.hi = htonl( 0 );
        contestwork.iv.lo = contestwork.iv.hi = htonl( 0 );
        contestwork.plain.lo = contestwork.plain.hi = htonl( 0 );
        contestwork.cypher.lo = contestwork.cypher.hi = htonl( 0 );
        contestwork.keysdone.lo = contestwork.keysdone.hi = htonl( 0 );
        contestwork.iterations.lo = htonl( benchsize );
        contestwork.iterations.hi = htonl( 0 );
        problem.LoadState( &contestwork , contestid, benchsize, whichcrunch ); 

        if (contestid == 0)
          {
          // there are now 3 RC5 cores from which to choose
          // probably be a 4th one soon
          switch(whichcrunch)
            {
            case 1: rc5_unit_func = rc5_unit_func_arm_2;
                    break;
            case 2: rc5_unit_func = rc5_unit_func_arm_3;
                    break;
            default:rc5_unit_func = rc5_unit_func_arm_1;
                    break;
            }
          }
        else
          {
          // select the correct DES core engine
          switch(whichcrunch)
            {
            case 1:des_unit_func = des_unit_func_strongarm;
                   break;
            default:des_unit_func = des_unit_func_arm;
                   break;
            }
          }
        problem.Run( 0 ); //threadnum
    
        double elapsed = CliGetKeyrateForProblemNoSave( &problem );
        //printf("%s Core %d: %f\n",contestid ? "DES" : "RC5",whichcrunch,elapsed);
    
        if (fastcoretest[contestid] < 0 || elapsed < fasttime[contestid])
          {
          fastcoretest[contestid] = whichcrunch; fasttime[contestid] = elapsed;
          }
        }
      }
    cputype = (8-(fastcoretest[0] + ((fastcoretest[1]&1)<<2)))&7;
    if (cputype == 1)
      cputype = 3;
    else if (cputype > 3)
      cputype = 1;
    detectedtype = cputype;
    }
  if (!quietly)
    LogScreen("Selecting %s code.\n",GetCoreNameFromCoreType(cputype));
    
  // select the correct core engine
  switch(cputype)
    {
    case 0: rc5_unit_func = rc5_unit_func_arm_1;
            des_unit_func = des_unit_func_arm;
            break;
    default:
    case 1: rc5_unit_func = rc5_unit_func_arm_3;
            des_unit_func = des_unit_func_strongarm;
            break;
    case 2: rc5_unit_func = rc5_unit_func_arm_2;
            des_unit_func = des_unit_func_strongarm;
    break;
    case 3: rc5_unit_func = rc5_unit_func_arm_3;
            des_unit_func = des_unit_func_arm;
            break;
    }
#else
  cputype = 0;
#endif

  last_cputype = cputype;
  return 0;
}

// ---------------------------------------------------------------------------
