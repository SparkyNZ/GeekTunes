//
//  EasyDrillViewController.h
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#import <UIKit/UIKit.h>
#import "TuneSelectedDelegate.h"
#include "vector.h"

enum
{
  SELECT_ARTIST = 0,
  SELECT_ALBUM_FOR_ARTIST,
  SELECT_ALBUM,
  SELECT_TUNE
};

enum
{
  CATEGORY_ARTIST = 0,
  CATEGORY_ALBUM,
  CATEGORY_TUNE
};


@interface EasyDrillViewController : UIViewController <UIScrollViewDelegate, TuneSelectedDelegate>
{
  Vector *pvStringItems;

  Vector  vItems;
  Vector  vMatchedItems;
  Vector  vMatchedItemsIdx;
  int     nSelectedIndex;
  
  int     nArtistIndex;
  int     nAlbumIndex;
  int     nTuneIndex;
  
  int     nSelectStep;  
}

@property (nonatomic, assign) __unsafe_unretained id tuneSelectedDelegate;
@property (nonatomic) Vector *pvStringItems;

@property (nonatomic) Vector  vItems;
@property (nonatomic) Vector  vMatchedItems;
@property (nonatomic) Vector  vMatchedItemsIdx;
@property (nonatomic) int     nSelectedIndex;
@property (nonatomic) int     nSelectStep;
@property (nonatomic) int     nArtistIndex;
@property (nonatomic) int     nAlbumIndex;
@property (nonatomic) int     nTuneIndex;

-(void) reset;
-(void) searchAutocompleteEntriesWithSubstring: (char *) pSubStr;

@end
