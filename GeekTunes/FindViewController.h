//
//  FindViewController.h
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#import <UIKit/UIKit.h>

#include "TuneSelectedDelegate.h"
#include "vector.h"

@interface FindViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TuneSelectedDelegate, UIPopoverControllerDelegate>
{
  UITableView    *autocompleteTableView;
  
  Vector *pvItems;
  Vector  vItems;
  Vector  vMatchedItems;
  Vector  vMatchedItemsIdx;
  int     nSelectedIndex;
  
  __unsafe_unretained id <TuneSelectedDelegate> tuneSelectedDelegate;
}

-(void) hideKeyboard;

@property (nonatomic, assign) __unsafe_unretained id tuneSelectedDelegate;
@property (nonatomic, retain) UITableView    *autocompleteTableView;
@property (nonatomic) Vector *pvItems;
@property (nonatomic) Vector  vItems;
@property (nonatomic) Vector  vMatchedItems;
@property (nonatomic) Vector  vMatchedItemsIdx;
@property (nonatomic) int     nSelectedIndex;

- (void) goPressed;
- (void) searchAutocompleteEntriesWithSubstring:(NSString *)substring;


@end
