//
//  TVAlbums.h
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DismissDelegate.h"

@interface TVAlbums : UITableViewController <UIPopoverControllerDelegate,DismissDelegate>
{
  int nArtistIndex;  
}

-(void) ratingButtonPressed:   (id) sender;
-(void) playlistButtonPressed: (id) sender;

@property (nonatomic) int nArtistIndex;

@end
