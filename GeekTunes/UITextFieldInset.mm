//
//  UITextFieldInset.m
//  GeekTunes
//
//  Created by Admin on 17/09/13.
//
//

#import "UITextFieldInset.h"

@implementation UITextFieldInset

@synthesize nInset;
@synthesize nRightSpace;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
//  return CGRectInset( bounds, nInset, nInset );
  return CGRectMake( nInset, nInset, self.frame.size.width - nRightSpace - nInset , self.frame.size.height );
}

-(CGRect)editingRectForBounds:(CGRect)bounds
{
//  return CGRectInset( bounds, nInset, nInset );
  return CGRectMake( nInset, nInset, self.frame.size.width - nRightSpace - nInset, self.frame.size.height );
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
