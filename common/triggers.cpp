// Copyright distributed.net 1997-1998 - All Rights Reserved
// For use in distributed.net projects only.
// Any other distribution or use of this source violates copyright.

// $Log: triggers.cpp,v $
// Revision 1.8.2.2  1998/11/08 11:52:07  remi
// Lots of $Log tags.
//
// Synchronized with official 1.8

// --------------------------------------------------------------------------

#include "cputypes.h"
#include "baseincs.h"  // basic (even if port-specific) #includes
#include "clitime.h"   // CliGetTimeString(NULL,1)
#include "logstuff.h"  // LogScreen()
#include "triggers.h"  // for xxx_CHECKTIME defines

// --------------------------------------------------------------------------

#define TRIGSETBY_INTERNAL  1  /* signal or explicit call to raise */ 
#define TRIGSETBY_EXTERNAL  2  /* flag file */

struct trigstruct 
{
  const char *flagfile; 
  struct { unsigned int whenon, whenoff; } pollinterval;
  unsigned int incheck; //recursion check
  void (*pollproc)(void);
  volatile int trigger; 
  time_t nextcheck;
};

static struct 
{
  int isinit;
  struct trigstruct exittrig;
  struct trigstruct pausetrig;
  struct trigstruct huptrig;
} trigstatics = {0};

// -----------------------------------------------------------------------

int RaiseExitRequestTrigger(void) 
{ 
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  int oldstate = trigstatics.exittrig.trigger;
  trigstatics.exittrig.trigger = TRIGSETBY_INTERNAL;
  return (oldstate);
}  

int RaiseRestartRequestTrigger(void) 
{ 
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  int oldstate = trigstatics.huptrig.trigger;
  trigstatics.exittrig.trigger = TRIGSETBY_INTERNAL;
  trigstatics.huptrig.trigger = TRIGSETBY_INTERNAL;
  return (oldstate);
}  

int RaisePauseRequestTrigger(void) 
{ 
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  int oldstate = trigstatics.pausetrig.trigger;
  trigstatics.pausetrig.trigger = TRIGSETBY_INTERNAL;
  return (oldstate);
}  

int ClearPauseRequestTrigger(void)
{
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  int oldstate = trigstatics.pausetrig.trigger;
  trigstatics.pausetrig.trigger = 0;
  return oldstate;
}  

int CheckExitRequestTriggerNoIO(void) 
{ return (trigstatics.exittrig.trigger); } 
int CheckPauseRequestTriggerNoIO(void) 
{ return (trigstatics.pausetrig.trigger); }
int CheckRestartRequestTriggerNoIO(void) 
{ return (trigstatics.huptrig.trigger); }
int CheckRestartRequestTrigger(void) 
{ return (trigstatics.huptrig.trigger); }

// -----------------------------------------------------------------------

void *RegisterPollDrivenBreakCheck( register void (*proc)(void) )
{
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  register void (*oldproc)(void) = trigstatics.exittrig.pollproc;
  trigstatics.exittrig.pollproc = proc;
  return (void *)oldproc;
}

// -----------------------------------------------------------------------

static void InternalPollForFlagFiles(struct trigstruct *trig, int undoable)
{
  time_t now;
  
  if ((undoable || !trig->trigger) && trig->flagfile)
    {
    if ((now = time(NULL)) >= trig->nextcheck) 
      {
      trig->nextcheck = now + (time_t)trig->pollinterval.whenoff;
      trig->trigger = 0;
      }
    }
  return;
}

// -----------------------------------------------------------------------

int CheckExitRequestTrigger(void) 
{
  static int wasseen = 0;

  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  if (!wasseen && !trigstatics.exittrig.incheck)
    {
    ++trigstatics.exittrig.incheck;
    if ( !trigstatics.exittrig.trigger )
      {
      if (trigstatics.exittrig.pollproc)
        (*trigstatics.exittrig.pollproc)();
      }
    if ( !trigstatics.exittrig.trigger )
      InternalPollForFlagFiles( &trigstatics.exittrig, 0 );
    if ( trigstatics.exittrig.trigger )
      {
      LogScreen("*Break*%s\n", 
       (trigstatics.exittrig.trigger == TRIGSETBY_EXTERNAL)?
         (" (found exit flag file)"): 
         ((trigstatics.huptrig.trigger)?(" Restarting..."):
         (" Shutting down...")) );
      wasseen = 1;             
      }
    --trigstatics.exittrig.incheck;
    }
  return( trigstatics.exittrig.trigger );
}  

// -----------------------------------------------------------------------

int CheckPauseRequestTrigger(void) 
{
  if (!trigstatics.isinit)
    InitializeTriggers( NULL, NULL );
  if ( CheckExitRequestTrigger() )   //only check if not exiting
    return 0;
  if ( !trigstatics.pausetrig.incheck && 
       trigstatics.pausetrig.trigger != TRIGSETBY_INTERNAL )
    {
    ++trigstatics.pausetrig.incheck;
    InternalPollForFlagFiles( &trigstatics.pausetrig, 1 );
    --trigstatics.pausetrig.incheck;
    }
  return( trigstatics.pausetrig.trigger );
}   

// -----------------------------------------------------------------------

int DeinitializeTriggers(void)
{
  trigstatics.isinit=0;
  int huptrig = trigstatics.huptrig.trigger;
  memset( (void *)(&trigstatics), 0, sizeof(trigstatics) );
  trigstatics.huptrig.trigger = huptrig;
  return 0;
}  

// -----------------------------------------------------------------------

int InitializeTriggers( const char *exitfile, const char *pausefile )
{
  if (!trigstatics.isinit)
    {
    memset( (void *)(&trigstatics), 0, sizeof(trigstatics) );
    trigstatics.isinit = 1;
    trigstatics.exittrig.pollinterval.whenon = 0;
    trigstatics.exittrig.pollinterval.whenoff = EXITFILE_CHECKTIME;
    trigstatics.pausetrig.pollinterval.whenon = PAUSEFILE_CHECKTIME_WHENON;
    trigstatics.pausetrig.pollinterval.whenoff = PAUSEFILE_CHECKTIME_WHENOFF;
    CliSetupSignals();
    }
  if (exitfile && *exitfile && strcmp(exitfile,"none")!=0)
    trigstatics.exittrig.flagfile = exitfile;
  if (pausefile && *pausefile && strcmp(pausefile,"none")!=0)
    trigstatics.pausetrig.flagfile = pausefile;

  return (CheckExitRequestTrigger());
}  

// =======================================================================

#if (CLIENT_OS == OS_AMIGAOS)
extern "C" void __regargs __chkabort(void) 
{ 
  /* Disable SAS/C CTRL-C handing */
  return;
}
void CliPollDrivenBreakCheck( void )
{
  if ( SetSignal(0L,0L) & SIGBREAKF_CTRL_C )
    RaiseExitRequestTrigger();
}
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_WIN32)
bool CliSignalHandler(DWORD  dwCtrlType)
{
  if ( dwCtrlType == CTRL_C_EVENT || dwCtrlType == CTRL_BREAK_EVENT ||
       dwCtrlType == CTRL_CLOSE_EVENT || dwCtrlType == CTRL_SHUTDOWN_EVENT)
  {
    RaiseExitRequestTrigger();
    return TRUE;
  }
  return FALSE;
}
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_NETWARE)
void CliSignalHandler( int sig )
{
  if (sig == SIGHUP)
    RaiseRestartRequestTrigger();
  else
    {
    RaiseExitRequestTrigger();
    nwCliSignalHandler( sig ); //never to return...
    }
}
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_OS390)
extern "C" void CliSignalHandler( int )
{
  RaiseExitRequestTrigger();
  CliSetupSignals(); //reset the signal handlers
}
#define CLISIGHANDLER_IS_SPECIAL
#endif
  
// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_OS2)
void CliSignalHandler( int )
{
  // Give priority boost quit works faster
  DosSetPriority(PRTYS_THREAD, PRTYC_REGULAR, 0, 0); 
  RaiseExitRequestTrigger();
  CliSetupSignals(); //reset the signal handlers
}  
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_RISCOS)
void CliSignalHandler( int )
{
  // clear escape trigger for polling check in Problem::Run
  _kernel_escape_seen(); 
  RaiseExitRequestTrigger();
  CliSetupSignals(); //reset the signal handlers
}
#define CLISIGHANDLER_IS_SPECIAL
#endif  

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_DOS)
void CliSignalHandler( int )
{
  RaiseExitRequestTrigger();
  //break_off(); //break only on screen i/o (different from setup signals)
  //- don't reset sighandlers or we may end up in an
  //  infinite loop (keyboard buffer isn't clear yet)
}
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#if (CLIENT_OS == OS_WIN16) || (CLIENT_OS == OS_WIN32S)
void CliPollDrivenBreakCheck( void )
{
  #if 0
  if (kbhit())
    {
    int key = getch();
    if ( key == 3 ) RaiseExitRequestTrigger();
    else if (!key ) getch();
    }
  #endif
  return;  
}      
#define CLISIGHANDLER_IS_SPECIAL
#endif

// -----------------------------------------------------------------------

#ifndef CLISIGHANDLER_IS_SPECIAL
void CliSignalHandler
  (
#ifdef SIGHUP
  int sig
#else 
  int
#endif 
  )
{
#ifdef SIGHUP
  if (sig == SIGHUP)
    RaiseRestartRequestTrigger();
#endif
  RaiseExitRequestTrigger();
  CliSetupSignals(); //reset the signal handlers
}  
#endif //ifndef CLISIGHANDLER_IS_SPECIAL

// -----------------------------------------------------------------------

void CliSetupSignals( void )
{
  #if (CLIENT_OS == OS_MACOS) 
    // nothing
  #elif (CLIENT_OS == OS_AMIGAOS)
    SetSignal(0L, SIGBREAKF_CTRL_C); // Clear the signal triggers
    RegisterPollDrivenBreakCheck( CliPollDrivenBreakCheck );
  #elif (CLIENT_OS == OS_WIN32)
    SetConsoleCtrlHandler( (PHANDLER_ROUTINE) CliSignalHandler, TRUE );
  #elif (CLIENT_OS == OS_WIN16) || (CLIENT_OS == OS_WIN32S) || \
        (CLIENT_OS == OS_DOS && defined(__WINDOWS__)) //watcom win32
    while (kbhit()) { if (getch()==0) getch(); } //flush the keyboard
    RegisterPollDrivenBreakCheck( CliPollDrivenBreakCheck );
  #elif (CLIENT_OS == OS_RISCOS)
    signal( SIGINT, CliSignalHandler );
  #elif (CLIENT_OS == OS_OS2)
    signal( SIGINT, CliSignalHandler );
    signal( SIGTERM, CliSignalHandler );
  #elif (CLIENT_OS == OS_DOS)
    break_on(); //break on any dos call 
    signal( SIGINT, CliSignalHandler );  //The  break_o functions can be used
    signal( SIGTERM, CliSignalHandler ); // with DOS to restrict break checking
    signal( SIGABRT, CliSignalHandler ); // break_off(): raise() on conio only
    signal( SIGBREAK, CliSignalHandler ); //break_on(): raise() on any dos call
  #elif (CLIENT_OS == OS_IRIX) && defined(__GNUC__)
    signal( SIGHUP, (void(*)(...)) CliSignalHandler );
    signal( SIGQUIT, (void(*)(...)) CliSignalHandler );
    signal( SIGTERM, (void(*)(...)) CliSignalHandler );
    signal( SIGINT, (void(*)(...)) CliSignalHandler );
    signal( SIGSTOP, (void(*)(...)) CliSignalHandler );
  #elif (CLIENT_OS == OS_VMS)
    signal( SIGHUP, CliSignalHandler );
    signal( SIGQUIT, CliSignalHandler );
    signal( SIGTERM, CliSignalHandler );
    signal( SIGINT, CliSignalHandler );
  #elif (CLIENT_OS == OS_NETWARE)
    signal( SIGHUP, CliSignalHandler );
    signal( SIGQUIT, CliSignalHandler );
    signal( SIGTERM, CliSignalHandler );
    signal( SIGINT, CliSignalHandler );
    RegisterPollDrivenBreakCheck( nwCliCheckForUserBreak );
    signal( SIGSTOP, CliSignalHandler );
    //workaround NW 3.x bug - printf "%f" handler is in mathlib not clib, which
    signal( SIGABRT, CliSignalHandler ); //raises abrt if mathlib isn't loaded
  #else
    signal( SIGHUP, CliSignalHandler );
    signal( SIGQUIT, CliSignalHandler );
    signal( SIGTERM, CliSignalHandler );
    signal( SIGINT, CliSignalHandler );
    signal( SIGSTOP, CliSignalHandler );
  #endif
}

// -----------------------------------------------------------------------

