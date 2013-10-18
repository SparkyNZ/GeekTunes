//
//  MODPlayPaul.h
//  GeekTunes
//
//  Created by Paul Spark on 7/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef GeekTunes_MODPlayPaul_h
#define GeekTunes_MODPlayPaul_h


#import <AudioToolbox/AudioToolbox.h>
#include "Common.h"
#include "mikmod_internals.h"


extern AudioComponentInstance g_ToneUnit;
extern MODULE                *g_Module;


extern void MODPlaySetup( void );
extern void MODPlay_Update( void );
extern void MODPlay_Callback( void *userdata, BYTE *pbStream, int nDataLen );

extern OSStatus MODRenderCallback(
                               void *inRefCon, 
                               AudioUnitRenderActionFlags 	*ioActionFlags, 
                               const AudioTimeStamp 		    *inTimeStamp, 
                               UInt32 						           inBusNumber, 
                               UInt32 						           inNumberFrames, 
                               AudioBufferList 		        	*ioData );

#endif
