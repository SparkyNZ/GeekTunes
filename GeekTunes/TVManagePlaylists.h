//
//  TVManagePlaylists.h
//  GeekTunes
//
//  Created by Admin on 22/07/13.
//
//

#import <UIKit/UIKit.h>

extern UIImage  *g_ImageDice;
extern UIImage  *g_ImagePencil;
extern UIImage  *g_ImageRecycle;
extern UIImage  *g_ImageTrashcan;


@interface TVManagePlaylists : UITableViewController <UIAlertViewDelegate>
{
  UIButton *buttonShuffle;
  UIButton *buttonRename;
  UIButton *buttonRecycle;
  UIButton *buttonDelete;

  //__unsafe_unretained id <DismissDelegate>      dismissDelegate;
  
}

@property (nonatomic, retain) UIButton *buttonShuffle;
@property (nonatomic, retain) UIButton *buttonRename;
@property (nonatomic, retain) UIButton *buttonRecycle;
@property (nonatomic, retain) UIButton *buttonDelete;

//@property (nonatomic, assign) __unsafe_unretained id <DismissDelegate>      dismissDelegate;


-(void) addPlaylist;
-(void) assignButtonTargets: (UIViewController *) parentVC;

@end
