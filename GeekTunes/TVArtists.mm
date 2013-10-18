//
//  TVArtists.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVModes.h"
#import "TVArtists.h"
#import "TVAlbums.h"
#import "TVTunes.h"
#import "TVFavouritePopup.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
#include "Utils.h"

#import "UIPopoverController+iPhone.h"
#import "TVFavouritePopup.h"

@implementation TVArtists

extern UINavigationController *g_navController;

Vector  g_vArtistsForListMode;
Vector *g_pvArtistForListMode = &g_vArtistsForListMode;

extern Vector g_vTunesName;
extern Vector g_vTunesType;
extern Vector g_vTunesPath;
extern Vector g_vTunesRating;
extern Vector g_vTunesArtistIndex;
extern Vector g_vTunesAlbumIndex;
extern Vector g_vArtist;
extern Vector g_vAlbum;
extern Vector g_vAlbumArtistIndex;
extern Vector g_vPlayList   [ MODE_MAX_MODES ];
extern Vector g_vPlayListMD5[ MODE_MAX_MODES ];



static Vector g_vSectionHeadings;
Vector  g_vArtistSectionList[ MAX_ALPHA_SECTIONS ];

Vector  g_vSIDArtistSectionList[ MAX_ALPHA_SECTIONS ];
Vector  g_vSIDSectionHeadings;

Vector *g_pvSectionHeadings   = &g_vSectionHeadings;
Vector *g_pvArtistSectionList = g_vArtistSectionList;

Vector g_vSIDArtists;

extern int g_PopoverWidth;

static int g_SelectedSection = -1;
static int g_SelectedRow     = -1;

static UITableView *g_TableView = nil;


//-----------------------------------------------------------------------------------------
// GetArtistsForListMode
//-----------------------------------------------------------------------------------------
void GetArtistsForListMode( Vector *pvArtists )
{
  pvArtists->removeAll();

  Vector vArtistIndices;
  int    nTuneType;
  int    nArtistIndex;
  char  *pszArtist;
  BOOL   fAdd;
  int    nTunes = g_vTunesType.elementCount();
  char  *pszTune;
  int    i;
  int    nRating;
  
  for( i = 0; i < nTunes; i ++ )
  {
    nTuneType = g_vTunesType.elementIntAt( i );

    fAdd = FALSE;
    
    switch( g_DrillDownMode )
    {
      case LIST_ALL_LIKES:
        nRating = g_vTunesRating.elementIntAt( i );
        
        if( nRating > 0 )
          fAdd = TRUE;
        break;

      case LIST_ALL_MP3:
        if( nTuneType == UNIT_MP3 )
          fAdd = TRUE;
        break;
        
      case LIST_ALL_SID:
        if( nTuneType == UNIT_SID )
          fAdd = TRUE;
        break;
        
      case LIST_ALL_MOD:
      case LIST_ALL_MOD_NEW:
      case LIST_ALL_MOD_OLD:
        if( nTuneType == UNIT_MOD )
        {
          if( g_DrillDownMode == LIST_ALL_MOD )
          {
            fAdd = TRUE;
          }
          else
          if( g_DrillDownMode == LIST_ALL_MOD_NEW )
          {
            pszTune = g_vTunesPath.elementStrAt( i );
            
            if( IsNewMODFile( pszTune ) )
              fAdd = TRUE;
          }
          else
          if( g_DrillDownMode == LIST_ALL_MOD_OLD )
          {
            pszTune = g_vTunesPath.elementStrAt( i );
            
            if( IsOldMODFile( pszTune ) )
              fAdd = TRUE;
          }
        }
        break;
    }
    
    if( fAdd )
    {
      nArtistIndex = g_vTunesArtistIndex.elementIntAt( i );

      // PDS: I'm going to add artists indices because they should be faster to make comparisons on..
      vArtistIndices.addUnique( nArtistIndex );
    }
  }

  // PDS: Add all artists now..
  for( i = 0; i < vArtistIndices.elementCount(); i ++ )
  {
    nArtistIndex = vArtistIndices.elementIntAt( i );
    pszArtist    = g_vArtist.elementStrAt( nArtistIndex );
    pvArtists->addElement( pszArtist );
  }
}

//-----------------------------------------------------------------------------------------
// DetermineSelectedSectionAndRow()
//-----------------------------------------------------------------------------------------
void DetermineSelectedSectionAndRow( void )
{
  // PDS: If we're not doing selection, assume selected artist is the one thats playing..
  if( DrillDownModeToUnitType( g_DrillDownMode ) == g_CurrentUnitTypePlaying )
  {
    //if( g_CurrentArtistIndexSelected == -1 )
    
    // PDS: For now we'll always follow the current playing artist..
    g_CurrentArtistIndexSelected = g_CurrentArtistIndexPlaying;
  }
  
  if( g_CurrentArtistIndexSelected != -1 )
  {
    // PDS: Now try to determine what the section and row of the currently selected artist would be..
    //      The section can be derived from the first character of the artist..
    char *pszSelArtist = g_vArtist.elementStrAt( g_CurrentArtistIndexSelected );
    char  txStartingChar[ 2 ];
    
    txStartingChar[ 0 ] = pszSelArtist[ 0 ];
    txStartingChar[ 1 ] = 0;

    // PDS: I CANNOT use Full27IndexFromChar for the section as we don't have all 28 sections necessarily.. most unlikely!
    g_SelectedSection  = g_pvSectionHeadings->indexOf( txStartingChar );
    
    if( g_SelectedSection >= 0 )
    {
      int    nFull28Index = Full28IndexFromChar( pszSelArtist[ 0 ] );
      g_SelectedRow       = g_pvArtistSectionList[ nFull28Index ].indexOf( pszSelArtist );
    }
  }
}

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  [super viewDidLoad];

  g_SelectedSection = -1;
  g_SelectedRow     = -1;

  LogDebugf( "TVArtists, viewDidLoad, g_CurrentArtistIndexSelected: %d", g_CurrentArtistIndexSelected );
  
  g_vSectionHeadings.removeAll();

  ClearAlphaSectionedVector( g_vArtistSectionList );

  if( DrillDownModeToUnitType( g_DrillDownMode ) == UNIT_SID )
  {
    // PDS: Get the SID artists once and for all..
    if( g_vSIDArtists.elementCount() > 0 )
    {
      g_pvArtistForListMode = &g_vSIDArtists;
      g_pvSectionHeadings   = &g_vSIDSectionHeadings;
      g_pvArtistSectionList = g_vSIDArtistSectionList;
      
      DetermineSelectedSectionAndRow();
      return;
    }
    else
    {
      GetArtistsForListMode( &g_vSIDArtists );
      
      g_pvArtistForListMode = &g_vSIDArtists;
      g_pvSectionHeadings   = &g_vSIDSectionHeadings;
      g_pvArtistSectionList = g_vSIDArtistSectionList;
      
      PopulateAlphaSectionedVector( g_vSIDArtistSectionList, g_pvArtistForListMode, NULL );
      LoadSectionHeadingVector( &g_vSIDSectionHeadings, g_vSIDArtistSectionList );
      
      return;
    }
  }
  else
  {
    LogDebugf( "TVArtists, other.." );
    
    g_pvArtistForListMode = &g_vArtistsForListMode;
    GetArtistsForListMode( g_pvArtistForListMode );
    
    g_pvSectionHeadings   = &g_vSectionHeadings;
    g_pvArtistSectionList = g_vArtistSectionList;
  }
  
  PopulateAlphaSectionedVector( g_vArtistSectionList, g_pvArtistForListMode, NULL );
  LoadSectionHeadingVector( &g_vSectionHeadings, g_vArtistSectionList );

  DetermineSelectedSectionAndRow();
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];

  LogDebugf( "(TVArtists) didAppear, g_SelectedSection: %d, g_SelectedRow: %d", g_SelectedSection, g_SelectedRow );
  
  // PDS: Scroll to the selected artist.. if we can..
  if( ( g_SelectedSection != -1 ) && ( g_SelectedRow != -1 ) )
  {
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow: g_SelectedRow inSection: g_SelectedSection ];
    
    [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition: UITableViewScrollPositionMiddle animated: NO ];
  }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



//-----------------------------------------------------------------------------------------
// heightForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  // PDS: DO NOT call default method as it crashes.. Use tableView.rowHeight instead..
  //return [super tableView:tableView heightForRowAtIndexPath:indexPath];
  return tableView.rowHeight;
}

//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  g_TableView = tableView;
  
  char  *pszSection   = g_pvSectionHeadings->elementStrAt( section );
  int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
  
  return g_pvArtistSectionList[ nFull28Index ].elementCount();
}

//-----------------------------------------------------------------------------------------
// ConfigureLikeHatePlayCellArtist()
//-----------------------------------------------------------------------------------------
void ConfigureLikeHatePlayCellArtist( LikeHatePlayCell      *cell,
                                      int                    nArtistIndex,
                                      SEL                    ratingButtonFn,
                                      SEL                    playlistButtonFn,
                                      UITableViewController *pTableView )
{
  cell.textLabel.backgroundColor   = [UIColor clearColor];
  cell.contentView.backgroundColor = [UIColor clearColor];
  
  // PDS: Set this so I can toggle the rating for the required tune..
  cell.ratingButton.tag   = nArtistIndex;
  cell.playlistButton.tag = nArtistIndex;
  
  [cell.ratingButton   addTarget: pTableView action: ratingButtonFn   forControlEvents: UIControlEventTouchUpInside];
  [cell.playlistButton addTarget: pTableView action: playlistButtonFn forControlEvents: UIControlEventTouchUpInside];
  
  Vector vArtistTunes;
  
  GetTunesForArtist( nArtistIndex, &vArtistTunes );
  
  int nAverageRating = GetAverageRatingForTunes( &vArtistTunes );
  
  if( nAverageRating > 0 )
    [cell.ratingButton setBackgroundImage: g_ImageLike forState: UIControlStateNormal];
  else
  if( nAverageRating < 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHate forState: UIControlStateNormal];
  else
  if( nAverageRating == 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHeartGrey forState: UIControlStateNormal];
  
  // PDS: If the tune lives in a playlist, colour the icon purple..
  if( AllTunesInFavourites( &vArtistTunes ) )
    [cell.playlistButton setBackgroundImage: g_ImageClipboardPurple forState:  UIControlStateNormal];
  else
    [cell.playlistButton setBackgroundImage: g_ImageClipboardGrey   forState:  UIControlStateNormal];
}


//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString        *CellIdentifier;
  int              nSection = [indexPath section];
 
  /*
  char txID[ 20 ];
  
  sprintf( txID, "%02d%06d", nSection, [indexPath row] );

  CellIdentifier = [NSString stringWithUTF8String: txID];
  */
  
  CellIdentifier = @"MyID";
  
  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if( cell == nil )
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  char  *pszSection   = g_pvSectionHeadings->elementStrAt( nSection );
  int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
  char  *pszArtist    = g_pvArtistSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  
  int    nUnsortedArtistIndex = g_vArtist.indexOf( pszArtist );
//  int    nUnsortedArtistIndex =   g_pvArtistForListMode->indexOf( pszArtist );
 
  NSString *nsText    = [NSString stringWithUTF8String: pszArtist];
  
  cell.textLabel.text = nsText;
  
  // PDS: Set various button states.
  ConfigureLikeHatePlayCellArtist( cell,
                                   nUnsortedArtistIndex,
                                   @selector( ratingButtonPressed: ),
                                   @selector( playlistButtonPressed: ),
                                   self );
  
  cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;   

  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  
  
  // PDS: Hilight current artist..
  if( g_CurrentArtistIndexSelected != -1 )
  {
    if( g_CurrentArtistIndexSelected == nUnsortedArtistIndex )
    {
      g_SelectedSection = nSection;
      g_SelectedRow     = [indexPath row];
  
      [cell setHighlighted: YES];
    }
    else
    {
      [cell setHighlighted: NO];
    }
  }
  else
  {
    [cell setHighlighted: NO];
  }

 
  //  [nsText         release];
  //  [CellIdentifier release];
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// willDisplayCell
//-----------------------------------------------------------------------------------------
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if( ( [indexPath section] == g_SelectedSection ) && ( [indexPath row] == g_SelectedRow ) )
  {
    [cell setHighlighted: YES];
  }
  else
    [cell setHighlighted: NO];
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  char  *pszSection   = g_pvSectionHeadings->elementStrAt( [indexPath section] );
  int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
  char  *pszArtist    = g_pvArtistSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  
  int   nUnsortedIndex = g_vArtist.indexOf( pszArtist );  
  
  // PDS: Maintain highlighting in list..
  g_CurrentArtistIndexSelected = nUnsortedIndex;

  /* PDS> I'm not sure if I really do want to select/highlight the chosen album. Makes more sense to select the one that is currently playing, yes??
  // PDS: Change selected colour..
  g_SelectedSection = [indexPath section];
  g_SelectedRow     = [indexPath row];
  
  // PDS: Reload the current screen's cells.
  [self.tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  */
  
  if( g_DrillDownMode == LIST_ALL_MP3 )
  {  
    TVAlbums *tvAlbums = [TVAlbums alloc];
  
    [tvAlbums init];      
    [tvAlbums initWithStyle: UITableViewStylePlain];
    [tvAlbums setTitle: @"Albums"];
  
    // PDS: Pass in artist into album view..
    tvAlbums.nArtistIndex = nUnsortedIndex;
    
    [g_navController pushViewController: tvAlbums animated:YES];
  }
  else
  {
    TVTunes *tvTunes = [TVTunes alloc];
    
    [tvTunes init];
    [tvTunes initWithStyle: UITableViewStylePlain];
    [tvTunes setTitle: @"Tunes"];
            
    // PDS: Pass in artist into tunes view..
    tvTunes.nArtistIndex = nUnsortedIndex;
    
    [g_navController pushViewController: tvTunes animated:YES];
  }  
}

//-----------------------------------------------------------------------------------------
// backButtonHit
//-----------------------------------------------------------------------------------------
-(void) backButtonHit
{
  [g_navController popViewControllerAnimated:YES];
}


//-----------------------------------------------------------------------------------------
// titleForHeaderInSection
//-----------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
  char     *pszHeading = g_pvSectionHeadings->elementStrAt( section );
  NSString *nsTitle    = [NSString stringWithUTF8String: pszHeading];
  
  return nsTitle;
}

//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return g_pvSectionHeadings->elementCount();
}

//-----------------------------------------------------------------------------------------
// sectionIndexTitlesForTableView
//-----------------------------------------------------------------------------------------
- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView 
{
  NSMutableArray *nsArray = [ [NSMutableArray alloc] init ];
  
  for( int i = 0; i < g_pvSectionHeadings->elementCount(); i ++ )
  {
    char *pszItem = g_pvSectionHeadings->elementStrAt( i );
    [nsArray addObject: [NSString stringWithUTF8String: pszItem] ];
  }
  
  return nsArray;
}

//-----------------------------------------------------------------------------------------
// ratingButtonPressed
//-----------------------------------------------------------------------------------------
-(void) ratingButtonPressed: (id) sender
{
  NSInteger nArtistIndex = ((UIControl *) sender).tag;
  
  Vector vArtistTunes;
  
  GetTunesForArtist( nArtistIndex, &vArtistTunes );
  
  int nAverageRating = GetAverageRatingForTunes( &vArtistTunes );
  
  if( nAverageRating < 0 )
  {
    // PDS: Remove tune hate status..
    RateAllTunes( &vArtistTunes, 0 );
  }
  else
  if( nAverageRating > 0 )
  {
    RateAllTunes( &vArtistTunes, -1 );
  }
  else
  if( nAverageRating == 0 )
  {
    RateAllTunes( &vArtistTunes, 1 );
  }
  
  if( g_TableView )
  {
    // PDS: Reload the current screen's cells.
    [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  }
}

//-----------------------------------------------------------------------------------------
// AddArtistTracksToFavouritePlaylist()
//-----------------------------------------------------------------------------------------
void AddArtistTracksToFavouritePlaylist( void )
{
  int    nFound = 0;
  Vector vArtistTunes;
  
  GetTunesForArtist( g_nSelectedArtistIndexInLib, &vArtistTunes );
  
  LogDebugf( "Artist tunecount: %d", vArtistTunes.elementCount() );
  
  for( int i = 0; i < vArtistTunes.elementCount(); i ++ )
  {
    int nTuneIndexInLib = vArtistTunes.elementIntAt( i );
    
    LogDebugf( "Add %s", g_vTunesName.elementStrAt( nTuneIndexInLib ) );
    
    int nFavIndex       = g_vPlayList[ g_PreferredFavouriteList ].indexOf( nTuneIndexInLib );
    
    // PDS: Tune already in play list..
    if( nFavIndex >= 0 )
      continue;
    
    nFound ++;
    
    // PDS: Add to preferred favourites if not already present..
    AddToPlayList( g_PreferredFavouriteList, nTuneIndexInLib );
  }
  
  if( nFound > 0 )
  {
    ExportPlayList( g_PreferredFavouriteList );
  
    if( g_TableView )
    {
      // PDS: Reload the current screen's cells.
      [ g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
  }
 
}

//-----------------------------------------------------------------------------------------
// dismissPopover()
//-----------------------------------------------------------------------------------------
-(void) dismissPopover
{
  // popoverControllerDidDismissPopover()
  //
  // PDS: Does not get called if explicitly dismissed! Only gets called when somebody taps
  //      outside of popover in which case I don't care. So.. I'm using my own DismissDelegate instead
  AddArtistTracksToFavouritePlaylist();
  
  [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];  
}

//-----------------------------------------------------------------------------------------
// SelectDestinationPlaylist()
//-----------------------------------------------------------------------------------------
-(void) SelectDestinationPlaylist
{
  LogDebugf( "g_PreferredFavouriteList: %d", g_PreferredFavouriteList );
  
  if( g_DefaultPreferredFavouriteList )
  {
    // PDS: Choice not necessary..
    [self dismissPopover];
    return;
  }
  
  
  TVFavouritePopup *tvFavs = [TVFavouritePopup alloc];
  
  [tvFavs init];
  [tvFavs setTitle: @"Playlists"];
  
  tvFavs.contentSizeForViewInPopover = CGSizeMake( g_PopoverWidth, 800 );
  
  [tvFavs initWithStyle: UITableViewStylePlain];

/*
  UINavigationController *nav = [[UINavigationController alloc]
                                 initWithRootViewController: tvFavs];
//  [tvFavs release];
  
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController: nav];
//  [nav release];
  */
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController: tvFavs];
  
  [popover setDelegate: self];
  
  tvFavs.popover = popover;
  
  // PDS: Delegate my popover dismiss delegate to this TV..
  tvFavs.dismissDelegate = self;
  
  // PDS: Ensure popover appears in the visible part of the table view..
  NSArray         *arrIndexPaths = [g_TableView indexPathsForVisibleRows];
  NSIndexPath     *indexPath     = [arrIndexPaths objectAtIndex: 0];
  UITableViewCell *cell          = [g_TableView cellForRowAtIndexPath: indexPath];
  
  CGRect rect = CGRectMake( cell.bounds.origin.x + 20, cell.bounds.origin.y + 10, 50, 30 );
  
  [popover presentPopoverFromRect:rect inView: cell permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

//-----------------------------------------------------------------------------------------
// playlistButtonPressed
//-----------------------------------------------------------------------------------------
-(void) playlistButtonPressed: (id) sender
{
  g_nSelectedArtistIndexInLib = ((UIControl *) sender).tag;
  
  LogDebugf( "nArtistIndex pressed (add to playlist): %d", g_nSelectedArtistIndexInLib );
  
  // PDS: Depending upon number of playlists, or default playlist destination.. add it.. (or remove)..
  if( g_NumFavouritePlaylists > 1 )
  {
    // PDS: Complicate people (women!) may have to choose which playlist they want to add this to..
    [self SelectDestinationPlaylist];
    
    // PDS: We need to call AddToFavouritePlaylist() in the pop over dismiss handler..
  }
  else
  {
    // PDS: By default.. simple people such as myself only have one playlist!
    g_PreferredFavouriteList = MODE_FAVOURITES_1;
    
    AddArtistTracksToFavouritePlaylist();
  }
}

@end
