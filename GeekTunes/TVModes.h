//
//  TVModes.h
//  GeekTunes
//
//  Created by Paul Spark on 30/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "DismissDelegate.h"
#import  "LikeHatePlayCell.h"

#include "vector.h"

extern int       g_DrillDownMode;

extern UIImage  *g_ImagePlay;
extern UIImage  *g_ImageLike;
extern UIImage  *g_ImageHate;
extern UIImage  *g_ImageHeartRed;
extern UIImage  *g_ImageHeartGreen;
extern UIImage  *g_ImageHeartGrey;
extern UIImage  *g_ImageClipboardPurple;
extern UIImage  *g_ImageClipboardGrey;
extern UIImage  *g_ImageMinusRed;

extern UIImage  *g_ImagePlayWhite;
extern UIImage  *g_ImageStop;

extern BOOL      g_RatingsChanged;
extern int       g_nSelectedTuneIndexInLib;
extern int       g_nSelectedArtistIndexInLib;
extern int       g_nSelectedAlbumIndexInLib;

// PDS: Common table view functions..
void ConfigureLikeHatePlayCell( LikeHatePlayCell *cell, int nTuneRating, int nTuneIndexInLib, SEL ratingButtonFn, SEL playlistButtonFn,
                                UITableViewController *pTableView );
void AdvancedAddToFavouritePlaylist( int nTuneIndexInLib );
void ratingButtonPressedCommon( int nTuneIndexInLib, UITableView *pTableView );
void playlistButtonPressedCommon( int nTuneIndexInLib, UITableView *pTableView );

void GetTunesForAlbum( int nAlbumIndex, Vector *pvAlbumTunes );
void GetTunesForArtist( int nArtistIndex, Vector *pvArtistTunes );
void RateAllTunes( Vector *pvTunes, int nRating );
int  GetAverageRatingForTunes( Vector *pvTunes );
BOOL AllTunesInFavourites( Vector *pvTunes );
void AddToFavouritePlaylist( void );
void RemoveFromPlaylist( int nTuneIndexInLib, int nPlayListIndex );

@interface TVModes : UITableViewController <DismissDelegate>
{
  id <DismissDelegate>      dismissDelegate;
}

-(void) dismissVC;
-(void) dismissAll;

@property (nonatomic, assign) id dismissDelegate;


@end
