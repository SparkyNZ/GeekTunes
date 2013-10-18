//
//  TVTunes.h
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "TuneSelectedDelegate.h"
#include "DismissDelegate.h"


@interface TVTunes : UITableViewController <TuneSelectedDelegate, DismissDelegate, UIPopoverControllerDelegate>
{
  __unsafe_unretained id <TuneSelectedDelegate> tuneSelectedDelegate;
  __unsafe_unretained id <DismissDelegate>      dismissDelegate;
  
  int nArtistIndex;
}

-(void) ratingButtonPressed:   (id) sender;
-(void) playlistButtonPressed: (id) sender;
-(void) doneButtonTapped;

-(void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;

@property (nonatomic) int nArtistIndex;
@property (nonatomic, assign) __unsafe_unretained id dismissDelegate;
@property (nonatomic, assign) __unsafe_unretained id tuneSelectedDelegate;

@end




