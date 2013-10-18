//
//  LikeHatePlayCell.h
//  GeekTunes
//
//  Created by Admin on 14/07/13.
//
//

#import <UIKit/UIKit.h>

@interface LikeHatePlayCell : UITableViewCell
{
  UIButton *playlistButton;
  UIButton *ratingButton;
  UIButton *playButton;
  UIButton *removeButton;
  
  BOOL fDeleted;
  BOOL fRemoveButton;
  int  nTuneIndexInLib;
}

@property (nonatomic) int  nTuneIndexInLib;
@property (nonatomic) BOOL fDeleted;
@property (nonatomic) BOOL fRemoveButton;

@property(nonatomic, retain) IBOutlet UIButton *ratingButton;
@property(nonatomic, retain) IBOutlet UIButton *playButton;
@property(nonatomic, retain) IBOutlet UIButton *playlistButton;
@property(nonatomic, retain) IBOutlet UIButton *removeButton;

@end

