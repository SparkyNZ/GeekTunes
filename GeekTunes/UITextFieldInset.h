//
//  UITextFieldInset.h
//  GeekTunes
//
//  Created by Admin on 17/09/13.
//
//

#import <UIKit/UIKit.h>

@interface UITextFieldInset : UITextField
{
  int nInset;
  int nRightSpace;
}

@property (nonatomic) int nInset;
@property (nonatomic) int nRightSpace;

@end

