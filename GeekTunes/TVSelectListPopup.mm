//
//  TVSelectListPopup.m
//  GeekTunes
//
//  Created by Admin on 19/07/13.
//
//

#import "TVSelectListPopup.h"
#include "PaulPlayer.h"

#include "vector.h"
#include "Utils.h"

@interface TVSelectListPopup ()

@end

@implementation TVSelectListPopup

@synthesize popover;
@synthesize dismissDelegate;

@synthesize pnSelectedRow;
@synthesize pvSelectListItems;
@synthesize nsTitle;


static UITableView *g_TableView   = nil;


- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  
  if (self)
  {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear:animated];
  
  [self.pCustomHeaderTitle setText: nsTitle];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
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
  
  int nItems = pvSelectListItems->elementCount();
  
  LogDebugf( "PDS> nItems: %d", nItems );
  
  return nItems;
}

//-----------------------------------------------------------------------------------------
// reloadData
//-----------------------------------------------------------------------------------------
-(void) reloadData
{
  [g_TableView reloadData];
}


//-----------------------------------------------------------------------------------------
// willDisplayCell
//-----------------------------------------------------------------------------------------
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if( [indexPath row] == (*pnSelectedRow) )
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
  
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;

  cell.textLabel.backgroundColor = [UIColor clearColor];

  char *pszName = pvSelectListItems->elementStrAt( [indexPath row ] );
  nsText        = [NSString stringWithUTF8String: pszName];
  
  cell.textLabel.text = nsText;
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  (*pnSelectedRow) = [indexPath row];
  
  if( g_TableView )
  {
    // PDS: Reload the current screen's cells.
    [g_TableView reloadRowsAtIndexPaths:[g_TableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
  }
  
  LogDebugf( "Selected index now: %d", (*pnSelectedRow) );
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [dismissDelegate respondsToSelector: @selector( dismissPopover ) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [dismissDelegate dismissPopover];
  }
  
  [popover dismissPopoverAnimated:YES];
}

@end
