//
//  TVTunes.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVTunes.h"
#import "TVAlbums.h"
#import "TVModes.h"
#import "TVArtists.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
#include "Utils.h"

#import "ViewController.h"
#import "LikeHatePlayCell.h"
#import "TVFavouritePopup.h"

@implementation TVTunes

@synthesize nArtistIndex;
@synthesize tuneSelectedDelegate;
@synthesize dismissDelegate;

extern UINavigationController *g_navController;

extern ViewController *g_MainViewController;
extern TVModes        *g_tvModes;

extern Vector g_vArtist;
extern Vector g_vTunesName;
extern Vector g_vTunesType;
extern Vector g_vTunesArtistIndex;
extern Vector g_vTunesPath;
extern Vector g_vTunesRating;
extern Vector g_vPlayList   [ MODE_MAX_MODES ];
extern Vector g_vPlayListMD5[ MODE_MAX_MODES ];



static Vector g_vSectionHeadings;

Vector g_vTunesForArtist;
Vector g_vTuneIndicesForArtist;
Vector g_vTunesSectionList[ MAX_ALPHA_SECTIONS ];

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
  
  LogDebugf( "TVTunes->viewDidLoad" );
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector( doneButtonTapped )];
  self.navigationItem.rightBarButtonItem = doneButton;
  
  tuneSelectedDelegate = g_MainViewController;
  dismissDelegate      = g_tvModes;
  
  g_vTunesForArtist.removeAll();
  g_vTuneIndicesForArtist.removeAll();
  g_vSectionHeadings.removeAll();
  
  ClearAlphaSectionedVector( g_vTunesSectionList );  
  
  LogDebugf( "Loading tunes for artist %d [%s]", nArtistIndex, g_vArtist.elementStrAt( nArtistIndex ) );
  
  char *pszTuneName;
  char *pszTune;
  int   nTuneType;
  int   nRating;
  BOOL  fAdd;
  
  // PDS: Find all tunes for the artist..
  for( int a = 0; a < g_vTunesArtistIndex.elementCount(); a ++ )
  {
    if( g_vTunesArtistIndex.elementIntAt( a ) == nArtistIndex )
    {      
      nTuneType = g_vTunesType.elementIntAt( a );
      fAdd      = FALSE;
      
      switch( g_DrillDownMode )
      {
        case LIST_ALL_MP3:
          if( nTuneType == UNIT_MP3 )
            fAdd = TRUE;
          break;
          
        case LIST_ALL_LIKES:
          nRating = g_vTunesRating.elementIntAt( a );
          
          if( nRating > 0 )
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
              pszTune = g_vTunesPath.elementStrAt( a );
              
              if( IsNewMODFile( pszTune ) )
                fAdd = TRUE;
            }
            else
            if( g_DrillDownMode == LIST_ALL_MOD_OLD )
            {
              pszTune = g_vTunesPath.elementStrAt( a );
              
              if( IsOldMODFile( pszTune ) )
                fAdd = TRUE;
            }
          }
          break;
      }
      
      if( fAdd )
      {      
        pszTuneName = g_vTunesName.elementStrAt( a );
        g_vTunesForArtist.addElement( pszTuneName );
        g_vTuneIndicesForArtist.addElement( a );
        
        //LogDebugf( "TuneForArtist: %s  %s  Index: %d", pszTuneName, g_vArtist.elementStrAt( nArtistIndex ), a );
      }
    }
  }  
  
  PopulateAlphaSectionedVector( g_vTunesSectionList, &g_vTunesForArtist, NULL );
  LoadSectionHeadingVector( &g_vSectionHeadings, g_vTunesSectionList );
  
  LogDebugf( "TVTunes g_CurrentTuneLibIndexPlaying: %d", g_CurrentTuneLibIndexPlaying );
  
  if( g_CurrentTuneLibIndexPlaying != -1 )
  {
    // PDS: Now try to determine what the section and row of the currently selected tune would be..
    //      The section can be derived from the first character of the tun..
    char *pszSelTune = g_vTunesName.elementStrAt( g_CurrentTuneLibIndexPlaying );
    char  txStartingChar[ 2 ];
    
    txStartingChar[ 0 ] = pszSelTune[ 0 ];
    txStartingChar[ 1 ] = 0;
    
    // PDS: I CANNOT use Full27IndexFromChar for the section as we don't have all 28 sections necessarily.. most unlikely!
    g_SelectedSection  = g_vSectionHeadings.indexOf( txStartingChar );
    
    if( g_SelectedSection >= 0 )
    {
      int    nFull28Index = Full28IndexFromChar( pszSelTune[ 0 ] );
      g_SelectedRow      = g_vTunesSectionList[ nFull28Index ].indexOf( pszSelTune );
    }
    
    LogDebugf( "TVTunes (didload) select section: %d  row: %d", g_SelectedSection, g_SelectedRow );
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
  
  return g_vTunesSectionList[ nFull28Index ].elementCount();
}

//-----------------------------------------------------------------------------------------
// ConfigureLikeHatePlayCell()
//-----------------------------------------------------------------------------------------
void ConfigureLikeHatePlayCell( LikeHatePlayCell *cell,
                                int               nTuneRating,
                                int               nTuneIndexInLib,
                                SEL               ratingButtonFn,
                                SEL               playlistButtonFn,
                                UITableViewController *pTableView )
{
  cell.textLabel.backgroundColor   = [UIColor clearColor];
  cell.contentView.backgroundColor = [UIColor clearColor];
  
  // PDS: Set this so I can toggle the rating for the required tune..
  cell.ratingButton.tag   = nTuneIndexInLib;
  cell.playlistButton.tag = nTuneIndexInLib;
  
  [cell.ratingButton   addTarget: pTableView action: ratingButtonFn   forControlEvents: UIControlEventTouchUpInside];
  
  if( playlistButtonFn != nil )
    [cell.playlistButton addTarget: pTableView action: playlistButtonFn forControlEvents: UIControlEventTouchUpInside];
  
  if( nTuneRating > 0 )
    [cell.ratingButton setBackgroundImage: g_ImageLike forState: UIControlStateNormal];
  else
  if( nTuneRating < 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHate forState: UIControlStateNormal];
  else
  if( nTuneRating == 0 )
    [cell.ratingButton setBackgroundImage: g_ImageHeartGrey forState: UIControlStateNormal];
  
  // PDS: If the tune lives in a playlist, colour the icon purple..
  if( playlistButtonFn != nil )
  {
    if( TuneInFavourites( nTuneIndexInLib ) )
      [cell.playlistButton setBackgroundImage: g_ImageClipboardPurple forState:  UIControlStateNormal];
    else
      [cell.playlistButton setBackgroundImage: g_ImageClipboardGrey   forState:  UIControlStateNormal];
  }
  else
  {
    [cell.playlistButton setBackgroundImage: nil   forState:  UIControlStateNormal];
  }
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString        *CellIdentifier;
  int              nSection = [indexPath section];
  
  // PDS: DO NOT use CellIDs based on section and row otherwise you will run out of memory with heaps of cells!!
  CellIdentifier = @"MyID";
  
  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if( cell == nil )
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  char *pszSection   = g_vSectionHeadings.elementStrAt( [indexPath section] );
  int   nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
  
  char *pszTune      = g_vTunesSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  NSString *nsText   = [NSString stringWithUTF8String: pszTune];
  
  //FindTuneByNameWithCorrectArtist( char *pszTune, int nArtistIndex )
  int   nTuneIndexInLib = g_vTunesName.indexOf( pszTune );
  
  int   nTuneRating  = g_vTunesRating.elementIntAt( nTuneIndexInLib );

  cell.textLabel.text       = nsText;

  // PDS: Set various button states.
  ConfigureLikeHatePlayCell( cell, nTuneRating, nTuneIndexInLib, @selector( ratingButtonPressed: ), @selector( playlistButtonPressed: ),
                             self );

  BOOL fPlayIconAdded = FALSE;
  
  // PDS: Hilight current tune..
  if( g_CurrentTuneLibIndexPlaying != -1 )
  {
    // PDS: Try adding a speaker/playing icon..
    if( g_CurrentTuneLibIndexPlaying == nTuneIndexInLib )
    {
      g_SelectedSection = nSection;
      g_SelectedRow     = [indexPath row];

      fPlayIconAdded = TRUE;
      [cell.playButton setBackgroundImage: g_ImagePlay forState: UIControlStateNormal];
    }
  }

  if( ! fPlayIconAdded )
    [cell.playButton setBackgroundImage: nil forState: UIControlStateNormal];
  
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
// FindTuneByNameWithCorrectArtist
//-----------------------------------------------------------------------------------------
int FindTuneByNameWithCorrectArtist( char *pszTune, int nArtistIndex )
{
  int nUnsortedIndex = g_vTunesName.indexOf( pszTune );
  int nLastTuneIndex = g_vTunesName.elementCount();
  int nArtistFound;
  
  LogDebugf( "Find Tune (%s) artistIdx: %d (%s)", pszTune, nArtistIndex, g_vArtist.elementStrAt( nArtistIndex ) );
  
  for( ;; )
  {
    nArtistFound  = g_vTunesArtistIndex.elementIntAt( nUnsortedIndex );
    
    LogDebugf( "  Artist match: %d (%s)  TuneIndex: %d", nArtistFound, g_vArtist.elementStrAt( nArtistFound ), nUnsortedIndex );
    
    if( nArtistFound == nArtistIndex )
    {
      LogDebugf( "  Returning Tune Index: %d", nUnsortedIndex );
      
      LogDebugf( "  Path[%s]", g_vTunesPath.elementStrAt( nUnsortedIndex ) );
      return nUnsortedIndex;
    }

    LogDebugf( "Wrong artist.. looking again.." );
    nUnsortedIndex ++;

    // PDS: Bail when we hit the end of the list..
    if( nUnsortedIndex >= nLastTuneIndex )
      break;
    
     nUnsortedIndex = g_vTunesName.indexOf( pszTune, nUnsortedIndex );
  }
  
  return -1;
}


//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  char  *pszSection     = g_vSectionHeadings.elementStrAt( [indexPath section] );
  int    nFull28Index   = Full28IndexFromChar( pszSection[ 0 ] );
  char  *pszTune        = g_vTunesSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  
  int    nUnsortedIndex = FindTuneByNameWithCorrectArtist( pszTune, nArtistIndex );

  LogDebugf( "(TVTunes) Tune selected: %s  (libindex: %d)", pszTune, nUnsortedIndex );
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [tuneSelectedDelegate respondsToSelector: @selector( tuneSelected: continueArtist:) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [tuneSelectedDelegate tuneSelected: nUnsortedIndex continueArtist: nArtistIndex];
  }

  // PDS: Maintain highlighting in list..
  g_CurrentTuneLibIndexPlaying = nUnsortedIndex;
  
  // PDS: Change selected colour..
  g_SelectedSection = [indexPath section];
  g_SelectedRow     = [indexPath row];
  
  // PDS: Reload the current screen's cells.
  [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
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
// ratingButtonPressedCommon()
//
// PDS: This can be used by more than one TableView !
//-----------------------------------------------------------------------------------------
void ratingButtonPressedCommon( int nTuneIndexInLib, UITableView *pTableView )
{
  int   nTuneRating  = g_vTunesRating.elementIntAt( nTuneIndexInLib );
  
  if( nTuneRating < 0 )
  {
    // PDS: Remove tune hate status..
    nTuneRating = 0;
  }
  else
  if( nTuneRating > 0 )
  {
    nTuneRating = -1;
  }
  else
  if( nTuneRating == 0 )
  {
    nTuneRating = 1;
  }
  
  g_vTunesRating.setElementAt( nTuneIndexInLib, nTuneRating );
  
  //LogDebugf( "Tune rating @ %d changed to %d", nTuneIndexInLib, nTuneRating );
  
  if( pTableView )
  {
    // PDS: Reload the current screen's cells.
    [pTableView reloadRowsAtIndexPaths:[pTableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  }
  
  // PDS: Make sure likes and RND LIKES playlist is updated and saved ONCE.. when we are done fiddling around..
  g_RatingsChanged = TRUE;
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
// AddToFavouritePlaylist
//
// PDS: g_PreferredFavouriteList has been either set manually or chosen from popover list
//      ..so now we apply the favourite addition and update the table view
//-----------------------------------------------------------------------------------------
void AddToFavouritePlaylist( void )
{
  int nFavIndex = g_vPlayList[ g_PreferredFavouriteList ].indexOf( g_nSelectedTuneIndexInLib );
  
  if( nFavIndex < 0 )
  {
    // PDS: Add to preferred favourites if not already present..
    AddToPlayList( g_PreferredFavouriteList, g_nSelectedTuneIndexInLib );
    ExportPlayList( g_PreferredFavouriteList );
  }
  
  if( g_TableView )
  {
    // PDS: Reload the current screen's cells.
    [ g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
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
  
  AddToFavouritePlaylist();
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
  g_nSelectedTuneIndexInLib = ((UIControl *) sender).tag;
  
  LogDebugf( "nTuneIndexInLib pressed (add to playlist): %d", g_nSelectedTuneIndexInLib );
  
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

