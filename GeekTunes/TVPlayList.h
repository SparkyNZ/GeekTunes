//
//  TVPlayList.h
//  GeekTunes
//
//  Created by Paul Spark on 2/07/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "TuneSelectedDelegate.h"
#include "DismissDelegate.h"

@interface TVPlayList : UITableViewController <TuneSelectedDelegate, DismissDelegate, UIPopoverControllerDelegate>
{
  __unsafe_unretained id <TuneSelectedDelegate> tuneSelectedDelegate;
  __unsafe_unretained id <DismissDelegate>      dismissDelegate;
  
  int  nPlayListIndex;
  BOOL fHates;
}

-(void) ratingButtonPressed:   (id) sender;
-(void) playlistButtonPressed: (id) sender;
-(void) removeButtonPressed:   (id) sender;

-(void) doneButtonTapped;

@property (nonatomic, assign) __unsafe_unretained id tuneSelectedDelegate;
@property (nonatomic, assign) __unsafe_unretained id dismissDelegate;
@property (nonatomic) int  nPlayListIndex;
@property (nonatomic) BOOL fHates;

@end
