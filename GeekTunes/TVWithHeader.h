//
//  TVWithHeader.h
//  GeekTunes
//
//  Created by Admin on 22/07/13.
//
//

#import <UIKit/UIKit.h>

@interface TVWithHeader : UITableViewController
{
  UITableView *m_TableView;
  UILabel     *pCustomHeaderTitle;
}

@property (nonatomic, retain) UILabel *pCustomHeaderTitle;
@property (nonatomic, retain) UITableView *m_TableView;

@end



