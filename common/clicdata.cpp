// Copyright distributed.net 1997-1998 - All Rights Reserved
// For use in distributed.net projects only.
// Any other distribution or use of this source violates copyright.

// This file contains functions for obtaining contest constants (name, id,
// iteration-to-keycount-multiplication-factor) or obtaining/adding to
// contest summary data (totalblocks, totaliterations, totaltime).
// The data itself is hidden from other modules to protect integrity and
// ease maintenance.
//
// $Log: clicdata.cpp,v $
// Revision 1.7  1998/06/15 12:03:45  kbracey
// Lots of consts.
//
// Revision 1.6  1998/06/14 08:26:37  friedbait
// 'Id' tags added in order to support 'ident' command to display a bill of
// material of the binary executable
//
// Revision 1.5  1998/06/14 08:12:30  friedbait
// 'Log' keywords added to maintain automatic change history
//
//


/* module history:
   01 May 1998 - created - Cyrus Patel <cyp@fb14.uni-mainz.de>
*/

static const char *id="@(#)$Id: clicdata.cpp,v 1.7 1998/06/15 12:03:45 kbracey Exp $";

#include "clicdata.h" //includes client.h for timeval and NULL definitions

// ---------------------------------------------------------------------------

static struct contestInfo
{
  const char *ContestName;
  int ContestID;
  unsigned int Iter2KeyFactor; /* by how much must iterations/keysdone
                        be multiplied to get the number of keys checked. */
  unsigned int BlocksDone;
  double IterDone;
  struct timeval TimeDone;
  struct timeval TimeStart;
} conStats[] = {  { "RC5", 0, 1, 0, 0, {0,0}, {0,0} },
                  { "DES", 1, 2, 0, 0, {0,0}, {0,0} },
                  {  NULL,-1, 0, 0, 0, {0,0}, {0,0} }  };

// ---------------------------------------------------------------------------

static struct contestInfo *__internalCliGetContestInfoVectorForID( int contestid )
{
  for (int i = 0; conStats[i].ContestName != NULL; i++)
  {
    if (conStats[i].ContestID == contestid)
      return (&conStats[i]);
  }
  return ((struct contestInfo *)(NULL));
}

// ---------------------------------------------------------------------------

// obtain the contestID for a contest identified by name.
// returns -1 if invalid name (contest not found).
int CliGetContestIDFromName( char *name )
{
  for (int i = 0; conStats[i].ContestName != NULL; i++)
  {
    int n;
    for (n = 0; conStats[i].ContestName[n] != 0; n++)
    {
      if (conStats[i].ContestName[n] != name[n])
        return -1;
    }
    if (!name[n])
      return i;
  }
  return -1;
}

// ---------------------------------------------------------------------------

// obtain constant data for a contest. name/iter2key may be NULL
// returns 0 if success, !0 if error (bad contestID).
int CliGetContestInfoBaseData( int contestid, const char **name, unsigned int *iter2key )
{
  struct contestInfo *conInfo =
                       __internalCliGetContestInfoVectorForID( contestid );
  if (!conInfo)
    return -1;
  if (name)     *name = conInfo->ContestName;
  if (iter2key) *iter2key = (conInfo->Iter2KeyFactor<=1)?(1):(conInfo->Iter2KeyFactor);
  return 0;
}

// ---------------------------------------------------------------------------

    //obtain summary data for a contest. unrequired args may be NULL
    //returns 0 if success, !0 if error (bad contestID).
int CliGetContestInfoSummaryData( int contestid, unsigned int *totalblocks,
                               double *totaliter, struct timeval *totaltime)
{
  struct contestInfo *conInfo =
                      __internalCliGetContestInfoVectorForID( contestid );
  if (!conInfo)
    return -1;
  if (totalblocks) *totalblocks = conInfo->BlocksDone;
  if (totaliter)   *totaliter   = conInfo->IterDone;
  if (totaltime)
  {
    if (conInfo->BlocksDone <= 1)
    {
      totaltime->tv_sec = conInfo->TimeDone.tv_sec;
      totaltime->tv_usec = conInfo->TimeDone.tv_usec;
    }
    else
    {
      //get time since first call to CliTimer() (time when 1st prob started)
      CliClock(totaltime);
      if (totaltime->tv_sec >= conInfo->TimeDone.tv_sec)
      {
        //no overlap means non-mt or only single thread
        totaltime->tv_sec = conInfo->TimeDone.tv_sec;
        totaltime->tv_usec = conInfo->TimeDone.tv_usec;
      }
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------

// add data to the summary data for a contest.
// returns 0 if added successfully, !0 if error (bad contestID).
int CliAddContestInfoSummaryData( int contestid, unsigned int *addblocks,
                                double *additer, struct timeval *addtime)
{
  struct contestInfo *conInfo =
                       __internalCliGetContestInfoVectorForID( contestid );
  if (!conInfo)
    return -1;
  if (addblocks) conInfo->BlocksDone += (*addblocks);
  if (additer)   conInfo->IterDone = conInfo->IterDone + (*additer);
  if (addtime)
  {
    conInfo->TimeDone.tv_sec += addtime->tv_sec;
    if ((conInfo->TimeDone.tv_usec += addtime->tv_usec)>1000000)
    {
      conInfo->TimeDone.tv_sec += (conInfo->TimeDone.tv_usec/1000000);
      conInfo->TimeDone.tv_usec %= 1000000;
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------

// return 0 if contestID is invalid, non-zero if valid.
int CliIsContestIDValid(int contestid)
{
  return (__internalCliGetContestInfoVectorForID(contestid)!=NULL);
}

// ---------------------------------------------------------------------------

// Return a usable contest name.
const char *CliGetContestNameFromID(int contestid)
{
  struct contestInfo *conInfo =
                     __internalCliGetContestInfoVectorForID( contestid );
  if (conInfo)
    return conInfo->ContestName;
  return ((const char *)("???"));
}

// ---------------------------------------------------------------------------

