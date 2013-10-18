//
//  DismissDelegate.h
//  GeekTunes
//
//  Created by Admin on 10/07/13.
//
//

#ifndef GeekTunes_DismissDelegate_h
#define GeekTunes_DismissDelegate_h


//-----------------------------------------------------------------------------------------
// DismissDelegate
//-----------------------------------------------------------------------------------------
@protocol DismissDelegate <NSObject>
@optional

-(void) dismissAll;
-(void) dismissPopover;
-(void) reloadContent;

@end


#endif

