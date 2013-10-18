//
//  FindViewController.m
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#import "FindViewController.h"
#import "ViewController.h"
#import "ContainerVC.h"
#import "TVFavouritePopup.h"

#import "GlossyButton.h"
#import "UITextFieldInset.h"
#import "LikeHatePlayCell.h"

#include "TVModes.h"
#include "PaulPlayer.h"
#include "Events.h"
#include "Utils.h"
#include "CommonVectors.h"

@interface FindViewController ()

@end

@implementation FindViewController

@synthesize autocompleteTableView;
@synthesize pvItems;
@synthesize vItems;
@synthesize vMatchedItems;
@synthesize vMatchedItemsIdx;
@synthesize nSelectedIndex;

@synthesize tuneSelectedDelegate;

FindViewController     *g_FindViewController = nil;
UITextFieldInset       *g_SearchTextField    = nil;

extern float g_ButInset;
extern ViewController *g_MainViewController;
extern ContainerVC    *g_ContainerVC;


static UITableView    *g_TableView = nil;

//-----------------------------------------------------------------------------------------
// addButton
//-----------------------------------------------------------------------------------------
-(UIButton *) addButton: (NSString *) nsText subTitle: (NSString *) nsSubtitle atX: (float) x atY: (float) y
                  width: (float) w height: (float) h
               selector: (SEL) fn
             bgndColour: (UIColor*) bgndColour
               subLabel: (UILabel **) pSubLabel
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake( x+g_ButInset, y+g_ButInset, w-(g_ButInset*2), h-(g_ButInset*2) );
  
	// Configure background image(s)
	[button setBackgroundToGlossyRectOfColor: bgndColour              withBorder: YES forState: UIControlStateNormal];
	[button setBackgroundToGlossyRectOfColor:[UIColor blackColor ] withBorder: YES forState:UIControlStateHighlighted];
  
  // PDS: Add subtitle..
  UILabel *subtitle = [[UILabel alloc]initWithFrame:CGRectMake(8, 40, w-20, h-20)];
  [subtitle setBackgroundColor:[UIColor clearColor]];
	[subtitle setFont:[UIFont boldSystemFontOfSize:24]];
  subtitle.text = nsSubtitle;
  subtitle.textAlignment = UITextAlignmentCenter;
  
  [subtitle setTextColor:[UIColor yellowColor]];
  [button   addSubview:subtitle];
  
	// Configure title(s)
  button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
  button.titleLabel.textAlignment = UITextAlignmentCenter;
  
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor colorWithRed:.25 green:.25 blue:.25 alpha:1] forState:UIControlStateNormal];
	[button setTitleShadowOffset:CGSizeMake(0, -1)];
	[button setFont:[UIFont boldSystemFontOfSize:20]];
  
  [button addTarget:self
             action: fn
   forControlEvents:UIControlEventTouchUpInside];
  [button setTitle: nsText forState:UIControlStateNormal];
  
  //[pView addSubview:button];
  
  return button;
}

//-----------------------------------------------------------------------------------------
// hideKeyboard
//-----------------------------------------------------------------------------------------
-(void) hideKeyboard
{
  [g_SearchTextField resignFirstResponder];
}

//-----------------------------------------------------------------------------------------
// goPressed
//-----------------------------------------------------------------------------------------
-(void) goPressed
{
  // Clean up UI
  [self hideKeyboard];
  
  autocompleteTableView.hidden = YES;
  
  LogDebugf( "PDS>[%s]", [g_SearchTextField.text UTF8String] );
  
  // Push the wev view controller onto the stack
  //  [self.navigationController pushViewController:self.webViewController animated:YES];
}

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  [super viewDidLoad];

  // PDS: Main view controller is what will kick off playing of tunes..
  tuneSelectedDelegate = g_MainViewController;
  
  // PDS: Point to internal vector (pointer can be later reassigned).
  pvItems = &vItems;

  int nTextBoxWidth    = self.view.frame.size.width;
  int nTextBoxHeight   = 60;
  int nTextBoxInset    = 5;
  /*
  int nButtonHeight    = 30;
  int nButtonWidth     = 60;
   */
  int nTableViewWidth  = self.view.frame.size.width;
  int nYTableView      = nTextBoxHeight + nTextBoxInset;
  int nTableViewHeight = self.view.frame.size.height - nYTableView;
  
  if( g_SearchTextField == nil )
    g_SearchTextField = [[UITextFieldInset alloc] initWithFrame: CGRectMake( 0, 0,
                                                                        nTextBoxWidth,
                                                                        nTextBoxHeight ) ];
  
  /* PDS> Why do I need a FIND button??
  g_SearchTextField.rightViewMode = UITextFieldViewModeAlways;
  
  g_SearchTextField.rightView = [self addButton: @"FIND"
         subTitle: @""
              atX: nTextBoxWidth - nButtonWidth - nTextBoxInset
              atY: nTextBoxInset * 2
            width: nButtonWidth
           height: nButtonHeight
         selector: @selector( goPressed )
       bgndColour: [UIColor colorWithRed: 0.6 green: 0.6 blue: 0.0 alpha: 1.0]
         subLabel: nil];
   
   g_SearchTextField.nRightSpace = nButtonWidth + 10;
  */
  g_SearchTextField.nInset      = 10;
  
  g_SearchTextField.placeholder = @"Enter Search Keywords";
  
  g_SearchTextField.autocorrectionType        = UITextAutocorrectionTypeNo ;
  g_SearchTextField.autocapitalizationType    = UITextAutocapitalizationTypeNone;
  g_SearchTextField.adjustsFontSizeToFitWidth = YES;
  g_SearchTextField.textColor       = [UIColor colorWithRed: 1.0 green: 1.0 blue: 1.0 alpha:1.0 ];
  g_SearchTextField.backgroundColor = [UIColor colorWithRed: 0.2 green: 0.2 blue: 0.2 alpha:1.0 ];
  
  g_SearchTextField.borderStyle = UITextBorderStyleRoundedRect;
  
  g_SearchTextField.textInputView.frame = CGRectMake( nTextBoxInset,
                                                      nTextBoxInset,
                                                      nTextBoxWidth  - ( 2 * nTextBoxInset),
                                                      nTextBoxHeight - ( 2 * nTextBoxInset ) );
  
  g_SearchTextField.font     = [UIFont boldSystemFontOfSize:22];
  g_SearchTextField.text     = @"";
  g_SearchTextField.hidden   = FALSE;
  g_SearchTextField.delegate = self;
  
  [self.view addSubview: g_SearchTextField];
  
  autocompleteTableView = [[UITableView alloc] initWithFrame:CGRectMake( 0, nYTableView, nTableViewWidth, nTableViewHeight ) style:UITableViewStylePlain];
  autocompleteTableView.delegate      = self;
  autocompleteTableView.dataSource    = self;
  autocompleteTableView.scrollEnabled = YES;
  autocompleteTableView.hidden        = NO;
  
  [self.view addSubview: autocompleteTableView];
}

//-----------------------------------------------------------------------------------------
// searchAutocompleteEntriesWithSubstring
//-----------------------------------------------------------------------------------------
-(void) searchAutocompleteEntriesWithSubstring: (NSString *) substring
{
  vMatchedItems.removeAll();
  vMatchedItemsIdx.removeAll();

  char  *pItem;
  char  *pSubStr = (char *) [substring UTF8String];
  
  Vector vSubStrings;
  int    nWords;
  
  nWords = ParseWordsIntoVector( pSubStr, &vSubStrings );
 
  if( nWords > 0 )
  {
    for( int i = 0; i < pvItems->elementCount(); i ++ )
    {
      pItem = pvItems->elementStrAt( i );
      
      // PDS: Match text starting with..
      //    if( SubStrMatchAnyCase( pItem, pSubStr ) )
      if( SubStrMatchAnyCaseMultiple( pItem, &vSubStrings ) )
      {
        vMatchedItems.addElement( pItem );
        vMatchedItemsIdx.addElement( i );
      }
    }
  }
  
  // PDS: Update tableview with latest matches..
  [autocompleteTableView reloadData];
}

#pragma mark UITextFieldDelegate methods

//-----------------------------------------------------------------------------------------
// shouldChangeCharactersInRange
//-----------------------------------------------------------------------------------------
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  autocompleteTableView.hidden = NO;
  
  NSString *substring = [NSString stringWithString: textField.text];
  substring = [substring stringByReplacingCharactersInRange:range withString:string];
  
  [self searchAutocompleteEntriesWithSubstring:substring];
  return YES;
}
 
#pragma mark UITableViewDataSource methods
 
//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
  g_TableView = tableView;
  return vMatchedItems.elementCount();
}

/* PDS> OLD, WORKING..
//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = nil;
  static NSString *AutoCompleteRowIdentifier = @"AutoCompleteRowIdentifier";
  cell = [tableView dequeueReusableCellWithIdentifier:AutoCompleteRowIdentifier];
  
  if( cell == nil )
  {
    cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutoCompleteRowIdentifier];
  }
  
  cell.textLabel.text = [NSString stringWithUTF8String: vMatchedItems.elementStrAt( indexPath.row ) ];
  cell.tag            = vMatchedItemsIdx.elementIntAt( indexPath.row );
  
  return cell;
}
*/

//-----------------------------------------------------------------------------------------
// ConfigureLikeHatePlayCell()
//-----------------------------------------------------------------------------------------
void ConfigureLikeHatePlayCell( LikeHatePlayCell   *cell,
                                int                 nTuneRating,
                                int                 nTuneIndexInLib,
                                SEL                 ratingButtonFn,
                                SEL                 playlistButtonFn,
                                FindViewController *pFindVC )
{
  cell.textLabel.backgroundColor   = [UIColor clearColor];
  cell.contentView.backgroundColor = [UIColor clearColor];
  
  // PDS: Set this so I can toggle the rating for the required tune..
  cell.ratingButton.tag   = nTuneIndexInLib;
  cell.playlistButton.tag = nTuneIndexInLib;
  
  [cell.ratingButton   addTarget: pFindVC action: ratingButtonFn   forControlEvents: UIControlEventTouchUpInside];
  
  if( playlistButtonFn != nil )
    [cell.playlistButton addTarget: pFindVC action: playlistButtonFn forControlEvents: UIControlEventTouchUpInside];
  
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
  
  TVFavouritePopup *tvFavs = [[TVFavouritePopup alloc] initWithStyle: UITableViewStylePlain];
  
  [tvFavs setTitle: @"Playlists"];
  
  tvFavs.contentSizeForViewInPopover = CGSizeMake( 320, 800 );
  
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
// AddToFavouritePlaylist
//
// PDS: g_PreferredFavouriteList has been either set manually or chosen from popover list
//      ..so now we apply the favourite addition and update the table view
//-----------------------------------------------------------------------------------------
void AddToFavouritePlaylist_FVC( void )
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
    
    AddToFavouritePlaylist_FVC();
  }
}

//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString        *CellIdentifier;
  int              nSection = [indexPath section];
  
  char txID[ 20 ];
  
  sprintf( txID, "%02d%06d", nSection, [indexPath row] );
  
  CellIdentifier = [NSString stringWithUTF8String: txID];

  LikeHatePlayCell *cell = (LikeHatePlayCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if( cell == nil )
    cell = [[LikeHatePlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

  int   nTuneIndexInLib = vMatchedItemsIdx.elementIntAt( indexPath.row );
  int   nTuneRating     = g_vTunesRating.elementIntAt( nTuneIndexInLib );
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.textLabel.text = [NSString stringWithUTF8String: vMatchedItems.elementStrAt( indexPath.row ) ];
  cell.tag            = nTuneIndexInLib;
  
  // PDS: Set various button states.
  ConfigureLikeHatePlayCell( cell, nTuneRating, nTuneIndexInLib, @selector( ratingButtonPressed: ), @selector( playlistButtonPressed: ), self );
  
  [cell.playButton setBackgroundImage: nil forState: UIControlStateNormal];
  
  return cell;
}



#pragma mark UITableViewDelegate methods

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  nSelectedIndex = vMatchedItemsIdx.elementIntAt( [indexPath row] );

  g_SearchTextField.text = [NSString stringWithUTF8String: vMatchedItems.elementStrAt( indexPath.row ) ];
  
  [self hideKeyboard];
  
  autocompleteTableView.hidden = YES;
  
  LogDebugf( "PDS>[%s]", [g_SearchTextField.text UTF8String] );
  
  // PDS: Check that something has registered to listen for the delegate..
  if( [tuneSelectedDelegate respondsToSelector: @selector( tuneSelected: ) ] )
  {
    // PDS: Call the activityDeleted delegate method on the parent..
    [tuneSelectedDelegate tuneSelected: nSelectedIndex];
    
    [g_ContainerVC scrollToPage: 1 ];
  }
}


@end
