//
//  TVAlbums.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVAlbums.h"
#import "TVModes.h"
#import "TVArtists.h"
#import "TVAlbumTunes.h"
#import "TVFavouritePopup.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
#include "Utils.h"

@implementation TVAlbums

@synthesize nArtistIndex;

extern UINavigationController *g_navController;
extern TVModes                *g_tvModes;

extern Vector g_vAlbum;
extern Vector g_vAlbumArtistIndex;
extern Vector g_vArtist;
extern Vector g_vPlayList   [ MODE_MAX_MODES ];
extern Vector g_vPlayListMD5[ MODE_MAX_MODES ];

static Vector g_vSectionHeadings;

static Vector g_vAlbumsForArtist;
Vector g_vAlbumSectionList[ MAX_ALPHA_SECTIONS ];

static int g_SelectedSection = -1;
static int g_SelectedRow     = -1;

static UITableView *g_TableView = nil;


//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{    
  [super viewDidLoad]; 
  
  g_SelectedSection = -1;
  g_SelectedRow     = -1;
  
  g_vAlbumsForArtist.removeAll();
  g_vSectionHeadings.removeAll();
  
  ClearAlphaSectionedVector( g_vAlbumSectionList );  
  
  LogDebugf( "Loading albums for artist %d [%s]", nArtistIndex, g_vArtist.elementStrAt( nArtistIndex ) );
  
  // PDS: Find all albums for the artist..
  for( int a = 0; a < g_vAlbum.elementCount(); a ++ )
  {
    if( g_vAlbumArtistIndex.elementIntAt( a ) == nArtistIndex )
    {
      char *pszAlbumName = g_vAlbum.elementStrAt( a );
      g_vAlbumsForArtist.addElement( pszAlbumName );
      
      LogDebugf( "Album for artist: %s", pszAlbumName );
    }
  }  
  
  PopulateAlphaSectionedVector( g_vAlbumSectionList, &g_vAlbumsForArtist, NULL );
  LoadSectionHeadingVector( &g_vSectionHeadings, g_vAlbumSectionList );
  
  // PDS: If we're playing an MP3, follow it through the drill down list..
  if( DrillDownModeToUnitType( g_DrillDownMode ) == UNIT_MP3 )
    g_CurrentAlbumIndexSelected = g_CurrentAlbumIndexPlaying;
  
  if( g_CurrentAlbumIndexSelected != -1 )
  {
    // PDS: Now try to determine what the section and row of the currently selected album would be..
    //      The section can be derived from the first character of the album..
    char *pszSelAlbum = g_vAlbum.elementStrAt( g_CurrentAlbumIndexSelected );
    char  txStartingChar[ 2 ];
    
    txStartingChar[ 0 ] = pszSelAlbum[ 0 ];
    txStartingChar[ 1 ] = 0;
    
    // PDS: I CANNOT use Full27IndexFromChar for the section as we don't have all 28 sections necessarily.. most unlikely!
    g_SelectedSection  = g_vSectionHeadings.indexOf( txStartingChar );
    
    if( g_SelectedSection >= 0 )
    {
      int    nFull28Index = Full28IndexFromChar( pszSelAlbum[ 0 ] );
      g_SelectedRow      = g_vAlbumSectionList[ nFull28Index ].indexOf( pszSelAlbum );
    }
  }
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];
  
  // PDS: Scroll to the selected album.. if we can..
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
  
  char  *pszSection   = g_vSectionHeadings.elementStrAt( section );
  int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
  
  return g_vAlbumSectionList[ nFull28Index ].elementCount();
}

//-----------------------------------------------------------------------------------------
// ConfigureLikeHatePlayCellAlbum()
//-----------------------------------------------------------------------------------------
void ConfigureLikeHatePlayCellAlbum( LikeHatePlayCell      *cell,
                                     int                    nAlbumIndex,
                                     SEL                    ratingButtonFn,
                                     SEL                    playlistButtonFn,
                                     UITableViewController *pTableView )
{
  cell.textLabel.backgroundColor   = [UIColor clearColor];
  cell.contentView.backgroundColor = [UIColor clearColor];
  
  // PDS: Set this so I can toggle the rating for the required tune..
  cell.ratingButton.tag   = nAlbumIndex;
  cell.playlistButton.tag = nAlbumIndex;
  
  [cell.ratingButton   addTarget: pTableView action: ratingButtonFn   forControlEvents: UIControlEventTouchUpInside];
  [cell.playlistButton addTarget: pTableView action: playlistButtonFn forControlEvents: UIControlEventTouchUpInside];
  
  Vector vAlbumTunes;
  
  GetTunesForAlbum( nAlbumIndex, &vAlbumTunes );
  
  int nAverageRating = GetAverageRatingForTunes( &vAlbumTunes );
  
  if( nAverageRating > 0 )
    [cell.ratingButton setBackgroundImage: g_ImageLike forState: UIControlStateNormal];
  else
  if( nAverageRating < 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHate forState: UIControlStateNormal];
  else
  if( nAverageRating == 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHeartGrey forState: UIControlStateNormal];
  
  // PDS: If all tunes live in a playlist, colour the icon purple..
  if( AllTunesInFavourites( &vAlbumTunes ) )
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
  
  char txID[ 20 ];
  
  sprintf( txID, "%02d%06d", nSection, [indexPath row] );
  
  CellIdentifier = [NSString stringWithUTF8String: txID];
  
  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if( cell == nil )
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  char *pszSection   = g_vSectionHeadings.elementStrAt( nSection );
  int   nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
    
  char *pszAlbum     = g_vAlbumSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  NSString *nsText   = [NSString stringWithUTF8String: pszAlbum];

  int   nUnsortedAlbumIndex = g_vAlbum.indexOf( pszAlbum );
  
  cell.textLabel.text       = nsText;
  cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;   
  
  // PDS: Set various button states.
  ConfigureLikeHatePlayCellAlbum( cell,
                                  nUnsortedAlbumIndex,
                                  @selector( ratingButtonPressed: ),
                                  @selector( playlistButtonPressed: ),
                                  self );
  
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  
  
  // PDS: Hilight current artist..
  if( g_CurrentAlbumIndexSelected != -1 )
  {
    if( g_CurrentAlbumIndexSelected == nUnsortedAlbumIndex )
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
  char  *pszSection     = g_vSectionHeadings.elementStrAt( [indexPath section] );
  int    nFull28Index   = Full28IndexFromChar( pszSection[ 0 ] );
  char  *pszAlbum       = g_vAlbumSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  int    nUnsortedIndex = g_vAlbum.indexOf( pszAlbum );
  
  // PDS: Maintain highlighting in list..
  g_CurrentAlbumIndexSelected = nUnsortedIndex;
  
  /* PDS> I'm not sure if I really do want to select/highlight the chosen album. Makes more sense to select the one that is currently playing, yes??
  // PDS: Change selected colour..
  g_SelectedSection = [indexPath section];
  g_SelectedRow     = [indexPath row];
  
  // PDS: Reload the current screen's cells.
  [self.tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  */
  
  TVAlbumTunes *tvTunes = [TVAlbumTunes alloc];
  
//  tvTunes.dismissDelegate = g_tvModes.dismissDelegate;
  
  [tvTunes init];      
  [tvTunes initWithStyle: UITableViewStylePlain];
  [tvTunes setTitle: @"Tunes"];

  LogDebugf( "Album selected: %s", pszAlbum );
  
  // PDS: Pass in album into tunes view..
  tvTunes.nAlbumIndex = nUnsortedIndex;
  
  [g_navController pushViewController: tvTunes animated:YES];
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
  char     *pszHeading = g_vSectionHeadings.elementStrAt( section );
  NSString *nsTitle    = [NSString stringWithUTF8String: pszHeading];
  
  return nsTitle;
}

//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return g_vSectionHeadings.elementCount();
}

//-----------------------------------------------------------------------------------------
// sectionIndexTitlesForTableView
//-----------------------------------------------------------------------------------------
- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView 
{
  NSMutableArray *nsArray = [ [NSMutableArray alloc] init ];
      
  for( int i = 0; i < g_vSectionHeadings.elementCount(); i ++ )
  {
    char *pszItem = g_vSectionHeadings.elementStrAt( i );
 
    [nsArray addObject: [NSString stringWithUTF8String: pszItem] ];
  }
  
  return nsArray;
}

//-----------------------------------------------------------------------------------------
// ratingButtonPressed
//-----------------------------------------------------------------------------------------
-(void) ratingButtonPressed: (id) sender
{
  NSInteger nAlbumIndex = ((UIControl *) sender).tag;
  
  Vector vAlbumTunes;
  
  GetTunesForAlbum( nAlbumIndex, &vAlbumTunes );
  
  int nAverageRating = GetAverageRatingForTunes( &vAlbumTunes );
  
  if( nAverageRating < 0 )
  {
    // PDS: Remove tune hate status..
    RateAllTunes( &vAlbumTunes, 0 );
  }
  else
  if( nAverageRating > 0 )
  {
    RateAllTunes( &vAlbumTunes, -1 );
  }
  else
  if( nAverageRating == 0 )
  {
    RateAllTunes( &vAlbumTunes, 1 );
  }
  
  if( g_TableView )
  {
    // PDS: Reload the current screen's cells.
    [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  }
}

//-----------------------------------------------------------------------------------------
// AddAlbumTracksToFavouritePlaylist()
//-----------------------------------------------------------------------------------------
void AddAlbumTracksToFavouritePlaylist( void )
{
  int    nFound = 0;
  Vector vAlbumTunes;
  
  GetTunesForAlbum( g_nSelectedAlbumIndexInLib, &vAlbumTunes );
  
  for( int i = 0; i < vAlbumTunes.elementCount(); i ++ )
  {
    int nTuneIndexInLib = vAlbumTunes.elementIntAt( i );
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
  AddAlbumTracksToFavouritePlaylist();
  
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
  
  tvFavs.contentSizeForViewInPopover = CGSizeMake( 320, 800 );
  
  [tvFavs initWithStyle: UITableViewStylePlain];
  
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController: tvFavs];
  
  //  tvFavs.tag = POPUP_PLAYLIST_PRESSED;
  
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
  g_nSelectedAlbumIndexInLib = ((UIControl *) sender).tag;
  
  LogDebugf( "nAlbumIndex pressed (add to playlist): %d", g_nSelectedAlbumIndexInLib );
  
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
    
    AddAlbumTracksToFavouritePlaylist();
  }
}


@end
