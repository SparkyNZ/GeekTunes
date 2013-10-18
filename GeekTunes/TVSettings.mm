//
//  TVSettings.m
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TVSettings.h"
#import "TVModes.h"
#import "TVManagePlaylists.h"
#import "TVFavouritePopup.h"
#import "TVSelectListPopup.h"
#import "ViewController.h"
#import "BackupRestoreVC.h"
#import "DCRoundSwitch.h"
#import "DismissDelegate.h"

#include "Common.h"
#include "Utils.h"
#include "PaulPlayer.h"
#include "Events.h"

@implementation TVSettings

@synthesize doneButton;

extern UINavigationController *g_navController;



static UITableView *g_TableView = nil;
extern int          g_PopOverTagEvent;

DCRoundSwitch      *g_SIDSwitch = nil;
TVManagePlaylists  *g_tvManage  = nil;
BackupRestoreVC    *g_BackupRestoreView = nil;

int g_nBotBarHeight    = 49;

int      g_AboutHeight = 100;
NSString *g_AboutText = @"GeekTunes v1.1\n\nby Paul D. Spark\ngeektunesapp@gmail.com";

#define NUM_ABOUT_LINES 4

//-----------------------------------------------------------------------------------------
// Settings sections
//-----------------------------------------------------------------------------------------
enum
{
  SETTINGS_SECTION_PLAYLISTS = 0,
  SETTINGS_SECTION_HATES,
  SETTINGS_SECTION_PLAYBACK_SID,
  SETTINGS_SECTION_ABOUT,
  
  SETTINGS_NUM_SECTIONS
};

//-----------------------------------------------------------------------------------------
// Settings - Main
//-----------------------------------------------------------------------------------------
enum
{
  SETTINGS_MAIN_1 = 0,
  
  SETTINGS_MAIN_NUM_ROWS
};

//-----------------------------------------------------------------------------------------
// Settings - Playlists
//-----------------------------------------------------------------------------------------
enum
{
  SETTINGS_PLAYLISTS_MANAGE = 0,
  SETTINGS_PLAYLISTS_DEFAULT,
  SETTINGS_PLAYLISTS_LIKE,
  
  SETTINGS_PLAYLISTS_NUM_ROWS
};

//-----------------------------------------------------------------------------------------
// Settings - Filestore
//-----------------------------------------------------------------------------------------
enum
{
  SETTINGS_HATES_UNHATE = 0,
  SETTINGS_HATES_DELETE,
  SETTINGS_LIKES_TO_PLIST,
  SETTINGS_HATES_SAFEKEEP,
  SETTINGS_REBUILD_LIB,
  SETTINGS_START_FTP,
  
  SETTINGS_HATES_NUM_ROWS
};

//-----------------------------------------------------------------------------------------
// Settings - SID Playback
//-----------------------------------------------------------------------------------------
enum
{
  SETTINGS_PLAYBACK_SID_CHIP = 0,
};

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
- (void)viewDidLoad
{
  [super viewDidLoad];

  doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                             target:self action:@selector( doneButtonPressed )];

  // add the "Done" button to the nav bar
  self.navigationItem.rightBarButtonItem = self.doneButton;
  
  self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]
                                         initWithTitle:@"Back"
                                         style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector( backButtonHit ) ];
  
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
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  g_TableView = tableView;
  
  // Return the number of sections.
  return SETTINGS_NUM_SECTIONS;
}

//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  switch ( section )
  {
    case SETTINGS_SECTION_PLAYLISTS:       return SETTINGS_PLAYLISTS_NUM_ROWS;
    case SETTINGS_SECTION_HATES:           return SETTINGS_HATES_NUM_ROWS;
    case SETTINGS_SECTION_PLAYBACK_SID:    return 1;
    case SETTINGS_SECTION_ABOUT:           return 1;
    default:                               break;
  }
  return 0;
}

//-----------------------------------------------------------------------------------------
// titleForHeaderInSection
//-----------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  switch ( section )
  {
    case SETTINGS_SECTION_PLAYLISTS:       return @"Playlists";
    case SETTINGS_SECTION_HATES:           return @"Filestore";
    case SETTINGS_SECTION_PLAYBACK_SID:    return @"SID Playback";
    case SETTINGS_SECTION_ABOUT:           return @"About";
    default:                               break;
  }
  return 0;
}

//-----------------------------------------------------------------------------------------
// cellForPlaylistsSection
//-----------------------------------------------------------------------------------------
-(UITableViewCell *) cellForPlaylistsSection: (UITableView *)tableView atRow: (int) nRow  
{
  UITableViewCell *cell = nil;

  char txID[ 20 ];
  
  sprintf( txID, "%02d%02d", SETTINGS_SECTION_PLAYLISTS, nRow );
  NSString *CellIdentifier = CellIdentifier = [NSString stringWithUTF8String: txID];

  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  switch( nRow )
  {
    case SETTINGS_PLAYLISTS_MANAGE:
      cell.textLabel.text = @"Manage Playlists";
      cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
      break;
      
    case SETTINGS_PLAYLISTS_DEFAULT:
      cell.textLabel.text = @"Set Preferred Playlist";
      cell.accessoryType  = UITableViewCellAccessoryNone;
      break;
      
    case SETTINGS_PLAYLISTS_LIKE:
      cell.textLabel.text = @"Set LIKE Behaviour";
      cell.accessoryType  = UITableViewCellAccessoryNone;
      break;
  }
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// cellForHatesSection
//-----------------------------------------------------------------------------------------
- (UITableViewCell *) cellForHatesSection: (UITableView *)tableView atRow: (int) nRow
{
  UITableViewCell *cell = nil;
  
  char txID[ 20 ];
  
  sprintf( txID, "%02d%02d", SETTINGS_SECTION_HATES, nRow );
  NSString *CellIdentifier = CellIdentifier = [NSString stringWithUTF8String: txID];
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  
  switch( nRow )
  {
    case SETTINGS_HATES_UNHATE:    cell.textLabel.text = @"Un-Hate All";        break;
    case SETTINGS_HATES_DELETE:    cell.textLabel.text = @"Delete All Hates";   break;
      
    case SETTINGS_LIKES_TO_PLIST:  cell.textLabel.text = @"Add Likes to Playlist"; break;
      
    case SETTINGS_HATES_SAFEKEEP:  cell.textLabel.text = @"Safekeep Likes";     break;
    case SETTINGS_REBUILD_LIB:     cell.textLabel.text = @"Rebuild Library";    break;
    case SETTINGS_START_FTP:       cell.textLabel.text = @"Upload Files (FTP)"; break;
  }
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// ToggleSIDChip
//-----------------------------------------------------------------------------------------
-(void) ToggleSIDChip
{
  g_SIDChipType = ( g_SIDSwitch.on ) ? SID2_MOS6581 : SID2_MOS8580;
  
  PostPlayerEvent( evSID_CHIP_TOGGLE );
}

//-----------------------------------------------------------------------------------------
// cellForSIDPlaybackSection
//-----------------------------------------------------------------------------------------
- (UITableViewCell *) cellForSIDPlaybackSection: (UITableView *)tableView atRow: (int) nRow
{
  UITableViewCell *cell = nil;
  
  char txID[ 20 ];

  sprintf( txID, "%02d%02d", SETTINGS_SECTION_PLAYBACK_SID, nRow );
  NSString *CellIdentifier = CellIdentifier = [NSString stringWithUTF8String: txID];
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell != nil)
    return cell;
  
  cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  
  switch( nRow )
  {
    case SETTINGS_PLAYBACK_SID_CHIP:
    {
      g_SIDSwitch = [[DCRoundSwitch alloc] initWithFrame: CGRectMake(1.0, 1.0, 70.0, 25.0)];
     
      g_SIDSwitch.onText  = @"6581";
      g_SIDSwitch.offText = @"8580";

      // PDS: Green background for 8580..
      g_SIDSwitch.offTintColor = [UIColor colorWithRed:0.000 green:0.682 blue:0.278 alpha:1.0];
      
      [g_SIDSwitch setOn: (g_SIDChipType == SID2_MOS6581) ? TRUE : FALSE
                animated: TRUE
     ignoreControlEvents: TRUE ];
      
      [g_SIDSwitch addTarget: self action: @selector( ToggleSIDChip ) forControlEvents:UIControlEventValueChanged];
      
      cell.accessoryView = g_SIDSwitch;
      cell.textLabel.text = @"SID Chip";
      break;
    }
  }
 
  return cell;
}

//-----------------------------------------------------------------------------------------
// cellForAboutSection
//-----------------------------------------------------------------------------------------
- (UITableViewCell *) cellForAboutSection: (UITableView *)tableView atRow: (int) nRow
{
  UITableViewCell *cell = nil;
  NSString        *CellIdentifier;
  
  static NSString *idAbout  = @"CellAbout";
  
  CellIdentifier = idAbout;
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.backgroundColor = UIColorFromRGB( 0x8080FF );
  
  cell.textColor = UIColorFromRGB( 0xFFFFFF );
  cell.text = g_AboutText;
  cell.textAlignment  = UITextAlignmentCenter;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.textLabel.numberOfLines = NUM_ABOUT_LINES;
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// heightForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
  if( indexPath.section == SETTINGS_SECTION_ABOUT )
    return g_AboutHeight;
  
  return tableView.rowHeight;
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  
  // Configure the cell...
  switch( [indexPath section] )
  {
    case SETTINGS_SECTION_PLAYLISTS:
      cell = [self cellForPlaylistsSection: tableView atRow: [indexPath row] ];
      break;
     
    case SETTINGS_SECTION_HATES:
      cell = [self cellForHatesSection: tableView atRow: [indexPath row] ];
      break;
      
    case SETTINGS_SECTION_PLAYBACK_SID:
      cell = [self cellForSIDPlaybackSection: tableView atRow: [indexPath row ] ];
      break;
      
    case SETTINGS_SECTION_ABOUT:
      cell = [self cellForAboutSection: tableView atRow: [indexPath row] ];
      break;
  }
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// backButtonHit
//-----------------------------------------------------------------------------------------
-(void) backButtonHit
{
  if( ( fSettingsChanged == TRUE ) && ( fDoneButtonPressed == FALSE ) )
  {
    // PDS: Are you sure?
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:@"Confirm"];
    [alert setMessage:@"Any changes will be lost. Are you sure?"];
    [alert setDelegate:self];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert show];
    
    // PDS: Don't disappear here until alert confirmed..
    return;
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
//  [self.navigationController popViewControllerAnimated:YES];
}


//-----------------------------------------------------------------------------------------
// doneButtonPressed
//-----------------------------------------------------------------------------------------
-(void) doneButtonPressed
{
  fDoneButtonPressed = TRUE;
//  [self settingsChanged];
  
  [self dismissViewControllerAnimated:YES completion:nil];  
  //[self.navigationController popViewControllerAnimated:YES];
}

//-----------------------------------------------------------------------------------------
// alertView
//-----------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if( buttonIndex == 0 )
  {
    // PDS: Are you sure you want to lose changes.. YES..
    [self.navigationController popViewControllerAnimated:YES];
    
    switch( alertView.tag )
    {
      case SETTINGS_HATES_UNHATE:   PostManageEvent( evUNHATE_ALL     );  break;
      case SETTINGS_HATES_DELETE:   PostManageEvent( evDELETE_HATES   );  break;
      case SETTINGS_LIKES_TO_PLIST: PostManageEvent( evLIKES_TO_PLIST );  break;
      case SETTINGS_HATES_SAFEKEEP: PostManageEvent( evSAFEKEEP_LIKES );  break;
      case SETTINGS_REBUILD_LIB:    PostManageEvent( evREBUILD_LIB    );  break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// ConfirmAction
//-----------------------------------------------------------------------------------------
-(void) ConfirmAction: (int) nAction
{
  UIAlertView *alert = [[UIAlertView alloc] init];
  
  switch( nAction )
  {
    case SETTINGS_HATES_UNHATE:
      [alert setTitle:@"Un-Hate All"];
      [alert setMessage:@"Unmark all hated tunes?"];
      break;
      
    case SETTINGS_HATES_DELETE:
      [alert setTitle:@"Delete All Hates"];
      [alert setMessage:@"Delete all hated tunes from device?"];
      break;
      
    case SETTINGS_LIKES_TO_PLIST:
      [alert setTitle:@"Add Likes to Playlist"];
      [alert setMessage:@"Add all liked tunes to preferred playlist?"];
      break;
      
    case SETTINGS_HATES_SAFEKEEP:
      [alert setTitle:@"Safekeep Liked Tunes"];
      [alert setMessage:@"Move liked tunes to a safe place?"];
      break;
      
    case SETTINGS_REBUILD_LIB:
      [alert setTitle:@"Rebuild Entire Library"];
      [alert setMessage:@"Import all tunes?"];
      break;
  }

  alert.tag = nAction;
  
  [alert setDelegate:self];
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  [alert show];
}

//-----------------------------------------------------------------------------------------
// AddSmallLabelToButton()
//-----------------------------------------------------------------------------------------
UILabel *AddSmallLabelToButton( char *pTxt, UIButton *pButton )
{
  int x = 0;
  int y = g_nBotBarHeight - 10;
  
  UILabel *label = [UILabel alloc];
  [label initWithFrame: CGRectMake( x, y, pButton.frame.size.width, 10 ) ];
  label.backgroundColor = [UIColor  clearColor];
  label.textAlignment   = UITextAlignmentCenter;
  label.textColor       = [UIColor whiteColor];
  label.font            = [UIFont fontWithName:@"Helvetica-Bold" size: 10 ];
  [label setText: [NSString stringWithUTF8String: pTxt] ];
  
  [pButton addSubview: label];
  
  return label;
}

//-----------------------------------------------------------------------------------------
// ManagePlaylists
//-----------------------------------------------------------------------------------------
-(void) ManagePlaylists
{
  // PDS: I need to maintain a global pointer reference, otherwise view will be lost as soon
  //      as we return from this function (thanks to ARC!)
  if( g_tvManage == nil )
    g_tvManage = [TVManagePlaylists alloc];
  
  [g_tvManage init];
  [g_tvManage initWithStyle: UITableViewStylePlain];
  [g_tvManage setTitle: @"Manage Playlists"];
  
  UIViewController  *vcManage = [UIViewController alloc];
  
  [vcManage init];
  [vcManage setTitle: @"Manage Playlists"];
  
  int nNavBarHeight   = g_navController.navigationBar.viewForBaselineLayout.frame.size.height;
  
  LogDebugf( "Navbar height: %d", nNavBarHeight );
  
  int nNumButtons      = 4;
  int nStatusBarHeight = 20;
  int nTVHeight        = g_MaxPixelHeight - g_nBotBarHeight;
  int nButtonHeight    = 39;
  int nButtonWidth     = g_MaxPixelWidth / nNumButtons;
  int yBotBar          = nTVHeight - ( nNavBarHeight + nStatusBarHeight );
  
  // PDS: 0 y coordinate is beneath the Nav bar
  [g_tvManage.tableView setFrame: CGRectMake( 0, 0, g_MaxPixelWidth, nTVHeight)];
  [vcManage.view addSubview: g_tvManage.tableView];
  
  UIView   *bottomView = [[UIView alloc] initWithFrame:CGRectMake( 0, yBotBar, g_MaxPixelWidth, g_nBotBarHeight )];
  [bottomView setBackgroundColor: [UIColor blackColor]];
  
  g_tvManage.buttonShuffle = [UIButton buttonWithType: UIButtonTypeCustom];
  g_tvManage.buttonRename  = [UIButton buttonWithType: UIButtonTypeCustom];
  g_tvManage.buttonRecycle = [UIButton buttonWithType: UIButtonTypeCustom];
  g_tvManage.buttonDelete  = [UIButton buttonWithType: UIButtonTypeCustom];
  
  [g_tvManage.buttonShuffle setImage: g_ImageDice     forState: UIControlStateNormal];
  [g_tvManage.buttonRename  setImage: g_ImagePencil   forState: UIControlStateNormal];
  [g_tvManage.buttonRecycle setImage: g_ImageRecycle  forState: UIControlStateNormal];
  [g_tvManage.buttonDelete  setImage: g_ImageTrashcan forState: UIControlStateNormal];
  
  int x = 0;
  
  g_tvManage.buttonShuffle.frame = CGRectMake( x, 2, nButtonWidth, nButtonHeight );  x += nButtonWidth;
  g_tvManage.buttonRename.frame  = CGRectMake( x, 2, nButtonWidth, nButtonHeight );  x += nButtonWidth;
  g_tvManage.buttonRecycle.frame = CGRectMake( x, 2, nButtonWidth, nButtonHeight );  x += nButtonWidth;
  g_tvManage.buttonDelete.frame  = CGRectMake( x, 2, nButtonWidth, nButtonHeight );  x += nButtonWidth;
  
  AddSmallLabelToButton( "Shuffle", g_tvManage.buttonShuffle );
  AddSmallLabelToButton( "Rename" , g_tvManage.buttonRename );
  AddSmallLabelToButton( "Recycle", g_tvManage.buttonRecycle );
  AddSmallLabelToButton( "Delete",  g_tvManage.buttonDelete );
  
  [g_tvManage assignButtonTargets: vcManage];
  
  // PDS: Add to bottom view
  [bottomView addSubview: g_tvManage.buttonShuffle];
  [bottomView addSubview: g_tvManage.buttonRename];
  [bottomView addSubview: g_tvManage.buttonRecycle];
  [bottomView addSubview: g_tvManage.buttonDelete];
  
  [vcManage.view  addSubview: bottomView]; //add bottom view main view
  
  
  LogDebugf( "Reload Tableview" );
  [g_tvManage.tableView reloadData];
  
  [g_navController pushViewController: vcManage animated:YES];
  
  // PDS: Need to release this later on!
  //[g_tvManage release];
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
  if( g_PopOverTagEvent == evLIKES_TO_PLIST )
  {
    PostManageEvent( evLIKES_TO_PLIST );
  }
  else
  {
    AddToFavouritePlaylist();
  }
  
  g_PopOverTagEvent = evNO_EVENT;
}

//-----------------------------------------------------------------------------------------
// SetDefaultPlaylist
//-----------------------------------------------------------------------------------------
-(void) SetDefaultPlaylist
{
  LogDebugf( "g_PreferredFavouriteList: %d", g_PreferredFavouriteList );
  
  TVFavouritePopup *tvFavs = [TVFavouritePopup alloc];
  
  [tvFavs init];
  [tvFavs setTitle: @"Playlists"];
  
  // PDS: Make sure "No default" appears in selection..
  tvFavs.fIncludeNoDefault = TRUE;
  g_PopOverTagEvent = evNO_EVENT;
  
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

TVSelectListPopup   *g_tvFavs = nil;
UIPopoverController *g_tvFavsPopover = nil;
Vector               g_vFavs;
int                  g_FavSelected = -1;
extern int           g_NumFavouritePlaylists;
extern Vector        g_vFavouritePlaylistNames;



//-----------------------------------------------------------------------------------------
// AddLikesToPlaylist
//-----------------------------------------------------------------------------------------
-(void) AddLikesToPlaylist
{
  if( g_tvFavs == nil )
  {
    g_tvFavs = [[ TVSelectListPopup alloc] initWithStyle: UITableViewStylePlain];
        
    g_tvFavs.contentSizeForViewInPopover = CGSizeMake( 320, 800 );
    
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController: g_tvFavs];
    
    [popover setDelegate: self];
    
    g_tvFavs.popover = popover;
    
    // PDS: Maintain pointers to keep objects alive..
    g_tvFavsPopover = popover;
    
    // PDS: Delegate my popover dismiss delegate to this TV..
    g_tvFavs.dismissDelegate = self;
  }
 
  [g_tvFavs setTitle: @"Add LIKES to PL"];
 
  g_PopOverTagEvent = evLIKES_TO_PLIST;
  
  g_tvFavs.pnSelectedRow = &g_FavSelected;
  g_tvFavs.nsTitle = @"Select Dest Playlist";
  
  g_vFavs.removeAll();
  
  for( int i = 0; i < g_NumFavouritePlaylists; i ++ )
  {
    char *pszName = g_vFavouritePlaylistNames.elementStrAt( i );
    g_vFavs.addElement( pszName );
  }
  
  g_tvFavs.pvSelectListItems = &g_vFavs;
  
  [g_tvFavs reloadData];

  
  // PDS: Ensure popover appears in the visible part of the table view..
  NSArray         *arrIndexPaths = [g_TableView indexPathsForVisibleRows];
  NSIndexPath     *indexPath     = [arrIndexPaths objectAtIndex: 0];
  UITableViewCell *cell          = [g_TableView cellForRowAtIndexPath: indexPath];
  
  CGRect rect = CGRectMake( cell.bounds.origin.x + 20, cell.bounds.origin.y + 10, 50, 30 );
  
  [g_tvFavsPopover presentPopoverFromRect:rect inView: cell permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

TVSelectListPopup   *g_tvList        = nil;
UIPopoverController *g_tvListPopover = nil;
Vector               g_vLikeBehaviours;

//-----------------------------------------------------------------------------------------
// SetLikeBehaviour
//-----------------------------------------------------------------------------------------
-(void) SetLikeBehaviour
{
  if( g_tvList == nil )
  {
    TVSelectListPopup *tvList = [[ TVSelectListPopup alloc] init];
    
    tvList.contentSizeForViewInPopover = CGSizeMake( 320, 800 );
    
    [tvList initWithStyle: UITableViewStylePlain];
    
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController: tvList];
    
    [popover setDelegate: self];
    
    tvList.popover = popover;
    
    // PDS: Maintain pointers to keep objects alive..
    g_tvList        = tvList;
    g_tvListPopover = popover;
    
    // PDS: Delegate my popover dismiss delegate to this TV..
    tvList.dismissDelegate = self;
  }
  
  [g_tvList setTitle: @"LIKE Behaviour"];
  
  g_tvList.pnSelectedRow = &g_LikeButtonBehaviour;
  g_tvList.nsTitle = @"Select LIKE Behaviour";
  
  g_vLikeBehaviours.removeAll();
  g_vLikeBehaviours.addElement( "Increment Rating" );
  g_vLikeBehaviours.addElement( "Add to Default Playlist" );
  
  g_tvList.pvSelectListItems = &g_vLikeBehaviours;
  
  // PDS: Ensure popover appears in the visible part of the table view..
  NSArray         *arrIndexPaths = [g_TableView indexPathsForVisibleRows];
  NSIndexPath     *indexPath     = [arrIndexPaths objectAtIndex: 0];
  UITableViewCell *cell          = [g_TableView cellForRowAtIndexPath: indexPath];
  
  CGRect rect = CGRectMake( cell.bounds.origin.x + 20, cell.bounds.origin.y + 10, 50, 30 );
  
  [g_tvListPopover presentPopoverFromRect:rect inView: cell permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

//-----------------------------------------------------------------------------------------
// UploadTunes
//-----------------------------------------------------------------------------------------
-(void) UploadTunes
{
  if( g_BackupRestoreView == nil )
    g_BackupRestoreView = [ [BackupRestoreVC alloc] initWithStyle: UITableViewStyleGrouped];
  
  g_BackupRestoreView.title = @"Backup & Restore";
  
  g_BackupRestoreView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  //[self presentModalViewController: backupRestoreView animated:YES];
  
  [g_navController pushViewController: g_BackupRestoreView animated:YES];
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch( [indexPath section] )
  {
    case SETTINGS_SECTION_PLAYLISTS:
    {
      if( [indexPath row] == SETTINGS_PLAYLISTS_MANAGE )
        [self ManagePlaylists];
      else
      if( [indexPath row] == SETTINGS_PLAYLISTS_DEFAULT )
        [self SetDefaultPlaylist];
      else
      if( [indexPath row] == SETTINGS_PLAYLISTS_LIKE )
        [self SetLikeBehaviour];
      
      break;
    }
      
    case SETTINGS_SECTION_HATES:
    {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
      cell.selected = FALSE;
      
      if( [indexPath row] == SETTINGS_START_FTP )
      {
        [self UploadTunes];
      }
      else
      if( [indexPath row] == SETTINGS_LIKES_TO_PLIST )
      {
        [self AddLikesToPlaylist];
      }
      else
      {
        [self ConfirmAction: [indexPath row ] ];
      }
      break;
    }
  }
  
}


@end
