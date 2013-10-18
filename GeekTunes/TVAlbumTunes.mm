//
//  TVTunes.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVAlbumTunes.h"
#import "TVAlbums.h"
#import "TVModes.h"
#import "TVArtists.h"
#import "TVFavouritePopup.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
#include "Utils.h"
#import "ViewController.h"


@implementation TVAlbumTunes

@synthesize nAlbumIndex;
@synthesize tuneSelectedDelegate;
@synthesize dismissDelegate;

extern UINavigationController *g_navController;
extern ViewController         *g_MainViewController;
extern TVModes                *g_tvModes;

extern Vector g_vAlbum;
extern Vector g_vAlbumArtistIndex;
extern Vector g_vArtist;
extern Vector g_vTunesName;
extern Vector g_vTunesAlbumIndex;
extern Vector g_vTunesTrack;
extern Vector g_vTunesRating;

Vector g_vTunesForAlbum;
Vector g_vTuneIndicesForAlbum;

static int g_SelectedSection = -1;
static int g_SelectedRow     = -1;

static UITableView *g_TableView = nil;

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{    
  Vector vAlbumTunesUnsorted;
  Vector vAlbumTrackUnsorted;
  Vector vAlbumTuneLibIndexUnsorted;
  
  g_SelectedSection = -1;
  g_SelectedRow     = -1;
  
  [super viewDidLoad]; 
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector( doneButtonTapped )];
  self.navigationItem.rightBarButtonItem = doneButton;
  
  tuneSelectedDelegate = g_MainViewController;
  dismissDelegate      = g_tvModes;
  
  g_vTunesForAlbum.removeAll();
  g_vTuneIndicesForAlbum.removeAll();
  
  LogDebugf( "### Loading tunes for album %d [%s]", nAlbumIndex, g_vAlbum.elementStrAt( nAlbumIndex ) );
  
  int nMissingTrackNum = 1;
  
  // PDS: Find all tunes for the album..
  for( int a = 0; a < g_vTunesAlbumIndex.elementCount(); a ++ )
  {
    if( g_vTunesAlbumIndex.elementIntAt( a ) == nAlbumIndex )
    {
      char *pszTuneName = g_vTunesName.elementStrAt( a );
      int   nTrackNum   = g_vTunesTrack.elementIntAt( a );

      // PDS: If tunes don't have track numbers (such as my Sparky MP3s.. ehem..).. assign fake ones..
      if( nTrackNum == 0 )
        nTrackNum = nMissingTrackNum ++;
      
      // PDS: Watch out for duplicates in the iPod library!!
      if( vAlbumTrackUnsorted.contains( nTrackNum ) )
      {
        //NSLog( @"Track for tune: %s  Trk: %d", pszTuneName, nTrackNum );
        continue;
      }
      
      vAlbumTunesUnsorted.addElement( pszTuneName );
      vAlbumTrackUnsorted.addElement( nTrackNum );
      vAlbumTuneLibIndexUnsorted.addElement( a );
      
      //NSLog( @"Tune for album: %s", pszTuneName );
    }
  }  
  
  int   nIndex;
  char *pszTune;
  int   nLibIndex;

  // PDS: Now add according to track number..
  for( int i = 1; i < 100; i ++ )
  {
    if( g_vTunesForAlbum.elementCount() >= vAlbumTunesUnsorted.elementCount() )
      break;
    
    nIndex    = vAlbumTrackUnsorted.indexOf( i );
    
    // PDS: Watch out for missing tracks..
    if( nIndex < 0 )
      continue;
    
    NSLog( @"Album track: %d, index in album tracks unsorted: %d/%d", i, nIndex, vAlbumTunesUnsorted.elementCount() );
    
    pszTune   = vAlbumTunesUnsorted.elementStrAt( nIndex );
    
    NSLog( @"  Track name:[%s]", pszTune );
    
    nLibIndex = vAlbumTuneLibIndexUnsorted.elementIntAt( nIndex );
    
    NSLog( @"  Lib index : %d", nLibIndex );
    
    g_vTunesForAlbum.addElement( pszTune );
    g_vTuneIndicesForAlbum.addElement( nLibIndex );
  }
  
  if( g_CurrentTuneLibIndexPlaying != -1 )
  {
    // PDS: Now try to determine what the section and row of the currently selected tune would be..
    //      The section can be derived from the first character of the tun..
    char *pszSelTune = g_vTunesName.elementStrAt( g_CurrentTuneLibIndexPlaying );
    
    g_SelectedSection  = 0;
    g_SelectedRow      = g_vTunesForAlbum.indexOf( pszSelTune );
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
  
  return g_vTunesForAlbum.elementCount();
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString        *CellIdentifier;
  
  char txID[ 20 ];
  
  sprintf( txID, "%06d", [indexPath row] );
  
  CellIdentifier = [NSString stringWithUTF8String: txID];
  
  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
  char *pszTune      = g_vTunesForAlbum.elementStrAt( [indexPath row] );
  NSString *nsText   = [NSString stringWithUTF8String: pszTune];
  
  cell.textLabel.text       = nsText;

  int   nTuneIndexInLib  = g_vTuneIndicesForAlbum.elementIntAt( [indexPath row] );
  int   nTuneRating      = g_vTunesRating.elementIntAt( nTuneIndexInLib );

  cell.tag = nTuneIndexInLib;
  
  // PDS: Set various button states.
  ConfigureLikeHatePlayCell( cell, nTuneRating, nTuneIndexInLib, @selector( ratingButtonPressed: ), @selector( playlistButtonPressed: ),
                             self );
  
  // PDS: Try adding a speaker/playing icon..
  if( ( g_CurrentTuneLibIndexPlaying != -1 ) && 
      ( nTuneIndexInLib == g_CurrentTuneLibIndexPlaying ) )
  {
    [cell.playButton setBackgroundImage: g_ImagePlay forState: UIControlStateNormal];
  }
  else
  {
    // PDS: No icon for this cell..
    [cell.playButton setBackgroundImage: nil forState: UIControlStateNormal];
  }
 
  return cell;
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
  
  int    nTuneIndexInLib = cell.tag;
  char  *pszTune         = g_vTunesName.elementStrAt( nTuneIndexInLib );
  
  NSLog( @"Tune selected: %s in album: %d (libindex: %d)", pszTune, nAlbumIndex, nTuneIndexInLib );
  
  // PDS: Maintain highlighting in list..
  g_CurrentTuneLibIndexPlaying = nTuneIndexInLib;
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [tuneSelectedDelegate respondsToSelector: @selector( tuneSelectedInAlbum: inAlbum: ) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [tuneSelectedDelegate tuneSelectedInAlbum: nTuneIndexInLib inAlbum: nAlbumIndex];
  }
  
  // PDS: Reload the current screen's cells.
  [self.tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

//-----------------------------------------------------------------------------------------
// backButtonHit
//-----------------------------------------------------------------------------------------
-(void) backButtonHit
{
  [g_navController popViewControllerAnimated:YES];
}

//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

//-----------------------------------------------------------------------------------------
// doneButtonTapped
//-----------------------------------------------------------------------------------------
-(void) doneButtonTapped
{
  [g_navController  popToViewController:[[g_navController viewControllers] objectAtIndex: 0] animated:YES];
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [dismissDelegate respondsToSelector: @selector( dismissAll ) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [dismissDelegate dismissAll];
  }
}

//-----------------------------------------------------------------------------------------
// ratingButtonPressed
//-----------------------------------------------------------------------------------------
-(void) ratingButtonPressed: (id) sender
{
  NSInteger nTuneIndexInLib = ((UIControl *) sender).tag;
  
  ratingButtonPressedCommon( nTuneIndexInLib, g_TableView );
}

//-----------------------------------------------------------------------------------------
// dismissPopover()
//-----------------------------------------------------------------------------------------
-(void) dismissPopover
{
  NSLog( @"g_PreferredFavouriteList NOW: %d", g_PreferredFavouriteList );
  
  // popoverControllerDidDismissPopover()
  //
  // PDS: Does not get called if explicitly dismissed! Only gets called when somebody taps
  //      outside of popover in which case I don't care. So.. I'm using my own DismissDelegate instead
  AddToFavouritePlaylist();
  
  [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

//-----------------------------------------------------------------------------------------
// SelectDestinationPlaylist()
//-----------------------------------------------------------------------------------------
-(void) SelectDestinationPlaylist
{
  NSLog( @"g_PreferredFavouriteList: %d", g_PreferredFavouriteList );
  
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
  g_nSelectedTuneIndexInLib = ((UIControl *) sender).tag;
  
  NSLog( @"nTuneIndexInLib pressed (add to playlist): %d", g_nSelectedTuneIndexInLib );
  
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
    
    AddToFavouritePlaylist();
  }
}

@end

