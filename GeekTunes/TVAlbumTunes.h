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

@interface TVAlbumTunes : UITableViewController <TuneSelectedDelegate, DismissDelegate, UIPopoverControllerDelegate>
{
  __unsafe_unretained id <TuneSelectedDelegate> tuneSelectedDelegate;
  __unsafe_unretained id <DismissDelegate>      dismissDelegate;

  int nAlbumIndex;
  
}

-(void) ratingButtonPressed:   (id) sender;
-(void) playlistButtonPressed: (id) sender;
-(void) doneButtonTapped;

@property (nonatomic) int nAlbumIndex;
@property (nonatomic, assign) __unsafe_unretained id tuneSelectedDelegate;
@property (nonatomic, assign) __unsafe_unretained id dismissDelegate;

@end


