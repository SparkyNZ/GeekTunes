//
//  PaulPlayer.mm
//  GeekTunes
//
//  Created by Paul Spark on 7/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define BOOL_DEFINED


#include "PaulPlayer.h"
#include "SIDPlayPaul.h"
#include "MODPlayPaul.h"

BOOL   g_Stopped       = TRUE;

BYTE  *g_BigTuneBuffer = NULL;
ULONG  g_BigTuneAvailW = 0;
ULONG  g_BigTunePlayed = 0;

ULONG  g_BigTuneBufferMax = /* 1024 */ 512 * 1024 * 2 * 2;
ULONG  g_BigTuneUpdateNumSamples = 65536;
BOOL   g_BigTuneAvailStarted     = FALSE;
BOOL   g_WrapOccurred            = FALSE;
BOOL   g_WrapToZeroPending       = FALSE;
BOOL   g_UnderwriteOccurred      = FALSE;
BYTE   g_ByteSampleBuffer[ 32768 ];

int    g_Samples  = 2048;
int    g_Channels = 2;

double g_SampleRate = 44100;

AudioComponentInstance g_ToneUnit;

float  g_BitScaleFactor = 1.0f / 32768.0f;

//--------------------------------------------------------------------------------------------
// ToneInterruptionListener()
//
// WHats this for?
//--------------------------------------------------------------------------------------------
void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
}

//--------------------------------------------------------------------------------------------
// CreateToneUnit
//--------------------------------------------------------------------------------------------
void CreateToneUnit( int nType )
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew( defaultOutput, &g_ToneUnit );
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
  
  switch( nType )
  {
    case UNIT_SID:  input.inputProc = SIDRenderCallback;  break;
    case UNIT_MOD:  input.inputProc = MODRenderCallback;  break;
  }
  
  // PDS: Arbitrary data - not needed..
	input.inputProcRefCon = NULL; //self;
  
	err = AudioUnitSetProperty( g_ToneUnit, 
                             kAudioUnitProperty_SetRenderCallback, 
                             kAudioUnitScope_Input,
                             0, 
                             &input, 
                             sizeof(input) );
  
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
  
	AudioStreamBasicDescription streamFormat;
  
  if( nType == UNIT_SID )
  {
    streamFormat.mSampleRate  = g_SampleRate;
    streamFormat.mFormatID    = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket   = four_bytes_per_float;
    streamFormat.mFramesPerPacket  = 1;	
    streamFormat.mBytesPerFrame    = four_bytes_per_float;		
    streamFormat.mChannelsPerFrame = g_Channels;	
    streamFormat.mBitsPerChannel   = 32; //four_bytes_per_float * 8; //eight_bits_per_byte;
  }
  else
  if( nType == UNIT_MOD )
  {
    streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  |	kAudioFormatFlagIsPacked;  
    //streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  |	kAudioFormatFlagIsNonInterleaved;  
    streamFormat.mFormatID    = kAudioFormatLinearPCM;
    streamFormat.mSampleRate  = 44100;
    
    streamFormat.mChannelsPerFrame = g_Channels; 	
    streamFormat.mBitsPerChannel   = 16; 
    
    streamFormat.mBytesPerFrame =   (streamFormat.mBitsPerChannel / 8) * streamFormat.mChannelsPerFrame;
    
    streamFormat.mFramesPerPacket  = 1;	  
    streamFormat.mBytesPerPacket   = streamFormat.mBytesPerFrame;
  }
  
	err = AudioUnitSetProperty ( g_ToneUnit,
                              kAudioUnitProperty_StreamFormat,
                              kAudioUnitScope_Input,
                              0,
                              &streamFormat,
                              sizeof(AudioStreamBasicDescription));
  
}

//--------------------------------------------------------------------------------------------
// ToneUnitPlay
//--------------------------------------------------------------------------------------------
void ToneUnitPlay( int nType )
{
  //CreateToneUnit( nType );
  
  // Stop changing parameters on the unit
  OSErr err = AudioUnitInitialize( g_ToneUnit );
  
  // Start playback
  err = AudioOutputUnitStart( g_ToneUnit );
}

//--------------------------------------------------------------------------------------------
// ToneUnitStop
//--------------------------------------------------------------------------------------------
void ToneUnitStop( void )
{
	if( g_ToneUnit )
	{
		AudioOutputUnitStop( g_ToneUnit );
		AudioUnitUninitialize( g_ToneUnit );
		AudioComponentInstanceDispose( g_ToneUnit );
		g_ToneUnit = nil;
	}
}

//--------------------------------------------------------------------------------------------
// SetupAudioSession()
//--------------------------------------------------------------------------------------------
void SetupAudioSession( void )
{
	OSStatus result = AudioSessionInitialize( NULL, NULL, ToneInterruptionListener, NULL );
  
	if (result == kAudioSessionNoError)
	{
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    
    /*
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&sessionError];   
     */
	}
  
	AudioSessionSetActive(true);
}

//--------------------------------------------------------------------------------------------
// ShutdownAudioSession()
//--------------------------------------------------------------------------------------------
void ShutdownAudioSession( void )
{
	AudioSessionSetActive( FALSE );
}

//--------------------------------------------------------------------------------------------
// PaulPlayerInitialise()
//--------------------------------------------------------------------------------------------
void PaulPlayerInitialise( void )
{
  // PDS: Set up big buffer which will get updated by MikMod Update function..
  if( ! g_BigTuneBuffer ) 
    g_BigTuneBuffer = (BYTE *) malloc( g_BigTuneBufferMax );
  
  memset( g_BigTuneBuffer, 0, g_BigTuneBufferMax );
  
  g_BigTuneAvailW       = 0;
  g_BigTunePlayed       = 0;
  
  g_BigTuneAvailStarted = FALSE;
  g_WrapOccurred        = FALSE;
  g_WrapToZeroPending   = FALSE;
  g_UnderwriteOccurred  = FALSE;  
  
  g_Stopped = FALSE;
}



