//
//  TVSettings.h
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "DismissDelegate.h"

@interface TVSettings : UITableViewController <UIAlertViewDelegate, DismissDelegate, UIPopoverControllerDelegate>
{
  UIBarButtonItem *doneButton;
  
  BOOL fDoneButtonPressed;
  BOOL fSettingsChanged;
  
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;

-(void) doneButtonPressed;

@end
