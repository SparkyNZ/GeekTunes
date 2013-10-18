
#include <time.h>
#include "mikmod_internals.h"

#include "PaulPlayer.h"
#include "MODPlayPaul.h"


#include <memory.h>
#include <string.h>




static void DS_CommandLine(CHAR *cmdline)
{
}

static BOOL DS_IsPresent(void)
{
	return 1;
}

//--------------------------------------------------------------------------------------------
// DS_Init()
//--------------------------------------------------------------------------------------------
static BOOL DS_Init(void)
{
	return VC_Init();
}

//--------------------------------------------------------------------------------------------
// DS_Exit()
//--------------------------------------------------------------------------------------------
static void DS_Exit( void )
{
	VC_Exit();
}

static BOOL do_update = 0;


//--------------------------------------------------------------------------------------------
// DS_Update()
//--------------------------------------------------------------------------------------------
static void DS_Update( void )
{
  MODPlay_Update();
}

static void DS_PlayStop(void)
{
	do_update = 0;

	VC_PlayStop();
}

static BOOL DS_PlayStart(void)
{
	do_update = 1;
	return VC_PlayStart();
}

MIKMODAPI MDRIVER drv_ds=
{
	NULL,
	"DirectSound",
	"DirectSound Driver (DX6+) v0.4",
	0,
  255,
	"ds",
	"buffer:r:12,19,16:Audio buffer log2 size\n"
  "globalfocus:b:0:Play if window does not have the focus\n",

	NULL, //DS_CommandLine,
	DS_IsPresent,

	VC_SampleLoad,
	VC_SampleUnload,
	VC_SampleSpace,
	VC_SampleLength,
	DS_Init,
	DS_Exit,
	NULL,
	VC_SetNumVoices,
	DS_PlayStart,
	DS_PlayStop,
	DS_Update,
	NULL,
	VC_VoiceSetVolume,
	VC_VoiceGetVolume,
	VC_VoiceSetFrequency,
	VC_VoiceGetFrequency,
	VC_VoiceSetPanning,
	VC_VoiceGetPanning,
	VC_VoicePlay,
	VC_VoiceStop,
	VC_VoiceStopped,
	VC_VoiceGetPosition,
	VC_VoiceRealVolume
};


