//
//  TVFavouritePopup.h
//  GeekTunes
//
//  Created by Admin on 19/07/13.
//
//

#import <UIKit/UIKit.h>
#import "DismissDelegate.h"
#import "TVWithHeader.h"

//@interface TVFavouritePopup : UITableViewController
@interface TVFavouritePopup : TVWithHeader
{
  UIPopoverController *popover;

  __unsafe_unretained id <DismissDelegate>      dismissDelegate;
  
  BOOL fIncludeNoDefault;
  int tag;
}

@property (nonatomic, retain) UIPopoverController *popover;

@property (nonatomic, assign) __unsafe_unretained id dismissDelegate;
@property (nonatomic, assign) BOOL fIncludeNoDefault;
@property (nonatomic, assign) int  tag;

@end
