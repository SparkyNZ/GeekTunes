//
//  SIDPlayPaul.h
//  GeekTunes
//
//  Created by Paul Spark on 3/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef GeekTunes_SIDPlayPaul_h
#define GeekTunes_SIDPlayPaul_h

#import <AudioToolbox/AudioToolbox.h>
#include "Common.h"

#include "sidplay2.h"
#include "sidtune.h"

extern SidTune    *g_SIDTune;
extern sidplay2   *g_SIDPlay;
extern SidTuneInfo g_SIDTuneInfo;
extern int         g_SIDSubTune;

extern void SIDPlaySetup( void );
extern void SIDPlay_Update( void );
extern void SIDPlay_Callback( void *userdata, BYTE *pbStream, int nDataLen );

extern OSStatus SIDRenderCallback(
                               void *inRefCon, 
                               AudioUnitRenderActionFlags 	*ioActionFlags, 
                               const AudioTimeStamp 		    *inTimeStamp, 
                               UInt32 						           inBusNumber, 
                               UInt32 						           inNumberFrames, 
                               AudioBufferList 		        	*ioData );

#endif
