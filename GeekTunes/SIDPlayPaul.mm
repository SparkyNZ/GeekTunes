//
//  SIDPlayPaul.mm
//  GeekTunes
//
//  Created by Paul Spark on 3/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

//
//  ToneGeneratorViewController.m
//  ToneGenerator
//
//  Created by Matt Gallagher on 2010/10/20.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <AudioToolbox/AudioToolbox.h>

#define BOOL_DEFINED


#include "PaulPlayer.h"
#include "SIDPlayPaul.h"
#include "MODPlayPaul.h"

#include "sidplay2.h"
#include "sidtune.h"

#include "resid.h"

#include <time.h>
#include "vector.h"
#include "Utils.h"


SidTune      *g_SIDTune = NULL;
sidplay2     *g_SIDPlay = NULL;
ReSIDBuilder *mBuilder  = NULL;
SidTuneInfo   g_SIDTuneInfo;
int           g_SIDSubTune;
sid2_model_t  g_SIDChipType = SID2_MOS6581; // SID2_MOS8580;

//--------------------------------------------------------------------------------------------
// SIDRenderCallback() 
//--------------------------------------------------------------------------------------------
OSStatus SIDRenderCallback( void *inRefCon, 
                            AudioUnitRenderActionFlags 	*ioActionFlags, 
                            const AudioTimeStamp 		    *inTimeStamp, 
                            UInt32 						           inBusNumber, 
                            UInt32 						           inNumberFrames, 
                            AudioBufferList 		        	*ioData )

{
	// This is a mono tone generator so we only need the first buffer
	Float32 *buffer;
    
  
  //LogDebugf( "PDS> Frames: %ld", inNumberFrames );
  
  SIDPlay_Callback( NULL, g_ByteSampleBuffer, inNumberFrames * 2 );
  
  
  // PDS: driverInstance->mStreamFormat.mChannelsPerFrame == 1
	// Generate the samples
  short *ps = (short*) g_ByteSampleBuffer;
  
  // PDS: Get 1st channel sample data..
  buffer = (Float32 *)ioData->mBuffers[ 0 ].mData;  
  
	for( UInt32 frame = 0; frame < inNumberFrames; frame++ ) 
	{
    //BYTE *pb = &g_ByteSampleBuffer[ frame * g_Channels * 2 ];
    
		buffer[frame] = (*ps) * g_BitScaleFactor;
    ps ++; 
	}  

  // PDS: Get 2nd channel sample data..
  buffer = (Float32 *)ioData->mBuffers[ 1 ].mData;

  ps = (short*) g_ByteSampleBuffer;
  
	for( UInt32 frame = 0; frame < inNumberFrames; frame++ ) 
	{    
		buffer[frame] = (*ps) * g_BitScaleFactor;
    ps ++;
	}  
  
  
  
  /*
  else if (driverInstance->mStreamFormat.mChannelsPerFrame == 2)
  {
    register float sample = 0.0f;
    
    while (audioBuffer < bufferEnd)
    {
      sample = (*audioBuffer++) * scaleFactor;
      *outBuffer++ = sample;
      *outBuffer++ = sample;
    }
  }
   */
  
  /*
  
	// Generate the samples
	for( UInt32 frame = 0; frame < inNumberFrames; frame++ ) 
	{
    BYTE *pb = &g_ByteSampleBuffer[ frame * g_Channels * 2 ];
    
    short shAmp = 32768 + ( ( pb[ 0 ] << 8 ) | ( pb[ 1 ] ) );
		buffer[frame] = shAmp / 32768.0;
	}
  */
  
	return noErr;
}

//--------------------------------------------------------------------------------------------
// SIDPlay_Callback()
//
// PDS: Requests 'len' bytes of samples - this is NOT the number of samples!!
//--------------------------------------------------------------------------------------------
void SIDPlay_Callback( void *userdata, BYTE *pbStream, int nDataLen )
{
  if( ! g_SIDPlay )
    return;
  
  // PDS: Two channels, and 16 bit = 4x the number of samples..
  // PDS: Looks as though SDL knows how many bytes to ask for for stereo and 16 bit..
  int nSampleDataBytes = nDataLen;
  
  if( ( g_Stopped ) || ( ! g_BigTuneAvailStarted ) )
  {
    memset( pbStream, 0, nSampleDataBytes );
    return;
  }
  
  memcpy( pbStream, &g_BigTuneBuffer[ g_BigTunePlayed ], nSampleDataBytes );
  g_BigTunePlayed += nSampleDataBytes;
  
  if( ( g_WrapOccurred ) &&
     //( g_BigTunePlayed + g_BigTuneUpdateNumSamples >= g_BigTuneBufferMax ) )
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
// SIDPlay_Update()
//--------------------------------------------------------------------------------------------
void SIDPlay_Update( void )
{
  if( g_Stopped )
    return;
  
  //LogDebugf(  "Update: Played: %10ld  Avail(W): %10ld  MAX: %10ld\n", g_BigTunePlayed, g_BigTuneAvailW, g_BigTuneBufferMax );

  
  // PDS: Don't get more sample data if wrap has occurred and write position is attempting to overtake read posn..
  //if( g_BigTuneAvailW < g_BigTunePlayed )
  //{
  //printf( "Bail 1\n" );
  //return;
  //}
  
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
  
  /*
   if( Player_Paused_internal() ) 
   {
   VC_SilenceBytes( (SBYTE *) &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
   } 
   else 
   */
  {
    
    //LogDebugf( "Update %10ld -> %10ld", g_BigTuneAvailW, g_BigTuneAvailW + g_BigTuneUpdateNumSamples );
    
		//VC_WriteBytes( (SBYTE *) &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
    g_SIDPlay->play( &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
	}

  g_BigTuneAvailW += g_BigTuneUpdateNumSamples;
  
  g_BigTuneAvailStarted = TRUE;
}

//--------------------------------------------------------------------------------------------
// SIDPlaySetup()
//--------------------------------------------------------------------------------------------
void SIDPlaySetup( void )
{ 
  // PDS: Setup common stuff..
  PaulPlayerInitialise();
      
  g_SIDPlay = new sidplay2;
  
  mBuilder = new ReSIDBuilder("resid");
  
	sid2_config_t cfg = g_SIDPlay->config();

	cfg.clockSpeed    = SID2_CLOCK_PAL;
	cfg.clockDefault  = SID2_CLOCK_PAL;
  
	cfg.clockForced   = TRUE;

	cfg.environment   = sid2_envR;
	//cfg.playback	    = sid2_stereo; 
  cfg.playback	    = sid2_mono;

	cfg.precision     = 16; //mPlaybackSettings.mBits;
	cfg.frequency	    = 44100;
	cfg.forceDualSids = FALSE;
	cfg.emulateStereo = FALSE;
//  cfg.leftVolume = 15;
//  cfg.rightVolume = 15;
  
	cfg.optimisation = SID2_DEFAULT_OPTIMISATION;
	
  cfg.sidDefault	  = g_SIDChipType;
	cfg.sidModel      = cfg.sidDefault;
  
	cfg.sidEmulation  = mBuilder;
	cfg.sidSamples	  = TRUE;
  //	cfg.sampleFormat  = SID2_BIG_UNSIGNED;
  
	// setup resid
	if( mBuilder->devices( TRUE ) == 0 )
		mBuilder->create( 1 );
  
	mBuilder->filter( TRUE );
	//mBuilder->filter(&mFilterSettings);
	mBuilder->sampling( cfg.frequency );
	
	int rc = g_SIDPlay->config( cfg );

	if(rc != 0)
		LogDebugf( "configure error: %s\n", g_SIDPlay->error() );
  
	g_SIDPlay->setRegisterFrameChangedCallback( NULL, NULL );
    
  // This no longer works with the library, the signature has changed.....
  //g_SIDPlay->config(sid2_mono, 44100, 16, false); 
  
}

