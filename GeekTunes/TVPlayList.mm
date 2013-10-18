//
//  TVPlayList.m
//  GeekTunes
//
//  Created by Paul Spark on 2/07/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVPlayList.h"

#import "TVTunes.h"
#import "TVAlbums.h"
#import "TVModes.h"
#import "TVArtists.h"
#import "TVFavouritePopup.h"
#import "ViewController.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
#include "Utils.h"
#include "TuneSelectedDelegate.h"

@implementation TVPlayList

@synthesize nPlayListIndex;
@synthesize tuneSelectedDelegate;
@synthesize dismissDelegate;
@synthesize fHates;

extern UINavigationController *g_navController;

extern Vector g_vTunesName;
extern Vector g_vTunesRating;
extern Vector g_vTunesType;
extern Vector g_vPlayList   [ MODE_MAX_MODES ];
extern Vector g_vPlayListMD5[ MODE_MAX_MODES ];

static Vector g_vSectionHeadings;

extern Vector g_vTunesSectionList[ MAX_ALPHA_SECTIONS ];

extern ViewController *g_MainViewController;
extern TVModes        *g_tvModes;

// PDS: I have a seperate tune index in the playlist display because tune names are not unique
Vector g_vTunesInList;
Vector g_vTuneIndexInList;

BOOL   g_SectionHeaders = TRUE;

static int g_SelectedSection = -1;
static int g_SelectedRow     = -1;

static UITableView *g_TableView = nil;

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  LogDebugf( "(TVPlayList)  viewDidLoad.." );
  
  [super viewDidLoad]; 
  
  g_SelectedSection = -1;
  g_SelectedRow     = -1;
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector( doneButtonTapped )];
  self.navigationItem.rightBarButtonItem = doneButton;
  
  tuneSelectedDelegate = g_MainViewController;
  dismissDelegate      = g_tvModes;

  g_vTunesInList.removeAll();
  g_vTuneIndexInList.removeAll();
  g_vSectionHeadings.removeAll();
  
  ClearAlphaSectionedVector( g_vTunesSectionList );  
  
  if( ! fHates )
  {
    LogDebugf( "(TVPlayList) Loading tunes in playlist %d, tuneCount: %d", nPlayListIndex, g_vPlayList[ nPlayListIndex ].elementCount() );
  }
  else
  {
    LogDebugf( "(TVPlayList) Loading hates" );
  }
  
  char *pszTuneName;
  int   nTuneIndexInLib;
  
  // PDS: In most cases we want so see section headers..
  g_SectionHeaders = TRUE;
  
  if( nPlayListIndex >= 0 )
  {
    // PDS: Find all tunes for the playlist..
    for( int a = 0; a < g_vPlayList[ nPlayListIndex ].elementCount(); a ++ )
    {
      nTuneIndexInLib = g_vPlayList[ nPlayListIndex ].elementIntAt( a );
      pszTuneName = g_vTunesName.elementStrAt( nTuneIndexInLib );
      
      g_vTunesInList.addElement( pszTuneName );
      g_vTuneIndexInList.addElement( nTuneIndexInLib );
    }
  }
  else
  {
    int nRating;
    
    // PDS: Load in the hate list..
    for( nTuneIndexInLib = 0; nTuneIndexInLib < g_vTunesRating.elementCount(); nTuneIndexInLib ++ )
    {
      nRating     = g_vTunesRating.elementIntAt( nTuneIndexInLib );
      pszTuneName = g_vTunesName.elementStrAt( nTuneIndexInLib );
      
      if( nRating < 0 )
      {
        g_vTunesInList.addElement( pszTuneName );
        g_vTuneIndexInList.addElement( nTuneIndexInLib );
      }
    }
  }
  
  if( g_DrillDownMode != LIST_HATES )
  {
    LogDebugf( "RANDOM/Fav drill down list.. no sections!" );
    // PDS: Randomised lists should NOT be sorted!! Not should favourite playlists..
    g_SectionHeaders = FALSE;
    return;
  }
  
  PopulateAlphaSectionedVector( g_vTunesSectionList, &g_vTunesInList, &g_vTuneIndexInList );
  LoadSectionHeadingVector( &g_vSectionHeadings, g_vTunesSectionList );

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
  }
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];

  LogDebugf( "(TVPlaylist) didAppear, g_SectionHeaders: %d, g_SelectedSection: %d, g_SelectedRow: %d", g_SectionHeaders, g_SelectedSection, g_SelectedRow );
  
  // PDS: Scroll to the selected album.. if we can..
  if( g_SectionHeaders )
  {
    if( ( g_SelectedSection != -1 ) && ( g_SelectedRow != -1 ) )
    {
      NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow: g_SelectedRow inSection: g_SelectedSection ];
      
      [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition: UITableViewScrollPositionMiddle animated: NO ];
    }
  }
  else
  {
    // PDS: If no section headers (e.g. massive list such as RND ALL).. scroll to the tune playing.. if there is one..
    if( g_CurrentTuneLibIndexPlaying != -1 )
    {
      int nRow = g_vTuneIndexInList.indexOf( g_CurrentTuneLibIndexPlaying );
      
      if( nRow < 0 )
        return;
      
      NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow: nRow inSection: 0 ];
      
      [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition: UITableViewScrollPositionMiddle animated: NO ];
    }
  }
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
  
  if( g_SectionHeaders )
  {
    char  *pszSection   = g_vSectionHeadings.elementStrAt( section );
    int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
    
    return g_vTunesSectionList[ nFull28Index ].elementCount();
  }
  
  int nRows = g_vTunesInList.elementCount();
  
  return nRows;
}

//-----------------------------------------------------------------------------------------
// ConfigureLikeHatePlayCellWithRemove()
//-----------------------------------------------------------------------------------------
void ConfigureLikeHatePlayCellWithRemove( LikeHatePlayCell *cell, int nTuneIndexInLib, SEL removeButtonFn,
                                          UITableViewController *pTableView )
{
  cell.textLabel.backgroundColor   = [UIColor clearColor];
  cell.contentView.backgroundColor = [UIColor clearColor];
  
  cell.removeButton.tag   = nTuneIndexInLib;
  
  [cell.removeButton addTarget: pTableView action: removeButtonFn forControlEvents: UIControlEventTouchUpInside];
  
  [cell.removeButton   setBackgroundImage:   g_ImageMinusRed forState:  UIControlStateNormal];
  
  // PDS: For favourite list we only need remove button..
  [cell.playlistButton setBackgroundImage: nil   forState:  UIControlStateNormal];
  
  // PDS: Don't touch rating button images if remove button is present..
  //[cell.ratingButton   setBackgroundImage: nil   forState:  UIControlStateNormal];
}


//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString         *CellIdentifier;
  int              nSection = [indexPath section];

  // PDS: DO NOT use CellIDs based on section and row otherwise you will run out of memory with heaps of cells!!
  CellIdentifier = @"MyID";

  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if( cell == nil )
  {
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    if( ( nPlayListIndex >= MODE_FAVOURITES_1 ) && ( nPlayListIndex <= MODE_FAVOURITES_10 ) )
      cell.fRemoveButton = TRUE;
    else
      cell.fRemoveButton = FALSE;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  char *pszTune;
  
  if( g_SectionHeaders )
  {
    char *pszSection   = g_vSectionHeadings.elementStrAt( [indexPath section] );
    int   nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
    
    pszTune              =       g_vTunesSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
    
    cell.nTuneIndexInLib = (int) g_vTunesSectionList[ nFull28Index ].secondaryPtrAt( [indexPath row] );
  }
  else
  {
    pszTune = g_vTunesInList.elementStrAt( [indexPath row] );
    
    cell.nTuneIndexInLib = g_vTuneIndexInList.elementIntAt( [ indexPath row] );
  }
  
  NSString *nsText       = [NSString stringWithUTF8String: pszTune];
  
  cell.textLabel.text       = nsText;
  
  int   nTuneIndexInLib  = cell.nTuneIndexInLib;
  
  // PDS: Get rid of add to playlist button when showing favourites (playlists)..
  if( ( nPlayListIndex >= MODE_FAVOURITES_1 ) && ( nPlayListIndex <= MODE_FAVOURITES_10 ) )
  {
    // PDS: Set various button states.
    ConfigureLikeHatePlayCellWithRemove( cell, nTuneIndexInLib, @selector( removeButtonPressed: ), self );
  }
  else
  {
    int   nTuneRating      = g_vTunesRating.elementIntAt( nTuneIndexInLib );
 
    // PDS: Set various button states.
    ConfigureLikeHatePlayCell( cell,
                               nTuneRating,
                               nTuneIndexInLib,
                               @selector( ratingButtonPressed: ),
                               ( fHates ) ? nil : @selector( playlistButtonPressed: ),
                               self );
  }
  
  // PDS: Diclosure button only to be enabled for hate list..
  if( fHates )
  {
  }
  else
  {
    BOOL fAddIcon = FALSE;
    
    if( g_SectionHeaders )
    {
      // PDS: Try adding a speaker/playing icon..
      if( ( nSection == g_SelectedSection ) && ( [indexPath row] == g_SelectedRow ) )
        fAddIcon = TRUE;
    }
    else
    {
      if( nTuneIndexInLib == g_CurrentTuneLibIndexPlaying )
        fAddIcon = TRUE;
    }
      
    if( fAddIcon )
    {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

      UIImage *image = [UIImage imageNamed:@"Play_30x30.png"];
      
      UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
      CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
      button.frame = frame;
      [button setBackgroundImage:image forState:UIControlStateNormal];
      button.backgroundColor = [UIColor clearColor];
      cell.accessoryView = button;
    }
    else
    {
      // PDS: No icon for this cell..
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.accessoryView = nil;
    }
  }
  
  // PDS: Hilight current tune..
  if( g_CurrentTuneLibIndexPlaying != -1 )
  {
    if( g_CurrentTuneLibIndexPlaying == nTuneIndexInLib )
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
  char  *pszTune;
  int    nTuneLibIndex;
  
  if( g_SectionHeaders )
  {
    char  *pszSection   = g_vSectionHeadings.elementStrAt( [indexPath section] );
    int    nFull28Index = Full28IndexFromChar( pszSection[ 0 ] );
    pszTune             = g_vTunesSectionList[ nFull28Index ].elementStrAt( [indexPath row] );
  }
  else
  {
    int nRandListIndex  = [indexPath row];
    pszTune             = g_vTunesInList.elementStrAt( nRandListIndex );
  }

  // PDS: Find out the index of the tune in the master library..
  nTuneLibIndex         = g_vTunesName.indexOf( pszTune );
  
  if( fHates != TRUE )
  {
    // PDS: Here I need to toggle the like/hate status.. or change play index to this tune..
    g_PlayListIndex[ nPlayListIndex ] = [indexPath row];
    
    LogDebugf( "(TVPlaylist) Tune selected: %s  (libindex: %d)", pszTune, nTuneLibIndex );
    
    if( g_SectionHeaders )
    {
      // PDS: Check that something has registered to listen for the delegate..
      if( [tuneSelectedDelegate respondsToSelector: @selector( tuneSelected: ) ] )
      {
        // PDS: Call the activityDeleted delegate method on the parent..
        [tuneSelectedDelegate tuneSelected: nTuneLibIndex];
      }
    }
    else
    {
      // PDS: Check that something has registered to listen for the delegate..
      if( [tuneSelectedDelegate respondsToSelector: @selector( tuneSelectedInPlayList: inPlayList: ) ] )
      {
        // PDS: Call the activityDeleted delegate method on the parent..
        [tuneSelectedDelegate tuneSelectedInPlayList: [indexPath row] inPlayList: nPlayListIndex];
      }
      
      // PDS: Reload the current screen's cells.
      [self.tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    // PDS: Dismiss view if tune selected for playing.. ??
    //[g_navController popViewControllerAnimated:YES];
    
    // PDS: Maintain highlighting in list..
    g_CurrentTuneLibIndexPlaying = nTuneLibIndex;
  }

  // PDS: Change selected colour..
  g_SelectedSection = [indexPath section];
  g_SelectedRow     = [indexPath row];
  
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
// titleForHeaderInSection
//-----------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
  if( g_SectionHeaders )
  {
    char     *pszHeading = g_vSectionHeadings.elementStrAt( section );
    NSString *nsTitle    = [NSString stringWithUTF8String: pszHeading];
    
    return nsTitle;
  }
  
  return @"";
}

//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  if( ! g_SectionHeaders )
    return 1;
  
  // Return the number of sections.
  return g_vSectionHeadings.elementCount();
}

//-----------------------------------------------------------------------------------------
// sectionIndexTitlesForTableView
//-----------------------------------------------------------------------------------------
- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView 
{
  if( ! g_SectionHeaders )
    return nil;
  
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
  if( g_DefaultPreferredFavouriteList )
  {
    // PDS: Choice not necessary..
    [self dismissPopover];
    return;
  }
  
  LogDebugf( "g_PreferredFavouriteList: %d", g_PreferredFavouriteList );
  
  TVFavouritePopup *tvFavs = [TVFavouritePopup alloc];
  
  [tvFavs init];
  [tvFavs setTitle: @"Playlists"];
  
  // PDS: Only show playlists..
  tvFavs.fIncludeNoDefault = FALSE;
  
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

//-----------------------------------------------------------------------------------------
// RemoveFromPlaylist()
//-----------------------------------------------------------------------------------------
void RemoveFromPlaylist( int nTuneIndexInLib, int nPlayListIndex )
{
  int nFavIndex = g_vPlayList[ nPlayListIndex ].indexOf( nTuneIndexInLib );
  
  if( nFavIndex < 0 )
    return;

  LogDebugf( "Tune %d FOUND found in list %d", nTuneIndexInLib, nPlayListIndex );
  
  g_vPlayList[ nPlayListIndex ].removeElementAt( nFavIndex );
  
  char txHash[ MD5_ASC_SIZE + 1 ];
  
  GetHashForTuneIndexInLib( txHash, nTuneIndexInLib );
  g_vPlayList[ nPlayListIndex ].removeUniqueElement( txHash );
  
  int   nLocalIndex = g_vTuneIndexInList.indexOf( nTuneIndexInLib );
  
  if( nLocalIndex >= 0 )
  {
    g_vTunesInList.removeElementAt( nLocalIndex );
    g_vTuneIndexInList.removeElementAt( nLocalIndex );
  
    if( g_TableView )
    {
      [g_TableView reloadData];
      
      // PDS: Reload the current screen's cells.
      [ g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  
  ExportPlayList( nPlayListIndex );  
}

//-----------------------------------------------------------------------------------------
// removeButtonPressed
//-----------------------------------------------------------------------------------------
-(void) removeButtonPressed: (id) sender
{
  NSInteger nTuneIndexInLib = ((UIControl *) sender).tag;
  
  LikeHatePlayCell *cell = (LikeHatePlayCell *) [ [sender superview] superview];
  
  cell.fDeleted = TRUE;

  LogDebugf( "Remove tune index: %d (Confirm cell index: %d)", nTuneIndexInLib, cell.nTuneIndexInLib );
  
  RemoveFromPlaylist( nTuneIndexInLib, nPlayListIndex );
}


@end
