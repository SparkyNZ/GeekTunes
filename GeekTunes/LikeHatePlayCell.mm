//
//  LikeHatePlayCell.m
//  GeekTunes
//
//  Created by Admin on 14/07/13.
//
//

#import "LikeHatePlayCell.h"
#import "TVModes.h"

@implementation LikeHatePlayCell

@synthesize playlistButton;
@synthesize ratingButton;
@synthesize playButton;
@synthesize removeButton;

@synthesize nTuneIndexInLib;
@synthesize fDeleted;
@synthesize fRemoveButton;

       int g_CellHeight = 44;
static int g_IconYInset = 0;

#define ICON_HEIGHT 30
#define ICON_WIDTH  30

//-----------------------------------------------------------------------------------------
// initWithStyle
//-----------------------------------------------------------------------------------------
-(id) initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  
  if (self)
  {
    // Initialization code
    ratingButton   = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton     = [UIButton buttonWithType:UIButtonTypeCustom];
    playlistButton = [UIButton buttonWithType:UIButtonTypeCustom];
    removeButton   = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if( ! g_IconYInset )
    {
      g_CellHeight = self.frame.size.height;
      
      //LogDebugf( "CellHeight: %f", self.frame.size.height );
      
      g_IconYInset = ( g_CellHeight - ICON_HEIGHT ) / 2;
    }
    
    playlistButton.frame = CGRectMake( 200, g_IconYInset, ICON_WIDTH, ICON_HEIGHT );
    ratingButton.frame   = CGRectMake( 240, g_IconYInset, ICON_WIDTH, ICON_HEIGHT );
    playButton.frame     = CGRectMake( 280, g_IconYInset, ICON_WIDTH, ICON_HEIGHT );
    
    // PDS: Put remove button in same place as rating.. like/hate/remove should be mutualy exclusive. ie. if a tune
    //      is in a favourite playlist, its unlikely that is would be hated!
    removeButton.frame   = CGRectMake( 240, g_IconYInset, ICON_WIDTH, ICON_HEIGHT );
    
    [self.contentView addSubview: playlistButton];
    
    if( fRemoveButton )
      [self.contentView addSubview: removeButton];
    else
      [self.contentView addSubview: ratingButton];

    [self.contentView addSubview: playButton];

    [playlistButton setBackgroundColor:[UIColor clearColor]];
    [ratingButton   setBackgroundColor:[UIColor clearColor]];
    [playButton     setBackgroundColor:[UIColor clearColor]];
    [removeButton   setBackgroundColor:[UIColor clearColor]];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    nTuneIndexInLib = -1;
    fDeleted        = FALSE;
  }
  return self;
}


//-----------------------------------------------------------------------------------------
// initWithFrame
//-----------------------------------------------------------------------------------------
-(id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString*)reuseIdentifier
{
  if( self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier] )
  {
  }
  return self;
}

//-----------------------------------------------------------------------------------------
// setSelected
//-----------------------------------------------------------------------------------------
-(void) setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  
  // configure for selected
}

- (void)dealloc
{
  // PDS: Don't need to release buttons as they were never allocated as such..
  // [ratingButton release];
  // [playButton release];
}

@end


