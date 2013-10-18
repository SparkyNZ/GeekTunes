//
//  TuneLibrary.mm
//  GeekTunes
//
//  Created by Paul Spark on 8/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define BOOL_DEFINED

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>

#import "ViewController.h"
#import "BackupRestoreVC.h"


#include "PaulPlayer.h"
#include "SIDPlayPaul.h"
#include "MODPlayPaul.h"
#include "mikmod.h"
#include "vector.h"
#include "Utils.h"
#include "XUnzip.h"
#include "ZIPDelete.h"
#include "Events.h"
#include "BarbUtils.h"
#include "CommonVectors.h"


#include <sys/stat.h>

extern ViewController *g_MainViewController;
extern UIAlertView    *g_ProgressAlertView;
extern UIProgressView *g_ProgressBar;
extern UILabel        *g_ProgressViewText;
extern int             g_ProgressStep;
extern int             g_ProgressSteps;

extern UIImage        *g_ImagePlayWhite;
extern UIImage        *g_ImageStop;

extern int             g_FavSelected;

@implementation ViewController (ExtraMethods)

AVPlayer *g_AVPlayer = nil;

#define TX_EXP_TUNESNAME          "TunesName"
#define TX_EXP_TUNESTYPE          "TunesType"
#define TX_EXP_TUNESPATH          "TunesPath"
#define TX_EXP_TUNESRATE          "TunesRate"
#define TX_EXP_TUNESRATE_MD5      "TunesRateMD5"
#define TX_EXP_ARTIST             "Artist"
#define TX_EXP_TUNES_ARTIST_INDEX "TunesArtistIdx"
#define TX_EXP_ALBUM              "Album"
#define TX_EXP_TUNES_ALBUM_INDEX  "TunesAlbumIdx"
#define TX_EXP_ALBUM_ARTIST_INDEX "AlbumArtistIdx"
#define TX_EXP_TUNESTRACK         "TunesTrack"
#define TX_EXP_SIDSONGLEN         "SIDSONGLENGTHS"
#define TX_EXP_SIDFILENAME        "SIDFILENAME"

char g_PathSafe                  [ MAX_PATH ];
char g_PathSettings              [ MAX_PATH ];
char g_PathSIDSettings           [ MAX_PATH ];
char g_PathEXP_TUNESNAME         [ MAX_PATH ];
char g_PathEXP_TUNESTYPE         [ MAX_PATH ];
char g_PathEXP_TUNESPATH         [ MAX_PATH ];
char g_PathEXP_TUNESRATE         [ MAX_PATH ];
char g_PathEXP_TUNESRATE_MD5     [ MAX_PATH ];
char g_PathEXP_ARTIST            [ MAX_PATH ];
char g_PathEXP_TUNES_ARTIST_INDEX[ MAX_PATH ];
char g_PathEXP_ALBUM             [ MAX_PATH ];
char g_PathEXP_TUNES_ALBUM_INDEX [ MAX_PATH ];
char g_PathEXP_ALBUM_ARTIST_INDEX[ MAX_PATH ];
char g_PathEXP_TUNESTRACK        [ MAX_PATH ];
char g_PathEXP_SIDSONGLEN        [ MAX_PATH ];
char g_PathEXP_SIDFILENAME       [ MAX_PATH ];
char g_PathEXP_FAVNAMES          [ MAX_PATH ];
char g_PathEXP_FAVACTIVE         [ MAX_PATH ];

char g_PathPlayListPositions     [ MAX_PATH ];

int  g_MP3Count = 0;
BOOL g_MP3CountChanged = FALSE;

Vector g_vFilesToDelete;
Vector g_vSIDFilesToDelete;

Vector g_vSIDSongLengths;
Vector g_vSIDFileNames;

Vector g_vFavouritePlaylistNames;


BOOL   g_DefaultPreferredFavouriteList = FALSE;


extern int    g_CurrentSIDSecsLong;
extern long   g_CurrentSIDSecsStart;
extern int    g_CurrentSIDNumSubTunes ;

extern UIButton *g_PlayStopButton;

BOOL   g_LibHasSID     = FALSE;
BOOL   g_LibHasMOD     = FALSE;
BOOL   g_LibHasNewMOD  = FALSE;
BOOL   g_LibHasXM      = FALSE;


// PDS: Rating minimum of tunes to include. Tunes drop to -1 when heard..
int g_IncludeRating = 0;

void PlaylistRandomCommon( BOOL    fIncludeMP3,
                           BOOL    fIncludeMod,
                           BOOL    fIncludeSID,
                           Vector *pvWithExtensions,
                           Vector *pvPlayList = NULL
                          );


//-----------------------------------------------------------------------------------------
// ProgressCallback()
//-----------------------------------------------------------------------------------------
void ProgressCallback( int nStep, int nSteps, int nPercent )
{
  //LogDebugf( "Progress: %d of %d  (%3d %%)", nStep, nSteps, nPercent );
  
  // PDS: Actual update of progress bar must be done on main (GUI) thread..
  dispatch_async( dispatch_get_main_queue(), ^
                 {
                   static int nLastStep = -1;
                   
                   // PDS: Update text if step changed..
                   if( g_ProgressStep != nLastStep )
                   {
                     char txTmp[ 100 ];
                     sprintf( txTmp, "Step %d of %d", g_ProgressStep, g_ProgressSteps );
                     nLastStep = g_ProgressStep;
                     
                     g_ProgressBar.progress = 0.0f;
                     
                     [g_ProgressAlertView setMessage: [NSString stringWithUTF8String: txTmp] ];
                   }
                   else
                   {
                     g_ProgressBar.progress  = nPercent / 100.0f;
                   }
                 } );
}

//-----------------------------------------------------------------------------------------
// IncProgress()
//-----------------------------------------------------------------------------------------
void IncProgress( void )
{
  if( g_ProgressStep < g_ProgressSteps )
    g_ProgressStep ++;
}

//-----------------------------------------------------------------------------------------
// ClearAllLibraryVectors()
//-----------------------------------------------------------------------------------------
void ClearAllLibraryVectors( void )
{
  g_vTunesName.removeAll();
  g_vTunesType.removeAll();
  g_vTunesPath.removeAll();
  g_vTunesRating.removeAll();
  g_vTunesTrack.removeAll();
  
  g_vTunesArtistIndex.removeAll();
  g_vTunesAlbumIndex.removeAll();
  g_vAlbumArtistIndex.removeAll();
  
  g_vArtist.removeAll();
  g_vAlbum.removeAll();
  
  // PDS: Save status now.. just in case..
  ExportLibrary();
}

//-----------------------------------------------------------------------------------------
// SetupExportPaths()
//-----------------------------------------------------------------------------------------
void SetupExportPaths( void )
{
  sprintf( g_PathSafe,        "%s/%s", g_txFTPPath, ".SafeKeeping" );
  sprintf( g_PathSettings,    "%s/%s", g_txFTPPath, ".Settings" );
  sprintf( g_txUnzipPath,     "%s/%s", g_txFTPPath, ".Unzip" );

  strcpy( g_PathSIDSettings, g_txFTPHome );
  
  if( ! FileExists( g_PathSafe ) )
    mkdir( g_PathSafe, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH );

  if( ! FileExists( g_PathSettings ) )
    mkdir( g_PathSettings, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH );

  if( ! FileExists( g_txUnzipPath ) )
    mkdir( g_txUnzipPath, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH );
  
  sprintf( g_PathSIDSettings, "%s/%s", g_txFTPPath, ".SIDSettings" );
  
  if( ! FileExists( g_PathSIDSettings ) )
    mkdir( g_PathSIDSettings, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH );
  
  sprintf( g_PathPlayListPositions,       "%s/%s", g_PathSettings, "PlayListPositions" );
  
  sprintf( g_PathEXP_TUNESNAME,           "%s/%s", g_PathSettings, TX_EXP_TUNESNAME );
  sprintf( g_PathEXP_TUNESTYPE,           "%s/%s", g_PathSettings, TX_EXP_TUNESTYPE );
  sprintf( g_PathEXP_TUNESPATH,           "%s/%s", g_PathSettings, TX_EXP_TUNESPATH );
  sprintf( g_PathEXP_TUNESRATE,           "%s/%s", g_PathSettings, TX_EXP_TUNESRATE );
  sprintf( g_PathEXP_TUNESRATE_MD5,       "%s/%s", g_PathSettings, TX_EXP_TUNESRATE_MD5 );
  sprintf( g_PathEXP_ARTIST,              "%s/%s", g_PathSettings, TX_EXP_ARTIST    );
  sprintf( g_PathEXP_TUNES_ARTIST_INDEX,  "%s/%s", g_PathSettings, TX_EXP_TUNES_ARTIST_INDEX );
  sprintf( g_PathEXP_ALBUM,               "%s/%s", g_PathSettings, TX_EXP_ALBUM );
  sprintf( g_PathEXP_TUNES_ALBUM_INDEX,   "%s/%s", g_PathSettings, TX_EXP_TUNES_ALBUM_INDEX );
  sprintf( g_PathEXP_ALBUM_ARTIST_INDEX,  "%s/%s", g_PathSettings, TX_EXP_ALBUM_ARTIST_INDEX );
  sprintf( g_PathEXP_TUNESTRACK,          "%s/%s", g_PathSettings, TX_EXP_TUNESTRACK );
  
  // PDS: These files should be installed by the user ?? Could I bundle these ??
  sprintf( g_PathEXP_SIDSONGLEN,          "%s/%s.vec", g_PathSIDSettings, "SIDSongLengths" );
  sprintf( g_PathEXP_SIDFILENAME,         "%s/%s.vec", g_PathSIDSettings, TX_EXP_SIDFILENAME );

  char txFullExportPath[ MAX_PATH ];
  char txModeName      [ MAX_PATH ];
  
  for( int i = 0; i < MODE_MAX_MODES; i ++ )
  {
    GetModeName( i, txModeName );
    sprintf( txFullExportPath, "%s/%s", g_PathSettings, txModeName );
    g_vPlayListExpPath.addElement( txFullExportPath );

    sprintf( txFullExportPath, "%s/%s.MD5", g_PathSettings, txModeName );
    g_vPlayListExpPathMD5.addElement( txFullExportPath );
  }

  sprintf( g_PathEXP_FAVNAMES, "%s/FAVNAMES", g_PathSettings );
  sprintf( g_PathEXP_FAVACTIVE, "%s/FAVACTIVE", g_PathSettings );
}

//-----------------------------------------------------------------------------------------
// ExportLibrary()
//-----------------------------------------------------------------------------------------
void ExportLibrary( void )
{
  LogDebugf( "ExportLib, g_MP3Count: %d", g_MP3Count );
  
  g_vTunesName.exportToFile( TX_EXP_TUNESNAME, g_PathEXP_TUNESNAME );
  g_vTunesType.exportToFileInt( TX_EXP_TUNESTYPE, g_PathEXP_TUNESTYPE );
  g_vTunesPath.exportToFile( TX_EXP_TUNESPATH, g_PathEXP_TUNESPATH );
  g_vTunesRating.exportToFileInt( TX_EXP_TUNESRATE, g_PathEXP_TUNESRATE );
  g_vTunesRatingMD5.exportToFile( TX_EXP_TUNESRATE_MD5, g_PathEXP_TUNESRATE_MD5 );
  g_vTunesTrack.exportToFileInt( TX_EXP_TUNESTRACK, g_PathEXP_TUNESTRACK );
  
  g_vArtist.exportToFile( TX_EXP_ARTIST, g_PathEXP_ARTIST );
  g_vTunesArtistIndex.exportToFileInt( TX_EXP_TUNES_ARTIST_INDEX, g_PathEXP_TUNES_ARTIST_INDEX );
  
  g_vAlbum.exportToFile( TX_EXP_ALBUM, g_PathEXP_ALBUM );
    
  g_vTunesAlbumIndex.exportToFileInt( TX_EXP_TUNES_ALBUM_INDEX, g_PathEXP_TUNES_ALBUM_INDEX );
  g_vAlbumArtistIndex.exportToFileInt( TX_EXP_ALBUM_ARTIST_INDEX, g_PathEXP_ALBUM_ARTIST_INDEX );

  SaveSettings();
}

//-----------------------------------------------------------------------------------------
// DeterminePresentTuneTypes()
//-----------------------------------------------------------------------------------------
void DeterminePresentTuneTypes( void )
{
  // PDS: Set flags indicating what type of tunes are in the library..
  for( int i = 0; i < g_vTunesPath.elementCount(); i ++ )
  {
    char *pszPath = g_vTunesPath.elementStrAt( i );
    
    if( g_LibHasXM == FALSE )
    {
      if( IsXMFile( pszPath ) )
        g_LibHasXM = TRUE;
    }
    
    if( g_LibHasSID == FALSE )
    {
      if( IsSIDFile( pszPath ) )
        g_LibHasSID = TRUE;
    }
    
    if( g_LibHasMOD == FALSE )
    {
      if( IsMODFile( pszPath ) )
        g_LibHasMOD = TRUE;
    }
    
    if( g_LibHasNewMOD == FALSE )
    {
      if( IsNewMODFile( pszPath ) )
        g_LibHasNewMOD = TRUE;
    }
    
    if( ( g_LibHasMOD ) && ( g_LibHasSID ) && ( g_LibHasXM ) && ( g_LibHasNewMOD ) )
      break;
  }

  LogDebugf( "Has SID: %d", g_LibHasSID );
  LogDebugf( "Has XM : %d", g_LibHasXM );
  LogDebugf( "Has MOD: %d", g_LibHasMOD );
  LogDebugf( "Has NEW: %d", g_LibHasNewMOD );
}

//-----------------------------------------------------------------------------------------
// ImportLibrary()
//-----------------------------------------------------------------------------------------
void ImportLibrary( void )
{
  IncProgress();
  g_vTunesName.importFromFile( TX_EXP_TUNESNAME, g_PathEXP_TUNESNAME, ProgressCallback );

  LogDebugf( "Imported %d tunes",   g_vTunesName.elementCount() );
  
  /*
  for( int i = 0; i < g_vTunesName.elementCount(); i ++ )
  {
    LogDebugf( "Imported: %s", g_vTunesName.elementStrAt( i ) );
  }
  */

  IncProgress();
  g_vTunesType.importFromFileInt( TX_EXP_TUNESTYPE, g_PathEXP_TUNESTYPE, ProgressCallback );
  
  IncProgress();
  g_vTunesPath.importFromFile( TX_EXP_TUNESPATH, g_PathEXP_TUNESPATH, ProgressCallback );

  IncProgress();
  g_vTunesRating.importFromFileInt( TX_EXP_TUNESRATE, g_PathEXP_TUNESRATE, ProgressCallback );
  
  IncProgress();
  g_vTunesTrack.importFromFileInt( TX_EXP_TUNESTRACK, g_PathEXP_TUNESTRACK, ProgressCallback );
  
  IncProgress();
  g_vArtist.importFromFile( TX_EXP_ARTIST, g_PathEXP_ARTIST, ProgressCallback );
  
  IncProgress();
  g_vTunesArtistIndex.importFromFileInt( TX_EXP_TUNES_ARTIST_INDEX, g_PathEXP_TUNES_ARTIST_INDEX, ProgressCallback );
  
  IncProgress();
  g_vAlbum.importFromFile( TX_EXP_ALBUM, g_PathEXP_ALBUM, ProgressCallback );
  
  IncProgress();
  g_vTunesAlbumIndex.importFromFileInt( TX_EXP_TUNES_ALBUM_INDEX, g_PathEXP_TUNES_ALBUM_INDEX, ProgressCallback );
  
  IncProgress();
  g_vAlbumArtistIndex.importFromFileInt( TX_EXP_ALBUM_ARTIST_INDEX, g_PathEXP_ALBUM_ARTIST_INDEX, ProgressCallback );
  
  // PDS: Import the SID paired vectors..
  IncProgress();
  g_vSIDFileNames.importFromFile( TX_EXP_SIDFILENAME, g_PathEXP_SIDFILENAME, ProgressCallback );
  
  IncProgress();
  g_vSIDSongLengths.importFromFile( TX_EXP_SIDSONGLEN, g_PathEXP_SIDSONGLEN, ProgressCallback );
  
  //LogDebugf( "Sid files: %d", g_vSIDFileNames.elementCount() );
  //LogDebugf( "Sid lens:  %d", g_vSIDSongLengths.elementCount() );
  
  IncProgress();
}

//-----------------------------------------------------------------------------------------
// ImportMD5Info()
//-----------------------------------------------------------------------------------------
void ImportMD5Info( void )
{
  // PDS: After rebuilding a new library, assign any likes or playlist items if we have any
  //      of those same tunes still..
  int   i;
  int   nTotal = g_vTunesName.elementCount();
  char  txHashCurrent[ MD5_ASC_SIZE + 1 ];
  
  for( i = 0; i < nTotal; i ++ )
  {
    GetHashForTuneIndexInLib( txHashCurrent, i );
    
    // PDS: Add to likes..
    if( g_vTunesRatingMD5.contains( txHashCurrent ) )
    {
      LogDebugf( "** Found MD5 LIKES match (%s)", g_vTunesName.elementStrAt( i ) );
      g_vTunesRating.setElementAt( i, 1 );
    }
    
    // PDs: Now add to any playlists..
    for( int p = 0; p < MODE_MAX_MODES; p ++ )
    {
      if( g_vPlayListMD5[ p ].contains( txHashCurrent ) )
      {
        LogDebugf( "** Found MD5 FAV%d match (%s)", p, g_vTunesName.elementStrAt( i ) );

        g_vPlayList[ p ].addUnique( i );
      }
    }
  }
}

//-----------------------------------------------------------------------------------------
// ExportRatings()
//-----------------------------------------------------------------------------------------
void ExportRatings( void )
{
  static BOOL fExporting  = FALSE;
  
  if( fExporting )
    return;
  
  // PDS: Avoid potential re-entrancy..
  fExporting = TRUE;
  g_vTunesRating.exportToFileInt( TX_EXP_TUNESRATE, g_PathEXP_TUNESRATE );
  g_vTunesRatingMD5.exportToFile( TX_EXP_TUNESRATE_MD5, g_PathEXP_TUNESRATE_MD5 );
  fExporting = FALSE;
}

//-----------------------------------------------------------------------------------------
// AddTuneToLibrary()
//-----------------------------------------------------------------------------------------
void AddTuneToLibrary( char *pszTitle, char *pszArtist, char *pszAlbum, char *pszPath, char *pszTrackNum, int nType )
{
  static int nUnknownArtistIdx = -1;
  static int nUnknownAlbumIdx  = -1;
  
  char   txArtist[  100 ];
  char   txAlbum [  512 ];
  char   txPath  [ 1024 ];
  int    nTrackNum;
  BOOL   fUnknownArtist = FALSE;
  BOOL   fUnknownAlbum  = FALSE;
  
  if( pszTrackNum )
    nTrackNum = atoi( pszTrackNum );
  else
    nTrackNum = -1;
  
  if( pszArtist == nil )
  {
    strcpy( txArtist, "Unknown" );
    fUnknownArtist = TRUE;
  }
  else
    strcpy( txArtist, pszArtist );
  
  if( pszAlbum == nil )
  {
    strcpy( txAlbum, "Unknown" );
    fUnknownAlbum = TRUE;
  }
  else
    strcpy( txAlbum, pszAlbum );
  
  if( pszPath == nil )
    strcpy( txPath, "" );
  else
    strcpy( txPath, pszPath );
    
  g_vTunesName.addElement( pszTitle );
  g_vTunesType.addElement( nType );
  g_vTunesPath.addElement( txPath );
  g_vTunesTrack.addElement( nTrackNum );
  
  // PDS: Unrated.. Leave listener to lower or up the rating..
  g_vTunesRating.addElement( 0 );
  
  
  int nArtistIndex;
  
  if( ( fUnknownArtist ) && ( nUnknownArtistIdx >= 0 ) )
    nArtistIndex = nUnknownArtistIdx;
  else
    nArtistIndex = g_vArtist.indexOf( txArtist );
  
  if( nArtistIndex < 0 )
  {
    nArtistIndex = g_vArtist.elementCount();
    g_vArtist.addElement( txArtist );
    
    // PDS: Maintain index of unknown artist (optimisation - save searching for it each time)
    if( ( fUnknownArtist ) && ( nUnknownArtistIdx < 0 ) )
      nUnknownArtistIdx = g_vArtist.elementCount() - 1;
  }
  
  g_vTunesArtistIndex.addElement( nArtistIndex );
  
  // PDS: Now add album info..
  int nAlbumIndex;
  
  if( ( fUnknownAlbum ) && ( nUnknownAlbumIdx >= 0 ) )
    nAlbumIndex = nUnknownAlbumIdx;
  else
    nAlbumIndex = g_vAlbum.indexOf( txAlbum );
    
  if( nAlbumIndex < 0 )
  {
    nAlbumIndex = g_vAlbum.elementCount();
    g_vAlbum.addElement( txAlbum );
    g_vAlbumArtistIndex.addElement( nArtistIndex );
    
    // PDS: Maintain index of unknown album (optimisation - save searching for it each time)
    if( ( fUnknownAlbum ) && ( nUnknownAlbumIdx < 0 ) )
      nUnknownAlbumIdx = g_vAlbum.elementCount() - 1;
  }
  
  g_vTunesAlbumIndex.addElement( nAlbumIndex );  
}

//-----------------------------------------------------------------------------------------
// AddZIPToLibrary()
//-----------------------------------------------------------------------------------------
void AddZIPToLibrary( char *pZipFile )
{
  char   txInnerFile  [ MAX_PATH ];
  char   txFullZipPath[ MAX_PATH ];
  Vector vFiles;
  
  //GetFullZipPath( pZipFile, txFullZipPath );
  
  // PDS: Get full path of the .zip but DO NOT use GetFullZipPath() as this contains the Unzip folder
  MakeDocumentsPath( pZipFile, txFullZipPath );
  
  // PDS: We need to examine file(s) within ZIP to get the type of file..
  GetZIPInnerFilenames( txFullZipPath, &vFiles );
  
  for( int i = 0; i < vFiles.elementCount(); i ++ )
  {
    strcpy( txInnerFile, vFiles.elementStrAt( i ) );
   
    LogDebugf( "Inner File: %s", txInnerFile );
    
    // PDS: Only add one file for now.. path to the file is the ZIP file..
    if( IsMODFile( txInnerFile ) )
    {
      AddMODToLibrary( txInnerFile, NULL, NULL, txFullZipPath );
      break;
    }
    else
    if( IsSIDFile( txInnerFile ) )
    {
      AddSIDToLibrary( txInnerFile, NULL, NULL, txFullZipPath );
      break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// AddMODToLibrary()
//-----------------------------------------------------------------------------------------
void AddMODToLibrary( char *pszTitle, char *pszArtist, char *pszAlbum, char *pszPath )
{
  // PDS: Maybe extract artist info at a later date..
  AddTuneToLibrary( pszTitle, NULL, NULL, pszPath, 0, UNIT_MOD );
}

//-----------------------------------------------------------------------------------------
// AddSIDToLibrary()
//-----------------------------------------------------------------------------------------
void AddSIDToLibrary( char *pszTitle, char *pszArtist, char *pszAlbum, char *pszPath )
{
  // PDS: Maybe extract artist info at a later date..  
  AddTuneToLibrary( pszTitle, pszArtist, NULL, pszPath, 0, UNIT_SID );
}

//-----------------------------------------------------------------------------------------
// RefreshTuneLibrary
//-----------------------------------------------------------------------------------------
-(void) RefreshTuneLibrary
{
  ClearAllLibraryVectors();
  
  // PDS: Load all MP3s.
  MPMediaQuery *allSongsQuery = [MPMediaQuery   songsQuery];
  NSArray      *allSongsArray = [allSongsQuery  collections];
  
  int nTotalSongs  = [allSongsArray count];
  int nAdded       = 0;
  int nPercent     = 0;
  int nLastPercent = 0;
  
  //LogDebugf( "All songs count: %d", [allSongsArray count] );
    
  NSString    *nsURL;
  
  for( MPMediaItemCollection *collection in allSongsArray )
  {
    MPMediaItem *item     = [collection representativeItem];
    NSString    *nsArtist = [item valueForProperty: MPMediaItemPropertyArtist];
    NSString    *nsSong   = [item valueForProperty: MPMediaItemPropertyTitle];
    NSString    *nsAlbum  = [item valueForProperty: MPMediaItemPropertyAlbumTitle];
    NSURL       *url      = [item valueForProperty: MPMediaItemPropertyAssetURL];  
    //NSString    *nsTrack  = [item valueForProperty: MPMediaItemPropertyAlbumTrackNumber];
    
    NSString    *nsTrack  = [NSString stringWithFormat: @ "%@", [item valueForProperty: MPMediaItemPropertyAlbumTrackNumber]];
            
    // PDS: Some URLs are broken in the iPod - DO NOT add those..
    if( ( url == nil ) || /* ( nsArtist == nil ) || */ ( nsSong == nil ) )
    {
      continue;
    }
    
    nsURL  = [url absoluteString];
    
    AddTuneToLibrary( (char *) [nsSong   UTF8String], 
                      (char *) [nsArtist UTF8String],
                      (char *) [nsAlbum  UTF8String],
                      (char *) [nsURL    UTF8String], 
                      (char *) [nsTrack  UTF8String], 
                      UNIT_MP3 );
    
    // PDS: Progress callback..
    nPercent = ( nAdded * 100 ) / nTotalSongs;
    
    if( nPercent != nLastPercent )
    {
      ProgressCallback( 1, 1, nPercent );
      nLastPercent = nPercent;
    }
    
    nAdded ++;
  }
  
  //LogDebugf( "Songs LOADED: %d", g_vTunesName.elementCount() );
    
  return;
}

//-----------------------------------------------------------------------------------------
// GetTuneInfo
//-----------------------------------------------------------------------------------------
BOOL GetTuneInfo( int nIndex, char *pTune, char *pArtist, char *pAlbum, char *pURL, int *pnType, int *pnArtistIndex, int *pnAlbumIndex )
{
  if( ( nIndex < 0 ) || ( nIndex >= g_vTunesName.elementCount() ) )
    return FALSE;
  
  if( pTune )
    strcpy( pTune, g_vTunesName.elementStrAt( nIndex ) );
  
  char *pPath = g_vTunesPath.elementStrAt( nIndex );
  
  strcpy( pURL,  pPath );
  
  int   nArtist = g_vTunesArtistIndex.elementIntAt( nIndex );
  int   nAlbum  = g_vTunesAlbumIndex.elementIntAt( nIndex );
  
  strcpy( pArtist, g_vArtist.elementStrAt( nArtist ) );
  strcpy( pAlbum,  g_vAlbum.elementStrAt( nAlbum ) );
  
  (*pnType)        = g_vTunesType.elementIntAt( nIndex );
  
  if( pnArtistIndex )
    (*pnArtistIndex) = nArtist;
  
  if( pnAlbumIndex )
    (*pnAlbumIndex)  = nAlbum;
  
  return TRUE;
}

//-----------------------------------------------------------------------------------------
// FindTuneMatch()
//
// PDS: Pattern match find a tune and return its index
//-----------------------------------------------------------------------------------------
int FindTuneMatch( char *pszTune )
{
  int nIndex = g_vTunesName.indexOfStringStartingWith( pszTune );
  
  LogDebugf( "---- Find Match with[%s]---->",pszTune );
  
  /*
  for( int i = 0; i < g_vTunesName.elementCount(); i ++ )
  {
    LogDebugf( "  %d:%s", i, g_vTunesName.elementStrAt( i ) );
  }
  */
  return nIndex;
}

//-----------------------------------------------------------------------------------------
// TuneFinishedPlaying
//-----------------------------------------------------------------------------------------
-(void) TuneFinishedPlaying
{  
  LogDebugf( "Tune finished.. onto next.." );
  
  // PDS: Make sure iPod itself doesn't jump onto next tune..
  g_AVPlayer = nil;
  
  [self NextTune];
}

//-----------------------------------------------------------------------------------------
// PlayTuneWithURL
//-----------------------------------------------------------------------------------------
void PlayTuneWithURL( char *pURL )
{
  NSString *nsURL = [NSString stringWithUTF8String: pURL];

  //LogDebugf( "Play: %s by %s", pTune, pArtist );

  NSURL *url = [[NSURL alloc] initWithString: nsURL];
  
  StopSIDorMOD();
  
  dispatch_sync( dispatch_get_main_queue(), ^
  {
    if( g_AVPlayer )
    {
      g_AVPlayer = nil;
    }
  
    // PDS Play..
    if( ! g_AVPlayer )
    {
      // PDS: Audio session is required even for media/mp3 playback otherwise locking of iPod will stop playback!
      SetupAudioSession();
      
      AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
      
      // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
      [[NSNotificationCenter defaultCenter] addObserver: g_MainViewController
                                               selector: @selector( TuneFinishedPlaying )
                                                   name: AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
      
      g_AVPlayer =  [ [AVPlayer alloc] initWithPlayerItem:playerItem];
    }
    
    [g_AVPlayer play];
  } );
  
  g_UnitType = UNIT_MP3;
  LogDebugf( "#### UNIT_MP3" );
  
}

//-----------------------------------------------------------------------------------------
// IsArchivedSID()
//-----------------------------------------------------------------------------------------
BOOL IsArchivedSID( char *pszPath, char *pszZip, char *pszZipInnerFilePath )
{
  char *pArchive;
  
  pArchive = stristr( pszPath, ".zip::" );
  
  if( ! pArchive )
    return FALSE;
  
  pArchive = strstr( pszPath, "::" );
  
  long lOffset = (long) pArchive - (long) pszPath; 
  
  strcpy( pszZipInnerFilePath, &pArchive[ 2 ] ); 
  memcpy( pszZip, pszPath, lOffset );
  pszZip[ lOffset ] = 0;
         
  return TRUE;
}

//-----------------------------------------------------------------------------------------
// PlayTune
//-----------------------------------------------------------------------------------------
void PlayTune( char *pszTitle, int nTuneLibIndex )
{
  char txArtist      [  100 ];
  char txAlbum       [  512 ];
  char txPath        [ MAX_PATH ] = { 0 };
  char txZip         [ MAX_PATH ];
  char txZipInnerFile[ MAX_PATH ];
  int  nType;

  GetTuneInfo( nTuneLibIndex, NULL, txArtist, txAlbum, txPath, &nType, NULL, NULL );
  
  HandleStopTune();

  if( IsArchivedSID( txPath, txZip, txZipInnerFile ) )
  {
    char txFullZipPath     [ MAX_PATH ];
    char txTuneFilenameOnly[ MAX_PATH ];
    
    LogDebugf( "Zip[%s]  File:[%s]", txZip, txZipInnerFile );
    
    //    [1394.sid] path[C64MUSIC.ZIP::C64Music/DEMOS/0-9/1394.sid]
    sprintf( txFullZipPath, "%s/%s", g_PathSIDSettings, txZip );

    RemoveAllIn( g_txUnzipPath );    
    
    UnzipFileInZip( txFullZipPath, g_txUnzipPath, txZipInnerFile );

    LogDebugf( "UnzipPath(%s)", g_txUnzipPath );
    
    GetFilenameOnly( txZipInnerFile, txTuneFilenameOnly );    
    
    // PDS: Modify the path of the .MOD or .SID file that will be played..
    strcpy( txPath, g_txUnzipPath ); 
    strcat( txPath, "/" );
    strcat( txPath, txTuneFilenameOnly );
  }
  else  
  // PDS: Copy and unzip file if required..
  if( IsZIPFile( txPath ) )
  {
    char txFullUnzipPath   [ MAX_PATH ];
    char txZIPFilenameOnly [ MAX_PATH ];
    char txTuneFilenameOnly[ MAX_PATH ];

    LogDebugf( "txPath[%s]", txPath );
    
    // PDS: Also need to remove doc path before generating new long path!
    GetFilenameOnly( txPath, txZIPFilenameOnly );
    
    LogDebugf( "txZIPFilenameOnly[%s]", txZIPFilenameOnly );

    GetFullUnzipPath( txZIPFilenameOnly, txFullUnzipPath );
    
    RemoveAllIn( g_txUnzipPath );

    LogDebugf( "txFullZipPath[%s]", txFullUnzipPath );

    [MyUtils CopyFile: txPath to: txFullUnzipPath];
    
    // PDS: We need to examine file(s) within ZIP to get the type of file.. get that while unzipping..    
    UnzipGetInnerFilename( txFullUnzipPath, g_txUnzipPath, txTuneFilenameOnly );

    // PDS: Modify the path of the .MOD or .SID file that will be played..
    strcpy( txPath, g_txUnzipPath ); 
    strcat( txPath, "/" );
    strcat( txPath, txTuneFilenameOnly );
        
    LogDebugf( "New path (to play):[%s]", txPath );
  }
  
  if( txPath[ 0 ] == 0 )
    return;
  
  switch ( nType ) 
  {
    case UNIT_MOD:
      PlayMODAtPath( txPath );
      break;
      
    case UNIT_SID:
      PlaySIDAtPath( txPath, nTuneLibIndex );
      break;

    case UNIT_MP3:
      PlayTuneWithURL( txPath );
      break;
      
    default:
      break;
  }
}

//-----------------------------------------------------------------------------------------
// GetSIDInfo()
//-----------------------------------------------------------------------------------------
void GetSIDInfo( char *txSIDLibPath, char *txTitle, char *txAuthor )
{
  if( stristr( txSIDLibPath, "GAMES/" ) )
  {
    strcpy( txAuthor, "Games" ); 
    return;
  }
  
  char *pMusicians = stristr( txSIDLibPath, "MUSICIANS/" );
  
  if( pMusicians )
  {
    // PDS: Find second slash after MUSICIANS/0-9/
    char *pSlash2 = strchr( &pMusicians[ 10 ], '/' );
    
    if( ! pSlash2 )
      return;
    
    char *pSlash3 = strchr( &pSlash2[ 1 ], '/' );

    if( ! pSlash3 )
      return;
    
    int   nAuthorLen = (long) pSlash3 - (long) &pSlash2[ 1 ];
    memcpy( txAuthor, &pSlash2[ 1 ], nAuthorLen );
    txAuthor[ nAuthorLen ] = 0;
    
    //LogDebugf( "Author[%s]", txAuthor );
    return;
  }
  
  strcpy( txAuthor, "Misc" ); 
}


Vector vSIDPath;
Vector vSIDAuthors;
Vector vSIDTuneAuthIdx;
Vector vSIDTuneTitle;

//-----------------------------------------------------------------------------------------
// GetSIDInfo2()
//-----------------------------------------------------------------------------------------
BOOL GetSIDInfo2( char *pszZipFullPath, char *pszTitle, char *pszAuthor )
{
  if( memcmp( pszZipFullPath, "C64Music/", 9 ) != 0 )
    return FALSE;
  
  // PDS: I removed C64Music/ from my vectors to save space..
  char *pTruncC64MUSIC = &pszZipFullPath[ 9 ];
  int   nIndex = vSIDPath.indexOf( pTruncC64MUSIC );
  
  if( nIndex < 0 )
    return FALSE;
  
  if( nIndex >= vSIDTuneTitle.elementCount() )
  {
    //LogDebugf( "FAILED, index %d %s", nIndex, pTruncC64MUSIC );
    return FALSE;
  }
  
  strcpy( pszTitle, vSIDTuneTitle.elementStrAt( nIndex ) ); 
  
  int nAuthorIndex = vSIDTuneAuthIdx.elementIntAt( nIndex );
  
  strcpy( pszAuthor, vSIDAuthors.elementStrAt( nAuthorIndex ) );
  
  return TRUE;
}

//-----------------------------------------------------------------------------------------
// MoveToSIDSettings()
//-----------------------------------------------------------------------------------------
void MoveToSIDSettings( char *pFile )
{
  char txUserPath[ MAX_PATH ];
  char txSIDPath [ MAX_PATH ];
  char txSensFile[ MAX_PATH ];

  if( FileExistsInPath( g_txFTPPath, pFile, txSensFile ) )
  {
    LogDebugf( "Moving %s..", txSensFile );
    
    sprintf( txUserPath, "%s/%s", g_txFTPPath, txSensFile );
    
    LogDebugf( "MoveSID[%s] - File only", txSensFile );
    LogDebugf( "MoveSID[%s]", txUserPath );
    
    sprintf( txSIDPath,  "%s/%s", g_PathSIDSettings, txSensFile );
    [MyUtils CopyFile: txUserPath to: txSIDPath];
    
    remove( txUserPath );
  }
}

//-----------------------------------------------------------------------------------------
// MoveAnySIDSettings()
//
// PDS: Help users by stopping accidental deletion of their SID settings..
//-----------------------------------------------------------------------------------------
void MoveAnySIDSettings( void )
{
  MoveToSIDSettings( "SIDTuneTitle.vec" );
  MoveToSIDSettings( "SIDTuneAuthorIdx.vec" );
  MoveToSIDSettings( "SIDAuthors.vec" );
  MoveToSIDSettings( "SIDTunePath.vec" );
  
  MoveToSIDSettings( "SIDSongLengths.vec" );
  MoveToSIDSettings( "SIDFILENAME.vec" );
}

//-----------------------------------------------------------------------------------------
// HVSCImport()
//-----------------------------------------------------------------------------------------
void HVSCImport( void )
{
  LogDebugf( "HVSC import.." );
  
  char   txFileOnly [ MAX_PATH ];
  char   txHVSCZip  [ MAX_PATH ];
  char  *pszHVSC;
  char   txExpPath   [ MAX_PATH ];
  char   txExpAuthors[ MAX_PATH ];
  char   txExpAuthIdx[ MAX_PATH ];
  char   txExpTitle  [ MAX_PATH ];
  
  Vector vFiles;
  BOOL   fIndicesFound = FALSE;
    
  LogDebugf( "DocsDir[%@]", g_DocumentsDirectory );

  sprintf( txExpTitle,   "%s/SIDTuneTitle.vec",     g_PathSIDSettings );
  sprintf( txExpAuthIdx, "%s/SIDTuneAuthorIdx.vec", g_PathSIDSettings );
  sprintf( txExpAuthors, "%s/SIDAuthors.vec",       g_PathSIDSettings );
  sprintf( txExpPath,    "%s/SIDTunePath.vec",      g_PathSIDSettings );
  
  LogDebugf( "Import SID file info.." );
  
  if( ( FileExists( txExpPath    ) ) &&
      ( FileExists( txExpAuthIdx ) ) &&
      ( FileExists( txExpAuthors ) ) &&
      ( FileExists( txExpTitle   ) ) )
  {
    vSIDTuneTitle.importFromFile( "SIDTITLE", txExpTitle );
    vSIDTuneAuthIdx.importFromFile( "SIDAUTHIDX", txExpAuthIdx );
    vSIDAuthors.importFromFile( "SIDAUTHORS", txExpAuthors );
    vSIDPath.importFromFile( "SIDPATH", txExpPath );
    
    LogDebugf( "SID indices all found, %d entries", vSIDTuneTitle.elementCount() );
    
    fIndicesFound = TRUE;
  }  
  
  // PDS: Test import of sids in ONE zip file ..
  [MyUtils findAllFilesInPath: g_DocumentsDirectory containing: "HVSC" andAlso: ".zip" populate: &vFiles ];
  
  if( vFiles.elementCount() == 1 )
  {  
    char  *pszInnerFile;  

    pszHVSC = vFiles.elementStrAt( 0 );
    
    MakeDocumentsPath( pszHVSC, txHVSCZip );
    
    // PDS: See how many files are in the ZIP.. extract the .ZIP if it contains one .ZIP..
    GetZIPInnerFilenames( txHVSCZip, &vFiles );
    
    if( vFiles.elementCount() != 1 )
      return;
    
    pszInnerFile = vFiles.elementStrAt( 0 );
    
    if( ! stristr( pszInnerFile, ".zip" ) )
      return;
    
    RemoveAllIn( g_txUnzipPath );
    
    // PDS: Unzip the file to home folder..
    UnzipAllFiles( txHVSCZip, g_txFTPPath );
    
    // PDS: Get rid of HVSC.zip file..
    remove( txHVSCZip );
    
    // PDS: Now process C64MUSIC.ZIP.. the inner file..
    MakeDocumentsPath( pszInnerFile, txHVSCZip );      
  }  
  else
  {
    char txUnzipZip[ MAX_PATH ];
            
    // PDS: Case insensitively find if zip file is there.. and get real case sensitive name..
    if( FileExistsInPath( g_txUnzipPath, "C64MUSIC.ZIP", txFileOnly ) )
    {
      sprintf( txUnzipZip, "%s/%s", g_txUnzipPath, txFileOnly );
      sprintf( txHVSCZip,  "%s/%s", g_txFTPPath,   txFileOnly );
      
      LogDebugf( "Unzip C64Path[%s]", txUnzipZip );
      
      LogDebugf( "Moving [%s] to [%s]", txUnzipZip, txHVSCZip );
      [MyUtils MoveFile: txUnzipZip to: txHVSCZip];
    }
  }

  if( FileExistsInPath( g_txFTPHome, "C64MUSIC.ZIP", txFileOnly ) )
  {
    // PDS: Put the ZIP to a safe place to user can add/delete all files when fiddling with bundles of MOD files etc..
    MoveToSIDSettings( "C64MUSIC.ZIP" );
  }
  
  if( ! FileExistsInPath( g_PathSIDSettings, "C64MUSIC.ZIP", txFileOnly ) )
    return;    
  
  dispatch_sync( dispatch_get_main_queue(), ^
  {
    [g_ProgressAlertView setTitle: @"Importing SIDs.."];
  } );
  
  LogDebugf( "C64Music.zip in home path" );
  
  // PDS: Get full filename..
  sprintf( txHVSCZip,  "%s/%s", g_PathSIDSettings, txFileOnly );
  
  // PDS: OK, the trick here is that I want to interrogate the ZIP file for info.. NOT extract it! ;-)
  int  nSIDsFound = 0;
  char txSIDLibPath [ MAX_PATH ];
  char txSIDNameOnly[ MAX_PATH ];
  BOOL fGotInfo;
  
  char txTitle [ MAX_PATH ] = { 0 };
  char txAuthor[ MAX_PATH ] = { 0 };
  char txInfo  [ 100 ];
  
  LogDebugf( "Scanning C64MUSIC.ZIP.." );
  
  ZipList( txHVSCZip, &vFiles );

  char *pszFile;
  
  for( int f = 0; f < vFiles.elementCount(); f ++ )
  {    
    fGotInfo = FALSE;

    pszFile = vFiles.elementStrAt( f );
    
    if( IsSIDFile( pszFile ) )
    {
      strcpy( txSIDLibPath, txFileOnly );
      strcat( txSIDLibPath, "::" );
      strcat( txSIDLibPath, pszFile );
      
      GetFilenameOnly( txSIDLibPath, txSIDNameOnly );

      //LogDebugf( "Add HVSC file[%s] path[%s]", txSIDNameOnly, txSIDLibPath );
   
      // PDS: Unfortunately this is STILL too slow!
      //if( fIndicesFound )
      //  fGotInfo = GetSIDInfo2( ze.name, txTitle, txAuthor );

      // PDS: Below method extracts author name from MUSICIANS path.. but won't get ALL authors for GAMES/DEMOS dir..      
      if( ! fGotInfo )
        GetSIDInfo( txSIDLibPath, txTitle, txAuthor );
      
      AddSIDToLibrary( txSIDNameOnly, txAuthor, NULL, txSIDLibPath );
      nSIDsFound ++;
    }
    
    // PDS> HACK REMOVE
    //if( nSIDsFound > 10 )
    //  break;
    
    if( nSIDsFound % 1000 == 0 )
    {
      sprintf( txInfo, "%d SIDs added..", nSIDsFound );
      
      NSString *nsInfo = [NSString stringWithUTF8String: txInfo];
      
      dispatch_sync( dispatch_get_main_queue(), ^
      {
        [g_ProgressAlertView setMessage: nsInfo ];
      } );
    }
  }
  
  LogDebugf( "%d SIDs added!", nSIDsFound );
}

//-----------------------------------------------------------------------------------------
// StopSIDorMOD
//-----------------------------------------------------------------------------------------
void StopSIDorMOD( void )
{
  ToneUnitStop();

  ShutdownAudioSession();
  
  if( g_UnitType == UNIT_MOD )
  {
    if( g_Module )
    {
      Player_Stop();
      
      Player_Free( g_Module );
      
      g_Module = NULL;
      
      /*
       MIKMODAPI extern void    Player_Start(MODULE*);
       MIKMODAPI extern BOOL    Player_Active(void);
       MIKMODAPI extern void    Player_TogglePause(void);
       MIKMODAPI extern BOOL    Player_Paused(void);
       */
    }   
  }
  else
  if( g_UnitType == UNIT_SID )
  {    
    if( g_SIDTune )
    {
      g_SIDPlay->stop();
      
      delete g_SIDTune;
      g_SIDTune = NULL;
    }    
  }
  
  // PDS: Reset callback pointers and clear buffer..
  PaulPlayerInitialise();  
}

//-----------------------------------------------------------------------------------------
// StartSIDorMOD
//-----------------------------------------------------------------------------------------
void StartSIDorMOD( void )
{
  SetupAudioSession();

  CreateToneUnit( g_UnitType );
    
  ToneUnitPlay( g_UnitType );
}

//-----------------------------------------------------------------------------------------
// PlayMODAtPath
//-----------------------------------------------------------------------------------------
void PlayMODAtPath( char *txPath )
{
  char txFullPath[ 1024 ];
  
  StopSIDorMOD();
  g_UnitType = UNIT_MOD;

  StartSIDorMOD();
  
  LogDebugf( "#### UNIT_MOD" );
   
  if( strchr( txPath, '/' ) )
    strcpy( txFullPath, txPath );
  else
  {
    MakeDocumentsPath( txPath, txFullPath );
  }  
  
  g_Module = Player_Load( txFullPath, 64, 0 );
    
  if( g_Module )  
  {
    int nChannels;
	  int wBitsPerSample;
    
    // start module
    Player_Start( g_Module );
    
    nChannels      = ( md_mode & DMODE_STEREO ) ?  2 : 1;
	  wBitsPerSample = ( md_mode & DMODE_16BITS ) ? 16 : 8;
    
    g_Stopped = FALSE;
  }    
}

//-----------------------------------------------------------------------------------------
// MakeDocumentsPath()
//-----------------------------------------------------------------------------------------
void MakeDocumentsPath( char *pszPath, char *pszFullPath )
{
  strcpy( pszFullPath, g_txFTPPath );
  strcat( pszFullPath, "/" );
  strcat( pszFullPath, pszPath );
}

//--------------------------------------------------------------------------------------------
// GetSIDSubTuneLengthsInSeconds()
//--------------------------------------------------------------------------------------------
void GetSIDSubTuneLengthsInSeconds( Vector *pvTimesSecs, char *pLine )
{
  static char txLine[ 1024 ];
  
  strcpy( txLine, pLine );

  char *p = txLine;
  
  pvTimesSecs->removeAll();
  
  p = strtok( txLine, " " );
  
  char txMM_SS[ 20 ];
  
  for( ;; )
  {
    if( ! p )
      break;
    
    strcpy( txMM_SS, p );
        
    char *pSecs = strchr( txMM_SS, ':' );
    *pSecs = 0;
    
    int nMins = atoi( txMM_SS );
    
    pSecs ++;
    
    int nSecs      = atoi( pSecs );
    int nSecsTotal = ( nMins * 60 ) + nSecs;
    
    pvTimesSecs->addElement( nSecsTotal );
    
    p = strtok( NULL, " " );
  }
}

//-----------------------------------------------------------------------------------------
// PlaySIDAtPath
//-----------------------------------------------------------------------------------------
void PlaySIDAtPath( char *txPath, int nTuneLibIndex )
{
  char txFullPath[ 1024 ];
  
  StopSIDorMOD();
  
  g_UnitType = UNIT_SID;
  LogDebugf( "#### UNIT_SID" );
  
  StartSIDorMOD();
  
  LogDebugf( "Path:[%s]", txPath );
  
  if( strchr( txPath, '/' ) )
    strcpy( txFullPath, txPath );
  else
  {
    MakeDocumentsPath( txPath, txFullPath );
  }
  
  if( FileExists( txFullPath ) )
  {
    LogDebugf( "- EXISTS" );
  }
  else
  {
    LogDebugf( "- DOESN'T EXIST" );
  }
  
  g_SIDTune = new SidTune( txFullPath, 0, false );

  g_vSIDSubTuneLengths.removeAll();
  
  char txSIDFilenameOnly[ MAX_PATH ];
  
  GetFilenameOnly( txPath, txSIDFilenameOnly );
  
  // PDS: Find out how big the SID and its subtunes are..
  int nSIDIndex = g_vSIDFileNames.indexOf( txSIDFilenameOnly );
  
  LogDebugf( "SIDtunePath for time lookup[%s]", txSIDFilenameOnly );
  
  if( nSIDIndex >= 0 )
  {
    char *pszTuneTimes = g_vSIDSongLengths.elementStrAt( nSIDIndex );
    
    LogDebugf( "TuneTimes[%s]", pszTuneTimes );
    
    GetSIDSubTuneLengthsInSeconds( &g_vSIDSubTuneLengths, pszTuneTimes );
  }
  else
  {
    LogDebugf( "SID tune not found - can't get times" );
  }
  
  for( int i = 0; i < g_vSIDSubTuneLengths.elementCount(); i ++ )
  {
    int nSecs = g_vSIDSubTuneLengths.elementIntAt( i );
    
    LogDebugf( "Subtune %d len: %d secs (%02d:%02d)", i, nSecs, nSecs / 60, nSecs % 60 );
  }
  
  memset( &g_SIDTuneInfo, 0, sizeof( g_SIDTuneInfo ) );
  
  g_SIDTune->getInfo( g_SIDTuneInfo );
  
  // PDS: I index subtunes from 0...
  g_SIDSubTune = g_SIDTuneInfo.startSong - 1;
  
  // PDS: I think ReSID indexes from 1..
  g_SIDTune->selectSong( g_SIDSubTune + 1 );
  
  g_SIDPlay->load( g_SIDTune );
  
  // PDS: Save SID subtune/time info for current SID..
  g_CurrentSIDNumSubTunes = g_SIDTuneInfo.songs;
  g_CurrentSIDSecsStart   = SecondsNow();
  
  if( g_vSIDSubTuneLengths.elementCount() > 0 )
    g_CurrentSIDSecsLong = g_vSIDSubTuneLengths.elementIntAt( g_SIDSubTune );
  else
    g_CurrentSIDSecsLong = 0;

  g_Stopped = FALSE;
}

//-----------------------------------------------------------------------------------------
// ResumeTune
//-----------------------------------------------------------------------------------------
-(void) ResumeTune
{
  PostPlayerEvent( evRESUME_TUNE );
}

//-----------------------------------------------------------------------------------------
// HandleResumeTune
//-----------------------------------------------------------------------------------------
void HandleResumeTune( void )
{
  g_Stopped = FALSE;
  
  switch( g_UnitType )
  {
    case UNIT_MP3:
      dispatch_sync( dispatch_get_main_queue(), ^
      {
        if( g_AVPlayer )
         [g_AVPlayer play];
      } );
      break;
      
    case UNIT_SID:
      g_SIDPlay->pause();
      break;
      
    case UNIT_MOD:
      Player_TogglePause();
      break;
  }
}

//-----------------------------------------------------------------------------------------
// PauseTune
//-----------------------------------------------------------------------------------------
-(void) PauseTune
{
  PostPlayerEvent( evPAUSE_TUNE );
}

//-----------------------------------------------------------------------------------------
// HandlePauseTune
//-----------------------------------------------------------------------------------------
void HandlePauseTune( void )
{
  dispatch_sync( dispatch_get_main_queue(), ^
  {
    [g_PlayStopButton setImage: g_ImagePlayWhite forState: UIControlStateNormal];
    [g_MainViewController UpdatePlayStopButton];
  } );
  
  g_Stopped = TRUE;
  
  switch( g_UnitType )
  {
    case UNIT_MP3:
      dispatch_sync( dispatch_get_main_queue(), ^
      {
        if( g_AVPlayer )
          [g_AVPlayer pause];
      });
      break;
      
    case UNIT_SID:
      g_SIDPlay->pause();
      break;
      
    case UNIT_MOD:
      Player_TogglePause();
      break;
  }
}

//-----------------------------------------------------------------------------------------
// StopTune
//-----------------------------------------------------------------------------------------
-(void) StopTune
{
  PostPlayerEvent( evSTOP_TUNE );
}

//-----------------------------------------------------------------------------------------
// HandleStopTune
//-----------------------------------------------------------------------------------------
void HandleStopTune( void )
{
  dispatch_sync( dispatch_get_main_queue(), ^
  {
    [g_PlayStopButton setImage: g_ImagePlayWhite forState: UIControlStateNormal];
    [g_MainViewController UpdatePlayStopButton];
  } );
  
  g_Stopped = TRUE;
  
  switch( g_UnitType )
  {
    case UNIT_MP3:
      dispatch_sync( dispatch_get_main_queue(), ^
      {
        if( g_AVPlayer )
        {
          [g_AVPlayer pause];
          g_AVPlayer = nil;
        }
      } );
      break;
      
    case UNIT_SID:
      g_SIDPlay->stop();
      break;
      
    case UNIT_MOD:
      Player_Stop();
      break;
  }
}

//-----------------------------------------------------------------------------------------
// HandlePlayStopTune()
//-----------------------------------------------------------------------------------------
void HandlePlayStopTune( void )
{
  if( g_Stopped )
    HandlePlaySelected();
  else
    HandleStopTune();
}
                 
//-----------------------------------------------------------------------------------------
// PlayStopTune
//-----------------------------------------------------------------------------------------
-(void) PlayStopTune
{
  PostPlayerEvent( evPLAY_STOP );
}

//-----------------------------------------------------------------------------------------
// LoadTuneLibrary
//-----------------------------------------------------------------------------------------
-(void) LoadTuneLibrary
{
  // PDS: For now I'll start at beginning of all playlists..
  for( int m = 0; m < MODE_MAX_MODES; m ++ )
    g_PlayListIndex[ m ] = -1;

  // PDS> REMOVE
  //g_MP3CountChanged = TRUE;
  
  if( g_MP3CountChanged )
    LogDebugf( "MP3 library changed, rebuild required.." );
  
  // PDS: Load retained playlists.. always..
  ImportMD5Playlists();
  
  // PDS: Help users by stopping accidental deletion of their SID settings..
  MoveAnySIDSettings();

  // PDS: If MP3 count has changed, we will import everything.. (need to make smarter so SIDs aren't all done again).
  if( ( g_MP3CountChanged != TRUE ) && ( FileExists( g_PathEXP_TUNESNAME ) ) )
  {
    LogDebugf( "Importing.." );
    
    ImportLibrary();
    ImportPlaylists();
    
    // PDS> SCREENSHOTS
    //g_vArtist.addElement( "Tina Turner" );
    //g_vAlbum.addElement( "What's Love Got To Do With It?" );
    //g_vAlbumArtistIndex.addElement( g_vArtist.elementCount() - 1 );
    
  }
  else
  {
    LogDebugf( "Rebuilding.." );
    
    [self RefreshTuneLibrary];
    
    LogDebugf( "Adding local files.." );
    
    [self addLocalFilesToLibrary];

    LogDebugf( "Deleting playlists.." );
    
    DeletePlaylists();
    
    // PDS: Test import of sids in ONE zip file ..
    HVSCImport();
    
    // PDS: Import any likes or playlists from retained MD5 content..
    ImportMD5Info();
    
    // PDS: Favourite list 1 is always present..
    if( g_vPlaylistsActive.elementCount() <= 0 )
      g_vPlaylistsActive.addElement( 1 );
    
    g_NumFavouritePlaylists = g_vPlaylistsActive.elementCount();
    
    LogDebugf( "Exporting.." );
    
    ExportLibrary();
  }
  
  DeterminePresentTuneTypes();
}

//-----------------------------------------------------------------------------------------
// RebuildTuneLibrary
//-----------------------------------------------------------------------------------------
-(void) RebuildTuneLibrary
{    
  remove( g_PathEXP_TUNESNAME );
  
  [self LoadTuneLibrary];
}

//-----------------------------------------------------------------------------------------
// UploadTunes
//-----------------------------------------------------------------------------------------
-(void) UploadTunes
{
  BackupRestoreVC *backupRestoreView = [[BackupRestoreVC alloc] initWithStyle: UITableViewStyleGrouped];
  
  [backupRestoreView initWithStyle: UITableViewStyleGrouped];
  backupRestoreView.title = @"Backup & Restore";
  
  // PDS: You would think it obvious but no... Tell the stupid object to act on events from itself..
  //[self.navigationController pushViewController: backupRestoreView animated:YES];
  
  backupRestoreView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController: backupRestoreView animated:YES];
  
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomCommon()
//-----------------------------------------------------------------------------------------
void PlaylistRandomCommon( BOOL    fIncludeMP3,
                           BOOL    fIncludeMod,
                           BOOL    fIncludeSID,
                           Vector *pvWithExtensions,
                           Vector *pvPlayList
                          )
{  
  Vector vCandidates;
  int    nTotal = g_vTunesName.elementCount();
  int    nTotalCandidates;
  int    nAdded = 0;
  int    nRandIndex;
  int    nCandidateIndex;
  int    nType;
  int    i;
  char  *pszTuneName;
  char  *pszWithExtension;
  int    nExtensions;
  BOOL   fAnExtInTune = FALSE;
  
  if( pvPlayList == NULL )
    pvPlayList = g_pvCurrPlayList;
  
  pvPlayList->removeAll();
  
  // PDS: Create candidate index (all tune indices initially)..
  for( i = 0; i < nTotal; i ++ )
  {
    if( g_vTunesRating.elementIntAt( i ) >= g_IncludeRating )
    {
      nType = g_vTunesType.elementIntAt( i );
      
      if( ( nType == UNIT_MP3 ) && ( ! fIncludeMP3 ) )
        continue;

      if( ( nType == UNIT_MOD ) && ( ! fIncludeMod ) )
        continue;

      if( ( nType == UNIT_SID ) && ( ! fIncludeSID ) )
        continue;
      
      pszTuneName  = g_vTunesName.elementStrAt( i );
            
      // PDS: Check for specific must contain "extension"..
      if( pvWithExtensions )
      {
        nExtensions = pvWithExtensions->elementCount();
        
        fAnExtInTune = FALSE;
        
        for( int e = 0; e < nExtensions; e ++ )
        {
          pszWithExtension = pvWithExtensions->elementStrAt( e );
          
          // PDS: Ensure tune name as XM or whatever within it..
          if( stristr( pszTuneName, pszWithExtension ) ) 
          {
            fAnExtInTune = TRUE;
            break;
          }
        }
        
        if( ! fAnExtInTune ) 
          continue;
      }
            
      vCandidates.addElement( i ); 
      
      //LogDebugf( "Adding %s to list", pszTuneName );
    }
  }
    
  for( ;; )
  {
    nTotalCandidates = vCandidates.elementCount();

    if( ( nAdded >= nTotalCandidates ) || ( nTotalCandidates < 1 ) )
      break;
    
    nRandIndex      = rand() % nTotalCandidates;
    nCandidateIndex = vCandidates.elementIntAt( nRandIndex );
  
    pvPlayList->addElement( nCandidateIndex );
    vCandidates.removeElementAt( nRandIndex );
  }
  
  LogDebugf( "Added %d tunes to playlist", pvPlayList->elementCount() );  
}

//-----------------------------------------------------------------------------------------
// AddToPlayList()
//
// PDS: Add to both current playlist and associated MD5 playlist
//-----------------------------------------------------------------------------------------
void AddToPlayList( int nMode, int nTuneIndexInLib )
{
  char txHash[ MD5_ASC_SIZE + 1 ];
  GetHashForTuneIndexInLib( txHash, nTuneIndexInLib );
  
  g_vPlayList   [ nMode ].addElement( nTuneIndexInLib );
  g_vPlayListMD5[ nMode ].addElement( txHash );
}


//-----------------------------------------------------------------------------------------
// AddToCurrentPlayList()
//
// PDS: Add to both current playlist and associated MD5 playlist
//-----------------------------------------------------------------------------------------
void AddToCurrentPlayList( int nTuneIndexInLib )
{
  char txHash[ MD5_ASC_SIZE + 1 ];
  GetHashForTuneIndexInLib( txHash, nTuneIndexInLib );
  
  g_pvCurrPlayList->addElement( nTuneIndexInLib );
  g_pvCurrPlayListMD5->addElement( txHash );
}

//-----------------------------------------------------------------------------------------
// SelectCurrentPlayList()
//-----------------------------------------------------------------------------------------
void SelectCurrentPlayList( int nMode )
{
  g_pvCurrPlayList    = &g_vPlayList   [ nMode ];
  g_pvCurrPlayListMD5 = &g_vPlayListMD5[ nMode ];
}

//-----------------------------------------------------------------------------------------
// TUNESORTINFO
//-----------------------------------------------------------------------------------------
typedef struct
{
  int nTuneIndex;
  int nTuneArtist;
  int nTuneAlbum;
  int nTuneTrack;
  
} TUNESORTINFO;

//-----------------------------------------------------------------------------------------
// QsortTuneInfo()
//-----------------------------------------------------------------------------------------
int QsortTuneInfo( const void *arg1, const void *arg2 )
{
  void *pKey     = (*((void **) arg1 ));
  void *pElement = (*((void **) arg2 ));
  
  TUNESORTINFO *pKeyRec     = (TUNESORTINFO *) pKey;
  TUNESORTINFO *pElementRec = (TUNESORTINFO *) pElement;

  char txKey    [ 20 ];
  char txElement[ 20 ];
  
  sprintf( txKey,     "%06d%03d", pKeyRec->nTuneAlbum,     pKeyRec->nTuneTrack );
  sprintf( txElement, "%06d%03d", pElementRec->nTuneAlbum, pElementRec->nTuneTrack );
  
  return stricmp( txKey, txElement );
}

//-----------------------------------------------------------------------------------------
// CreateSequencePlaylistForArtist()
//-----------------------------------------------------------------------------------------
void CreateSequencePlaylistForArtist( void )
{
  SelectCurrentPlayList( g_CurrentMode );

  g_pvCurrPlayList->removeAll();
  g_PlayListIndex[ g_CurrentMode ] = -1;

  Vector vSortInfo;
  int    i;
  
  TUNESORTINFO *pSortInfo;
  
  // PDS: This really needs to sort into album and track order!
  for( i = 0; i < g_vTunesArtistIndex.elementCount(); i ++ )
  {
    if( g_vTunesArtistIndex.elementIntAt( i ) == g_CurrentArtistIndexPlaying )
    {
      pSortInfo = (TUNESORTINFO *) malloc( sizeof( TUNESORTINFO ) );
      
      pSortInfo->nTuneIndex = i;
      pSortInfo->nTuneAlbum = g_vTunesAlbumIndex.elementIntAt( i );
      pSortInfo->nTuneTrack = g_vTunesTrack.elementIntAt( i );
  
      char *pszTune = g_vTunesName.elementStrAt( i );
      LogDebugf( "PDS> Unsorted: %3d/%s", i, pszTune );
      
      vSortInfo.addElement( (void*) pSortInfo );
    }
  }

  // PDS: Sort candidate list according to album and track..
  vSortInfo.sortPtrAscending( &QsortTuneInfo );

  // PDS: We now have a list of all tunes by the artist.. We now need to sort into albums and track order..
  for( i = 0; i < vSortInfo.elementCount(); i ++ )
  {
    pSortInfo = (TUNESORTINFO *) vSortInfo.elementPtrAt( i );

    char *pszTune = g_vTunesName.elementStrAt( pSortInfo->nTuneIndex );
    LogDebugf( "PDS> Sorted  : %3d/%s", i, pszTune );

    AddToCurrentPlayList( pSortInfo->nTuneIndex );

    // PDS: If we've created a sequence for the current artist, we should position the playlist index onto the tune already playing..    
    if( pSortInfo->nTuneIndex == g_CurrentTuneLibIndexPlaying )
    {
      LogDebugf( "Found %d (%s) at %d", pSortInfo->nTuneIndex, g_vTunesName.elementStrAt( pSortInfo->nTuneIndex ), i );
      g_PlayListIndex[ g_CurrentMode ] = i;
    }
    
    free( pSortInfo );
  }
}

//-----------------------------------------------------------------------------------------
// CreateRandomPlaylistForArtist()
//-----------------------------------------------------------------------------------------
void CreateRandomPlaylistForArtist( void )
{
  Vector vCandidates;
  
  SelectCurrentPlayList( g_CurrentMode );

  g_pvCurrPlayList->removeAll();
  g_PlayListIndex[ g_CurrentMode ] = -1;
  
  for( int i = 0; i < g_vTunesArtistIndex.elementCount(); i ++ )
  {
    if( g_vTunesArtistIndex.elementIntAt( i ) == g_CurrentArtistIndexPlaying )
      vCandidates.addElement( i );
  }
  
  int nTotalCandidates;
  int nAdded = 0;
  int nRandIndex;
  int nCandidateIndex;
  
  for( ;; )
  {
    nTotalCandidates = vCandidates.elementCount();
    
    if( ( nAdded >= nTotalCandidates ) || ( nTotalCandidates < 1 ) )
      break;
    
    nRandIndex      = rand() % nTotalCandidates;
    nCandidateIndex = vCandidates.elementIntAt( nRandIndex );
    
    AddToCurrentPlayList( nCandidateIndex );

    vCandidates.removeElementAt( nRandIndex );
  }
}

//-----------------------------------------------------------------------------------------
// CreateRandomPlaylistForAlbum()
//-----------------------------------------------------------------------------------------
void CreateRandomPlaylistForAlbum( void )
{
  Vector vCandidates;
  
  SelectCurrentPlayList( g_CurrentMode );

  g_pvCurrPlayList->removeAll();
  g_PlayListIndex[ g_CurrentMode ] = -1;
  
  for( int i = 0; i < g_vTunesAlbumIndex.elementCount(); i ++ )
  {
    if( g_vTunesAlbumIndex.elementIntAt( i ) == g_CurrentAlbumIndexPlaying )
      vCandidates.addElement( i );
  }
  
  int nTotalCandidates;
  int nAdded = 0;
  int nRandIndex;
  int nCandidateIndex;
  
  for( ;; )
  {
    nTotalCandidates = vCandidates.elementCount();
    
    if( ( nAdded >= nTotalCandidates ) || ( nTotalCandidates < 1 ) )
      break;
    
    nRandIndex      = rand() % nTotalCandidates;
    nCandidateIndex = vCandidates.elementIntAt( nRandIndex );
    
    AddToCurrentPlayList( nCandidateIndex );
    
    vCandidates.removeElementAt( nRandIndex );
  }
}

//-----------------------------------------------------------------------------------------
// CreateSequencePlaylistForAlbum()
//-----------------------------------------------------------------------------------------
void CreateSequencePlaylistForAlbum( void ) 
{
  SetMode( MODE_NORMAL_PLAY );
  
  SelectCurrentPlayList( g_CurrentMode );
  
  g_pvCurrPlayList->removeAll();
  g_PlayListIndex[ g_CurrentMode ] = -1;
  
  Vector vSortInfo;
  int    i;
  
  TUNESORTINFO *pSortInfo;
  
  // PDS: This really needs to sort into album and track order!
  for( i = 0; i < g_vTunesAlbumIndex.elementCount(); i ++ )
  {
    if( g_vTunesAlbumIndex.elementIntAt( i ) == g_CurrentAlbumIndexPlaying )
    {
      pSortInfo = (TUNESORTINFO *) malloc( sizeof( TUNESORTINFO ) );
      
      pSortInfo->nTuneIndex = i;
      pSortInfo->nTuneAlbum = g_vTunesAlbumIndex.elementIntAt( i );
      pSortInfo->nTuneTrack = g_vTunesTrack.elementIntAt( i );
      
      char *pszTune = g_vTunesName.elementStrAt( i );
      LogDebugf( "PDS> Unsorted: %3d/%s", i, pszTune );
      
      vSortInfo.addElement( (void*) pSortInfo );
    }
  }
  
  // PDS: Sort candidate list according to album and track..
  vSortInfo.sortPtrAscending( &QsortTuneInfo );
  
  // PDS: We now have a list of all tunes by the artist.. We now need to sort into albums and track order..
  for( i = 0; i < vSortInfo.elementCount(); i ++ )
  {
    pSortInfo = (TUNESORTINFO *) vSortInfo.elementPtrAt( i );
    
    char *pszTune = g_vTunesName.elementStrAt( pSortInfo->nTuneIndex );
    LogDebugf( "PDS> Sorted  : %3d/%s", i, pszTune );
    
    AddToCurrentPlayList( pSortInfo->nTuneIndex );
    
    free( pSortInfo );
  }
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomLikes()
//
// PDS: This can get called from the drill down screens when somebody choses a load of likes
//-----------------------------------------------------------------------------------------
void PlaylistRandomLikes( void )
{
  g_IncludeRating = 1;
  
  // PDS: Include ALL tunes with a rating of at least 1..
  PlaylistRandomCommon( TRUE, TRUE, TRUE, NULL, &g_vPlayList[ MODE_RND_LIKES ] );
  
  ExportPlayList( MODE_RND_LIKES );
  ExportRatings();
  
  g_IncludeRating = 0;
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomAll()
//-----------------------------------------------------------------------------------------
void PlaylistRandomAll( void )
{ 
  PlaylistRandomCommon( TRUE, TRUE, TRUE, NULL );
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomMP3()
//-----------------------------------------------------------------------------------------
void PlaylistRandomMP3( void )
{
  PlaylistRandomCommon( TRUE, FALSE, FALSE, NULL );
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomModNew()
//-----------------------------------------------------------------------------------------
void PlaylistRandomModNew( void )
{
  Vector vExtensions;
  
  vExtensions.addElement( ".xm" );
  vExtensions.addElement( ".it" );
  vExtensions.addElement( ".s3m" );
  vExtensions.addElement( ".it" );
  
  PlaylistRandomCommon( FALSE, TRUE, FALSE, &vExtensions );    
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomModOld()
//-----------------------------------------------------------------------------------------
void PlaylistRandomModOld( void )
{
  Vector vExtensions;
  
  vExtensions.addElement( ".mod" );
  vExtensions.addElement( "mod." );
  
  PlaylistRandomCommon( FALSE, TRUE, FALSE, &vExtensions );      
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomModXM()
//-----------------------------------------------------------------------------------------
void PlaylistRandomModXM( void )
{
  Vector vExtensions;
  
  vExtensions.addElement( ".xm" );
  
  PlaylistRandomCommon( FALSE, TRUE, FALSE, &vExtensions );  
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomSID()
//-----------------------------------------------------------------------------------------
void PlaylistRandomSID( void )
{
  PlaylistRandomCommon( FALSE, FALSE, TRUE, NULL );    
}

//-----------------------------------------------------------------------------------------
// PlaylistRandomModSID()
//-----------------------------------------------------------------------------------------
void PlaylistRandomModSID( void )
{
  PlaylistRandomCommon( FALSE, TRUE, TRUE, NULL );    
}

//-----------------------------------------------------------------------------------------
// PlaylistSequenceCurrentArtist()
//-----------------------------------------------------------------------------------------
void PlaylistSequenceCurrentArtist( void )
{
}

//-----------------------------------------------------------------------------------------
// GetModeName()
//-----------------------------------------------------------------------------------------
void GetModeName( int nMode, char *pMode )
{
  switch( nMode )
  {
    case MODE_NORMAL_PLAY:  strcpy( pMode, "NORM"        );  break;
    case MODE_RND_ALL:      strcpy( pMode, "RND ALL"     );  break;
    case MODE_RND_LIKES:    strcpy( pMode, "RND LIKES"   );  break;
    case MODE_RND_MP3:      strcpy( pMode, "RND MP3"     );  break;
    case MODE_RND_MOD_NEW:  strcpy( pMode, "RND MOD NEW" );  break;
    case MODE_RND_MOD_OLD:  strcpy( pMode, "RND MOD OLD" );  break;
    case MODE_RND_XM:       strcpy( pMode, "RND XM"      );  break;
    case MODE_RND_SID:      strcpy( pMode, "RND SID"     );  break;
    case MODE_RND_MOD_SID:  strcpy( pMode, "RND MOD SID" );  break;
    case MODE_RND_ARTIST:   strcpy( pMode, "RND ARTIST"  );  break;
    case MODE_RND_ALBUM:    strcpy( pMode, "RND ALBUM"   );  break;
    case MODE_SEQ_ARTIST:   strcpy( pMode, "SEQ ARTIST"  );  break;
      
    case MODE_FAVOURITES:
    default:
    {
      sprintf( pMode, "FAVOURITES%d", ( nMode - MODE_FAVOURITES ) + 1 );
      break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// IsRandomMode
//-----------------------------------------------------------------------------------------
BOOL IsRandomMode( int nMode )
{
  return ( ( nMode >= MODE_RND_FIRST ) && ( nMode <= MODE_RND_LAST ) );
}

//-----------------------------------------------------------------------------------------
//  GetListName()
//-----------------------------------------------------------------------------------------
void GetListName( int nList, char *pName )
{
  switch( nList )
  {
    case LIST_HATES:        strcpy( pName, "Hates/Trash" );  break;
            
    case LIST_RND_ALL:      strcpy( pName, "ALL"     );  break;
      
    case LIST_RND_MP3:      strcpy( pName, "MP3"     );  break;
    case LIST_RND_MOD_NEW:  strcpy( pName, "MOD NEW" );  break;
    case LIST_RND_MOD_OLD:  strcpy( pName, "MOD OLD" );  break;
    case LIST_RND_XM:       strcpy( pName, "MOD XM"  );  break;
    case LIST_RND_SID:      strcpy( pName, "SID"     );  break;
    case LIST_RND_MOD_SID:  strcpy( pName, "MOD SID" );  break;
    case LIST_RND_ARTIST:   strcpy( pName, "ARTIST"  );  break;
    case LIST_RND_ALBUM:    strcpy( pName, "ALBUM"   );  break;
    case LIST_RND_LIKES:    strcpy( pName, "LIKES"   );  break;
    
    case LIST_ALL_MP3:      strcpy( pName, "MP3"     );  break;
    case LIST_ALL_SID:      strcpy( pName, "SID"     );  break;
    case LIST_ALL_MOD:      strcpy( pName, "MOD"     );  break;
    case LIST_ALL_MOD_NEW:  strcpy( pName, "MOD NEW" );  break;
    case LIST_ALL_MOD_OLD:  strcpy( pName, "MOD OLD" );  break;
    case LIST_ALL_LIKES:    strcpy( pName, "LIKES"   );  break;
      
    case LIST_FAVOURITES:
    default:
      strcpy( pName, g_vFavouritePlaylistNames.elementStrAt( nList - LIST_FAVOURITES_1 ) );
      break;
  }
}

//-----------------------------------------------------------------------------------------
// DrillDownModeToUnitType()
//-----------------------------------------------------------------------------------------
int DrillDownModeToUnitType( int nDrillDownMode )
{
  switch( nDrillDownMode )
  {
    case LIST_ALL_MOD:
    case LIST_ALL_MOD_NEW:
    case LIST_ALL_MOD_OLD:
    case LIST_RND_MOD_NEW:
    case LIST_RND_MOD_OLD:
    case LIST_RND_XM:       return UNIT_MOD;
      
    case LIST_RND_SID:
    case LIST_ALL_SID:      return UNIT_SID;
      
    case LIST_ALL_MP3:
    case LIST_RND_MP3:      break;
  }
  
  return UNIT_MP3;
}

//-----------------------------------------------------------------------------------------
// ExportPlayList()
//-----------------------------------------------------------------------------------------
void ExportPlayList( int nMode )
{
  char txMode[ 100 ];

  char *pExpPlayList    = g_vPlayListExpPath.elementStrAt( nMode );
  char *pExpPlayListMD5 = g_vPlayListExpPathMD5.elementStrAt( nMode );
  GetModeName( nMode, txMode );

  LogDebugf( "Exporting Playlist[%s] : %s (%d tunes)", txMode, pExpPlayList, g_vPlayList[ nMode ].elementCount() );
  LogDebugf( "Exporting PL MD5  [%s] : %s (%d tunes)", txMode, pExpPlayListMD5, g_vPlayListMD5[ nMode ].elementCount() );
  
  g_vPlayList[ nMode ].exportToFileInt( txMode, pExpPlayList );
  g_vPlayListMD5[ nMode ].exportToFile( txMode, pExpPlayListMD5 );
}

//-----------------------------------------------------------------------------------------
// ExportActiveFavourites()
//-----------------------------------------------------------------------------------------
void ExportActiveFavourites( void )
{
  g_vPlaylistsActive.exportToFileInt( "FAVACTIVE", g_PathEXP_FAVACTIVE );
}


//-----------------------------------------------------------------------------------------
// CreatePlaylist()
//-----------------------------------------------------------------------------------------
void CreatePlaylist( void )
{
  switch( g_CurrentMode )
  {
    case MODE_RND_ALL:      PlaylistRandomAll();       break;
    case MODE_RND_LIKES:    PlaylistRandomLikes();     break;
    case MODE_RND_MP3:      PlaylistRandomMP3();       break;
    case MODE_RND_MOD_NEW:  PlaylistRandomModNew();    break;
    case MODE_RND_MOD_OLD:  PlaylistRandomModOld();    break;
    case MODE_RND_XM:       PlaylistRandomModXM();     break;
    case MODE_RND_SID:      PlaylistRandomSID();             break;
    case MODE_RND_MOD_SID:  PlaylistRandomModSID();          break;
      
    case MODE_SEQ_ARTIST:   PlaylistSequenceCurrentArtist(); break;
  }
 
  ExportPlayList( g_CurrentMode );
}

//-----------------------------------------------------------------------------------------
// SaveSettings()
//
// PDS: Formerly SavePlayListPositions()
//-----------------------------------------------------------------------------------------
void SaveSettings( void )
{
  FILE *op = fopen( g_PathPlayListPositions, "wb" );
  
  fwrite( g_PlayListIndex, 1, sizeof( g_PlayListIndex ), op );
  fwrite( &g_DefaultPreferredFavouriteList, 1, sizeof( g_DefaultPreferredFavouriteList ), op );
  fwrite( &g_PreferredFavouriteList,        1, sizeof( g_PreferredFavouriteList ), op );
  fwrite( &g_LikeButtonBehaviour,           1, sizeof( g_LikeButtonBehaviour ), op );
  fwrite( &g_SIDChipType,                   1, sizeof( g_SIDChipType ), op );
  fwrite( &g_MP3Count,                      1, sizeof( g_MP3Count ), op );
  
  fclose( op );
}

//-----------------------------------------------------------------------------------------
// LoadSettings()
//-----------------------------------------------------------------------------------------
void LoadSettings( void )
{
  long lSize = FileSize( g_PathPlayListPositions );
  
  // PDS: Only load play list index if exists and same size..
  if( lSize < sizeof( g_PlayListIndex ) )
    return;
  
  FILE *op = fopen( g_PathPlayListPositions, "rb" );
  
  fread( g_PlayListIndex, 1, sizeof( g_PlayListIndex ), op );
  fread( &g_DefaultPreferredFavouriteList, 1, sizeof( g_DefaultPreferredFavouriteList ), op );
  fread( &g_PreferredFavouriteList,        1, sizeof( g_PreferredFavouriteList ), op );
  fread( &g_LikeButtonBehaviour,           1, sizeof( g_LikeButtonBehaviour ), op );
  fread( &g_SIDChipType,                   1, sizeof( g_SIDChipType ), op );
  fread( &g_MP3Count,                      1, sizeof( g_MP3Count ), op );
  
  fclose( op );
}

//-----------------------------------------------------------------------------------------
// ImportMD5Playlists()
//-----------------------------------------------------------------------------------------
void ImportMD5Playlists( void )
{
  // PDS: Import LIKES as well..
  g_vTunesRatingMD5.importFromFile( TX_EXP_TUNESRATE_MD5, g_PathEXP_TUNESRATE_MD5, ProgressCallback );
  
  LogDebugf( "MD5 LIKE count: %d", g_vTunesRatingMD5.elementCount() );
  
  for( int i = 0; i < MODE_MAX_MODES; i ++ )
  {
    char txMode[ 100 ];
    
    GetModeName( i, txMode );
    char *pExpPlayListMD5 = g_vPlayListExpPathMD5.elementStrAt( i );
    
    IncProgress();
    g_vPlayListMD5[ i ].importFromFile( txMode, pExpPlayListMD5 );
    
    LogDebugf( "** Import MD5 %d tunes PL[%s]", g_vPlayListMD5[ i ].elementCount(), pExpPlayListMD5 );

  }
}

//-----------------------------------------------------------------------------------------
// ImportPlaylists()
//-----------------------------------------------------------------------------------------
void ImportPlaylists( void )
{
  ImportMD5Playlists();
  
  for( int i = 0; i < MODE_MAX_MODES; i ++ )
  {
    char txMode[ 100 ];
    
    GetModeName( i, txMode );
    char *pExpPlayList    = g_vPlayListExpPath.elementStrAt( i );

    IncProgress();
    g_vPlayList   [ i ].importFromFileInt( txMode, pExpPlayList, ProgressCallback );
    
    LogDebugf( "Importing Playlist[%s] : %s  (%d tunes)", txMode, pExpPlayList, g_vPlayList[ i ].elementCount() );
  }
  
  LoadSettings();

  IncProgress();
  g_vPlaylistsActive.importFromFileInt( "FAVACTIVE", g_PathEXP_FAVACTIVE, ProgressCallback );
    
  // PDS: Favourite list 1 is always present..
  if( g_vPlaylistsActive.elementCount() <= 0 )
    g_vPlaylistsActive.addElement( 1 );
  
  g_NumFavouritePlaylists = g_vPlaylistsActive.elementCount();

  IncProgress();
  LogDebugf( "Active PL: %d", g_NumFavouritePlaylists );
}

//-----------------------------------------------------------------------------------------
// DeletePlaylists()
//-----------------------------------------------------------------------------------------
void DeletePlaylists( void )
{
  for( int i = 0; i < MODE_MAX_MODES; i ++ )
  {
    char *pExpPlayList = g_vPlayListExpPath.elementStrAt( i );
    
    remove( pExpPlayList );
    g_vPlayList[ i ].removeAll();
  }
  
  g_vPlaylistsActive.removeAll();
  
  // PDS: Remove memory of all active playlists too..
  remove( g_PathEXP_FAVACTIVE );
  
  // PDS: Remove playlist names..
  remove( g_PathEXP_FAVNAMES );

  // PDS: Remove any playlist position info too.. don't want to try adding to a default playlist if it doesn't exist!
  remove( g_PathPlayListPositions );
}

//-----------------------------------------------------------------------------------------
// HandleCreatePlayList()
//-----------------------------------------------------------------------------------------
void HandleCreatePlayList( void )
{  
  // PDS: We don't create a playlist for a custom/user favourite list..
  if( ( g_CurrentMode >= MODE_FAVOURITES_1 ) && ( g_CurrentMode <= MODE_FAVOURITES_10 ) )
    return;
  
  if( g_vPlayList[ g_CurrentMode ].elementCount() < 1 )
  {
    char txMode[ 100 ];
    GetModeName( g_CurrentMode, txMode );
    
    LogDebugf( "Creating playlist for %s", txMode );
    
    CreatePlaylist();
  }
}

//-----------------------------------------------------------------------------------------
// CreatePlaylistIfEmpty()
//-----------------------------------------------------------------------------------------
void CreatePlaylistIfEmpty( void )
{
  PostManageEvent( evCREATE_PLAYLIST );
}

//-----------------------------------------------------------------------------------------
// TuneInFavourites()
//-----------------------------------------------------------------------------------------
BOOL TuneInFavourites( int nTuneIndexInLib )
{
  // PDS: Go looking through all playlists to see if tune belongs in one of them.. don't care which.
  for( int p = MODE_FAVOURITES_1; p < MODE_FAVOURITES_1 + g_NumFavouritePlaylists; p ++ )
  {
    if( g_vPlayList[ g_PreferredFavouriteList ].contains( nTuneIndexInLib ) )
      return TRUE;
  }
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// AllTunesInFavourites()
//-----------------------------------------------------------------------------------------
BOOL AllTunesInFavourites( Vector *pvTunes )
{
  int nTuneIndexInLib;
  
  for( int i = 0; i < pvTunes->elementCount(); i ++ )
  {
    nTuneIndexInLib = pvTunes->elementIntAt( i );
    
    if( ! TuneInFavourites( nTuneIndexInLib ) )
      return FALSE;
  }
  
  return TRUE;
}

//-----------------------------------------------------------------------------------------
// LoadFavouritePlaylistNames()
//-----------------------------------------------------------------------------------------
void LoadFavouritePlaylistNames( void )
{
  char txName[ 50 ];
  
  g_vFavouritePlaylistNames.importFromFile( "FAVNAMES", g_PathEXP_FAVNAMES );
  
  LogDebugf( "### LOADING FAVS.." );
  
  int nFavourites = g_vFavouritePlaylistNames.elementCount();
  
  if( nFavourites < MAX_FAVOURITE_PLAYLISTS )
  {
    for( int p = 0; p < MAX_FAVOURITE_PLAYLISTS; p ++ )
    {
      sprintf( txName, "Favourites %d", 1 + p );
      g_vFavouritePlaylistNames.addElement( txName );
    }
    
    g_vFavouritePlaylistNames.exportToFile( "FAVNAMES", g_PathEXP_FAVNAMES );
  }
  else
  {
    // PDS: Set the FAVS 1 Mode text to favourite playlist names instead..
    for( int p = 0; p < nFavourites; p ++ )
    {
      strcpy( txName, g_vFavouritePlaylistNames.elementStrAt( p ) );
      
      if( memcmp( txName, "Favourites ", 11 ) != 0 )
      {
        LogDebugf( "### Set Fav %d to %s", MODE_FAVOURITES_1 + p, txName );

        g_vModeText.setElementAt( MODE_FAVOURITES_1 + p, txName );
        g_vTypeText.setElementAt( TYPE_FAVOURITES1 + p, txName );
      }
    }
  }

}

//-----------------------------------------------------------------------------------------
// SaveFavouritePlaylistNames()
//-----------------------------------------------------------------------------------------
void SaveFavouritePlaylistNames( void )
{
  g_vFavouritePlaylistNames.exportToFile( "FAVNAMES", g_PathEXP_FAVNAMES );
}

//-----------------------------------------------------------------------------------------
// RateAllTunes()
//-----------------------------------------------------------------------------------------
void RateAllTunes( Vector *pvTunes, int nRating )
{
  for( int i = 0; i < pvTunes->elementCount(); i ++ )
  {
    int nTuneIndexInLib = pvTunes->elementIntAt( i );
    
    g_vTunesRating.setElementAt( nTuneIndexInLib, nRating );
  }
}

//-----------------------------------------------------------------------------------------
// GetTunesForArtist()
//-----------------------------------------------------------------------------------------
void GetTunesForAlbum( int nAlbumIndex, Vector *pvAlbumTunes )
{
  for( int a = 0; a < g_vTunesAlbumIndex.elementCount(); a ++ )
  {
    if( g_vTunesAlbumIndex.elementIntAt( a ) == nAlbumIndex )
      pvAlbumTunes->addElement( a );
  }
}

//-----------------------------------------------------------------------------------------
// GetTunesForArtist()
//-----------------------------------------------------------------------------------------
void GetTunesForArtist( int nArtistIndex, Vector *pvArtistTunes )
{
  for( int i = 0; i < g_vTunesArtistIndex.elementCount(); i ++ )
  {
    if( g_vTunesArtistIndex.elementIntAt( i ) == nArtistIndex )
      pvArtistTunes->addElement( i );
  }
}

//-----------------------------------------------------------------------------------------
// GetAverageRatingForTunes()
//-----------------------------------------------------------------------------------------
int GetAverageRatingForTunes( Vector *pvTunes )
{
  int nTuneCount = pvTunes->elementCount();

  if( nTuneCount < 1 )
    return 0;

  int nTotalRating = 0;
  int nTuneIndexInLib;
  
  for( int i = 0; i < nTuneCount; i ++ )
  {
    nTuneIndexInLib = pvTunes->elementIntAt( i );
    
    nTotalRating += g_vTunesRating.elementIntAt( nTuneIndexInLib );
  }
  
  int nAverageRating = nTotalRating / nTuneCount;
  
  return nAverageRating;
}

//-----------------------------------------------------------------------------------------
// MarkTuneForDeletion()
//-----------------------------------------------------------------------------------------
void MarkTuneForDeletion( int nTuneLibIndex )
{
  char txPath[ MAX_PATH ];
  int  nType;
  int  i;
  
  nType = g_vTunesType.elementIntAt( nTuneLibIndex );
  
  char *pszPath = g_vTunesPath.elementStrAt( nTuneLibIndex );
  
  if( ! pszPath )
    return;
  
  MakeDocumentsPath( pszPath, txPath );
  
  LogDebugf( "Delete[%s] LibIndex: %d", txPath, nTuneLibIndex );
  
  g_vTunesName.markElementDeletedAt( nTuneLibIndex );
  g_vTunesType.markElementDeletedAt( nTuneLibIndex );
  g_vTunesPath.markElementDeletedAt( nTuneLibIndex );
  g_vTunesRating.markElementDeletedAt( nTuneLibIndex );
  g_vTunesTrack.markElementDeletedAt( nTuneLibIndex );
  g_vTunesArtistIndex.markElementDeletedAt( nTuneLibIndex );
  g_vTunesAlbumIndex.markElementDeletedAt( nTuneLibIndex );

  // PDS: Remove from playlists too..
  for( i = 0; i < MODE_MAX_MODES; i ++ )
  {
    Vector *pvPlayList = &g_vPlayList[ i ];

    int nIndex = pvPlayList->indexOf( nTuneLibIndex );
    
    if( nIndex >= 0 )
    {
      pvPlayList->markElementDeletedAt( nIndex );
    
      // PDS: Go through entire playlist and adjust any tune library indicies that are above the tune being deleted by -1..
      for( int t = 0; t < pvPlayList->elementCount(); t ++ )
      {
        int nLibIndex = pvPlayList->elementIntAt( t );
        
        if( nLibIndex > nTuneLibIndex )
          pvPlayList->setElementAt( t, nLibIndex - 1 );
      }
    }
  }
  
  // PDS: Apple won't let me delete tunes from the common library.. BUT it will still be removed from my references..
  if( nType == UNIT_MP3 )
    return;
  
  if( ( nType == UNIT_SID ) && ( stristr( txPath, "::" ) ) )
  {
    LogDebugf( "SID, marking for deletion: %s", txPath );
     g_vSIDFilesToDelete.addElement( txPath );
  }
  else
    g_vFilesToDelete.addElement( txPath );
}

//-----------------------------------------------------------------------------------------
// PurgeDeletionMarkedTunes()
//-----------------------------------------------------------------------------------------
void PurgeDeletionMarkedTunes( void )
{
  int i;

  g_vTunesName.purgeDeletedElements();
  g_vTunesType.purgeDeletedElements();
  g_vTunesPath.purgeDeletedElements();
  g_vTunesRating.purgeDeletedElements();
  g_vTunesTrack.purgeDeletedElements();
  g_vTunesArtistIndex.purgeDeletedElements();
  g_vTunesAlbumIndex.purgeDeletedElements();

  // PDS: Remove from playlists too..
  for( i = 0; i < MODE_MAX_MODES; i ++ )
  {
    g_vPlayList[ i ].purgeDeletedElements();
  }
  
  // PDS: Remove simple (non-zipped or single file ZIP) files..
  for( i = 0; i < g_vFilesToDelete.elementCount(); i ++ )
  {
    char *pFile = g_vFilesToDelete.elementStrAt( i );
    remove( pFile );
  }
  
  int    nZippedSIDsToDelete = g_vSIDFilesToDelete.elementCount();
  Vector vFilesInZipToDelete;
  char   txZIPPath[ MAX_PATH ];
  
  if( nZippedSIDsToDelete > 0 )
  {
    char *pFirstPath = g_vSIDFilesToDelete.elementStrAt( 0 );
    char *pColons    = stristr( pFirstPath, "::" );
    char  txPath[ MAX_PATH ];

    if( ! pColons )
    {
      LogDebugf( "Colons not found" );
      return;
    }
    
    // PDS: Get ZIP filename..
    pColons[ 0 ] = 0;
    strcpy( txZIPPath, pFirstPath );
    pColons[ 0 ] = ':';
    
    LogDebugf( "ZIPDeleting for [%s]", txZIPPath );

    LogDebugf( "Old ZIP size: %ld", FileSize( txZIPPath ) );    
    
    int nZIPPathLen = strlen( txZIPPath );
    
    for( i = 0; i < nZippedSIDsToDelete; i ++ )
    {
      // PDS: If 1 file in many (e.g. C64MUSIC.ZIP, delete the 1 file inside the ZIP..
      //
      // SID Format:  /var/mobile/Applications/5145A2A7-2FD0-4DD2-AC72-5E794BFF377B/Documents/C64Music.zip::C64Music/MUSICIANS/S/Shapie/Hot_Cake.sid
      
      char *pFile = g_vSIDFilesToDelete.elementStrAt( i );
      
      strcpy( txPath, &pFile[ nZIPPathLen + 2 ] );
      
      LogDebugf( "ZIPDelete:: [%s]", txPath );
      
      vFilesInZipToDelete.addElement( txPath );
    }
    
    LogDebugf( "ZIPDelete starting.." );
    
    // PDS: Rebuild ZIP file minus deleted files..
    ZIPDelete( txZIPPath, &vFilesInZipToDelete );
    
    LogDebugf( "New ZIP size: %ld", FileSize( txZIPPath ) );
  }
}

//-----------------------------------------------------------------------------------------
// HandleUnhateAll()
//-----------------------------------------------------------------------------------------
void HandleUnhateAll( void )
{
  for( int i = 0; i < g_vTunesRating.elementCount(); i ++ )
    g_vTunesRating.setElementAt( i, 0 );

  ExportRatings();
}

//-----------------------------------------------------------------------------------------
// HandleDeleteAllHates()
//-----------------------------------------------------------------------------------------
void HandleDeleteAllHates( void )
{
  g_vFilesToDelete.removeAll();
  g_vSIDFilesToDelete.removeAll();
  
  for( int i = 0; i < g_vTunesRating.elementCount(); i ++ )
  {
    if( g_vTunesRating.elementIntAt( i ) < 0 )
    {
      MarkTuneForDeletion( i );
    }
  }

  PurgeDeletionMarkedTunes();
  
  // PDS: Library needs to be rewritten for next time app starts up..
  ExportLibrary();
}

//-----------------------------------------------------------------------------------------
// HandleAddLikesToPlaylist()
//-----------------------------------------------------------------------------------------
void HandleAddLikesToPlaylist( void )
{
  int nAddMode = MODE_FAVOURITES_1 + g_FavSelected;
  
  for( int i = 0; i < g_vTunesRating.elementCount(); i ++ )
  {
    if( g_vTunesRating.elementIntAt( i ) > 0 )
      g_vPlayList[ nAddMode ].addUnique( i );
  }
}

//-----------------------------------------------------------------------------------------
// SafekeepLikes()
//-----------------------------------------------------------------------------------------
void HandleSafekeepLikes( void )
{
  char txSafePath    [ MAX_PATH ];
  char txSourcePath  [ MAX_PATH ];
  char txFilenameOnly[ MAX_PATH ];
  
  for( int i = 0; i < g_vTunesRating.elementCount(); i ++ )
  {
    if( g_vTunesRating.elementIntAt( i ) > 0 )
    {
      int   nType = g_vTunesType.elementIntAt( i );

      // PDS: Can't safekeep tunes in the common library..
      if( nType == UNIT_MP3 )
        continue;
      
      char *pPath = g_vTunesPath.elementStrAt( i );
      
      // PDS: Skip if already in safe path..
      if( stristr( pPath, g_PathSafe ) )
      {
        continue;
      }

      // PDS: Skip SIDs in the huge HVSC archive..
      if( stristr( pPath, "C64MUSIC.ZIP" ) )
        continue;

      if( strchr( pPath, '/' ) )
        strcpy( txSourcePath, pPath );
      else
      {
        MakeDocumentsPath( pPath, txSourcePath );
      }  
      
      GetFilenameOnly( txSourcePath, txFilenameOnly );
      
      strcpy( txSafePath, g_PathSafe );
      strcat( txSafePath, "/" );
      strcat( txSafePath, txFilenameOnly );
      
      //LogDebugf( "Safekeeing [%s] to [%s]", txSourcePath, txSafePath );
      
      //LogDebugf( "BEFORE [%s] : %s", txSourcePath, ( FileExists( txSourcePath ) ? "EXISTS" : "NOT FOUND" ) );
      //LogDebugf( "BEFORE [%s] : %s", txSafePath, ( FileExists( txSafePath ) ? "EXISTS" : "NOT FOUND" ) );
      
      [MyUtils MoveFile: txSourcePath to: txSafePath];

      //LogDebugf( "AFTER  [%s] : %s", txSourcePath, ( FileExists( txSourcePath ) ? "EXISTS" : "NOT FOUND" ) );
      //LogDebugf( "AFTER  [%s] : %s", txSafePath, ( FileExists( txSafePath ) ? "EXISTS" : "NOT FOUND" ) );
 
      g_vTunesPath.setElementAt( i, txSafePath );
    }
  }
  
  ExportLibrary();
}


@end