//
//  ModPlayPaul.mm
//  GeekTunes
//
//  Created by Paul Spark on 6/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//
#define BOOL_DEFINED

#include "PaulPlayer.h"
#include "MODPlayPaul.h"

#include <time.h>

#include "mikmod_internals.h"
#include "mikmod.h"

MODULE *g_Module = NULL;

//--------------------------------------------------------------------------------------------
// MODRenderCallback() 
//--------------------------------------------------------------------------------------------
OSStatus MODRenderCallback( void *inRefCon, 
                            AudioUnitRenderActionFlags 	*ioActionFlags, 
                            const AudioTimeStamp 		    *inTimeStamp, 
                            UInt32 						           inBusNumber, 
                            UInt32 						           inNumberFrames, 
                            AudioBufferList 		        	*ioData )

{
	// This is a mono tone generator so we only need the first buffer
	SInt16 *buffer;
  
  // PDS: Ask for number of bytes, not channels.. 16bit (2bytes per sample & g_Channels)
  MODPlay_Callback( NULL, g_ByteSampleBuffer, inNumberFrames * 2 * g_Channels );
  
  SInt16 *ps = (SInt16*) g_ByteSampleBuffer;
  
  // PDS: Get 1st channel sample data..
  buffer = (SInt16 *)ioData->mBuffers[ 0 ].mData;  
  
	for( UInt32 frame = 0; frame < inNumberFrames * 2; frame++ ) 
	{
		buffer[ frame ] = (*ps);
    ps ++;
	}  
  
	return noErr;
}


//--------------------------------------------------------------------------------------------
// MODPlay_Callback()
//
// PDS: Requests 'len' bytes of samples - this is NOT the number of samples!!
//--------------------------------------------------------------------------------------------
void MODPlay_Callback( void *userdata, BYTE *pbStream, int nDataLen )
{  
  // PDS: Two channels, and 16 bit = 4x the number of samples..
  // PDS: Looks as though SDL knows how many bytes to ask for for stereo and 16 bit..
  int nSampleDataBytes = nDataLen;
  
  if( ( g_Stopped ) || (! g_BigTuneAvailStarted ) )
  {
    memset( pbStream, 0, nSampleDataBytes );
    return;
  }
  
  memcpy( pbStream, &g_BigTuneBuffer[ g_BigTunePlayed ], nSampleDataBytes );
  g_BigTunePlayed += nSampleDataBytes;
  
  if( ( g_WrapOccurred ) &&
      ( g_BigTunePlayed >= ( g_BigTuneBufferMax / 2 ) ) )
  {
    // PDS: Writer will have wrapped before we do.. but we clear its flag when reader reaches end of buffer
    //      and wraps also..
    g_WrapOccurred  = FALSE;
  }
  
  // PDS: Start playing from beginning of buffer again if end reached..
  if( g_BigTunePlayed >= g_BigTuneBufferMax )
  {
    g_BigTunePlayed = 0;
    
    // PDS: Once the reader wraps back to the start, clear the underwrite..
    if( g_UnderwriteOccurred )
      g_UnderwriteOccurred = FALSE;
  }
}

//--------------------------------------------------------------------------------------------
// MODPlay_Update()
//--------------------------------------------------------------------------------------------
void MODPlay_Update( void )
{  
  //LogDebugf(  "Update: Played: %10ld  Avail(W): %10ld  MAX: %10ld\n", g_BigTunePlayed, g_BigTuneAvailW, g_BigTuneBufferMax );
  
  // PDS: Don't get any more data until reader clears our wrap flag..
  if( g_WrapOccurred )
  {
    //LogDebugf(  "Update %10ld -> Wrapped, waiting..", g_BigTuneAvailW );
    return;
  }
  
  // PDS: Write/avail count should always be greater than played count in an ideal linear world..
  //      ..however, we have a circular buffer ..  
  if( g_UnderwriteOccurred )
  {
    //LogDebugf(  "Update %10ld -> Underwrite, waiting..", g_BigTuneAvailW );
    return;
  }
  
  if( ( g_BigTuneAvailW < g_BigTunePlayed                              ) &&
      ( g_BigTuneAvailW + g_BigTuneUpdateNumSamples >= g_BigTunePlayed ) &&
      ( g_BigTunePlayed != 0 ) )
  {
    g_UnderwriteOccurred = TRUE;
    
    //LogDebugf( "Bail to avoid update overwrite" );
    return;
  }
  
  if( ( g_WrapOccurred ) &&
      ( g_BigTuneAvailW + g_BigTuneUpdateNumSamples >= g_BigTunePlayed ) &&
      ( g_BigTuneAvailStarted == TRUE ) )
  {
    //printf( "Bail 2\n" );
    return;
  }
  
  if( g_WrapToZeroPending )
  {
    // PDS: Wrap and continue..
    g_BigTuneAvailW     = 0;
    g_WrapToZeroPending = FALSE;
    //LogDebugf( "Update %10ld -> Start again", g_BigTuneAvailW );
  }
  
  // PDS: Start writing data at start of buffer again..
  if( g_BigTuneAvailW + g_BigTuneUpdateNumSamples > g_BigTuneBufferMax )
  {
    // PDS: Reader/player will clear wrap flag when it wraps itself..
    g_WrapOccurred = TRUE;
    g_WrapToZeroPending = TRUE;
    //LogDebugf( "Update %10ld -> Wrap detected", g_BigTuneAvailW );
    return;
  }
  
  //LogDebugf( "Update %10ld -> %10ld", g_BigTuneAvailW, g_BigTuneAvailW + g_BigTuneUpdateNumSamples );
	if( Player_Paused_internal() ) 
  {
		VC_SilenceBytes( (SBYTE *) &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
	} 
  else 
  {
		VC_WriteBytes( (SBYTE *) &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
	}
    
  g_BigTuneAvailW += g_BigTuneUpdateNumSamples;
  
  g_BigTuneAvailStarted = TRUE;
}


//--------------------------------------------------------------------------------------------
// MODPlaySetup()
//--------------------------------------------------------------------------------------------
void MODPlaySetup( void )
{  
  // PDS: Setup common stuff..
  PaulPlayerInitialise();
      
  // register all the drivers 
  MikMod_RegisterAllDrivers();
  
  // register all the module loaders
  MikMod_RegisterAllLoaders();
  
  // initialize the library 
  md_mode |= DMODE_SOFT_MUSIC;
  
  if( MikMod_Init( "" ) ) 
  {
    return;
  }  
}
 
//--------------------------------------------------------------------------------------------
// MODPlay_Shutdown()
//--------------------------------------------------------------------------------------------
void MODPlay_Shutdown( void )
{
  MikMod_Exit();
}

