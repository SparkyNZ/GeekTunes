//
//  Events.h
//  GeekTunes
//
//  Created by Admin on 25/08/13.
//
//

#ifndef GeekTunes_Events_h
#define GeekTunes_Events_h

typedef enum
{
  evNO_EVENT = 0,
  
  // Player events..
  evSTARTUP,
  evTIMER_CALLBACK,
  evPLAY_SELECTED,
  evPLAY_STOP,
  evPLAY_STOP_ALL,
  evPLAY_TUNE,
  evRESUME_TUNE,
  evPAUSE_TUNE,
  evSTOP_TUNE,
  evPREV_TUNE,
  evNEXT_TUNE,
  evPREV_SUBTUNE,
  evNEXT_SUBTUNE,
  evMODE_SELECT,
  evSNAP,
  evSID_CHIP_TOGGLE,
  
  // Manage events..
  evDELETE_HATES,
  evUNHATE_ALL,
  evLIKES_TO_PLIST,
  evSAFEKEEP_LIKES,
  evREBUILD_LIB,
  evLIKE_TUNE,
  evHATE_TUNE,
  
  // TO DO..
  evCREATE_PLAYLIST,  // "Creating playlist for"
  evCREATE_PLAYLIST_LIKES,
  evCREATE_PLAYLIST_ALBUM,
  evCREATE_PLAYLIST_ARTIST,
  
  evFREE_TVMANAGE,
  
} EVENT_TYPE;


//--------------------------------------------------------------------------------------------
// PLAYERMSG
//--------------------------------------------------------------------------------------------
typedef struct
{
  int nEventType;
  
  int nTuneIndex;
  int nTuneType;
  
} PLAYERMSG;

void PostPlayerEvent( int evType, BYTE *pData = NULL, int nDataLen = 0 );
void PostManageEvent( int evType, BYTE *pData = NULL, int nDataLen = 0 );

// PlayerThread event handlers..
void HandlePlaySelected( void );
void HandlePlayStopTune( void );
void HandleStopTune( void );
void HandleResumeTune( void );
void HandlePauseTune( void );
void HandlePrevTune( void );
void HandleNextTune( void );
void HandlePrevSubtune( void );
void HandleNextSubtune( void );
void HandleModePressed( void );
void HandleSnapPressed( void );

// ManageThread event handlers..
void HandleLikeTune( void );
void HandleHateTune( void );
void HandleCreatePlayList( void );


#endif
