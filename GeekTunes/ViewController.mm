//
//  ViewController.m
//  GeekTunes
//
//  Created by Paul Spark on 2/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define BOOL_DEFINED

#include "AllIncludes.h"

extern TVManagePlaylists       *g_tvManage;

UIImageView *g_vcImageView        = nil;
UIImageView *g_ImgViewStatusFader = nil;
UITapGestureRecognizer    *g_TapLabelRecognizer[6] = { nil, nil, nil, nil, nil, nil };

Vector g_vPlayerEventQueue;
Vector g_vManageEventQueue;

dispatch_queue_t backgroundQueue;
dispatch_queue_t g_PlayerThreadQueue;
dispatch_queue_t g_ManageThreadQueue;

pthread_mutex_t  g_PlayerThreadQMutex;
pthread_mutex_t  g_ManageThreadQMutex;

BOOL g_ManageThreadBusy = FALSE;

extern int  g_MP3Count;
extern BOOL g_MP3CountChanged;

char g_ProgressKey;


UILabel *g_StatusFaderTuneLabel   = nil;
UILabel *g_StatusFaderArtistLabel = nil;
UILabel *g_StatusFaderAlbumLabel  = nil;


char g_txStatusTune   [ 1024 ] = { 0 };
char g_txStatusArtist [ 1024 ] = { 0 };
char g_txStatusArtist2[ 1024 ] = { 0 };
char g_txStatusAlbum  [ 1024 ] = { 0 };
char g_txStatusAlbum2 [ 1024 ] = { 0 };

NSTimer *g_Timer    = nil;
int      g_UnitType = UNIT_MP3;

float    g_ButInset  = 1;
float    g_ButSpace  = 10.0;
float    g_ButHeight = 40.0;
float    g_ButWidth  = 145;
float    g_StatusLabelWidth  = 70;
float    g_StatusLabelHeight = 20;
int      g_MaxPixelHeight  = 480;
int      g_MaxPixelWidth   = 320;
float    g_StatusBarHeight = 50.0;
int      g_xPlayButton = -1;
int      g_yPlayButton = -1;


int      g_MainScreen = SCREEN_SIMPLE;


UINavigationController *g_navController      = nil;
ViewController         *g_MainViewController = nil;
UIAlertView            *g_ProgressAlertView  = nil;
UIProgressView         *g_ProgressBar        = nil;
UILabel                *g_ProgressViewText   = nil;
int                     g_ProgressStep       = 0;
int                     g_ProgressSteps      = 0;
TVModes                *g_ModesView          = nil;
TVSettings             *g_SettingsView       = nil;
extern ContainerVC     *g_ContainerVC;

UIImage                *g_ModeButtonImage   = nil;
UIImage                *g_OrderButtonImage  = nil;

UIImage                *g_ImageSkipPrev  = nil;
UIImage                *g_ImageSkipNext  = nil;
UIImage                *g_ImageSkipPrev2 = nil;
UIImage                *g_ImageSkipNext2 = nil;
UIImage                *g_ImagePlayWhite = nil;
UIImage                *g_ImageStop      = nil;
UIImage                *g_ImageSubPrev   = nil;
UIImage                *g_ImageSubNext   = nil;
UIImage                *g_ImageLikeTune  = nil;
UIImage                *g_ImageHateTune  = nil;
UIImage                *g_ImageFolder    = nil;
UIImage                *g_ImageSettings  = nil;
UIImage                *g_ImagePrevSID   = nil;
UIImage                *g_ImageNextSID   = nil;
UIImage                *g_ImageBackspace = nil;
UIImage                *g_ImageRandom    = nil;
UIImage                *g_ImageSequence  = nil;
UIImage                *g_ImageMP3       = nil;
UIImage                *g_ImageSID       = nil;
UIImage                *g_ImageMod       = nil;
UIImage                *g_ImageModSID    = nil;
UIImage                *g_ImageAllTypes  = nil;


//-----------------------------------------------------------------------------------------
// Vectors
//-----------------------------------------------------------------------------------------

#define INIT_VECTOR_NODES 5000

Vector g_vTunesName( INIT_VECTOR_NODES );
Vector g_vTunesType( INIT_VECTOR_NODES );
Vector g_vTunesPath( INIT_VECTOR_NODES );
Vector g_vTunesTrack( INIT_VECTOR_NODES );

// PDS: Ratings are as follows:
//  
// -1 - Don't like
//  0 - Unrated
//  1 - Like
//  2-  Like twice (etc)s
Vector g_vTunesRating;

Vector g_vTunesArtistIndex( INIT_VECTOR_NODES );
Vector g_vTunesAlbumIndex( INIT_VECTOR_NODES );
Vector g_vAlbumArtistIndex( INIT_VECTOR_NODES );
Vector g_vArtist( INIT_VECTOR_NODES );
Vector g_vAlbum( INIT_VECTOR_NODES );

Vector g_vTunesRatingMD5( INIT_VECTOR_NODES );
Vector g_vPlayListMD5[ MODE_MAX_MODES ];


extern Vector g_vTuneIndicesForAlbum;
extern Vector g_vTunesForArtist;
extern Vector g_vTuneIndicesForArtist;

Vector   g_vPlayList[ MODE_MAX_MODES ];
Vector  *g_pvCurrPlayList    = &g_vPlayList[ 0 ];
Vector  *g_pvCurrPlayListMD5 = &g_vPlayListMD5[ 0 ];
Vector   g_vPlayListExpPath;
Vector   g_vPlayListExpPathMD5;
Vector   g_vSIDSubTuneLengths;

// PDS: We can have multiple favourite playlists.. the default will be the first.
int      g_CurrentFavouritePlaylist = MODE_FAVOURITES_1;
int      g_PreferredFavouriteList   = MODE_FAVOURITES_1;
int      g_LikeButtonBehaviour      = LIKE_BUTTON_INC_RATING;

int      g_NumFavouritePlaylists = 1;
Vector   g_vPlaylistsActive;

int      g_CurrentSIDSecsLong    = 0;
long     g_CurrentSIDSecsStart   = 0;
int      g_CurrentSIDNumSubTunes = 0;


int      g_PlayListIndex[ MODE_MAX_MODES ];
char     g_txUnzipPath[ MAX_PATH ];

UILabel      *g_StatusTitle1    = nil;
UILabel      *g_StatusTitle2    = nil;
UILabel      *g_StatusTitle3    = nil;
MarqueeLabel *g_StatusScroller1 = nil;
MarqueeLabel *g_StatusScroller2 = nil;
MarqueeLabel *g_StatusScroller3 = nil;

UIButton *g_ModeButton        = nil;
UIButton *g_PlayStopButton    = nil;
UIButton *g_HateButton        = nil;
UIButton *g_UpButton          = nil;
UIButton *g_SettingsButton    = nil;
UIButton *g_SeqButton         = nil;
UIButton *g_ListButton        = nil;
UIButton *g_DownButton        = nil;
UIButton *g_LikeButton        = nil;
UIButton *g_SubUpButton       = nil;
UIButton *g_SubDownButton     = nil;

UILabel  *g_ModeSubLabel  = nil;
UILabel  *g_OrderSubLabel = nil;
int       g_CurrentMode  = MODE_RND_MP3;
int       g_CurrentType  = TYPE_MP3;
int       g_CurrentOrder = ORDER_RANDOM_ANY;

UIImage  *g_ImageLike = nil;
UIImage  *g_ImageHate = nil;
UIImage  *g_ImagePlay = nil;
UIImage  *g_ImageHeartRed   = nil;
UIImage  *g_ImageHeartGreen = nil;
UIImage  *g_ImageHeartGrey  = nil;
UIImage  *g_ImageClipboardPurple = nil;
UIImage  *g_ImageClipboardGrey   = nil;
UIImage  *g_ImageMinusRed = nil;
UIImage  *g_ImageDice     = nil;
UIImage  *g_ImagePencil   = nil;
UIImage  *g_ImageRecycle  = nil;
UIImage  *g_ImageTrashcan = nil;


// PDS: Playing values are for what is playing..
int       g_CurrentArtistIndexPlaying  = -1;
int       g_CurrentAlbumIndexPlaying   = -1;

int       g_RndArtistIndex             = -1;
int       g_SeqArtistIndex             = -1;
int       g_RndAlbumIndex              = -1;

int       g_ModeBeforeSnap             = MODE_NORMAL_PLAY;
BOOL      g_SnapMode                   = FALSE;


// PDS: Selected values are for what has been selected (or is to be selected) in the drill down lists..
int       g_CurrentArtistIndexSelected = -1;
int       g_CurrentAlbumIndexSelected  = -1;
int       g_CurrentTuneLibIndexPlaying = -1;
int       g_CurrentUnitTypePlaying     = -1;

Vector    g_vModeText;

Vector    g_vTypeText;
Vector    g_vOrderText;

@implementation ViewController

@synthesize navigationController = _navigationController;

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


//-----------------------------------------------------------------------------------------
// PostManageEvent()
//-----------------------------------------------------------------------------------------
void PostManageEvent( int evType, BYTE *pData, int nDataLen )
{
  // PDS: If a task is still underway, ignore any further requests..
  if( g_ManageThreadBusy )
    return;
  
  pthread_mutex_lock( &g_ManageThreadQMutex );

  PLAYERMSG *pMsg = (PLAYERMSG *) malloc( sizeof( PLAYERMSG ) );
  
  pMsg->nEventType = evType;
  
  g_vManageEventQueue.addElement( (void*) pMsg );
  
  pthread_mutex_unlock( &g_ManageThreadQMutex );
}

//-----------------------------------------------------------------------------------------
// timerCallback
//-----------------------------------------------------------------------------------------
-(void) timerCallback
{
  // PDS: Perhaps this can signal a condition.. otherwise we could post heaps of events that
  //      may never get posted if something takes a while..

  g_TimerCallback = TRUE;
  
  // PDS: Kick the queue's condition.. if no events, we'll proces an evTIMER_CALLBACK
  [g_QueueEmptyCondition lock];
//  [g_QueueEmptyCondition wait];
  [g_QueueEmptyCondition signal];
  [g_QueueEmptyCondition unlock];
  
  //PostPlayerEvent( evTIMER_CALLBACK );
}

//-----------------------------------------------------------------------------------------
// restartTimer
//-----------------------------------------------------------------------------------------
-(void) restartTimer
{
  if( g_Timer )
  {
    [g_Timer invalidate];
    g_Timer = nil;
  }
  
  // PDS: Re-establish timer..
  g_Timer = [NSTimer scheduledTimerWithTimeInterval: 0.2
                                             target: self
                                           selector: @selector( timerCallback )
                                           userInfo: nil
                                            repeats: YES];  
}

//-----------------------------------------------------------------------------------------
// updateStatus
//-----------------------------------------------------------------------------------------
-(void) updateStatus: (NSString *) nsText
{
  return;
  
  static UILabel *label = NULL;
  
  if( ! label )
  {
    label = [UILabel alloc];
    [label initWithFrame: CGRectMake( 0.0, 400.0, g_MaxPixelWidth, 20.0 ) ];
    
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment   = UITextAlignmentCenter; // UITextAlignmentCenter, UITextAlignmentLeft
    label.textColor       = [UIColor redColor];
  }
    
  [label setText: nsText];
  [self.view addSubview: label];  
}

//-----------------------------------------------------------------------------------------
// AddToPlaylistIfFound
//-----------------------------------------------------------------------------------------
void AddToPlaylistIfFound( Vector *pvPlaylist, char *pszTitlePattern )
{
  int nTuneIndex;

  nTuneIndex = FindTuneMatch( pszTitlePattern );

  LogDebugf( "FindMatch[%s] -> index %d", pszTitlePattern, nTuneIndex );
  
  if( nTuneIndex >= 0 )
    pvPlaylist->addElement( nTuneIndex );
}

//-----------------------------------------------------------------------------------------
// FindTune
//-----------------------------------------------------------------------------------------
-(void) FindTune
{
  LogDebugf( "Deleting playlists.." );
 // DeletePlaylists();
}

//-----------------------------------------------------------------------------------------
// GetHashForTuneIndexInLib()
//-----------------------------------------------------------------------------------------
void GetHashForTuneIndexInLib( char *txHash, int nTuneIndexInLib )
{  
  int   nArtistIndex = g_vTunesArtistIndex.elementIntAt( nTuneIndexInLib );
  
  txHash[ 0 ] = 0;
  
  if( nArtistIndex < 0 )
    return;
  
  char *pszArtist    = g_vArtist.elementStrAt( nArtistIndex );
  char *pszTune      = g_vTunesName.elementStrAt( nTuneIndexInLib );
  
  BYTE   abHash[ 16 ];
  
  memset( txHash, 0, MD5_ASC_SIZE  + 1 );
  
  char txTmp[ 500 ];
      
  memset( txTmp, ' ', sizeof( txTmp ) );
  memcpy( txTmp, pszTune, strlen( pszTune ) );
  
  strcpy( &txTmp[ MAX_TUNE_LEN + 1 ], pszArtist );
  
  // PDS: MD5 hash..
  md5( (const BYTE *) txTmp, sizeof( txTmp ), abHash );
  FormatHash( abHash, txHash );
  
  //LogDebugf( "[%s]", txTmp );
  //LogDebugf( "Hash: %s", txHash );
}

//-----------------------------------------------------------------------------------------
// HandleLikeTune()
//-----------------------------------------------------------------------------------------
void HandleLikeTune( void )
{
  if( g_CurrentTuneLibIndexPlaying < 0 )
    return;
  
  char txHash[ MD5_ASC_SIZE + 1 ];
  
  int nTuneIndexInLib = g_CurrentTuneLibIndexPlaying;
  int nOldRating      = g_vTunesRating.elementIntAt( nTuneIndexInLib );
  
  GetHashForTuneIndexInLib( txHash, nTuneIndexInLib );
  
  LogDebugf( "Tune (index: %d) OLD rating: %d", nTuneIndexInLib, nOldRating );
  
  if( g_LikeButtonBehaviour == LIKE_BUTTON_INC_RATING )
  {
    g_vTunesRating.setElementAt( nTuneIndexInLib, nOldRating + 1 );
    
    g_vTunesRatingMD5.addUnique( txHash );
    LogDebugf( "Tune (index: %d) NEW rating: %d", nTuneIndexInLib, nOldRating + 1);
  }
  
  if( g_LikeButtonBehaviour == LIKE_BUTTON_ADD_DEFAULT )
  {
    if( nOldRating <= 0 )
    {
      g_vTunesRating.setElementAt( nTuneIndexInLib, 1 );
      g_vTunesRatingMD5.addUnique( txHash );
    }
    
    int nFavIndex = g_vPlayList[ g_PreferredFavouriteList ].indexOf( nTuneIndexInLib );
    
    if( nFavIndex < 0 )
    {
      LogDebugf( "Tune (index: %d) Added to Default Favourites", nTuneIndexInLib );
      
      // PDS: Add to favourites if not already present..
      g_vPlayListMD5[ g_PreferredFavouriteList ].addUnique( txHash );

      g_vPlayList[ g_PreferredFavouriteList ].addElement( nTuneIndexInLib );
      ExportPlayList( g_PreferredFavouriteList );
    }
  }
    
  ExportRatings();
  
  // PDS: Update the random likes play list as well.. This will also do the export!
  PlaylistRandomLikes();
}

//-----------------------------------------------------------------------------------------
// HandleHateTune()
//-----------------------------------------------------------------------------------------
void HandleHateTune( void )
{
  LogDebugf( "HATE TUNE: g_CurrentTuneLibIndexPlaying: %d", g_CurrentTuneLibIndexPlaying );
  
  if( g_CurrentTuneLibIndexPlaying < 0 )
    return;
 
  char txHash[ MD5_ASC_SIZE + 1 ];
  int  nTuneIndexInLib = g_CurrentTuneLibIndexPlaying;
  
  int  nOldRating = g_vTunesRating.elementIntAt( nTuneIndexInLib );
  
  
  GetHashForTuneIndexInLib( txHash, nTuneIndexInLib );
  
  g_vTunesRating.setElementAt( nTuneIndexInLib, nOldRating - 1 );
  
  if( nOldRating - 1 <= 0 )
    g_vTunesRatingMD5.removeUniqueElement( txHash );
  
  int nFavIndex = g_vPlayList[ g_PreferredFavouriteList ].indexOf( nTuneIndexInLib );
  
  // PDS: If tune is in favourites and you now hate it, lose it..
  if( nFavIndex >= 0 )
  {
    g_vPlayList   [ g_PreferredFavouriteList ].removeElementAt( nFavIndex );
    g_vPlayListMD5[ g_PreferredFavouriteList ].removeUniqueElement( txHash );
    ExportPlayList( g_PreferredFavouriteList );
  }
  
  // PDS: Skip it if you hate it..
  PostPlayerEvent( evNEXT_TUNE );
  
  if( g_Stopped )
    PostPlayerEvent( evPLAY_STOP );
  
  ExportRatings();
}

//-----------------------------------------------------------------------------------------
// LikeTune
//-----------------------------------------------------------------------------------------
-(void) LikeTune
{
  PostManageEvent( evLIKE_TUNE );
}

//-----------------------------------------------------------------------------------------
// HateTune
//-----------------------------------------------------------------------------------------
-(void) HateTune
{
  PostManageEvent( evHATE_TUNE );
}

//-----------------------------------------------------------------------------------------
// FindFirstTune()
//
// PDS: Returns index to first tune we want to hear in current playlist
//-----------------------------------------------------------------------------------------
int FindFirstTune( void )
{
  // PDS: Start at the beginning, find first tune liked..
  g_PlayListIndex[ g_CurrentMode ] = 0;
  
  int nTuneIndexInLib;
  int nTuneIndexInPlaylist;
  
  if( g_pvCurrPlayList->elementCount() < 1 )
    return -1;
  
  for( ;; )
  {
    nTuneIndexInPlaylist = g_PlayListIndex[ g_CurrentMode ];
    
    nTuneIndexInLib = g_pvCurrPlayList->elementIntAt( nTuneIndexInPlaylist );
    
    // PDS: Skip crappy tunes.. accept if rating it unheard or positive..
    if( g_vTunesRating.elementIntAt( nTuneIndexInLib ) >= 0 )
      return nTuneIndexInPlaylist;

    if( nTuneIndexInPlaylist < g_pvCurrPlayList->elementCount() - 1 )
      g_PlayListIndex[ g_CurrentMode ] ++;
    else
      break;
  }
  
  return 0;
}

//-----------------------------------------------------------------------------------------
// CreateRandomArtistOrAlbumPlaylist()
//
// PDS: If RND ALBUM or RND ARTIST is selected and NEXT/PREV pressed, then generate a new
//      'normal' playlist if need be..
//-----------------------------------------------------------------------------------------
void CreateRandomArtistOrAlbumPlaylist( void )
{
  if( g_CurrentMode == MODE_SEQ_ARTIST )
  {
    // PDS: If sequence artist same as the one playing, nothing new to do..
    if( g_SeqArtistIndex == g_CurrentArtistIndexPlaying )
    {
      LogDebugf( "** NO CHANGE: %d - NOT CREATING LIST", g_SeqArtistIndex );
      return;
    }
    
    g_SeqArtistIndex = g_CurrentArtistIndexPlaying;
    
    LogDebugf( "Creating SEQ ART list" );
    
    CreateSequencePlaylistForArtist();
  }
  else
  if( g_CurrentMode == MODE_RND_ARTIST )
  {
    // PDS: If random artist same as the one playing, nothing new to do..
    if( g_RndArtistIndex == g_CurrentArtistIndexPlaying )
      return;
    
    g_RndArtistIndex = g_CurrentArtistIndexPlaying;

    LogDebugf( "Creating RND ART list (%d / %s)", g_RndArtistIndex, g_vArtist.elementStrAt( g_RndArtistIndex ) );
    
    CreateRandomPlaylistForArtist();
  }
  else
  if( g_CurrentMode == MODE_RND_ALBUM )
  {
    // PDS: If random album same as the one playing, nothing new to do..
    if( g_RndAlbumIndex == g_CurrentAlbumIndexPlaying )
      return;
    
    LogDebugf( "Creating RND ALBUM list" );
    
    g_RndAlbumIndex = g_CurrentAlbumIndexPlaying;
    
    CreateRandomPlaylistForAlbum();
  }
}

//--------------------------------------------------------------------------------------------
// HandleSIDChipToggle()
//--------------------------------------------------------------------------------------------
void HandleSIDChipToggle( void )
{
  if( g_UnitType == UNIT_SID )
  {
    g_SIDPlay->stop();
    
    // PDS: We need to reset the buffers or current sub tune will keep playing for ages..
    PaulPlayerInitialise();
  }
  
  sid2_config_t cfg = g_SIDPlay->config();
  
  cfg.sidDefault	  = g_SIDChipType;
  cfg.sidModel      = cfg.sidDefault;
  
  int rc = g_SIDPlay->config( cfg );
  
  if(rc != 0)
    LogDebugf( "configure error: %s\n", g_SIDPlay->error() );
  
  SaveSettings();
}

//-----------------------------------------------------------------------------------------
// HandlePrevTune()
//-----------------------------------------------------------------------------------------
void HandlePrevTune( void )
{
  // PDS: Create a random artist or album playlist if required..
  CreateRandomArtistOrAlbumPlaylist();

  // PDS: Start playing if no current index..
  if( g_PlayListIndex[ g_CurrentMode ] == -1 )
  {
    g_PlayListIndex[ g_CurrentMode ] = FindFirstTune();
    
    HandlePlaySelected();
    return;
  }
  
  int nTuneIndexInPlaylist;
  int nTuneIndexInLib;
  
  for( ;; )
  {
    if( g_PlayListIndex[ g_CurrentMode ] > 0 )
    {
      g_PlayListIndex[ g_CurrentMode ] --;
      
      nTuneIndexInPlaylist = g_PlayListIndex[ g_CurrentMode ];
      nTuneIndexInLib      = g_pvCurrPlayList->elementIntAt( nTuneIndexInPlaylist );
      
      // PDS: Skip crappy tunes.. accept if rating it unheard or positive..
      if( g_vTunesRating.elementIntAt( nTuneIndexInLib ) >= 0 )
      {
        break;
      }
    }
    else
    {
      g_PlayListIndex[ g_CurrentMode ] = FindFirstTune();
      break;
    }
  }
  
  HandlePlaySelected();
}

//-----------------------------------------------------------------------------------------
// HandleNextTune()
//-----------------------------------------------------------------------------------------
void HandleNextTune( void )
{
  LogDebugf( "NEXT TUNE: g_CurrentMode: %d  g_PlayListIndex: %d", g_CurrentMode, g_PlayListIndex[ g_CurrentMode ] );
  
  // PDS: Create a random artist or album playlist if required..
  CreateRandomArtistOrAlbumPlaylist();
  
  // PDS: Start playing if no current index.. or if only one tune in playlist..
  if( ( g_PlayListIndex[ g_CurrentMode ] == -1 ) ||
      ( g_pvCurrPlayList->elementCount() < 2   ) )
  {
    LogDebugf( "## FIRST BAIL");
    g_PlayListIndex[ g_CurrentMode ] = FindFirstTune();
    HandlePlaySelected();
    return;
  }
  
  int nTuneIndexInPlaylist;
  int nTuneIndexInLib;
  
  for( ;; )
  {
    if( g_PlayListIndex[ g_CurrentMode ] < g_pvCurrPlayList->elementCount() - 1 )
    {
      g_PlayListIndex[ g_CurrentMode ] ++;
      

      LogDebugf( "HandleNextTune(), SKIP.." );
      
      nTuneIndexInPlaylist = g_PlayListIndex[ g_CurrentMode ];
      nTuneIndexInLib      = g_pvCurrPlayList->elementIntAt( nTuneIndexInPlaylist );
      
      // PDS: Skip crappy tunes.. accept if rating it unheard or positive..
      if( g_vTunesRating.elementIntAt( nTuneIndexInLib ) >= 0 )
        break;
    }
    else
    {
      // PDS: Stop when we get to the end.. may be half an album list. Don't want to restart
      HandleStopTune();
      return;
    }
  }
  
  
  LogDebugf( "  HandleNextTune(), g_CurrentMode: %d  PlaylistIndex: %d", g_CurrentMode, g_PlayListIndex[ g_CurrentMode ] );

  HandlePlaySelected();
}

//-----------------------------------------------------------------------------------------
// HandlePrevSubtune()
//-----------------------------------------------------------------------------------------
void HandlePrevSubtune( void )
{
  if( g_UnitType != UNIT_SID )
    return;
  
  if( g_SIDSubTune > 0 )
  {
    g_SIDPlay->stop();
    
    // PDS: We need to reset the buffers or current sub tune will keep playing for ages..
    PaulPlayerInitialise();
    
    g_SIDSubTune --;
    g_SIDTune->selectSong( g_SIDSubTune + 1 );
    g_SIDPlay->load( g_SIDTune );
    
    g_CurrentSIDSecsStart = SecondsNow();
    
    if( g_vSIDSubTuneLengths.elementCount() > 0 )
      g_CurrentSIDSecsLong = g_vSIDSubTuneLengths.elementIntAt( g_SIDSubTune );
    
    g_Stopped = FALSE;
    
    // PDS: Update buttons - need to change to "STOP" if now playing..
    // PDS: Do GUI updates - which are needed on the main thread.. However, I DON'T want to do this asynchonously!!
    dispatch_sync( dispatch_get_main_queue(), ^
    {
      // PDS: Show what we're playing..
      [g_MainViewController SetStatusInfo: TRUE];
                    
      // PDS: Update buttons to reflect features available for current tune type (eg. SID subtunes, MOD channel monotizing etc..)
      [g_PlayStopButton setImage: g_ImageStop forState: UIControlStateNormal];
      [g_MainViewController UpdatePlayStopButton];
    } );
  }
}

//-----------------------------------------------------------------------------------------
// HandleNextSubtune()
//-----------------------------------------------------------------------------------------
void HandleNextSubtune( void )
{
  if( g_UnitType != UNIT_SID )
    return;
  
  if( g_SIDSubTune < g_CurrentSIDNumSubTunes - 1 )
  {
    g_SIDPlay->stop();
    
    // PDS: We need to reset the buffers or current sub tune will keep playing for ages..
    PaulPlayerInitialise();
    
    g_SIDSubTune ++;
    g_SIDTune->selectSong( g_SIDSubTune + 1 );
    g_SIDPlay->load( g_SIDTune );
    
    g_CurrentSIDSecsStart = SecondsNow();
    
    if( g_vSIDSubTuneLengths.elementCount() > 0 )
      g_CurrentSIDSecsLong = g_vSIDSubTuneLengths.elementIntAt( g_SIDSubTune );
    
    g_Stopped = FALSE;
    
    // PDS: Update buttons - need to change to "STOP" if now playing..
    // PDS: Do GUI updates - which are needed on the main thread.. However, I DON'T want to do this asynchonously!!
    dispatch_sync( dispatch_get_main_queue(), ^
    {
      // PDS: Show what we're playing..
      [g_MainViewController SetStatusInfo: TRUE];
                    
      // PDS: Update buttons to reflect features available for current tune type (eg. SID subtunes, MOD channel monotizing etc..)
      // [g_MainViewController setupPlayerButtons];
      [g_PlayStopButton setImage: g_ImageStop forState: UIControlStateNormal];
      [g_MainViewController UpdatePlayStopButton];
      
    } );
  }
}

//-----------------------------------------------------------------------------------------
// PrevTune
//-----------------------------------------------------------------------------------------
-(void) PrevTune
{
  PostPlayerEvent( evPREV_TUNE );
}

//-----------------------------------------------------------------------------------------
// NextTune
//-----------------------------------------------------------------------------------------
-(void) NextTune
{
  PostPlayerEvent( evNEXT_TUNE );
}

//-----------------------------------------------------------------------------------------
// PrevSubTune
//-----------------------------------------------------------------------------------------
-(void) PrevSubTune
{
  PostPlayerEvent( evPREV_SUBTUNE );
}

//-----------------------------------------------------------------------------------------
// NextSubTune
//-----------------------------------------------------------------------------------------
-(void) NextSubTune
{
  LogDebugf( "Post NEXT_SUBTUNE" );
  PostPlayerEvent( evNEXT_SUBTUNE );
}

//-----------------------------------------------------------------------------------------
// tuneSelected
//
// delegate for tune selection in various drill down lists
//-----------------------------------------------------------------------------------------
-(void) tuneSelected: (int) nTuneIndexInLib
{
  SetMode( MODE_NORMAL_PLAY );
  
  SelectCurrentPlayList( g_CurrentMode );
  
  g_pvCurrPlayList->removeAll();
  g_pvCurrPlayList->addElement( nTuneIndexInLib );
  
  g_PlayListIndex[ g_CurrentMode ] = 0;
  
  [self PlaySelected];
}

//-----------------------------------------------------------------------------------------
// tuneSelected, continueArtist
//
// delegate for tune selection where we should continue the artist's tunes..
//-----------------------------------------------------------------------------------------
-(void) tuneSelected: (int) nTuneIndexInLib continueArtist: (int) nArtistIndex
{
  SetMode( MODE_NORMAL_PLAY );
  
  SelectCurrentPlayList( g_CurrentMode );
  
  g_pvCurrPlayList->removeAll();
  
  int nStart = g_vTuneIndicesForArtist.indexOf( nTuneIndexInLib );
  
  LogDebugf( "Index of 1st selected tune for artist bundle: %d LibIndex: %d  (Artist: %d)", nStart, nTuneIndexInLib, nArtistIndex );
  
  if( nStart >= 0 )
  {
    // PDS: Now add the rest of the artists' tunes..
    for( int i = nStart; i < g_vTuneIndicesForArtist.elementCount(); i ++ )
    {
      nTuneIndexInLib = g_vTuneIndicesForArtist.elementIntAt( i );
      
      LogDebugf( " Adding LibIndex: %d", nTuneIndexInLib );
      
      AddToCurrentPlayList( nTuneIndexInLib );
    }
  }
  else
  {
    // PDS: If no artist found (e.g. SID/MOD) then just play the tune and nothing else afterwards..
    LogDebugf( " Adding LibIndex: %d (1 tune only)", nTuneIndexInLib );
    
    AddToCurrentPlayList( nTuneIndexInLib );
  }
  
  g_PlayListIndex[ g_CurrentMode ] = 0;

  [self PlaySelected];
}

//-----------------------------------------------------------------------------------------
// tuneSelectedInAlbum
//
// This plays selected tune in album and adds the remaing album tracks to the normal play list
//-----------------------------------------------------------------------------------------
-(void) tuneSelectedInAlbum: (int) nTuneIndexInLib inAlbum: (int) nAlbum
{
  SetMode( MODE_NORMAL_PLAY );
  
  SelectCurrentPlayList( g_CurrentMode );
  
  g_pvCurrPlayList->removeAll();
  
  BOOL fAddTunes = FALSE;
  
  // PDS: Now add the remaining tunes in the album..
  for( int i = 0; i < g_vTuneIndicesForAlbum.elementCount(); i ++ )
  {
    if( ! fAddTunes )
    {
      if( g_vTuneIndicesForAlbum.elementIntAt( i ) == nTuneIndexInLib )
        fAddTunes = TRUE;
    }
    
    if( fAddTunes )
    {
      nTuneIndexInLib = g_vTuneIndicesForAlbum.elementIntAt( i );
      
      AddToCurrentPlayList( nTuneIndexInLib );
    }
  }
  
  g_PlayListIndex[ g_CurrentMode ] = 0;
  
  [self PlaySelected];
  
}

//-----------------------------------------------------------------------------------------
// tuneSelectedInPlayList
//
// delegate for tune selection in various drill down lists - this one selects a tune witin
// a particular playlist and sets the current playlist index.
//-----------------------------------------------------------------------------------------
-(void) tuneSelectedInPlayList: (int) nTuneIndex inPlayList: (int) nPlayList
{
  LogDebugf( "TuneSelected in playlist %d, index %d", nPlayList, nTuneIndex );
  
  SetMode( nPlayList );
  
  SelectCurrentPlayList( g_CurrentMode );

  g_PlayListIndex[ g_CurrentMode ] = nTuneIndex;
  
  // PDS: Reflect any change to the current playlist mode on the mode button..
  UpdateTypeAndOrderSubLabel();
  
  [self PlaySelected];
}

//-----------------------------------------------------------------------------------------
// notificationReceived 
//-----------------------------------------------------------------------------------------
-(void) setObserver 
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector( notificationReceived: ) 
                                               name:@"DismissModalView"
                                             object:nil];
}

//-----------------------------------------------------------------------------------------
// notificationReceived 
//-----------------------------------------------------------------------------------------
-(void) notificationReceived:(NSNotification *)notification 
{
  if ([[notification name] isEqualToString:@"DismissModalView"]) 
  {
    [self dismissModalViewControllerAnimated:YES];
  }
}

//-----------------------------------------------------------------------------------------
// dealloc 
//-----------------------------------------------------------------------------------------
-(void) dealloc 
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // other objects
}

//-----------------------------------------------------------------------------------------
// IsZIPFile() 
//-----------------------------------------------------------------------------------------
BOOL IsZIPFile( char *pFile )
{
  if( stristr( pFile, ".zip" ) )
     return TRUE;

  if( stristr( pFile, ".gzip" ) )
    return TRUE;
  
  //if( stristr( pFile, ".lha" ) )
    //return TRUE;  
  
  return FALSE;  
}

//-----------------------------------------------------------------------------------------
// StartsOrEndsWith()
//-----------------------------------------------------------------------------------------
BOOL StartsOrEndsWith( char *pString, char *pSub )
{
  int nSubLen = strlen( pSub );
  int nStrLen = strlen( pString );
  
  if( nStrLen < nSubLen )
    return FALSE;
  
  if( _strnicmp( pString, pSub, nSubLen ) == 0 )
    return TRUE;

  if( _strnicmp( &pString[ nStrLen - nSubLen ], pSub, nSubLen ) == 0 )
    return TRUE;
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// StartsWith()
//-----------------------------------------------------------------------------------------
BOOL StartsWith( char *pString, char *pSub )
{
  int nSubLen = strlen( pSub );
  int nStrLen = strlen( pString );
  
  if( nStrLen < nSubLen )
    return FALSE;
  
  if( _strnicmp( pString, pSub, nSubLen ) == 0 )
    return TRUE;
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// EndsWith()
//-----------------------------------------------------------------------------------------
BOOL EndsWith( char *pString, char *pSub )
{
  int nSubLen = strlen( pSub );
  int nStrLen = strlen( pString );
  
  if( nStrLen < nSubLen )
    return FALSE;
  
  if( _strnicmp( &pString[ nStrLen - nSubLen ], pSub, nSubLen ) == 0 )
    return TRUE;
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// EndsWithOrZip()
//-----------------------------------------------------------------------------------------
BOOL EndsWithOrZip( char *pString, char *pSub )
{
  if( EndsWith( pString, pSub ) )
    return TRUE;
  
  char txZipExt[ 64 ];
  strcpy( txZipExt, pSub );
  strcat( txZipExt, ".zip" );
  
  return EndsWith( pString, txZipExt );
}

//-----------------------------------------------------------------------------------------
// IsNewMODFile()
//-----------------------------------------------------------------------------------------
BOOL IsNewMODFile( char *pFile )
{
  if( ( EndsWithOrZip( pFile, ".xm" ) ) || ( StartsWith( pFile, "xm." ) ) )
    return TRUE;
  
  if( EndsWithOrZip( pFile, ".it" ) )
    return TRUE;
  
  if( ( EndsWithOrZip( pFile, ".s3m" ) ) || ( StartsWith( pFile, "s3m." ) ) )
    return TRUE;
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// IsOldMODFile()
//-----------------------------------------------------------------------------------------
BOOL IsOldMODFile( char *pFile )
{
  if( ( EndsWithOrZip( pFile, ".mod" ) ) || ( StartsWith( pFile, "mod." ) ) )
    return TRUE;
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// IsXMFile()
//-----------------------------------------------------------------------------------------
BOOL IsXMFile( char *pFile )
{
  if( EndsWithOrZip( pFile, ".xm" ) )
    return TRUE;
  
  return FALSE;
}
//-----------------------------------------------------------------------------------------
// IsMODFile() 
//-----------------------------------------------------------------------------------------
BOOL IsMODFile( char *pFile )
{
  if( IsSIDFile( pFile ) )
    return FALSE;
  
  if( ( EndsWithOrZip( pFile, ".mod" ) ) || ( StartsWith( pFile, "mod." ) ) )
    return TRUE;
  
  if( ( EndsWithOrZip( pFile, ".med" ) ) || ( StartsWith( pFile, "med." ) ) )
    return TRUE;
  
  if( ( EndsWithOrZip( pFile, ".xm" ) ) || ( StartsWith( pFile, "xm." ) ) )
    return TRUE;  

  if( EndsWithOrZip( pFile, ".it" ) )
    return TRUE;
  
  if( ( EndsWithOrZip( pFile, ".s3m" ) ) || ( StartsWith( pFile, "s3m." ) ) )
    return TRUE;  

  if( ( EndsWithOrZip( pFile, ".gt2" ) ) || ( StartsWith( pFile, "gt2." ) ) )
    return TRUE;  
   
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// IsSIDFile() 
//-----------------------------------------------------------------------------------------
BOOL IsSIDFile( char *pFile )
{
  if( ( EndsWithOrZip( pFile, ".sid" ) ) || ( EndsWithOrZip( pFile, ".psid" ) ) )
    return TRUE;
    
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// addLocalFilesToLibraryInPath
//-----------------------------------------------------------------------------------------
-(void) addLocalFilesToLibraryInPath: (char *) pszPath
{
  Vector vFiles;
  char   txFullPath[ MAX_PATH ];
  
  [MyUtils findAllFilesInPath: [NSString stringWithUTF8String: pszPath] populate: &vFiles];
  
  int nTotalFiles = vFiles.elementCount();
  
  for( int i = 0; i < nTotalFiles; i ++ )
  {
    char *pFile = vFiles.elementStrAt( i );
    
    if( i % 1000 == 0 )
      LogDebugf( "Locals added %6d/%6d", i, nTotalFiles  );
    
    MakeDocumentsPath( pFile, txFullPath );
    
    long lSize = FileSize( txFullPath );
    
    // PDS: Don't add huge zips.. such as C64Music.zip
    if( lSize > 10000000 )
      continue;
    
    // PDS: Not handling ZIPs yet..
    if( IsZIPFile( pFile ) )
      AddZIPToLibrary( pFile );
    else
    if( IsMODFile( pFile ) )
      AddMODToLibrary( pFile, NULL, NULL, pFile );
    else
    if( IsSIDFile( pFile ) )
      AddSIDToLibrary( pFile, NULL, NULL, pFile );
    else
    {
      LogDebugf( "NOT adding: %s", pFile );
    }
  }
}

//-----------------------------------------------------------------------------------------
// addLocalFilesToLibrary 
//-----------------------------------------------------------------------------------------
-(void) addLocalFilesToLibrary 
{
  // PDS: First add any safekeeping files..
  [self addLocalFilesToLibraryInPath: g_PathSafe];

  [self addLocalFilesToLibraryInPath: g_txFTPPath];
}

//-----------------------------------------------------------------------------------------
// remoteControlReceivedWithEvent
//-----------------------------------------------------------------------------------------
-(void) remoteControlReceivedWithEvent:(UIEvent *)receivedEvent 
{
  LogDebugf( "REMOVE VC EVENT" );
  
  if (receivedEvent.type == UIEventTypeRemoteControl) 
  {
    switch( receivedEvent.subtype ) 
    {
      case UIEventSubtypeRemoteControlTogglePlayPause:
        if( g_Stopped )
          [self PlaySelected];
        else
          [self PauseTune];
        break;
        
      case UIEventSubtypeRemoteControlPreviousTrack:
        [self PrevTune];          
        break;
        
      case UIEventSubtypeRemoteControlNextTrack:
        [self NextTune];  
        break;

      case UIEventSubtypeRemoteControlBeginSeekingBackward:        
        break;
        
      case UIEventSubtypeRemoteControlBeginSeekingForward:
        break;
        
        /*
        UIEventSubtypeRemoteControlPlay                 = 100,
        UIEventSubtypeRemoteControlPause                = 101,
        UIEventSubtypeRemoteControlStop                 = 102,
        UIEventSubtypeRemoteControlTogglePlayPause      = 103,
        UIEventSubtypeRemoteControlNextTrack            = 104,
        UIEventSubtypeRemoteControlPreviousTrack        = 105,
        UIEventSubtypeRemoteControlBeginSeekingBackward = 106,
        UIEventSubtypeRemoteControlEndSeekingBackward   = 107,
        UIEventSubtypeRemoteControlBeginSeekingForward  = 108,
        UIEventSubtypeRemoteControlEndSeekingForward    = 109,       
        */
        
      default:
        break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// addButton
//-----------------------------------------------------------------------------------------
-(UIButton *) addButton: (NSString *) nsText subTitle: (NSString *) nsSubtitle atX: (float) x atY: (float) y 
                  width: (float) w height: (float) h
               selector: (SEL) fn 
             bgndColour: (UIColor*) bgndColour
               subLabel: (UILabel *) pSubLabel
                  image: (UIImage *) image
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake( x+g_ButInset, y+g_ButInset, w-(g_ButInset*2), h-(g_ButInset*2) );
  
	// Configure background image(s)
	[button setBackgroundToGlossyRectOfColor: bgndColour              withBorder: YES forState: UIControlStateNormal];
	[button setBackgroundToGlossyRectOfColor:[UIColor blackColor ] withBorder: YES forState:UIControlStateHighlighted];
  
  if( pSubLabel != nil )
  {
    [button   addSubview: pSubLabel];
  }
  else
  {
    // PDS: Add subtitle..
    UILabel *subtitle = [[UILabel alloc]initWithFrame:CGRectMake(8, 40, w-20, h-20)];
    [subtitle setBackgroundColor:[UIColor clearColor]];
    [subtitle setFont:[UIFont boldSystemFontOfSize:24]];
    subtitle.text = nsSubtitle;
    subtitle.textAlignment = UITextAlignmentCenter;
    
    [subtitle setTextColor:[UIColor yellowColor]];
    [button   addSubview:subtitle];
  }
  
	// Configure title(s)
  button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;  
  button.titleLabel.textAlignment = UITextAlignmentCenter;
  
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor colorWithRed:.25 green:.25 blue:.25 alpha:1] forState:UIControlStateNormal];
	[button setTitleShadowOffset:CGSizeMake(0, -1)];
	[button setFont:[UIFont boldSystemFontOfSize:28]];
 
  [button addTarget:self 
             action: fn
   forControlEvents:UIControlEventTouchUpInside];
  [button setTitle: nsText forState:UIControlStateNormal];
  
  [button setImage: image forState: UIControlStateNormal];
  
  [self.view addSubview:button];  
  
  return button;
}

//-----------------------------------------------------------------------------------------
// addButton
//-----------------------------------------------------------------------------------------
-(void) addButton: (NSString *) nsText atX: (float) x atY: (float) y width: (float) w height: (float) h selector: (SEL) fn
{
//  UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
  //[button setBackgroundColor: UIColorFromRGB( 0x4080FF ) ];
  
  [button addTarget:self 
             action: fn
   forControlEvents:UIControlEventTouchUpInside];
  [button setTitle: nsText forState:UIControlStateNormal];
  
  button.frame = CGRectMake( x, y, w, h );
  [self.view addSubview:button];  
}

//-----------------------------------------------------------------------------------------
// DetermineModeFromTypeAndOrder()
//
// Returns value for g_CurrentMode based on new combination of Type and Order
//-----------------------------------------------------------------------------------------
int DetermineModeFromTypeAndOrder( void )
{
  switch( g_CurrentOrder )
  {
    // Snap modes only.. (not manual)
    case ORDER_RANDOM_WITHIN_ARTIST:
      return MODE_RND_ARTIST;
      
    case ORDER_RANDOM_WITHIN_ALBUM:
      return MODE_RND_ALBUM;
      
    case ORDER_SEQUENCE_WITHIN_ALBUM:
      return MODE_SEQ_ARTIST;
      
    case ORDER_SEQUENCE:
      // PDS: Play list sequences taken care of below..
      break;
  }
  
  switch( g_CurrentType )
  {
    case TYPE_MOD_NEW:
      return MODE_RND_MOD_NEW;
      
    case TYPE_MOD_OLD:
      return MODE_RND_MOD_OLD;
      
    case TYPE_XM:
      return MODE_RND_XM;

    case TYPE_MOD_SID:
      return MODE_RND_MOD_SID;
      
    case TYPE_SID:
      return MODE_RND_SID;
      
    case TYPE_MP3:
      return MODE_RND_MP3;

    case TYPE_LIKES:
      return MODE_RND_LIKES;
      
    case TYPE_ALL:
      return MODE_RND_ALL;
      
    default:
      if( ( g_CurrentType >= TYPE_FAVOURITES1 ) && ( g_CurrentType <= TYPE_FAVOURITES10 ) )
      {
        LogDebugf( "** TYPE_FAVOURTIES -> MODE_FAVOURTIES_x" );
        return ( g_CurrentType - TYPE_FAVOURITES1 ) + MODE_FAVOURITES_1;
      }
      break;
  }
  
  return MODE_NORMAL_PLAY;
}


//-----------------------------------------------------------------------------------------
// SetMode()
//
// Called by DrillDown views.. and other places
//-----------------------------------------------------------------------------------------
void SetMode( int nMode )
{
  g_CurrentMode = nMode;
  
  if( nMode == MODE_NORMAL_PLAY )
    g_CurrentOrder = ORDER_SEQUENCE;
  
  UpdateTypeAndOrderSubLabel();
}

//-----------------------------------------------------------------------------------------
// UpdateTypeAndOrderSubLabel()
//-----------------------------------------------------------------------------------------
void UpdateTypeAndOrderSubLabel( void )
{
  dispatch_async( dispatch_get_main_queue(), ^
                 {
                   LogDebugf( "g_CurrentType : %d / %d (%s)", g_CurrentType, g_vTypeText.elementCount(), g_vTypeText.elementStrAt( g_CurrentType ) );
                   LogDebugf( "g_CurrentOrder: %d / %d (%s)", g_CurrentOrder, g_vOrderText.elementCount(), g_vOrderText.elementStrAt( g_CurrentOrder ) );
                   
                   [g_ModeSubLabel  setText: [NSString stringWithUTF8String: (const char*) g_vTypeText.elementStrAt(  g_CurrentType  ) ] ];
                   [g_OrderSubLabel setText: [NSString stringWithUTF8String: (const char*) g_vOrderText.elementStrAt( g_CurrentOrder ) ] ];
                   
                   // PDS: Update 'Mode' button - now "Type" button!
                   switch( g_CurrentType )
                   {
                     case TYPE_MOD_NEW:
                     case TYPE_MOD_OLD:
                     case TYPE_XM:
                       [g_ModeButton setImage: g_ImageMod forState: UIControlStateNormal];
                       break;

                     case TYPE_MOD_SID:
                       [g_ModeButton setImage: g_ImageModSID forState: UIControlStateNormal];
                       break;
                       
                     case TYPE_SID:
                       [g_ModeButton setImage: g_ImageSID forState: UIControlStateNormal];
                       break;
                    
                     case TYPE_MP3:
                       [g_ModeButton setImage: g_ImageMP3 forState: UIControlStateNormal];
                       break;

                     case TYPE_ALL:
                     default:
                       [g_ModeButton setImage: g_ImageAllTypes forState: UIControlStateNormal];
                       break;
                   }
                   
                   switch( g_CurrentOrder )
                   {
                     case ORDER_RANDOM_ANY:
                     case ORDER_RANDOM_WITHIN_ARTIST:
                     case ORDER_RANDOM_WITHIN_ALBUM:
                       [g_SeqButton setImage: g_ImageRandom forState: UIControlStateNormal];
                       break;
                       
                     case ORDER_SEQUENCE:
                     case ORDER_SEQUENCE_WITHIN_ALBUM:
                       [g_SeqButton setImage: g_ImageSequence forState: UIControlStateNormal];
                       break;
                   }

                 } );
}

//-----------------------------------------------------------------------------------------
// HandleModePressed()
//
// "Type" button has been pressed..
//-----------------------------------------------------------------------------------------
void HandleModePressed( void )
{
  int nTypeFrom = g_CurrentType;

  // PDS: Get rid of any ordering..
  g_CurrentOrder = ORDER_RANDOM_ANY;
  
  //if( g_CurrentType < g_vTypeText.elementCount() - 1 )
  g_CurrentType ++;

  if( g_CurrentType > g_vTypeText.elementCount() - 1 )
  {
    g_CurrentType = TYPE_FAVOURITES1;
  }
  else
  {
    if( ( g_CurrentType == TYPE_MOD_NEW ) && ( g_LibHasNewMOD == FALSE ) )
      g_CurrentType ++;
    
    if( ( g_CurrentType == TYPE_MOD_OLD) && ( g_LibHasMOD == FALSE ) )
      g_CurrentType ++;
    
    if( ( g_CurrentType == TYPE_XM ) && ( g_LibHasXM == FALSE ) )
      g_CurrentType ++;
    
    if( ( g_CurrentType == TYPE_SID ) && ( g_LibHasSID == FALSE ) )
      g_CurrentType ++;
    
    if( ( g_CurrentType == TYPE_MOD_SID ) && ( g_LibHasSID == FALSE ) && ( g_LibHasMOD == FALSE ) )
      g_CurrentType = TYPE_FAVOURITES1;
    
    if( ( g_CurrentType >= TYPE_FAVOURITES1  ) &&
        ( g_CurrentType <= TYPE_FAVOURITES10 ) &&
        ( g_CurrentType >  TYPE_FAVOURITES1 + g_NumFavouritePlaylists - 1 ) )
    {
      // PDS: Skip the favourites if not active..
      g_CurrentType = TYPE_ALL;
    }
  }

  if( ( g_CurrentType >= TYPE_FAVOURITES1  ) &&
      ( g_CurrentType <= TYPE_FAVOURITES10 ) )
  {
    // PDS: Just show sequence icon and nothing else for favourites..
    g_CurrentOrder = ORDER_SEQUENCE;
  }
  
  g_CurrentMode = DetermineModeFromTypeAndOrder();
  
  LogDebugf( "**Type Change: %d / %d (%s)", g_CurrentType,  g_vTypeText.elementCount(), g_vTypeText.elementStrAt( g_CurrentType ) );
  LogDebugf( "  Order now  : %d / %d (%s)", g_CurrentOrder, g_vOrderText.elementCount(), g_vOrderText.elementStrAt( g_CurrentOrder ) );
  LogDebugf( "  Mode  now  : %d / %d (%s)", g_CurrentMode,  g_vModeText.elementCount(), g_vModeText.elementStrAt( g_CurrentMode ) );
   
  SelectCurrentPlayList( g_CurrentMode );
   
  UpdateTypeAndOrderSubLabel();
   
  HandleCreatePlayList();
}


//-----------------------------------------------------------------------------------------
// ModePressed
//-----------------------------------------------------------------------------------------
-(void) ModePressed
{
  PostPlayerEvent( evMODE_SELECT );
  
  g_SnapMode = FALSE;
}

//-----------------------------------------------------------------------------------------
// HandleSnapPressed()
//-----------------------------------------------------------------------------------------
void HandleSnapPressed( void )
{
  // PDS: Remember mode when making transition into snap..
  /*
  if( g_SnapMode == FALSE )
  {
    g_ModeBeforeSnap = g_CurrentMode;
    LogDebugf( "Mode before snap: %d", g_CurrentMode );
  }
  */

  BOOL fBackToStart = FALSE;
  
  if( ( g_CurrentType >= TYPE_FAVOURITES1  ) &&
      ( g_CurrentType <= TYPE_FAVOURITES10 ) &&
      ( g_CurrentOrder == ORDER_SEQUENCE   ) )
  {
    // PDS: If somebody wants to change modes, then we need to move to RND_ALL..
    g_CurrentType  = TYPE_ALL;
    g_CurrentOrder = ORDER_RANDOM_WITHIN_ARTIST;
  }
  else
  if( g_CurrentOrder == ORDER_SEQUENCE )
  {
    LogDebugf( "** IS THIS NOT WORKING?" );
    
    // PDS: If somebody wants to change modes, then we need to move to RND_ALL..
    g_CurrentType  = TYPE_ALL;
    g_CurrentOrder = ORDER_RANDOM_WITHIN_ARTIST;
  }
  else
  if( g_CurrentOrder == ORDER_SEQUENCE_WITHIN_ALBUM )
  {
    LogDebugf( "** Go baco to start (ANY order)" );
    fBackToStart = TRUE;
  }
  else
  {
    g_CurrentOrder ++;
  }
  
  // PDS: Order button can only operate on certain types.. I think!
  if( g_CurrentOrder >= MAX_ORDERS )
    fBackToStart = TRUE;
  
  // PDS: Snap mode cannot work if no artist playing..
  if( g_CurrentArtistIndexPlaying < 0 )
    fBackToStart = TRUE;
  
  if( ( g_CurrentOrder == ORDER_RANDOM_WITHIN_ALBUM   ) ||
      ( g_CurrentOrder == ORDER_SEQUENCE_WITHIN_ALBUM ) )
  {
    if( g_UnitType != UNIT_MP3 )
      fBackToStart = TRUE;
  }
  
  if( fBackToStart )
  {
    g_CurrentOrder = ORDER_RANDOM_ANY;
    
    // PDS: Cause new playlists to be generated next time..
    g_SeqArtistIndex = -1;
    g_RndArtistIndex = -1;
  }
  
  g_CurrentMode = DetermineModeFromTypeAndOrder();
  
  SetMode( g_CurrentMode );

  LogDebugf( "**Order Change: %d (%s)", g_CurrentOrder, g_vOrderText.elementStrAt( g_CurrentOrder ) );
  LogDebugf( "  Type  now   : %d (%s)", g_CurrentType,  g_vTypeText.elementStrAt( g_CurrentType ) );
  LogDebugf( "  Mode  now   : %d (%s)", g_CurrentMode,  g_vModeText.elementStrAt( g_CurrentMode ) );
 
  LogDebugf( "  Curr Artist : %d (%s)", g_CurrentArtistIndexPlaying, g_vArtist.elementStrAt( g_CurrentArtistIndexPlaying ) );
  
  g_SnapMode = TRUE;

  // PDS: Ensure we point to required playlist..
  SelectCurrentPlayList( g_CurrentMode );
  
  CreateRandomArtistOrAlbumPlaylist();
}

//-----------------------------------------------------------------------------------------
// SnapPressed
//-----------------------------------------------------------------------------------------
-(void) SnapPressed
{
  PostPlayerEvent( evSNAP );
}

//-----------------------------------------------------------------------------------------
// SetupModes()
//-----------------------------------------------------------------------------------------
void SetupModes( void )
{
  LogDebugf( "### SETUP MODES" );
  
  g_vModeText.addElement( "NORMAL" );

  for( int p = 0; p < MAX_FAVOURITE_PLAYLISTS; p ++ )
  {
    char txMode[ 30 ];
    sprintf( txMode, "FAVS %d", p + 1 );
    g_vModeText.addElement( txMode );
  }
  
  g_vModeText.addElement( "RND ALL" );
  g_vModeText.addElement( "RND LIKES" );  
  g_vModeText.addElement( "RND MP3" );
  
  // PDS: New mods..
  g_vModeText.addElement( "RND MODx" );
  
  // PDS: Old mods..  
  g_vModeText.addElement( "RND MOD4" );  
  g_vModeText.addElement( "RND XM" );
  g_vModeText.addElement( "RND SID" );
  g_vModeText.addElement( "RND M/S" );

  // PDS: Randomly play current artist..
  g_vModeText.addElement( "RND ART" );
  g_vModeText.addElement( "RND ALBUM" );
  
  // PDS: Sequentially play current artist..
  g_vModeText.addElement( "SEQ ART" );
  
  g_vTypeText.removeAll();
  
  // PDS: Setup text for Types..
  for( int p = TYPE_FAVOURITES1; p <= TYPE_FAVOURITES10; p ++ )
  {
    char txType[ 30 ];
    sprintf( txType, "FAVS %d", p + 1 );
    g_vTypeText.addElement( txType );
  }
  
  g_vTypeText.addElement( "ALL" );      //  TYPE_ALL,
  g_vTypeText.addElement( "LIKES" );      //  TYPE_LIKES,
  g_vTypeText.addElement( "MP3" );      //  TYPE_MP3,
  g_vTypeText.addElement( "MOD NEW" );      //  TYPE_MOD_NEW,
  g_vTypeText.addElement( "MOD OLD" );      //  TYPE_MOD_OLD,
  g_vTypeText.addElement( "XM" );      //  TYPE_XM,
  g_vTypeText.addElement( "SID" );      //  TYPE_SID,
  g_vTypeText.addElement( "MOD/SID" );      //  TYPE_MOD_SID,
  
  
  // PDS: Now set up Order text..
  g_vOrderText.removeAll();
  g_vOrderText.addElement( "Any" );     // ORDER_RANDOM_ANY
  g_vOrderText.addElement( "Artist" );  // ORDER_RANDOM_WITHIN_ARTIST
  g_vOrderText.addElement( "Album" );   // ORDER_RANDOM_WITHIN_ALBUM
  g_vOrderText.addElement( "Album" );   // ORDER_SEQUENCE_WITHIN_ALBUM
  g_vOrderText.addElement( "Normal" );  // ORDER_SEQUENCE
}

//-----------------------------------------------------------------------------------------
// addStatusScroller
//-----------------------------------------------------------------------------------------
-(MarqueeLabel *) addStatusScrollerAtX: (float) x atY: (float) y 
{  
  // Rate-speed label example
  MarqueeLabel *rateLabelOne = [[MarqueeLabel alloc] initWithFrame:CGRectMake( x, y, self.view.frame.size.width-20-x-(g_ButWidth/2), 20) 
                                                              rate:50.0f 
                                                     andFadeLength:10.0f];
  rateLabelOne.numberOfLines   = 1;
  rateLabelOne.opaque          = NO;
  rateLabelOne.enabled         = YES;
  rateLabelOne.shadowOffset    = CGSizeMake(0.0, -1.0);
  rateLabelOne.textAlignment   = UITextAlignmentCenter;
  rateLabelOne.textColor       = [UIColor yellowColor];
  rateLabelOne.backgroundColor = [UIColor clearColor];
  //rateLabelOne.font            = [UIFont fontWithName:@"Helvetica-Bold" size:17.000];
  rateLabelOne.font            = [UIFont fontWithName:@"Helvetica" size:17.000];
  rateLabelOne.text            = @"";
  
  [self.view addSubview:rateLabelOne];
  
  return rateLabelOne;
  
  //[rateLabelOne release];  
}

//-----------------------------------------------------------------------------------------
// SetStatusInfo
//-----------------------------------------------------------------------------------------
-(void) SetStatusInfo: (BOOL) fShowFader
{
  static BOOL fBusy = FALSE;
  
  if( fBusy )
  {
    return;
  }
  
  fBusy = TRUE;

  // PDS: Couldn't get this to work..
  //  [self.view.layer removeAllAnimations];

  // PDS> SCREENSHOTS
  //strcpy( g_txStatusTune, "Simply The Best" );
  //strcpy( g_txStatusArtist, "Tina Turner" );
  //strcpy( g_txStatusArtist, "Gray_Matt" );
  
  //g_StatusScroller1.labelize = TRUE;
  g_StatusScroller1.text = [NSString stringWithUTF8String: g_txStatusTune ];
  g_StatusScroller1.textColor = [UIColor yellowColor];
  
  //g_StatusScroller2.labelize = TRUE;
  g_StatusScroller2.text      = [NSString stringWithUTF8String: g_txStatusArtist];
  g_StatusScroller2.textColor = [UIColor orangeColor];
  
  // PDS: Don't bother displaying album name for non-MP3 files..
  if( g_UnitType != UNIT_MP3 )
    g_txStatusAlbum[ 0 ] = 0;
  
  // PDS> SCREENSHOTS
  //strcpy( g_txStatusAlbum, "Greatest Hits" );
  
  //g_StatusScroller3.labelize = TRUE;
  g_StatusScroller3.text      = [NSString stringWithUTF8String: g_txStatusAlbum];
  g_StatusScroller3.textColor = [UIColor greenColor];

  // PDS: Try popping up a larger status window and make it fade away..
  if( g_ImgViewStatusFader )
  {
    //[g_ImgViewStatusFader removeFromSuperview];
    //g_ImgViewStatusFader = nil;
  }

  {
    int nStatusFaderWidth  = g_MaxPixelWidth  - 20;
    int nStatusFaderHeight = 150;
    
    int x = ( g_MaxPixelWidth  - nStatusFaderWidth  ) / 2;
    int y = ( g_MaxPixelHeight - nStatusFaderHeight ) / 2;
    
    g_ImgViewStatusFader = [[UIImageView alloc] initWithFrame: CGRectMake( x, y, nStatusFaderWidth, nStatusFaderHeight ) ];

    //[g_ImgViewStatusFader setBackgroundColor: [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8]];
    
    // PDS: Add UILabels here..
    //if( g_StatusFaderTuneLabel == nil )
    {
      int nInset = 10;
      int nLabelWidth  = nStatusFaderWidth - ( nInset * 2 );
      int nLabelHeight = 30;
      int x = nInset;
      int y = nInset;
      int nExtra = 4;

      g_StatusFaderArtistLabel = [[UILabel alloc] initWithFrame: CGRectMake( x, y, nLabelWidth, nLabelHeight ) ];
      y += nLabelHeight + nInset;
      y += nExtra;
      
      g_StatusFaderTuneLabel   = [[UILabel alloc] initWithFrame: CGRectMake( x, y, nLabelWidth, nLabelHeight ) ];
      y += nLabelHeight + nInset;
      y += nExtra;
      
      g_StatusFaderAlbumLabel  = [[UILabel alloc] initWithFrame: CGRectMake( x, y, nLabelWidth, nLabelHeight ) ];
      y += nLabelHeight + nInset;
      
      g_StatusFaderTuneLabel.backgroundColor   = [UIColor  clearColor];
      g_StatusFaderArtistLabel.backgroundColor = [UIColor  clearColor];
      g_StatusFaderAlbumLabel.backgroundColor  = [UIColor  clearColor];
      
      g_StatusFaderTuneLabel.textAlignment     = UITextAlignmentCenter;
      g_StatusFaderArtistLabel.textAlignment   = UITextAlignmentCenter;
      g_StatusFaderAlbumLabel.textAlignment    = UITextAlignmentCenter;

      g_StatusFaderTuneLabel.textColor         = [UIColor yellowColor];
      g_StatusFaderArtistLabel.textColor       = [UIColor orangeColor];
      g_StatusFaderAlbumLabel.textColor        = [UIColor greenColor];
 
      g_StatusFaderTuneLabel.font              = [UIFont fontWithName:@"Helvetica-Bold" size: 22 ];
      g_StatusFaderArtistLabel.font            = [UIFont fontWithName:@"Helvetica-Bold" size: 26 ];
      g_StatusFaderAlbumLabel.font             = [UIFont fontWithName:@"Helvetica-Bold" size: 20 ];
      
      if( stricmp( g_txStatusArtist, "Unknown" ) == 0 )
        strcpy( g_txStatusArtist2, "Unknown Artist" );
      else
        strcpy( g_txStatusArtist2, g_txStatusArtist );
      
      [g_StatusFaderTuneLabel   setText: [NSString stringWithUTF8String: g_txStatusTune   ] ];
      [g_StatusFaderArtistLabel setText: [NSString stringWithUTF8String: g_txStatusArtist2] ];
      
      if( g_txStatusAlbum[ 0 ] )
      {
        strcpy( g_txStatusAlbum2, "(" );
        strcat( g_txStatusAlbum2, g_txStatusAlbum );
        strcat( g_txStatusAlbum2, ")" );
        
        [g_StatusFaderAlbumLabel  setText: [NSString stringWithUTF8String: g_txStatusAlbum2 ] ];
      }
    }


    // PDS: Try direct context drawing..
    UIGraphicsBeginImageContext( g_ImgViewStatusFader.frame.size );

    // Pass 1: Draw the original image as the background
    [g_ImgViewStatusFader.image drawAtPoint:CGPointMake(0,0)];
    
    // Pass 2: Draw the line on top of original image
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *lineColor2 = [UIColor colorWithRed: 0.9 green: 0.9 blue: 0.9 alpha: 0.8];
    
    // PDS: Draw my framed rounded rectangle..
    CGContextSetRGBFillColor( context, 0.1, 0.1, 0.1, 0.8 );
    DrawFilledRoundedRect( context, CGRectMake( 2, 2, g_ImgViewStatusFader.frame.size.width-4, g_ImgViewStatusFader.frame.size.height-4 ), 5 );
    CGContextSetLineWidth( context, 4.0);
    CGContextSetStrokeColorWithColor(context, [lineColor2 CGColor] );
    DrawRoundedRect( context, CGRectMake( 2, 2, g_ImgViewStatusFader.frame.size.width-4, g_ImgViewStatusFader.frame.size.height-4 ), 4 );
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    g_ImgViewStatusFader.image = newImage;
    
    // Tidy up
    UIGraphicsEndImageContext();
    
    [g_ImgViewStatusFader addSubview: g_StatusFaderTuneLabel  ];
    [g_ImgViewStatusFader addSubview: g_StatusFaderArtistLabel];
    
    if( g_txStatusAlbum2[ 0 ] )
      [g_ImgViewStatusFader addSubview: g_StatusFaderAlbumLabel ];

    [self.view addSubview: g_ImgViewStatusFader];
    
    // Then fades it away after 2 seconds (the cross-fade animation will take 0.5s)
  }

  g_ImgViewStatusFader.hidden = ( fShowFader ) ? NO : YES;
  g_ImgViewStatusFader.alpha  = 1.0f;
  
  [UIView animateWithDuration:0.5 delay: 4.0 options:0 animations:^
  {
    // Animate the alpha value of your imageView from 1.0 to 0.0 here
    g_ImgViewStatusFader.alpha = 0.0f;
  }
  completion:^(BOOL finished)
  {
    if( finished == YES )
    {
      // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
      // PDS: NO!!! This causes interleaving animations to abruplty switch off the status screen..
      //      g_ImgViewStatusFader.hidden = YES;
    }
  }];
  
  fBusy = FALSE;
}

//-----------------------------------------------------------------------------------------
// addLabel
//-----------------------------------------------------------------------------------------
-(UILabel *) addLabel: (char *) pTxt atX: (float) x atY: (float) y
{
  UILabel *label = [UILabel alloc];
  [label initWithFrame: CGRectMake( x, y, g_StatusLabelWidth, g_StatusLabelHeight ) ];
  label.backgroundColor = [UIColor  clearColor];
  label.textAlignment   = UITextAlignmentLeft;
  label.textColor       = [UIColor whiteColor];
  label.font            = [UIFont fontWithName:@"Helvetica-Bold" size:17.000];                   
  [label setText: [NSString stringWithUTF8String: pTxt] ];
  [self.view addSubview: label];  
  return label;
}

//-----------------------------------------------------------------------------------------
// freeButton
//-----------------------------------------------------------------------------------------
-(void) freeButton: (UIButton **) ppButton
{
  if( *ppButton )
  {
    UIButton *pButton = *ppButton;

    LogDebugf( "Free button    : 0x%08lx", (long) pButton );
    
    [*ppButton removeFromSuperview];
    
    (*ppButton) = nil;
  }
}

//-----------------------------------------------------------------------------------------
// freePlayerButtons
//-----------------------------------------------------------------------------------------
-(void) freePlayerButtons
{
  // PDS: Using ARC so setting to nil pointers will free objects..
  [g_ModeButton     removeFromSuperview]; g_ModeButton     = nil;
  [g_PlayStopButton removeFromSuperview]; g_PlayStopButton = nil;
  [g_HateButton     removeFromSuperview]; g_HateButton     = nil;
  [g_UpButton       removeFromSuperview]; g_UpButton       = nil;
  [g_SettingsButton removeFromSuperview]; g_SettingsButton = nil;
  [g_SeqButton      removeFromSuperview]; g_SeqButton      = nil;
  [g_PlayStopButton removeFromSuperview]; g_PlayStopButton = nil;
  [g_ListButton     removeFromSuperview]; g_ListButton     = nil;
  [g_DownButton     removeFromSuperview]; g_DownButton     = nil;
  [g_LikeButton     removeFromSuperview]; g_LikeButton     = nil;
  [g_SubUpButton    removeFromSuperview]; g_SubUpButton    = nil;
  [g_SubDownButton  removeFromSuperview]; g_SubDownButton  = nil;
}


//-----------------------------------------------------------------------------------------
// UpdatePlayStopButton
//-----------------------------------------------------------------------------------------
-(void) UpdatePlayStopButton
{
  if( g_xPlayButton < 0 )
    return;
  
  if( [g_PlayStopButton imageForState: UIControlStateNormal] == g_ImageStop )
  {
    UIColor *colRed       = UIColorFromRGB( 0xFF0000 );

  	[g_PlayStopButton setBackgroundToGlossyRectOfColor: colRed withBorder: YES forState: UIControlStateNormal];
  }
  else
  {
    UIColor *colGreen     = UIColorFromRGB( 0x108010 );

    [g_PlayStopButton setBackgroundToGlossyRectOfColor: colGreen withBorder: YES forState: UIControlStateNormal];
  }
}

//-----------------------------------------------------------------------------------------
// setupPlayerButtons
//-----------------------------------------------------------------------------------------
-(void) setupPlayerButtons
{
  static BOOL fModesNotSet = TRUE;
  
  //[self setupPlayerButtonsDevelopment];
  //return;
  
  if( fModesNotSet )
  {
    fModesNotSet = FALSE;
    
    int nButtonsAcross  = 2;
    int nButtonsDown    = 3;
    int nTitlebarHeight = 24;
    
    g_StatusBarHeight   =  70;
    g_ButWidth  = g_MaxPixelWidth  / nButtonsAcross;
    g_ButHeight = ( g_MaxPixelHeight - nTitlebarHeight - g_StatusBarHeight ) / nButtonsDown;
    g_ButSpace  = 0;

    // PDS: Add subtitle..
    g_OrderSubLabel = [[UILabel alloc]initWithFrame: CGRectMake( 8, 50, (g_ButWidth/2)-20, g_ButHeight-20) ];
    [g_OrderSubLabel setBackgroundColor:[UIColor clearColor]];
    [g_OrderSubLabel setFont:[UIFont boldSystemFontOfSize:16]];
    g_OrderSubLabel.textAlignment = UITextAlignmentCenter;
       
    [g_OrderSubLabel setTextColor:[UIColor whiteColor]];
    
    g_ModeSubLabel = [[UILabel alloc]initWithFrame: CGRectMake( 8, 50, g_ButWidth-20, g_ButHeight-20) ];
    [g_ModeSubLabel setBackgroundColor:[UIColor clearColor]];
    [g_ModeSubLabel setFont:[UIFont boldSystemFontOfSize:16]];
    g_ModeSubLabel.textAlignment = UITextAlignmentCenter;
    
    [g_ModeSubLabel setTextColor:[UIColor whiteColor]];
    
    g_StatusTitle1    = [self addLabel: "Tune"   atX: 0 atY:  5 ];
    g_StatusTitle2    = [self addLabel: "Artist" atX: 0 atY: 25 ];
    g_StatusTitle3    = [self addLabel: "Album"  atX: 0 atY: 45 ];
    
    g_StatusTitle1.textColor = [UIColor yellowColor];
    g_StatusTitle2.textColor = [UIColor orangeColor];
    g_StatusTitle3.textColor = [UIColor greenColor];
    
    g_StatusScroller1 = [self addStatusScrollerAtX: g_StatusLabelWidth atY:  5];
    g_StatusScroller2 = [self addStatusScrollerAtX: g_StatusLabelWidth atY: 25];
    g_StatusScroller3 = [self addStatusScrollerAtX: g_StatusLabelWidth atY: 45];
    
    g_txStatusTune  [ 0 ] = 0;
    g_txStatusArtist[ 0 ] = 0;
    g_txStatusAlbum [ 0 ] = 0;

    // PDS: Add tap recogniser(s) for labels..
    for( int x = 0; x < 6; x ++ )
    {
      g_TapLabelRecognizer[ x ] = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector( labelTouched )];
    
      [g_TapLabelRecognizer[ x ] setNumberOfTapsRequired:1];
    }

  }

  if( g_ModeButton == nil )
    g_ModeButtonImage = g_ImageMP3;
  else
    g_ModeButtonImage = [g_ModeButton imageForState: UIControlStateNormal];
  
  if( g_SeqButton == nil )
    g_OrderButtonImage = g_ImageRandom;
  else
    g_OrderButtonImage = [g_SeqButton imageForState: UIControlStateNormal];

  
  [self freePlayerButtons];

  // PDS: Allow tapping of labels to display bigger status fader text..
  [g_StatusTitle1    setUserInteractionEnabled:YES];
  [g_StatusTitle2    setUserInteractionEnabled:YES];
  [g_StatusTitle3    setUserInteractionEnabled:YES];
  
  [g_StatusScroller1 setUserInteractionEnabled:YES];
  [g_StatusScroller2 setUserInteractionEnabled:YES];
  [g_StatusScroller3 setUserInteractionEnabled:YES];
  
  [g_StatusTitle1    addGestureRecognizer: g_TapLabelRecognizer[0]];
  [g_StatusTitle2    addGestureRecognizer: g_TapLabelRecognizer[1]];
  [g_StatusTitle3    addGestureRecognizer: g_TapLabelRecognizer[2]];
  [g_StatusScroller1 addGestureRecognizer: g_TapLabelRecognizer[3]];
  [g_StatusScroller2 addGestureRecognizer: g_TapLabelRecognizer[4]];
  [g_StatusScroller3 addGestureRecognizer: g_TapLabelRecognizer[5]];
  
  
  float y = 0;
  
  float xCol1   = 0.0;
  float xCol1_5 = ( g_ButWidth / 2 );
  float xCol2   = g_ButWidth;
  float xCol3   = xCol2 + ( g_ButWidth / 2 );
  
  UIColor *colRed       = UIColorFromRGB( 0xFF0000 );
  UIColor *colPurple    = UIColorFromRGB( 0xA000A0 );
  UIColor *colOrange    = UIColorFromRGB( 0xA06000 );
  UIColor *colGreen     = UIColorFromRGB( 0x108010 );
  UIColor *colBlue      = UIColorFromRGB( 0x2020A0 );
  UIColor *colBrown     = UIColorFromRGB( 0x602000 );
  UIColor *colLightBlue = UIColorFromRGB( 0x4040C0 );
  UIColor *colCyan      = UIColorFromRGB( 0x40C0C0 );
  UIColor *colDarkGrey  = UIColorFromRGB( 0x606060 );
  
  g_SettingsButton = [self addButton: @""
                            subTitle: @""
                                 atX: xCol3 atY: y
                               width: g_ButWidth / 2
                              height: g_StatusBarHeight
                            selector: @selector( DisplaySettings )
                          bgndColour: colDarkGrey 
                            subLabel: nil
                               image: g_ImageSettings];
  
  y += g_StatusBarHeight;
  
  g_ModeButton = [self addButton: @""
                        subTitle: @""     
                             atX: xCol1 atY: y 
                           width: g_ButWidth
                          height: g_ButHeight 
                        selector: @selector( ModePressed ) 
                      bgndColour: colRed 
                        subLabel: g_ModeSubLabel
                           image: g_ModeButtonImage ];
  
  
  g_SeqButton = [self addButton: @""
                       subTitle: @""
                            atX: xCol2 atY: y
                          width: g_ButWidth / 2
                         height: g_ButHeight
                       selector: @selector( SnapPressed )
                     bgndColour: colOrange 
                       subLabel: g_OrderSubLabel
                          image: g_OrderButtonImage ];

  g_xPlayButton = xCol3;
  g_yPlayButton = y;
  
  g_PlayStopButton = [self addButton: @""
                            subTitle: @""
                                 atX: g_xPlayButton atY: g_yPlayButton
                               width: g_ButWidth / 2
                              height: g_ButHeight
                            selector: @selector( PlayStopTune )
                          bgndColour: colGreen
                            subLabel: nil
                               image: g_ImagePlayWhite];
  
  //-----------------------------------------------------------------------------------------
  
  y += g_ButHeight + g_ButSpace;  

  int yUp = y;

  // PDS> REMOVE -
  //g_UnitType = UNIT_SID;
  //g_CurrentSIDNumSubTunes= 2;
  
  if( ( g_UnitType == UNIT_SID ) && ( g_CurrentSIDNumSubTunes > 1 ) )
  {
    g_UpButton = [self addButton: @""
                        subTitle: @""
                             atX: xCol1
                             atY: yUp
                           width: g_ButWidth
                          height: g_ButHeight / 2
                        selector: @selector( PrevTune )
                      bgndColour: colLightBlue
                        subLabel: nil
                           image: g_ImageSkipPrev2];
    
    g_SubUpButton = [self addButton: @""
                           subTitle: @""
                                atX: xCol1
                                atY: yUp + ( g_ButHeight / 2 )
                              width: g_ButWidth
                             height: g_ButHeight / 2
                           selector: @selector( PrevSubTune )
                         bgndColour: colCyan
                           subLabel: nil
                              image: g_ImagePrevSID];
  }
  else
  {
    g_UpButton = [self addButton: @""
                        subTitle: @""
                             atX: xCol1 atY: y
                           width: g_ButWidth
                          height: g_ButHeight
                        selector: @selector( PrevTune )
                      bgndColour: colLightBlue
                        subLabel: nil
                           image: g_ImageSkipPrev];
  }

  if( ( g_UnitType == UNIT_SID ) && ( g_CurrentSIDNumSubTunes > 1 ) )
  {
    g_DownButton = [self addButton: @""
                          subTitle: @""
                               atX: xCol2 atY: y
                             width: g_ButWidth
                            height: g_ButHeight / 2
                          selector: @selector( NextTune )
                        bgndColour: colLightBlue
                          subLabel: nil
                             image: g_ImageSkipNext2];
    
    g_SubDownButton = [self addButton: @""
                             subTitle: @""
                                  atX: xCol2
                                  atY: y + ( g_ButHeight / 2 )
                                width: g_ButWidth
                               height: g_ButHeight / 2
                             selector: @selector( NextSubTune )
                           bgndColour: colCyan
                             subLabel: nil
                                image: g_ImageNextSID];
  }
  else
  {
    g_DownButton = [self addButton: @""
                          subTitle: @""
                               atX: xCol2 atY: y
                             width: g_ButWidth
                            height: g_ButHeight
                          selector: @selector( NextTune )
                        bgndColour: colLightBlue
                          subLabel: nil
                             image: g_ImageSkipNext];
  }

  //-----------------------------------------------------------------------------------------

  y += g_ButHeight + g_ButSpace;
  
  g_ListButton = [self addButton: @""
                        subTitle: @""
                             atX: xCol1 atY: y
                           width: g_ButWidth / 2
                          height: g_ButHeight
                        selector: @selector( DisplayDrillDown )
                      bgndColour: colPurple
                        subLabel: nil
                           image: g_ImageFolder];
  
  g_HateButton = [self addButton: @""
                        subTitle: @""
                             atX: xCol1_5 atY: y
                           width: g_ButWidth / 2
                          height: g_ButHeight
                        selector: @selector( HateTune /*StopTune*/ )
                      bgndColour: colBrown
                        subLabel: nil
                           image: g_ImageHateTune];
  
  
  g_LikeButton = [self addButton: @"" subTitle: @""
                             atX: xCol2 atY: y
                           width: g_ButWidth
                          height: g_ButHeight
                        selector: @selector( LikeTune )
                      bgndColour: colGreen 
                        subLabel: nil
                           image: g_ImageLikeTune];

  UpdateTypeAndOrderSubLabel();
}

//-----------------------------------------------------------------------------------------
// DisplayDrillDown
//-----------------------------------------------------------------------------------------
-(void) DisplayDrillDown
{
  if( g_ModesView == nil )
    g_ModesView = [[TVModes alloc] initWithStyle: UITableViewStylePlain];
  
  g_ModesView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  
  if( g_navController )
  {
    g_navController = nil;
  }
  
  if( g_navController == nil )
  {
    g_navController = [[UINavigationController alloc] initWithRootViewController: g_ModesView];
  }

  [g_ContainerVC presentModalViewController: g_navController animated:YES];
}

//-----------------------------------------------------------------------------------------
// DisplaySettings
//-----------------------------------------------------------------------------------------
-(void) DisplaySettings
{
  if( g_SettingsView == nil )
    g_SettingsView = [[TVSettings alloc] initWithStyle: UITableViewStyleGrouped];
  
  g_SettingsView.title = @"Settings";
  
  g_SettingsView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  
  if( g_navController )
  {
    g_navController = nil;
  }

  if( g_navController == nil )
  {
    g_navController = [[UINavigationController alloc] initWithRootViewController: g_SettingsView];
  }

  // PDS: Don't use 'self' below - need to use base view controller.. which is container.. otherwise black screen
  //      will appear if lock button or power save occurs..
  [g_ContainerVC presentModalViewController: g_navController animated:YES];  
}

//-----------------------------------------------------------------------------------------
// CreateImages()
//-----------------------------------------------------------------------------------------
void CreateImages( void )
{
  g_ImageLike       = [UIImage imageNamed:@"GreenTick1_30x30.png"];
  g_ImageHate       = [UIImage imageNamed:@"RedCross1_30x30.png"];
  g_ImagePlay       = [UIImage imageNamed:@"Play_30x30.png"];
  g_ImageHeartRed   = [UIImage imageNamed: @"Heart1_30x30Red.png"];
  g_ImageHeartGrey  = [UIImage imageNamed: @"Heart1_30x30Grey.png"];
  g_ImageHeartGreen = [UIImage imageNamed: @"Heart1_30x30Green.png"];
  g_ImageClipboardPurple = [UIImage imageNamed: @"ClipBoard30x30Purple.png"];
  g_ImageClipboardGrey   = [UIImage imageNamed: @"ClipBoard30x30Grey.png"];
  g_ImageMinusRed        = [UIImage imageNamed: @"MinusRed30x30.png"];
  g_ImageDice       = [UIImage imageNamed: @"Dice2_30x30.png"];
  g_ImagePencil     = [UIImage imageNamed: @"Pencil_30x30.png"];
  g_ImageRecycle    = [UIImage imageNamed: @"Recycle_30x30.png"];
  g_ImageTrashcan   = [UIImage imageNamed: @"Trashcan_30x30.png"];
  
  g_ImageSkipPrev   = [UIImage imageNamed: @"SkipPrev_White_60x40.png"];
  g_ImageSkipNext   = [UIImage imageNamed: @"SkipNext_White_60x40.png"];
  g_ImageSkipPrev2  = [UIImage imageNamed: @"SkipPrev_White_60x20.png"];
  g_ImageSkipNext2  = [UIImage imageNamed: @"SkipNext_White_60x20.png"];
  g_ImageStop       = [UIImage imageNamed: @"Stop_White_40x40.png"];
  g_ImagePlayWhite  = [UIImage imageNamed: @"Play_White_20x40.png"];
  g_ImageSubPrev    = [UIImage imageNamed: @"SkipPrev_White_60x20.png"];
  g_ImageSubNext    = [UIImage imageNamed: @"SkipNext_White_60x20.png"];
  g_ImageLikeTune   = [UIImage imageNamed: @"LikeTune_x60.png"];
  g_ImageHateTune   = [UIImage imageNamed: @"HateTune_x60.png"];
  g_ImageFolder     = [UIImage imageNamed: @"White_Folder_40x40.png"];
  g_ImageSettings   = [UIImage imageNamed: @"Settings_2_60x60.png"];
  g_ImagePrevSID    = [UIImage imageNamed: @"PrevSID2_White_43x20.png"];
  g_ImageNextSID    = [UIImage imageNamed: @"NextSID2_White_43x20.png"];
  g_ImageBackspace  = [UIImage imageNamed: @"Backspace_31x60.png"];
  g_ImageRandom     = [UIImage imageNamed: @"Shuffle1_White_x60.png"];;
  g_ImageSequence   = [UIImage imageNamed: @"Sequence_x60.png"];;

  g_ImageMP3        = [UIImage imageNamed: @"Ipod_1_x60.png"];
  g_ImageSID        = [UIImage imageNamed: @"SID_x50.png"];
  g_ImageMod        = [UIImage imageNamed: @"ModFile_x60.png"];
  g_ImageModSID     = [UIImage imageNamed: @"SID_Mod1_x60.png"];
  g_ImageAllTypes   = [UIImage imageNamed: @"AllTypes_x60.png"];
}

//-----------------------------------------------------------------------------------------
// FreeImages()
//-----------------------------------------------------------------------------------------
void FreeImages( void )
{
  g_ImageHate = nil;
  g_ImageLike = nil;
  g_ImagePlay = nil;
  g_ImageHeartRed   = nil;
  g_ImageHeartGrey  = nil;
  g_ImageHeartGreen = nil;
  g_ImageClipboardPurple = nil;
  g_ImageClipboardGrey   = nil;
  g_ImageMinusRed   = nil;
  g_ImageDice       = nil;
  g_ImagePencil     = nil;
  g_ImageRecycle    = nil;
  g_ImageTrashcan   = nil;
}

//-----------------------------------------------------------------------------------------
// SetupEverything
//-----------------------------------------------------------------------------------------
-(void) SetupEverything
{
  LogDebugf( "SetupEverything.." );
  
  g_ProgressSteps = 15 + MODE_MAX_MODES;
  g_ProgressStep  = 0;
  
  CreateImages();
  
  if( g_DocumentsDirectory == nil )
  {
    NSArray  *paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    g_DocumentsDirectory = [paths lastObject];
    
    strcpy( g_txFTPPath, [g_DocumentsDirectory UTF8String] );

    LogDebugf( "FTP path:%s", g_txFTPPath );
    
    strcpy( g_txFTPHome, g_txFTPPath );
    //strcat( g_txFTPHome, "/Allowed" );
    //mkdir( g_txFTPHome, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH );
    
    SetupExportPaths();
    
    // PDS: Get rid of any mess..
    RemoveAllIn( g_txUnzipPath );
  }

  time_t tNow = time( NULL );

  LoadSettings();
  
  // PDS: Check to see if iPod tune library tune count has changed since last time..
  MPMediaQuery *allSongsQuery = [MPMediaQuery   songsQuery];
  NSArray      *allSongsArray = [allSongsQuery  collections];
  
  int nTotalSongs  = [allSongsArray count];

  LogDebugf( "Last song count: %d  Songs now: %d", g_MP3Count, nTotalSongs );
  
  if( nTotalSongs != g_MP3Count )
  {
    g_MP3CountChanged = TRUE;
    g_MP3Count        = nTotalSongs;
  }
  
  [self LoadTuneLibrary];
  
  // PDS: Taking about 4 seconds to query iPod with 1500 tunes..
  LogDebugf( "Took %ld seconds", time( NULL ) - tNow );

  SetupModes();
  
  // PDS: Set initial mode..
  SetMode( MODE_RND_MP3 );
  
  LogDebugf( "  Order init  : %d (%s)", g_CurrentOrder, g_vOrderText.elementStrAt( g_CurrentOrder ) );
  LogDebugf( "  Type  init  : %d (%s)", g_CurrentType,  g_vTypeText.elementStrAt( g_CurrentType ) );
  LogDebugf( "  Mode  init  : %d (%s)", g_CurrentMode,  g_vModeText.elementStrAt( g_CurrentMode ) );
  
  SelectCurrentPlayList( g_CurrentMode );

  IncProgress();

  IncProgress();
  LoadFavouritePlaylistNames();
  
  IncProgress();  

  // PDS: Rmove launch image..
  [g_vcImageView removeFromSuperview];
  
  g_vcImageView.image = nil;
  
  dispatch_async( dispatch_get_main_queue(), ^
  {
    [self setupPlayerButtons];
    UpdateTypeAndOrderSubLabel();
    [g_ProgressAlertView dismissWithClickedButtonIndex:0 animated:NO];
    
    [self restartTimer];
  } );
  
  PostPlayerEvent( evSTARTUP );
  
  LogDebugf( "SetupEverything.. DONE" );
}

//-----------------------------------------------------------------------------------------
// willPresentAlertView
//-----------------------------------------------------------------------------------------
-(void) willPresentAlertView: (UIAlertView *) alertView
{
  CGRect alertRect = alertView.bounds;
  
  if( g_ProgressBar == nil )
  {
    g_ProgressBar = [[UIProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleBar ];
    
    g_ProgressBar.frame = CGRectMake( alertRect.origin.x + 20,
                                      alertRect.origin.y + ( alertRect.size.height - 50 ),
                                      alertRect.size.width - 40,
                                      40.0 );
    
    
    g_ProgressBar.progress = 0.0f;
    
    //  UIProgressView *pv = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    //  pv.frame = CGRectMake(20, 20, 200, 15);
    //  pv.progress = 0.5;
    
    
    [alertView addSubview: g_ProgressBar];
  }
  
  //  Note the status Bar will always be there, haven't found a way of hiding it yet
  //  Suggest adding an objective C reference to the original loading bar if you want to manipulate it further on don't forget to add
  objc_setAssociatedObject(alertView, &g_ProgressKey, g_ProgressBar, OBJC_ASSOCIATION_RETAIN); // Send the progressbar over to the alertview
}

//-----------------------------------------------------------------------------------------
// HandlePlayerTimerCallback()
//-----------------------------------------------------------------------------------------
void HandlePlayerTimerCallback( void )
{
  switch( g_UnitType )
  {
    case UNIT_SID:
      // PDS: If all playback has been stopped.. don't move onto next tune..
      if( g_Stopped )
        return;
      
      if( g_CurrentSIDSecsLong > 0 )
      {
        g_CurrentSIDSecsLong = g_vSIDSubTuneLengths.elementIntAt( g_SIDSubTune );
        
        if( SecondsElapsed( g_CurrentSIDSecsStart ) > g_CurrentSIDSecsLong )
        {
          if( g_SIDSubTune < g_CurrentSIDNumSubTunes - 1 )
            [g_MainViewController NextSubTune];
          else
            [g_MainViewController TuneFinishedPlaying];
        }
      }
      
      SIDPlay_Update();
      break;
      
    case UNIT_MOD:
    {
      // PDS: Ensure player has enough data to play etc..
      if( Player_Active() )
      {
        MikMod_Update();
      }
      else
      if( ! g_Stopped )
      {
        g_Stopped = TRUE;
        
        Player_Stop();
        
        if( g_Module )
        {
          Player_Free( g_Module );
          g_Module = NULL;
        }
        
        // PDS: Done..
        [g_MainViewController TuneFinishedPlaying];
      }
      
      break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// HandleRebuildTuneLibrary()
//-----------------------------------------------------------------------------------------
void HandleRebuildTuneLibrary( void )
{
  g_ProgressSteps = 15 + MODE_MAX_MODES;
  g_ProgressStep  = 0;

  // PDS: Nice progress window..
  if( g_ProgressAlertView == nil )
  {
    g_ProgressAlertView = [[UIAlertView alloc] initWithTitle: @"Loading"
                                                     message: @"Please wait.."
                                                    delegate: g_MainViewController
                                           cancelButtonTitle: nil
                                           otherButtonTitles: nil ];
  }

  dispatch_sync( dispatch_get_main_queue(), ^
  {
    [g_ProgressAlertView show];
  } );
  
//  dispatch_async( dispatch_get_main_queue(), ^
  //               {
                   [g_MainViewController RebuildTuneLibrary];
//                 } );

  dispatch_sync( dispatch_get_main_queue(), ^
  {
    [g_ProgressAlertView dismissWithClickedButtonIndex:0 animated:NO];
  } );
}

//-----------------------------------------------------------------------------------------
// LogEvent()
//-----------------------------------------------------------------------------------------
void LogEvent( int evType )
{
  static char txEventName[ 100 ];
  
  switch( evType )
  {
    case evTIMER_CALLBACK:
      return;
      //strcpy( txEventName, "evTIMER_CALLBACK" );      break;
      
    // PDS: Player events..
    case evSTARTUP:         strcpy( txEventName, "evSTARTUP"         );  break;
    case evPLAY_SELECTED:   strcpy( txEventName, "evPLAY_SELECTED"   );  break;
    case evPLAY_STOP:       strcpy( txEventName, "evPLAY_STOP"       );  break;
    case evPLAY_STOP_ALL:   strcpy( txEventName, "evPLAY_STOP_ALL"   );  break;
    case evPLAY_TUNE:       strcpy( txEventName, "evPLAY_TUNE"       );  break;
    case evRESUME_TUNE:     strcpy( txEventName, "evRESUME_TUNE"     );  break;
    case evPAUSE_TUNE:      strcpy( txEventName, "evPAUSE_TUNE"      );  break;
    case evSTOP_TUNE:       strcpy( txEventName, "evSTOP_TUNE"       );  break;      
    case evPREV_TUNE:       strcpy( txEventName, "evPREV_TUNE"       );  break;
    case evNEXT_TUNE:       strcpy( txEventName, "evNEXT_TUNE"       );  break;
    case evPREV_SUBTUNE:    strcpy( txEventName, "evPREV_SUBTUNE"    );  break;
    case evNEXT_SUBTUNE:    strcpy( txEventName, "evNEXT_SUBTUNE"    );  break;
    case evMODE_SELECT:     strcpy( txEventName, "evMODE_SELECT"     );  break;
    case evSNAP:            strcpy( txEventName, "evSNAP"            );  break;
    case evSID_CHIP_TOGGLE: strcpy( txEventName, "evSID_CHIP_TOGGLE" );  break;
      
    // PDS: Manage events..
    case evDELETE_HATES:    strcpy( txEventName, "evDELETE_HATES"    );  break;
    case evUNHATE_ALL:      strcpy( txEventName, "evUNHATE_ALL"      );  break;
    case evLIKES_TO_PLIST:  strcpy( txEventName, "evLIKES_TO_PLIST"  );  break;
    case evSAFEKEEP_LIKES:  strcpy( txEventName, "evSAFEKEEP_LIKE"   );  break;
    case evREBUILD_LIB:     strcpy( txEventName, "evREBUILD_LIB"     );  break;
    case evCREATE_PLAYLIST: strcpy( txEventName, "evCREATE_PLAYLIST" );  break;
      
    case evCREATE_PLAYLIST_LIKES:
                            strcpy( txEventName, "evCREATE_PLAYLIST_LIKES" );  break;

    case evCREATE_PLAYLIST_ALBUM:
                            strcpy( txEventName, "evCREATE_PLAYLIST_ALBUM" );  break;
      
    case evCREATE_PLAYLIST_ARTIST:
                            strcpy( txEventName, "evCREATE_PLAYLIST_ARTIST" );  break;
      
    case evLIKE_TUNE:       strcpy( txEventName, "evLIKE_TUNE"       );  break;
    case evHATE_TUNE:       strcpy( txEventName, "evHATE_TUNE"       );  break;
      
    case evFREE_TVMANAGE:   strcpy( txEventName, "evFREE_TVMANAGE"   );  break;
  }
  
  LogDebugf( "Event: %s", txEventName );
}

//-----------------------------------------------------------------------------------------
// PlaySelected
//-----------------------------------------------------------------------------------------
-(void) PlaySelected
{
  PostPlayerEvent( evPLAY_SELECTED );  
}

//-----------------------------------------------------------------------------------------
// HandlePlaySelected()
//-----------------------------------------------------------------------------------------
void HandlePlaySelected( void )
{
  // PDS: Do this on same thread..
  HandleCreatePlayList();
  SaveSettings();
  
  char txTitle [ 512 ];
  char txArtist[ 128 ];
  char txAlbum [ 512 ];
  char txPath  [ 1024 ];
  int  nType;
  
  // PDS: Get the tune's library index..
  if( g_pvCurrPlayList->elementCount() < 1 )
  {
    LogDebugf( "PlaySelected: No tunes in playlist" );
    return;
  }
  
  int  nPlaylistIndex    = g_PlayListIndex[ g_CurrentMode ];
  
  if( nPlaylistIndex < 0 )
    nPlaylistIndex = 0;
  
  if( g_pvCurrPlayList->elementCount() < 1 )
    return;
  
  int  nTuneLibraryIndex = g_pvCurrPlayList->elementIntAt( nPlaylistIndex );
  
  if( nTuneLibraryIndex < 0 )
  {
    LogDebugf( "PlaySelected: Current tune not found" );
    return;
  }
  
  GetTuneInfo( nTuneLibraryIndex, txTitle, txArtist, txAlbum, txPath, &nType, &g_CurrentArtistIndexPlaying, &g_CurrentAlbumIndexPlaying );
  
  LogDebugf( "Playing: %s, by %s (idx: %d), album: %s  (TuneLibIndex: %d) g_CurrentMode: %d  PLIndex: %d", txTitle, txArtist, g_CurrentArtistIndexPlaying, txAlbum, nTuneLibraryIndex, g_CurrentMode, nPlaylistIndex );

  g_CurrentTuneLibIndexPlaying = nTuneLibraryIndex;
  
  if( IsRandomMode( g_CurrentMode ) )
  {
    // PDS: Follow current artist and album for drill down lists in case listener is curious about currently playing random control (ie. in this case there are not "in control" !
    g_CurrentArtistIndexSelected = g_CurrentArtistIndexPlaying;
    g_CurrentAlbumIndexSelected  = g_CurrentAlbumIndexPlaying;
  }
  
  g_CurrentUnitTypePlaying = nType;
  
  if( nType == UNIT_MP3 )
  {
    PlayTuneWithURL( txPath );
  }
  else
  {
    PlayTune( txTitle, nTuneLibraryIndex );
  }
  
  strcpy( g_txStatusTune,   txTitle );
  strcpy( g_txStatusArtist, txArtist );
  strcpy( g_txStatusAlbum,  txAlbum );

  // PDS: Do GUI updates - which are needed on the main thread.. However, I DON'T want to do this asynchonously!!
  dispatch_sync( dispatch_get_main_queue(), ^
  {
    // PDS: Update buttons to reflect features available for current tune type (eg. SID subtunes, MOD channel monotizing etc..)
    [g_MainViewController setupPlayerButtons];

    // PDS: Show what we're playing..
    [g_MainViewController SetStatusInfo: TRUE];
  
    [g_PlayStopButton setImage: g_ImageStop forState: UIControlStateNormal];
    [g_MainViewController UpdatePlayStopButton];
 
  } );
}

NSCondition *g_QueueEmptyCondition   = [[NSCondition alloc] init];
BOOL         g_TimerCallback         = FALSE;

//-----------------------------------------------------------------------------------------
// PostPlayerEvent()
//-----------------------------------------------------------------------------------------
void PostPlayerEvent( int evType, BYTE *pData, int nDataLen )
{
  PLAYERMSG *pMsg = (PLAYERMSG *) malloc( sizeof( PLAYERMSG ) );
  
  pMsg->nEventType = evType;
  
  //g_vPlayerEventQueue.addElement( evType );
  g_vPlayerEventQueue.addElement( (void*) pMsg );
  
  [g_QueueEmptyCondition lock];
  [g_QueueEmptyCondition signal];
  [g_QueueEmptyCondition unlock];
}

//-----------------------------------------------------------------------------------------
// PlayerThread()
//-----------------------------------------------------------------------------------------
void PlayerThread( void )
{
  SIDPlaySetup();
  MODPlaySetup();
  
  int nEventCount = 0;
  int evType      = evNO_EVENT;
  
  PLAYERMSG *pMsg;
  PLAYERMSG  msgCopy;
  
  for( ;; )
  {
    // PDS: --- Block thread until signalled condition ---
    [g_QueueEmptyCondition lock];

    while( ( ( nEventCount = g_vPlayerEventQueue.elementCount() ) < 1 ) &&
           ( g_TimerCallback == FALSE ) )
    {
      [g_QueueEmptyCondition wait];
    }

    g_TimerCallback = FALSE;
    [g_QueueEmptyCondition unlock];
    // PDS: --- Block thread until signalled condition ---

    
    if( nEventCount < 1 )
    {
      // PDS: Hack a callback event.. These are lower priority than whats in the queue.. and we never post them to the
      //      queue so its what we do if we have no events.. every 0.2 seconds..
      evType = evTIMER_CALLBACK;
    }
    else
    {
      // PDS: Lock..
      pMsg = (PLAYERMSG *) g_vPlayerEventQueue.elementPtrAt( 0 );
      
      memcpy( &msgCopy, pMsg, sizeof( PLAYERMSG ) );
      
      evType = msgCopy.nEventType;
      
      // PDS: Normally I'd copy the event..
      free( pMsg );
      
      // PDS: Normally I'd copy the event..
      g_vPlayerEventQueue.removeElementAt( 0 );
    }
    
    // PDS: Release lock..
    LogEvent( evType );
    
    switch( evType )
    {
      case evTIMER_CALLBACK:
      {
        //double dblStart = CFAbsoluteTimeGetCurrent();
        HandlePlayerTimerCallback();
        //double dblEnd   = CFAbsoluteTimeGetCurrent();
        
        //LogDebugf( "CB: %lf seconds", dblEnd-dblStart);
        break;
      }
      
      case evSTARTUP:
        break;
        
      case evPLAY_SELECTED:
        HandlePlaySelected( /*msgCopy.nTuneIndex*/ );
        break;

      case evRESUME_TUNE:
        HandleResumeTune();
        break;
        
      case evPAUSE_TUNE:
        HandlePauseTune();
        break;
        
      case evPLAY_STOP:
        HandlePlayStopTune();
        break;
        
      case evPREV_TUNE:
        HandlePrevTune();
        break;
        
      case evNEXT_TUNE:
        HandleNextTune();
        break;
        
      case evPREV_SUBTUNE:
        HandlePrevSubtune();
        break;
        
      case evNEXT_SUBTUNE:
        HandleNextSubtune();
        break;
   
      case evMODE_SELECT:
        HandleModePressed();
        break;
        
      case evSNAP:
        HandleSnapPressed();
        break;
        
      case evSID_CHIP_TOGGLE:
        HandleSIDChipToggle();
        break;
        
      case evCREATE_PLAYLIST_ALBUM:
        // PDS: This is on player thread because a play event will immediately follow..
        CreateSequencePlaylistForAlbum();
        break;
        
      case evCREATE_PLAYLIST_ARTIST:
        // PDS: This is on player thread because a play event will immediately follow..
        CreateRandomPlaylistForArtist();
        break;
        
      default:
        LogDebugf( "-NOT IMPLEMENTED IN PlayerThread()" );
        break;
    }
    
  }
}

//-----------------------------------------------------------------------------------------
// ManageThread()
//-----------------------------------------------------------------------------------------
void ManageThread( void )
{
  int nEventCount = 0;
  
  PLAYERMSG  msgCopy;
  PLAYERMSG *pMsg;
  
  for( ;; )
  {
    nEventCount = g_vManageEventQueue.elementCount();
    
    if( nEventCount < 1 )
    {
      [NSThread sleepForTimeInterval: 0.1];
      continue;
    }

    // PDS: Lock..
    pthread_mutex_lock( &g_ManageThreadQMutex );
   
    pMsg = (PLAYERMSG *) g_vManageEventQueue.elementPtrAt( 0 );
    
    memcpy( &msgCopy, pMsg, sizeof( PLAYERMSG ) );
    
    int evType = msgCopy.nEventType;
    
    // PDS: Normally I'd copy the event..
    free( pMsg );

    g_vManageEventQueue.removeElementAt( 0 );

    // PDS: Release lock..
    pthread_mutex_unlock( &g_ManageThreadQMutex );
    
    LogEvent( evType );
    
    g_ManageThreadBusy = TRUE;
    
    switch( evType )
    {
      case evDELETE_HATES:
        HandleDeleteAllHates();
        break;
        
      case evUNHATE_ALL:
        HandleUnhateAll();
        break;
        
      case evLIKES_TO_PLIST:
        HandleAddLikesToPlaylist();
        break;
        
      case evSAFEKEEP_LIKES:
        HandleSafekeepLikes();
        break;
        
      case evREBUILD_LIB:
        HandleRebuildTuneLibrary();
        break;
        
      case evCREATE_PLAYLIST:
        HandleCreatePlayList();
        break;
                
      case evCREATE_PLAYLIST_LIKES:
        PlaylistRandomLikes();
        break;

      case evLIKE_TUNE:
        HandleLikeTune();
        break;
        
      case evHATE_TUNE:
        HandleHateTune();
        break;
        
      case evFREE_TVMANAGE:
        g_tvManage = nil;
        break;
        
      default:
        LogDebugf( "-ManageThread eveny not handled" );
    }
    
    g_ManageThreadBusy = FALSE;
    
  }
}

//-----------------------------------------------------------------------------------------
// labelTouched
//-----------------------------------------------------------------------------------------
-(void) labelTouched
{
  // PDS: Show what we're playing..
  [g_MainViewController SetStatusInfo: TRUE];
}

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  [super viewDidLoad];

  [self setObserver];
  
  CGRect screenBound = [[UIScreen mainScreen] bounds];
  CGSize screenSize  = screenBound.size;
  
  g_MaxPixelWidth    = screenSize.width;
  g_MaxPixelHeight   = screenSize.height;
    
  // PDS: Allow other views to easily delegate back to this main view..
  g_MainViewController = self;
  
  UIImage     *background = [UIImage imageNamed: @"Default@2x.png"];
  UIImage     *scaledImage;
  
  scaledImage = [MyUtils scaleImage: background scaledToWidth: (float) g_MaxPixelWidth];
  background  = nil;

  g_vcImageView  = [[UIImageView alloc] initWithImage: scaledImage];
  g_vcImageView.tag = 0x1814;
  g_vcImageView.frame = CGRectMake( 0, -20, g_MaxPixelWidth, g_MaxPixelHeight );
  
  [self.view addSubview: g_vcImageView];
  
  [self updateStatus: @"Loading.."];

  // PDS: Nice progress window..
  g_ProgressAlertView = [[UIAlertView alloc] initWithTitle: @"Loading"
                                                   message: @"Please wait.."
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles: nil ];
  
  [g_ProgressAlertView show];
  
  backgroundQueue = dispatch_queue_create( "EventQ", NULL );
  
  g_PlayerThreadQueue = dispatch_queue_create( "PlayerQ", NULL );
  g_ManageThreadQueue = dispatch_queue_create( "ManageQ", NULL );
  
  
  pthread_mutex_init( &g_PlayerThreadQMutex, NULL );
  pthread_mutex_init( &g_ManageThreadQMutex, NULL );
  
  dispatch_async( g_PlayerThreadQueue, ^(void)  { PlayerThread(); } );
  dispatch_async( g_ManageThreadQueue, ^(void)  { ManageThread(); } );
  
  dispatch_async( backgroundQueue, ^(void)
  {
    // PDS: Load MP3 library
    [self SetupEverything];
  } );

  LogDebugf( "viewDidLoad:: DONE" );
}

- (void)viewDidUnload
{  
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  
  FreeImages();
  
  g_StatusScroller1 = nil;
  g_StatusScroller2 = nil;
  g_StatusScroller3 = nil;

  g_StatusTitle1 = nil;
  g_StatusTitle2 = nil;
  g_StatusTitle3 = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

//-----------------------------------------------------------------------------------------
// canBecomeFirstResponder
//-----------------------------------------------------------------------------------------
- (BOOL)canBecomeFirstResponder
{
  return YES;
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  // Turn on remote control event delivery
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
  
  // Set itself as the first responder
  [self becomeFirstResponder];
}

//-----------------------------------------------------------------------------------------
// viewWillDisappear
//-----------------------------------------------------------------------------------------
-(void) viewWillDisappear:(BOOL)animated
{
  // Turn off remote control event delivery
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  
  // Resign as first responder
  [self resignFirstResponder];  
  
	[super viewWillDisappear:animated];
}



- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

//-----------------------------------------------------------------------------------------
// dismissAll
//-----------------------------------------------------------------------------------------
-(void) dismissAll
{
  LogDebugf( "ViewController::dismissAll() called");
}


@end
