//
//  TVFavouritePopup.m
//  GeekTunes
//
//  Created by Admin on 19/07/13.
//
//

#import "TVFavouritePopup.h"
#include "PaulPlayer.h"

#include "vector.h"
#include "Utils.h"
#include "Events.h"

@interface TVFavouritePopup ()

@end

@implementation TVFavouritePopup

@synthesize popover;
@synthesize dismissDelegate;
@synthesize fIncludeNoDefault;
@synthesize tag;

static UITableView *g_TableView   = nil;

static int          g_SelectedRow = -1;
extern int          g_PreferredFavouriteList;
extern int          g_NumFavouritePlaylists;
extern Vector       g_vFavouritePlaylistNames;

int                 g_PopOverTagEvent = evNO_EVENT;


- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];
  
  [self.pCustomHeaderTitle setText: @"Select Playlist"];
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
  
  if( fIncludeNoDefault )
    return 1 + g_NumFavouritePlaylists;
  
  return g_NumFavouritePlaylists;
}

//-----------------------------------------------------------------------------------------
// willDisplayCell
//-----------------------------------------------------------------------------------------
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if( [indexPath row] == g_SelectedRow )
  {
    [cell setHighlighted: YES];
  }
  else
    [cell setHighlighted: NO];
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
    
  NSString *nsText;
  BOOL      fSelected = FALSE;
  
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;

  cell.textLabel.backgroundColor = [UIColor clearColor];
  /*
  if( ( fIncludeNoDefault ) && ( [indexPath row] == 0 ) )
  {
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    nsText = @"** No Default **";
    
    if( ! g_DefaultPreferredFavouriteList )
      fSelected = TRUE;
  }
  else
  {
    char *pszName = g_vFavouritePlaylistNames.elementStrAt( [indexPath row ] - ( fIncludeNoDefault ) ? 1 : 0 );
    nsText        = [NSString stringWithUTF8String: pszName];
    
    // PDS: Only select other row if default preference is in place and no default is showing..
    if( ( g_DefaultPreferredFavouriteList ) && ( fIncludeNoDefault ) && ( [indexPath row] == g_PreferredFavouriteList ) )
      fSelected = TRUE;
  }
   */

  if( fIncludeNoDefault )
  {
    if( [indexPath row] == 0 )
    {
      cell.textLabel.textAlignment = UITextAlignmentCenter;
    
      nsText = @"** No Default **";
    
      if( ! g_DefaultPreferredFavouriteList )
        fSelected = TRUE;
    }
    else
    {
      char *pszName = g_vFavouritePlaylistNames.elementStrAt( [indexPath row ] -  1 );
      nsText        = [NSString stringWithUTF8String: pszName];
      
      // PDS: Only select other row if default preference is in place and no default is showing..
      if( ( g_DefaultPreferredFavouriteList ) && ( [indexPath row] == g_PreferredFavouriteList ) )
        fSelected = TRUE;
    }
  }
  else
  {
    char *pszName = g_vFavouritePlaylistNames.elementStrAt( [indexPath row ] );
    nsText        = [NSString stringWithUTF8String: pszName];
    
    // PDS: Only select other row if default preference is in place and no default is showing..
    if( ( g_DefaultPreferredFavouriteList )  && ( [indexPath row] == g_PreferredFavouriteList - 1 ) )
      fSelected = TRUE;
  }
  
  cell.textLabel.text = nsText;
  
  if( fSelected )
    g_SelectedRow = [indexPath row];
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if( fIncludeNoDefault )
  {
    // PDS: NO DEFAULT included - this means we are selecting a default play list!
    if( [indexPath row] == 0 )
    {
      // PDS: No default favourite (ie. choice will be required when adding to playlist..
      g_DefaultPreferredFavouriteList = FALSE;
    }
    else
    {
      // PDS: Enable default playlist..
      g_DefaultPreferredFavouriteList = TRUE;
      
      // PDS: Set favourite index..
      g_PreferredFavouriteList = [indexPath row] - 1 + MODE_FAVOURITES_1;
    }

    // PDS: Save the default favourite setting(s)..
    SaveSettings();
  }
  else
  {
    LogDebugf( "Only the fly playlist choice.." );
    
    // PDS: Set favourite index..
    g_PreferredFavouriteList = [indexPath row] + MODE_FAVOURITES_1;
  }
  
  g_SelectedRow = [indexPath row];
  
  if( g_TableView )
  {
    // PDS: Reload the current screen's cells.
    [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  }
  
  LogDebugf( "Preferred fav index now: %d  Default: %d", g_PreferredFavouriteList, g_DefaultPreferredFavouriteList );
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [dismissDelegate respondsToSelector: @selector( dismissPopover ) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [dismissDelegate dismissPopover];
  }
  
  [popover dismissPopoverAnimated:YES];
}

@end
