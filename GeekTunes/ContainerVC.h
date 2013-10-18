//
//  ContainerVC.h
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#import <UIKit/UIKit.h>

@interface ContainerVC : UINavigationController /*UIViewController*/ <UIScrollViewDelegate>

-(void) scrollToPage: (int) nPage;

@end
