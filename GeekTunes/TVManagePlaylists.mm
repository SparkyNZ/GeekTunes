//
//  TVManagePlaylists.m
//  GeekTunes
//
//  Created by Admin on 22/07/13.
//
//

#import "TVManagePlaylists.h"
#import "TVFavouritePopup.h"
#import "TVModes.h"
#include "PaulPlayer.h"
#include "Common.h"
#include "vector.h"
#include "Utils.h"
#include "Events.h"
#include "CommonVectors.h"


@implementation TVManagePlaylists

@synthesize buttonShuffle;
@synthesize buttonRename;
@synthesize buttonRecycle;
@synthesize buttonDelete;
//@synthesize dismissDelegate;

extern int      g_PreferredFavouriteList;
extern int      g_NumFavouritePlaylists;
extern Vector   g_vFavouritePlaylistNames;
extern Vector   g_vModeText;
extern Vector   g_vPlaylistsActive;
extern Vector   g_vPlayList   [ MODE_MAX_MODES ];
extern Vector   g_vPlayListMD5[ MODE_MAX_MODES ];

static int g_SelectedPlaylistIndex = -1;

static UITableView *g_TableView = nil;

enum
{
  ALERT_RENAME = 1,
  ALERT_DELETE_CONFIRM,
  ALERT_RECYCLE_CONFIRM,
  ALERT_SHUFFLE_CONFIRM
};


- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  
  if (self)
  {
    // Custom initialization
  }
  return self;
}

//-----------------------------------------------------------------------------------------
// assignButtonTargets
//-----------------------------------------------------------------------------------------
-(void) assignButtonTargets: (UIViewController *) parentVC
{
  [buttonShuffle addTarget:self action:@selector( shuffleClicked ) forControlEvents:UIControlEventTouchUpInside];
  [buttonRename  addTarget:self action:@selector( renameClicked ) forControlEvents:UIControlEventTouchUpInside];
  [buttonRecycle addTarget:self action:@selector( recycleClicked ) forControlEvents:UIControlEventTouchUpInside];
  [buttonDelete  addTarget:self action:@selector( deleteClicked ) forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
                                                                             action:@selector( addPlaylist )];
  
  
  parentVC.navigationItem.rightBarButtonItem = addButton;
}


//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  [super viewDidLoad];
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
                                                                             action:@selector( addPlaylist )];
  
  self.navigationItem.rightBarButtonItem = addButton;
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];
  
  g_SelectedPlaylistIndex = -1;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  g_TableView = tableView;
  
  LogDebugf( "%d favourites", g_NumFavouritePlaylists );

  return g_NumFavouritePlaylists;
  //return g_vFavouritePlaylistNames.elementCount();
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)pTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier;
  
  char txID[ 20 ];
  
  sprintf( txID, "%06d", [indexPath row] );
    
  CellIdentifier = [NSString stringWithUTF8String: txID];
  
  UITableViewCell *cell = (UITableViewCell *)[pTableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  // Configure the cell...  
  int nPlaylistIndex = g_vPlaylistsActive.elementIntAt( [indexPath row ] );
    
  char *pszName = g_vFavouritePlaylistNames.elementStrAt( nPlaylistIndex - 1 );
  
  NSString *nsText    = [NSString stringWithUTF8String: pszName];
  cell.textLabel.text = nsText;
  
  // PDS: Keep track of playlist index so we can handle deletion, missing slots etc
  cell.tag = nPlaylistIndex;
  return cell;
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *pCell = [tableView cellForRowAtIndexPath: indexPath];
  
  // PDS: Select playlist for changes..
  g_SelectedPlaylistIndex = pCell.tag;
}

//-----------------------------------------------------------------------------------------
// addPlaylist
//-----------------------------------------------------------------------------------------
-(void) addPlaylist
{
  BOOL fAdded = FALSE;
  char txName[ 100 ];
  
  // PDS: Find available playlist slot..
  for( int i = 0; i < MAX_FAVOURITE_PLAYLISTS; i ++ )
  {
    if( g_vPlaylistsActive.contains( i + 1 ) )
      continue;
    
    g_vPlaylistsActive.addElement( i + 1 );
    
    sprintf( txName, "Favourites %d", 1 + i );
    g_vFavouritePlaylistNames.setElementAt( i + 1, txName );

    fAdded = TRUE;
    break;
  }
  
  if( fAdded )
  {
    if( g_NumFavouritePlaylists < MAX_FAVOURITE_PLAYLISTS )
      g_NumFavouritePlaylists ++;

    g_vPlaylistsActive.sortIntAscending();
    
    ExportActiveFavourites();
  
    [g_TableView reloadData];
  }
}

//-----------------------------------------------------------------------------------------
// shuffleClicked
//-----------------------------------------------------------------------------------------
-(void) shuffleClicked
{
  if( g_SelectedPlaylistIndex < 0 )
    return;
  
  UIAlertView *alert = [[UIAlertView alloc] init];
  
  [alert setTitle:   @"Shuffle Playlist"];
  [alert setMessage: @"Shuffle all tunes in playlist?"];
  [alert setDelegate: self];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  
  alert.tag = ALERT_SHUFFLE_CONFIRM;
  
  alert.alertViewStyle = UIAlertViewStyleDefault;
  
  [alert show];
}

//-----------------------------------------------------------------------------------------
// alertView
//-----------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if( ( alertView.tag == ALERT_RENAME ) && ( buttonIndex == 0 ) )
  {
    // PDS: Actually rename the playlist..
    UITextField *tfNewName    = [alertView textFieldAtIndex:0];
    char        *pszNewName   = (char*) [tfNewName.text    UTF8String];
    
    if( ( ValidString( pszNewName ) ) && ( strlen( pszNewName ) > 0 ) )
    {
      // PDS: g_SelectedPlaylistIndex is numbered starting from 1..
      int   nPlaylistIndex = g_vPlaylistsActive.indexOf( g_SelectedPlaylistIndex );
      
      LogDebugf( "AV, index in active vector: %d of selected index: %d", nPlaylistIndex, g_SelectedPlaylistIndex );
      
      if( nPlaylistIndex >= 0 )
      {
        g_vFavouritePlaylistNames.setElementAt( nPlaylistIndex, pszNewName );
        g_vModeText.setElementAt( MODE_FAVOURITES_1 + nPlaylistIndex, pszNewName );
        g_vTypeText.setElementAt( TYPE_FAVOURITES1 + nPlaylistIndex, pszNewName );

        SaveFavouritePlaylistNames();
        
        [g_TableView reloadData];
      }
    }
  }
  else
  if( ( alertView.tag == ALERT_SHUFFLE_CONFIRM ) && ( buttonIndex == 0 ) )
  {
    g_vPlayList[ MODE_FAVOURITES_1 - 1 + g_SelectedPlaylistIndex ].shuffle();
    
    ExportActiveFavourites();
    
    // PDS: Nothing selected now.
    g_SelectedPlaylistIndex = -1;
  }
  else
  if( ( alertView.tag == ALERT_DELETE_CONFIRM ) && ( buttonIndex == 0 ) )
  {
    // PDS: Actually delete the playlist..
    g_NumFavouritePlaylists --;
    
    int nIndex = g_vPlaylistsActive.indexOf( g_SelectedPlaylistIndex );
    
    if( nIndex > -1 )
      g_vPlaylistsActive.removeElementAt( nIndex );
   
    g_vPlayList   [ MODE_FAVOURITES_1 - 1 + g_SelectedPlaylistIndex ].removeAll();
    g_vPlayListMD5[ MODE_FAVOURITES_1 - 1 + g_SelectedPlaylistIndex ].removeAll();
    
    ExportActiveFavourites();
    
    [g_TableView reloadData];
    
    // PDS: Nothing selected now.
    g_SelectedPlaylistIndex = -1;
  }
  else
  if( ( alertView.tag == ALERT_RECYCLE_CONFIRM ) && ( buttonIndex == 0 ) )
  {
    // PDS: Actually recycle the playlist.. ie. remove all tunes from selected playlist..
    g_vPlayList   [ MODE_FAVOURITES_1 - 1 + g_SelectedPlaylistIndex ].removeAll();
    g_vPlayListMD5[ MODE_FAVOURITES_1 - 1 + g_SelectedPlaylistIndex ].removeAll();
        
    ExportActiveFavourites();
    
    // PDS: Nothing selected now.
    g_SelectedPlaylistIndex = -1;
  }
}

//-----------------------------------------------------------------------------------------
// renameClicked
//-----------------------------------------------------------------------------------------
-(void) renameClicked
{
  if( g_SelectedPlaylistIndex < 0 )
    return;
  
  UIAlertView *alert = [[UIAlertView alloc] init];

  [alert setTitle:   @"Rename Playlist"];
  [alert setMessage: @"Enter new Playlist name."];
  [alert setDelegate: self];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  
  alert.tag = ALERT_RENAME;
  
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  
  [alert show];
}

//-----------------------------------------------------------------------------------------
// recycleClicked
//-----------------------------------------------------------------------------------------
-(void) recycleClicked
{
  if( g_SelectedPlaylistIndex < 0 )
    return;
  
  UIAlertView *alert = [[UIAlertView alloc] init];
  
  [alert setTitle:   @"Recycle Playlist"];
  [alert setMessage: @"Remove all tunes from playlist. Are you sure?"];
  [alert setDelegate: self];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  
  alert.tag = ALERT_RECYCLE_CONFIRM;
  
  alert.alertViewStyle = UIAlertViewStyleDefault;
  
  [alert show];
}

//-----------------------------------------------------------------------------------------
// deleteClicked
//-----------------------------------------------------------------------------------------
-(void) deleteClicked
{
  if( g_SelectedPlaylistIndex < 0 )
    return;
  
  // PDS: Always keep one playlist
  if( g_NumFavouritePlaylists <= 1 )
    return;

  UIAlertView *alert = [[UIAlertView alloc] init];
  
  [alert setTitle:   @"Delete Playlist"];
  [alert setMessage: @"Are you sure?"];
  [alert setDelegate: self];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  
  alert.tag = ALERT_DELETE_CONFIRM;
  
  alert.alertViewStyle = UIAlertViewStyleDefault;
  
  [alert show];
}

//-----------------------------------------------------------------------------------------
// viewWillDisappear
//-----------------------------------------------------------------------------------------
-(void) viewWillDisappear:(BOOL)animated
{
  PostManageEvent( evFREE_TVMANAGE );
}

@end
