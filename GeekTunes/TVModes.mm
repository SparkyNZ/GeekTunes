//
//  TVModes.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVModes.h"
#import "TVArtists.h"
#import "TVPlayList.h"

#include "Common.h"
#include "PaulPlayer.h"
#include "vector.h"
//#include "DismissDelegate.h"
#include "Events.h"
#include "Utils.h"

enum 
{
  MODE_SECTION_SEQUENCES = 0,
  MODE_SECTION_LIBRARY,
  MODE_SECTION_RANDOM,
  MODE_SECTION_HATES,
  
  MODE_NUM_SECTIONS
};


@implementation TVModes

extern UINavigationController *g_navController;

Vector   g_vListType;
BOOL     g_RatingsChanged = FALSE;
int      g_DrillDownMode  = LIST_ALL_MP3;
TVModes *g_tvModes        = nil;

extern Vector   g_vPlaylistsActive;
extern Vector   g_vFavouritePlaylistNames;

int      g_nSelectedTuneIndexInLib;
int      g_nSelectedArtistIndexInLib;
int      g_nSelectedAlbumIndexInLib;


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

//-----------------------------------------------------------------------------------------
// dismissVC
//-----------------------------------------------------------------------------------------
-(void) dismissVC
{
//  [g_navController popViewControllerAnimated:YES];
  [self dismissViewControllerAnimated:YES completion:nil];
}

//-----------------------------------------------------------------------------------------
// dismissAll
//-----------------------------------------------------------------------------------------
-(void) dismissAll
{
  LogDebugf( "TVModes::dismissAll() called");
  
  // PDS: Dismiss all viewcontrollers and bring us back here via delegation..
  [self dismissVC];
}

//-----------------------------------------------------------------------------------------
// viewWillAppear
//-----------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
  ReloadListNames();
  
  if( g_tvModes )
    [g_tvModes.tableView reloadData];
  
  [super viewWillAppear:animated];

  if( g_RatingsChanged )
  {
    PostManageEvent( evCREATE_PLAYLIST_LIKES );

    g_RatingsChanged = FALSE;
  }
}

//-----------------------------------------------------------------------------------------
// ReloadListNames()
//-----------------------------------------------------------------------------------------
void ReloadListNames( void )
{
  char txName[ 200 ];
  
  g_vListType.removeAll();
  
  for( int m = 0; m < LIST_MAX_TYPES; m ++ )
  {
    GetListName( m, txName );
    g_vListType.addElement( txName );
  }
}

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  self.title = @"Tune Lists";  

  [super viewDidLoad];
  
  g_tvModes = self;
  
  // PDS: No ratings have been changed yet..
  g_RatingsChanged = FALSE;
  
  ReloadListNames();
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector( dismissVC )];
  self.navigationItem.leftBarButtonItem = backButton;
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
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return MODE_NUM_SECTIONS;
}

//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch( section )
  {
    case MODE_SECTION_SEQUENCES:
      // PDS: Fav playlists should only appear if they have been officially added..
      LogDebugf( "### TVMODES, %d favourites", g_NumFavouritePlaylists );
      
      return g_NumFavouritePlaylists;
      
    case MODE_SECTION_LIBRARY:
      return NUM_LISTS_LIB_SECTION;
      
    case MODE_SECTION_HATES:
      return 1;
  }
  
  // PDS: Must be random section..
  return NUM_LISTS_RND_SECTION;
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  NSString        *CellIdentifier;
  
  char txID[ 10 ];
  
  sprintf( txID, "%01d%02d", [indexPath section], [indexPath row] );
  
  CellIdentifier = [NSString stringWithUTF8String: txID];
  
  cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  
  if (cell == nil) 
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  char *pszMode;
  char  txHates[] = "Hates/Trash";
  int   nListType;

  switch( [indexPath section] )
  {
    case MODE_SECTION_SEQUENCES:
      LogDebugf( "## nActivePL: %d", g_vPlaylistsActive.elementCount() );
      
      nListType = g_vPlaylistsActive.elementIntAt( [indexPath row] );
      
      LogDebugf( "## nListType: %d", nListType );
      
      pszMode = g_vListType.elementStrAt( nListType - 1 );
      break;
      
    case MODE_SECTION_HATES:
      nListType = LIST_HATES;
      pszMode = txHates;
      break;
      
    case MODE_SECTION_LIBRARY:
      nListType = [indexPath row] + LIST_ALL_MP3;
      pszMode = g_vListType.elementStrAt( nListType );
      break;
      
    default:
      // PDS: Random section..
      nListType = [indexPath row] + LIST_RND_ALL;
      pszMode = g_vListType.elementStrAt( nListType );
      break;
  }
  
  NSString *nsText = [NSString stringWithUTF8String: pszMode];
  
  cell.textLabel.text       = nsText;
  cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  NSString *nsListName;
  char      txListName[ 100 ];
  
  // PDS: Keep track of the type of list selected..
  if( [indexPath section] == MODE_SECTION_SEQUENCES )
  {
    g_DrillDownMode = [indexPath row] + LIST_FAVOURITES_1;
    
    TVPlayList *tvPlayList = [TVPlayList alloc];
    
    [tvPlayList init];
    [tvPlayList initWithStyle: UITableViewStylePlain];
    
    tvPlayList.fHates = FALSE;
    
    GetListName( g_DrillDownMode, txListName );
    
    nsListName = [NSString stringWithUTF8String: txListName];
    
    [tvPlayList setTitle: nsListName];
    
    // PDS: Map the drill down mode to the actual player list (mode)..
    if( ( g_DrillDownMode >= LIST_FAVOURITES_1  ) &&
        ( g_DrillDownMode <= LIST_FAVOURITES_10 ) )
    {
      tvPlayList.nPlayListIndex = MODE_FAVOURITES_1 + ( g_DrillDownMode - LIST_FAVOURITES_1 ) ;
    }
    
    [g_navController pushViewController: tvPlayList animated:YES];
  }
  else
  if( [indexPath section] == MODE_SECTION_LIBRARY )
  {
    // PDS: True drill-down lists are here.. these are NOT related to playlists!!
    g_DrillDownMode = [indexPath row] + LIST_ALL_MP3;
    
    TVArtists *tvArtists = [TVArtists alloc];
    
    [tvArtists init];
    [tvArtists initWithStyle: UITableViewStylePlain];
    [tvArtists setTitle: @"Artists"];
    
    [g_navController pushViewController: tvArtists animated:YES];
  }
  else
  if( [indexPath section] == MODE_SECTION_HATES )
  {
    g_DrillDownMode = LIST_HATES;
    
    TVPlayList *tvPlayList = [TVPlayList alloc];

    tvPlayList.fHates = TRUE;    
    
    [tvPlayList init];
    [tvPlayList initWithStyle: UITableViewStylePlain];
    
    // PDS: "Hates" isn't really a play list..
    [tvPlayList setTitle: @"Hates/Trash"        ];
    tvPlayList.nPlayListIndex = -1;
  
    [g_navController pushViewController: tvPlayList animated:YES];
  }
  else
  if( [indexPath section ] == MODE_SECTION_RANDOM )
  {
    LogDebugf( "Random Mode selected..");
    
    TVPlayList *tvPlayList = [TVPlayList alloc];
    
    [tvPlayList init];
    [tvPlayList initWithStyle: UITableViewStylePlain];
    
    tvPlayList.fHates = FALSE;

    g_DrillDownMode = [indexPath row] + LIST_RND_ALL;
    
    GetListName( g_DrillDownMode, txListName );
    
    nsListName = [NSString stringWithUTF8String: txListName];
    
    [tvPlayList setTitle: nsListName];
    
    // PDS: Map the drill down mode to the actual player list (mode)..
    tvPlayList.nPlayListIndex = [indexPath row] + MODE_RND_ALL;
    
    [g_navController pushViewController: tvPlayList animated:YES];
  }
}

//-----------------------------------------------------------------------------------------
// titleForHeaderInSection
//-----------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
  switch( section )
  {
    case MODE_SECTION_SEQUENCES:
      return @"Sequence Playlists";
      
    case MODE_SECTION_LIBRARY:
      return @"Library";

    case MODE_SECTION_RANDOM:
      return @"Randomised Playlists";
    
    default:
      break;
  }
  
  //  case MODE_SECTION_HATES:
  return @"Misc Lists";
}

//-----------------------------------------------------------------------------------------
// backButtonHit
//-----------------------------------------------------------------------------------------
-(void) backButtonHit
{
  [self.navigationController popViewControllerAnimated:YES];
}


@end
