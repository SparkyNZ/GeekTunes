//
//  PaulPlayer.h
//  GeekTunes
//
//  Created by Paul Spark on 7/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef GeekTunes_PaulPlayer_h
#define GeekTunes_PaulPlayer_h

#import <AudioToolbox/AudioToolbox.h>
#include "Common.h"

//#include "sidplay2.h"
//#include "sidtune.h"
#include "resid.h"

enum
{
  SCREEN_SIMPLE = 0,
  SCREEN_ADVANCED
};

#define MAX_ARTIST_LEN 50
#define MAX_TUNE_LEN   100

//-----------------------------------------------------------------------------------------
// Type modes
//-----------------------------------------------------------------------------------------
enum
{
  TYPE_FAVOURITES1 = 0,
  TYPE_FAVOURITES2,
  TYPE_FAVOURITES3,
  TYPE_FAVOURITES4,
  TYPE_FAVOURITES5,
  TYPE_FAVOURITES6,
  TYPE_FAVOURITES7,
  TYPE_FAVOURITES8,
  TYPE_FAVOURITES9,
  TYPE_FAVOURITES10,
  TYPE_ALL,
  TYPE_LIKES,
  TYPE_MP3,
  TYPE_MOD_NEW,
  TYPE_MOD_OLD,
  TYPE_XM,
  TYPE_SID,
  TYPE_MOD_SID,
  
  MAX_TYPES
};


//-----------------------------------------------------------------------------------------
// Order modes
//-----------------------------------------------------------------------------------------
enum
{
  ORDER_RANDOM_ANY = 0,
  ORDER_RANDOM_WITHIN_ARTIST,
  ORDER_RANDOM_WITHIN_ALBUM,
  ORDER_SEQUENCE_WITHIN_ALBUM,
  ORDER_SEQUENCE,
  
  MAX_ORDERS
};

//-----------------------------------------------------------------------------------------
// Player modes
//-----------------------------------------------------------------------------------------
enum 
{
  MODE_NORMAL_PLAY = 0,
  
  MODE_FAVOURITES_1,
  MODE_FAVOURITES_2,
  MODE_FAVOURITES_3,
  MODE_FAVOURITES_4,
  MODE_FAVOURITES_5,
  MODE_FAVOURITES_6,
  MODE_FAVOURITES_7,
  MODE_FAVOURITES_8,
  MODE_FAVOURITES_9,
  MODE_FAVOURITES_10,
    
  MODE_RND_ALL,
  MODE_RND_LIKES,
  MODE_RND_MP3,
  MODE_RND_MOD_NEW,
  MODE_RND_MOD_OLD,
  MODE_RND_XM,
  MODE_RND_SID,
  MODE_RND_MOD_SID,
  
  // Snap modes only.. (not manual)
  MODE_RND_ARTIST,
  MODE_RND_ALBUM,
  MODE_SEQ_ARTIST,
    
  MODE_MAX_MODES
};

#define MAX_FAVOURITE_PLAYLISTS 10

#define MODE_FAVOURITES MODE_FAVOURITES_1
#define NUM_FAVOURITES (MODE_RND_ALL - MODE_FAVOURITES_1)

#define MODE_RND_FIRST MODE_RND_ALL
#define MODE_RND_LAST  MODE_RND_ALBUM

//-----------------------------------------------------------------------------------------
// Drill down list modes
//-----------------------------------------------------------------------------------------
enum
{
  //--- SEQ SECTION
  
  LIST_FAVOURITES_1 = 0,
  LIST_FAVOURITES_2,
  LIST_FAVOURITES_3,
  LIST_FAVOURITES_4,
  LIST_FAVOURITES_5,
  LIST_FAVOURITES_6,
  LIST_FAVOURITES_7,
  LIST_FAVOURITES_8,
  LIST_FAVOURITES_9,
  LIST_FAVOURITES_10,
  
  LIST_ALL_MP3,
  LIST_ALL_SID,
  LIST_ALL_MOD,
  LIST_ALL_MOD_NEW,
  LIST_ALL_MOD_OLD,
  LIST_ALL_LIKES,

  //--- RND SECION
  
  LIST_RND_ALL,
  LIST_RND_LIKES,
  LIST_RND_MP3,
  LIST_RND_MOD_NEW,
  LIST_RND_MOD_OLD,
  LIST_RND_XM,
  LIST_RND_SID,
  LIST_RND_MOD_SID,
  LIST_RND_ARTIST,
  LIST_RND_ALBUM,
  
  LIST_HATES,
  
  LIST_MAX_TYPES
};

#define LIST_RND_LAST LIST_RND_ALBUM

#define LIST_FAVOURITES LIST_FAVOURITES_1

#define NUM_LISTS_SEQ_SECTION 2
#define NUM_LISTS_LIB_SECTION 6
#define NUM_LISTS_RND_SECTION 10

//-----------------------------------------------------------------------------------------
// Like button behaviours
//-----------------------------------------------------------------------------------------
enum
{
  LIKE_BUTTON_INC_RATING = 0,
  LIKE_BUTTON_ADD_DEFAULT
};

extern sid2_model_t           g_SIDChipType;
extern int                    g_CurrentMode;
extern int                    g_CurrentType;
extern int                    g_CurrentOrder;
extern int                    g_CurrentArtistIndexPlaying;
extern int                    g_CurrentAlbumIndexPlaying;
extern int                    g_CurrentArtistIndexSelected;
extern int                    g_CurrentAlbumIndexSelected;
extern int                    g_CurrentTuneLibIndexPlaying;
extern int                    g_CurrentUnitTypePlaying;

extern int                    g_CurrentFavouritePlaylist;
extern BOOL                   g_DefaultPreferredFavouriteList;
extern int                    g_PreferredFavouriteList;
extern int                    g_LikeButtonBehaviour;
extern int                    g_NumFavouritePlaylists;

extern int                    g_IncludeRating;

extern AudioComponentInstance g_ToneUnit;
extern int                    g_UnitType;

extern BOOL   g_Stopped;

extern BYTE  *g_BigTuneBuffer;
extern ULONG  g_BigTuneAvailW;
extern ULONG  g_BigTunePlayed;

extern ULONG  g_BigTuneBufferMax;
extern ULONG  g_BigTuneUpdateNumSamples;
extern BOOL   g_BigTuneAvailStarted;
extern BOOL   g_WrapOccurred;
extern BOOL   g_WrapToZeroPending;
extern BOOL   g_UnderwriteOccurred;
extern BYTE   g_ByteSampleBuffer[ 32768 ];

extern int    g_Samples;
extern int    g_Channels;

extern double g_SampleRate;
extern float  g_BitScaleFactor;

extern char   g_txUnzipPath[];

extern int    g_PlayListIndex[ MODE_MAX_MODES ];

extern BOOL   g_LibHasSID;
extern BOOL   g_LibHasMOD;
extern BOOL   g_LibHasNewMOD;
extern BOOL   g_LibHasXM;

extern void MakeDocumentsPath( char *pszPath, char *pszFullPath );

extern BOOL IsZIPFile( char *pFile );
extern BOOL IsMODFile( char *pFile );
extern BOOL IsSIDFile( char *pFile );
extern BOOL IsXMFile( char *pFile );
extern BOOL IsNewMODFile( char *pFile );
extern BOOL IsOldMODFile( char *pFile );

extern void HVSCImport( void );
extern void AddZIPToLibrary( char *pZipFile );
extern void AddMODToLibrary( char *pszTitle, char *pszArtist, char *pszAlbum, char *pszPath );
extern void AddSIDToLibrary( char *pszTitle, char *pszArtist, char *pszAlbum, char *pszPath );
extern int  FindTuneMatch( char *pszTune );
extern BOOL GetTuneInfo( int nIndex, char *pTune, char *pArtist, char *pAlbum, char *pURL, int *pnType, int *pnArtistIndex, int *pnAlbumIndex );
extern void GetModeName( int nMode, char *pMode );
extern BOOL IsRandomMode( int nMode );
extern void GetListName( int nList, char *pName );
extern void ExportPlayList( int nMode );
extern void ExportActiveFavourites( void );

extern void ExportRatings( void );
extern void GetHashForTuneIndexInLib( char *txHash, int nTuneIndexInLib );

extern void ToneInterruptionListener( void *inClientData, UInt32 inInterruptionState );
extern void SetupAudioSession( void );
extern void ShutdownAudioSession( void );
extern void ToneUnitStop( void );
extern void ToneUnitPlay( int nType );
extern void CreateToneUnit( int nType );
extern void PaulPlayerInitialise( void );

extern void SaveFavouritePlaylistNames( void );
extern void LoadSettings( void );
extern void SaveSettings( void );

extern void CreatePlaylistIfEmpty( void );

extern void AddToPlayList( int nMode, int nTuneIndexInLib );
extern void AddToCurrentPlayList( int nTuneIndexInLib );
extern void SelectCurrentPlayList( int nMode );
extern void CreatePlaylist( void );
extern void DeletePlaylists( void );
extern void ImportPlaylists( void );
extern void PlaylistRandomLikes( void );
extern void CreateSequencePlaylistForArtist( void );
extern void CreateSequencePlaylistForAlbum( void );
extern void CreateRandomPlaylistForAlbum( void );
extern void CreateRandomPlaylistForArtist( void );
extern BOOL TuneInFavourites( int nTuneIndexInLib );
extern void LoadFavouritePlaylistNames( void );
extern int  DrillDownModeToUnitType( int nDrillDownMode );

extern void HandleUnhateAll( void );
extern void HandleDeleteAllHates( void );
extern void HandleSafekeepLikes( void );
extern void HandleSIDChipToggle( void );
extern void HandleAddLikesToPlaylist( void );

extern void SetMode( int nMode );

#endif
