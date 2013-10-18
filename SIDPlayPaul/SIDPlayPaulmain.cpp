
#if 0

#define _SDL_DEFINED
#include "SDL.h"
#include "SDL_audio.h"

#include "sidplay2.h"
#include "sidtune.h"

#include "resid.h"

#include <time.h>


BOOL          g_Stopped = TRUE;

sidplay2 *pSidplay2 = NULL;
ReSIDBuilder *mBuilder = NULL;

SDL_AudioSpec  spec;
SDL_Surface   *screen = NULL;
Uint32         sound_len;
BYTE          *g_BigTuneBuffer = NULL;
ULONG          g_BigTuneAvailW = 0;
ULONG          g_BigTunePlayed = 0;

ULONG  g_BigTuneBufferMax = /*1024*/ 512 * 1024 * 2 * 2;
ULONG  g_BigTuneUpdateNumSamples = 65536;
BOOL   g_BigTuneAvailStarted     = FALSE;
BOOL   g_WrapOccurred            = FALSE;
BOOL   g_WrapToZeroPending       = FALSE;

extern int            sound_pos;
extern int            counter;
int            g_Samples = 2048;

extern void Callback16( void *userdata, Uint8 *pbStream, int nDataLen );

char g_DebugBuf[ 2048 ];

//--------------------------------------------------------------------------------------------
// LogDebug()
//--------------------------------------------------------------------------------------------
void LogDebug( char *s )
{
  static int nFirst = 1;

  FILE *op = fopen( "C:\\log.pds", "a" );

  if( nFirst )
  {
    time_t tNow = time( NULL );
    struct tm *ptm = localtime( &tNow );

    nFirst = 0;
    fprintf( op, "------------------------------------------------------------\n" );
    fprintf( op, "%02d:%02d:%02d\n", ptm->tm_hour, ptm->tm_min, ptm->tm_sec );
    fprintf( op, "------------------------------------------------------------\n" );
  }

  fprintf( op, "%s\n", s );
  fclose( op );
}

//--------------------------------------------------------------------------------------------
// LogDebugf()
//--------------------------------------------------------------------------------------------
void LogDebugf( char *pchFormat, ... ) 
{ 
  va_list argp; 
  char* tmp; 

  g_DebugBuf[0] = 0; 

  if( pchFormat != 0 ) 
  { 
    tmp = strchr(pchFormat, '%'); 

    if( tmp ) 
    { 
      va_start( argp, pchFormat ); 
      vsprintf( g_DebugBuf, pchFormat, argp ); 
      va_end( argp ); 
    } 
    else 
      strcpy( g_DebugBuf, pchFormat ); 
  } 

  LogDebug( g_DebugBuf ); 
} 


//--------------------------------------------------------------------------------------------
// Callback16()
//
// PDS: Requests 'len' bytes of samples - this is NOT the number of samples!!
//--------------------------------------------------------------------------------------------
void Callback16( void *userdata, Uint8 *pbStream, int nDataLen )
{
  if( ! pSidplay2 )
    return;

  // PDS: Two channels, and 16 bit = 4x the number of samples..
  // PDS: Looks as though SDL knows how many bytes to ask for for stereo and 16 bit..
  int nSampleDataBytes = nDataLen;

  if( ! g_BigTuneAvailStarted )
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
  }
}


//--------------------------------------------------------------------------------------------
// SetupSDLAudio()
//--------------------------------------------------------------------------------------------
void SetupSDLAudio( void )
{
  sound_len     = g_Samples * 2;

  spec.freq     = 44100;
  spec.format   = AUDIO_S16SYS; 
  spec.channels = 2;
  spec.silence  = 0;
  spec.samples  = g_Samples;
  spec.padding  = 0;
  spec.size     = 0;  
  spec.userdata = 0;

  spec.callback = Callback16;

  if( SDL_OpenAudio( &spec, NULL ) < 0 )
  {
    exit( -1 );
  }

  SDL_PauseAudio( 0 );
}


//--------------------------------------------------------------------------------------------
// DS_Update()
//--------------------------------------------------------------------------------------------
void DS_Update( void )
{
  printf( "Update: Played: %10ld  Avail(W): %10ld  MAX: %10ld\n", g_BigTunePlayed, g_BigTuneAvailW, g_BigTuneBufferMax );

  // PDS: Don't get more sample data if wrap has occurred and write position is attempting to overtake read posn..
  //if( g_BigTuneAvailW < g_BigTunePlayed )
  //{
    //printf( "Bail 1\n" );
    //return;
  //}

  // PDS: Don't get any more data until reader clears our wrap flag..
  if( g_WrapOccurred )
  {
    //LogDebugf( "Update %10ld -> Wrapped, waiting..", g_BigTuneAvailW );
    return;
  }

  // PDS: Write/avail count should always be greater than played count in an ideal linear world..
  //      ..however, we have a circular buffer ..

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
    printf( "Update %10ld -> %10ld\n", g_BigTuneAvailW, g_BigTuneAvailW + g_BigTuneUpdateNumSamples );

		//VC_WriteBytes( (SBYTE *) &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
    pSidplay2->play( &g_BigTuneBuffer[ g_BigTuneAvailW ], (ULONG) g_BigTuneUpdateNumSamples );
	}

  g_BigTuneAvailW += g_BigTuneUpdateNumSamples;

  g_BigTuneAvailStarted = TRUE;
}


//--------------------------------------------------------------------------------------------
// main()
//--------------------------------------------------------------------------------------------
int main( int argc, char* argv[] )
{
  SDL_Event event;
  BOOL      running = TRUE;

  if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO ) < 0 )
    exit( -1 );

  // PDS: An SDL surface appears to be required to get keypress events..
  screen = SDL_SetVideoMode( 640, 480, 16, SDL_HWSURFACE );

  if( screen == NULL )
    exit (-1);

  // PDS: Set up callback etc
  SetupSDLAudio();

  // PDS: Set up big buffer which will get updated by MikMod Update function..
  g_BigTuneBuffer = (BYTE *) malloc( g_BigTuneBufferMax );
  g_BigTuneAvailW = 0;
  g_BigTunePlayed = 0;

  g_Stopped = FALSE;

  //----

  SidTune* pTune = new SidTune( "Cybernoid.sid", 0, false);
  pTune->selectSong(0);
 
  pSidplay2 = new sidplay2;

  mBuilder = new ReSIDBuilder("resid");
  
	sid2_config_t cfg = pSidplay2->config();
	
	cfg.clockSpeed    = SID2_CLOCK_PAL;
	cfg.clockDefault  = SID2_CLOCK_PAL;

	cfg.clockForced   = TRUE;
	
	cfg.environment   = sid2_envR;
	cfg.playback	    = sid2_stereo; //sid2_mono;
	cfg.precision     = 16; //mPlaybackSettings.mBits;
	cfg.frequency	    = 44100;
	cfg.forceDualSids = FALSE;
	cfg.emulateStereo = FALSE;

	cfg.optimisation = SID2_DEFAULT_OPTIMISATION;
	
  cfg.sidDefault	  = SID2_MOS6581;
  //cfg.sidDefault	  = SID2_MOS8580;

	cfg.sidModel = cfg.sidDefault;

	cfg.sidEmulation  = mBuilder;
	cfg.sidSamples	  = TRUE;
  //	cfg.sampleFormat  = SID2_BIG_UNSIGNED;

	// setup resid
	if( mBuilder->devices( TRUE ) == 0 )
		mBuilder->create( 1 );
		
	mBuilder->filter( TRUE );
	//mBuilder->filter(&mFilterSettings);
	mBuilder->sampling( cfg.frequency );
	
	int rc = pSidplay2->config( cfg );

	if (rc != 0)
		printf("configure error: %s\n", pSidplay2->error());

	pSidplay2->setRegisterFrameChangedCallback( NULL, NULL );

  pSidplay2->load( pTune );

  // This no longer works with the library, the signature has changed.....
  //pSidplay2->config(sid2_mono, 44100, 16, false); 
 
  //----


  running = TRUE;

  while( running ) 
  {
    while( SDL_PollEvent( &event ) ) 
    {
      // GLOBAL KEYS / EVENTS 
      switch (event.type) 
      {
        case SDL_KEYDOWN:
        {
          //printf( "Key: %d\n", event.key.keysym.sym );

          switch( event.key.keysym.sym ) 
          {
            case SDLK_ESCAPE:
              running = FALSE;
              break;

            case SDLK_RETURN:
              //PlaySound();
              break;

            default: break;
          }
          break;
        }

        case SDL_QUIT:
          running = FALSE;
          break;
      }

      if( running == FALSE )
        break;

      SDL_Delay(1);
    }

    {
      static DWORD dwLastUpdate = 0;
      DWORD dwNow = GetTickCount();

      if( dwNow - dwLastUpdate >= 200 )
      {
        dwLastUpdate = dwNow;
        DS_Update();
      }
    }

    SDL_Delay(1);
  }

  SDL_Quit();

  return EXIT_SUCCESS;
} 

#endif
