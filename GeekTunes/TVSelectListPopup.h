//
//  TVSelectListPopup.h
//  GeekTunes
//
//  Created by Admin on 19/07/13.
//
//

#import <UIKit/UIKit.h>
#import "DismissDelegate.h"
#import "TVWithHeader.h"

#include "vector.h"

//@interface TVSelectListPopup : UITableViewController
@interface TVSelectListPopup : TVWithHeader
{
  UIPopoverController *popover;

  __unsafe_unretained id <DismissDelegate>      dismissDelegate;
  
  int         *pnSelectedRow;
  Vector      *pvSelectListItems;
  
  NSString    *nsTitle;

}

-(void) reloadData;

@property (nonatomic, retain) UIPopoverController *popover;

@property (nonatomic, assign) __unsafe_unretained id dismissDelegate;

@property (nonatomic, assign) int *pnSelectedRow;
@property (nonatomic, assign) Vector    *pvSelectListItems;
@property (nonatomic, retain) NSString  *nsTitle;


@end
