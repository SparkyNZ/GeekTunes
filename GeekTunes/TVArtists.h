//
//  TVArtists.h
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DismissDelegate.h"

@interface TVArtists : UITableViewController <UIPopoverControllerDelegate,DismissDelegate>

-(void) ratingButtonPressed:   (id) sender;
-(void) playlistButtonPressed: (id) sender;


@end
