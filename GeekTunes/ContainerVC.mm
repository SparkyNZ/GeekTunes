//
//  ContainerVC.m
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#include "AllIncludes.h"

// .....
@interface UIApplication (AppDimensions)

+(CGSize) currentSize;
+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation;

@end


@implementation UIApplication (AppDimensions)


//-----------------------------------------------------------------------------------------
// currentSize
//-----------------------------------------------------------------------------------------
+(CGSize) currentSize
{
  //NSLog( @"## StatusBar: %d", [UIApplication sharedApplication].statusBarOrientation );
  return [UIApplication sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

//-----------------------------------------------------------------------------------------
// sizeInOrientation
//-----------------------------------------------------------------------------------------
+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation
{
  CGSize size = [UIScreen mainScreen].bounds.size;
  
  UIApplication *application = [UIApplication sharedApplication];
  
  if( UIInterfaceOrientationIsLandscape( orientation ) )
  {
    //LogDebugf( "## LANDSCAPE" );
    size = CGSizeMake(size.height, size.width);
//    size = CGSizeMake(size.width, size.height);
  }
  else
  {
    //LogDebugf( "## PORTRAIT" );
  }
  
  if (application.statusBarHidden == NO)
    size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
  
  return size;
}


@end
// .....




@interface ContainerVC ()

@end

@implementation ContainerVC

#define MAX_PAGES 3


UIScrollView                   *g_ScrollView         = nil;
int                             g_NumScrollPages     = MAX_PAGES;
int                             g_ScrollPageWidth    = 0;
extern ViewController          *g_MainViewController;
extern FindViewController      *g_FindViewController;
extern EasyDrillViewController *g_EasyDrillViewController;
ContainerVC                    *g_ContainerVC = nil;

extern int      g_MaxPixelHeight;
extern int      g_MaxPixelWidth;


static BOOL g_Dragging = FALSE;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  g_Dragging = TRUE;
}

//-----------------------------------------------------------------------------------------
// scrollViewDidEndDragging
//-----------------------------------------------------------------------------------------
-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL) decelerate
{
  g_Dragging = FALSE;
}

//-----------------------------------------------------------------------------------------
// scrollViewDidScroll
//-----------------------------------------------------------------------------------------
-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
  static NSInteger previousPage = -1;
  
  if( g_Dragging )
    return;
  
  CGFloat pageWidth = g_ScrollView.frame.size.width;
  float fractionalPage = g_ScrollView.contentOffset.x / pageWidth;
  
  NSInteger page = lround(fractionalPage);
  
  if (previousPage != page)
  {
    LogDebugf( "Page: %d", page );
  
    if( page == 2 )
    {
      // PDS: Clear text input
      [g_EasyDrillViewController reset];
      g_EasyDrillViewController.nSelectStep  = SELECT_ARTIST;
      g_EasyDrillViewController.nArtistIndex = -1;
    }
    
    if( page == 0 )
    {
      // PDS: Reload find screen vectors..

    }
    else
    {
      // PDS: Close keyboard if going from find page to any other..
      if( previousPage == 0 )
        [g_FindViewController hideKeyboard];
    }
    
    // Page has changed
    // Do your thing!
    previousPage = page;
  }
}

//-----------------------------------------------------------------------------------------
// addMyContent
//-----------------------------------------------------------------------------------------
-(void) addMyContent
{
  //g_ScrollView = nil;
  
  if( g_FindViewController      == nil ) g_FindViewController      = [ [FindViewController      alloc] init];
  if( g_MainViewController      == nil ) g_MainViewController      = [ [ViewController          alloc] init];
  if( g_EasyDrillViewController == nil ) g_EasyDrillViewController = [ [EasyDrillViewController alloc] init];
  
  int nStatusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
  
  // PDS: Scrollview window is the same size as the screen..
  int nScrollViewWidth  = self.view.bounds.size.width; //self.view.frame.size.width;
  int nScrollViewHeight = self.view.bounds.size.height; //self.view.frame.size.height;
  
  if( [UIApplication sharedApplication].statusBarHidden == NO )
    nScrollViewHeight -= nStatusBarHeight;
  
  LogDebugf( "### Frame %3d x %3d ###", nScrollViewWidth, nScrollViewHeight );
  
  g_ScrollPageWidth = nScrollViewWidth;
  
  // PDS: Below we make the scroll view ("window" on the bigger picture) the same size as the full screen.
  if( g_ScrollView == nil )
    g_ScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake( 0,
                                                                    nStatusBarHeight,
                                                                    nScrollViewWidth,
                                                                    nScrollViewHeight )];
  g_ScrollView.pagingEnabled = YES;
  g_ScrollView.directionalLockEnabled = YES;
  g_ScrollView.bounces = NO;
  
  g_ScrollView.contentSize   = CGSizeMake( nScrollViewWidth * g_NumScrollPages, nScrollViewHeight );
  
  // PDS: Always scroll onto main (2nd) page..
  g_ScrollView.contentOffset = CGPointMake( nScrollViewWidth, 0 );
  
  int nViewWidth  = self.view.frame.size.width;
  int nViewHeight = nScrollViewHeight;
  
  int xViewOffset[ MAX_PAGES ];
  int yViewOffset[ MAX_PAGES ];
  
  for( int p = 0; p < MAX_PAGES; p ++ )
  {
    xViewOffset[ p ] = ( p * nViewWidth );
    yViewOffset[ p ] = 0;
  }
  
  g_FindViewController.view.frame = CGRectMake( xViewOffset[ 0 ], yViewOffset[ 0 ], nViewWidth, nViewHeight );
  g_FindViewController.view.backgroundColor = [UIColor  blackColor];
  
  g_MainViewController.view.frame = CGRectMake( xViewOffset[ 1 ], yViewOffset[ 1 ], nViewWidth, nViewHeight );
  g_MainViewController.view.backgroundColor = [UIColor  blackColor];
  
  g_EasyDrillViewController.view.frame = CGRectMake( xViewOffset[ 2 ], yViewOffset[ 2 ], nViewWidth, nViewHeight );
  g_EasyDrillViewController.view.backgroundColor = [UIColor  blackColor];
  
  [g_ScrollView addSubview: g_FindViewController.view];
  [g_ScrollView addSubview: g_MainViewController.view];
  [g_ScrollView addSubview: g_EasyDrillViewController.view];
  
  g_FindViewController.pvItems = &g_vTunesName;
  
  g_ScrollView.delegate = self;
  
  [self.view addSubview: g_ScrollView];

}

//-----------------------------------------------------------------------------------------
// loadView
//-----------------------------------------------------------------------------------------
-(void) loadView
{
//  LogDebugf( "### loadView %3d x %3d ###", g_MaxPixelWidth, g_MaxPixelHeight );
  
  // PDS> Stack overflow says don't call this but I get errors if I don't!!
  [super loadView];

  [self addMyContent];
}


//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  LogDebugf( "** VIEW DID LOAD" );
  
  [super viewDidLoad];
  
  g_ContainerVC = self;

//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( didRotate: ) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

//-----------------------------------------------------------------------------------------
// remoteControlReceivedWithEvent
//-----------------------------------------------------------------------------------------
-(void) remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
  if (receivedEvent.type == UIEventTypeRemoteControl)
  {
    LogDebugf( "PDS> REMOTE EVENT" );
    [g_MainViewController remoteControlReceivedWithEvent: receivedEvent];
  }
}

//-----------------------------------------------------------------------------------------
// canBecomeFirstResponder
//-----------------------------------------------------------------------------------------
- (BOOL)canBecomeFirstResponder
{
  return YES;
}

//-----------------------------------------------------------------------------------------
// viewDidAppear
//-----------------------------------------------------------------------------------------
-(void) viewDidAppear:(BOOL)animated
{
  LogDebugf( "** VIEW DID APPEAR" );  
  
  [super viewDidAppear:animated];
  
  // Turn on remote control event delivery
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
  
  // Set itself as the first responder
  [self becomeFirstResponder];
}

//-----------------------------------------------------------------------------------------
// viewWillDisappear
//-----------------------------------------------------------------------------------------
-(void) viewWillDisappear:(BOOL)animated
{
  // Turn off remote control event delivery
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  
  // Resign as first responder
  [self resignFirstResponder];
  
	[super viewWillDisappear:animated];
}

//-----------------------------------------------------------------------------------------
// scrollToPage
//-----------------------------------------------------------------------------------------
-(void) scrollToPage: (int) nPage
{
  [g_ScrollView setContentOffset: CGPointMake( g_ScrollPageWidth * nPage, 0 ) animated:YES];
}


//-----------------------------------------------------------------------------------------
// viewWillAppear
//-----------------------------------------------------------------------------------------
-(void) viewWillAppear: (BOOL) animated
{
//  [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector( orientationChanged: )  name:UIDeviceOrientationDidChangeNotification  object:nil];
}

//-----------------------------------------------------------------------------------------
// viewDidDisappear
//-----------------------------------------------------------------------------------------
-(void) viewDidDisappear:(BOOL) animated
{
//  [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
/*
//-----------------------------------------------------------------------------------------
// didRotateFromInterfaceOrientation
//-----------------------------------------------------------------------------------------
-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  LogDebugf( "didRotate" );
  [super didRotateFromInterfaceOrientation: interfaceOrientation];
}
*/
/*
//-----------------------------------------------------------------------------------------
// willAutorotateToInterfaceOrientation
//-----------------------------------------------------------------------------------------
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation: orientation duration: duration];
  
  CGSize screenSize = [UIApplication currentSize];
  
  LogDebugf( "ScreenSize: %d x %d", (int) screenSize.width, (int) screenSize.height );

}
 */

//-----------------------------------------------------------------------------------------
// adjustViewsForOrientation
//-----------------------------------------------------------------------------------------
-(void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation
{
}

/*
//-----------------------------------------------------------------------------------------
// orientationChanged
//-----------------------------------------------------------------------------------------
-(void) orientationChanged: (NSNotification *) notification
{
  CGSize screenSize = [UIApplication currentSize];
  
  LogDebugf( "** orientationChanged ** ScreenSize: %d x %d", (int) screenSize.width, (int) screenSize.height );

  g_MaxPixelWidth  = screenSize.width;
  g_MaxPixelHeight = screenSize.height;
 
  return;
  
//  [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}
*/

/*
//-----------------------------------------------------------------------------------------
// didRotate
//-----------------------------------------------------------------------------------------
-(void) didRotate: (id) sender
{
  UIDeviceOrientation    orientation       = [[UIDevice currentDevice] orientation];
  UIInterfaceOrientation cachedOrientation = [self interfaceOrientation];
  
  if( orientation == UIDeviceOrientationUnknown ||
      orientation == UIDeviceOrientationFaceUp  ||
      orientation == UIDeviceOrientationFaceDown )
  {
    orientation = (UIDeviceOrientation)cachedOrientation;
  }

  if( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight )
  {
    if( orientation == UIDeviceOrientationLandscapeLeft )
      [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeLeft;
    else
    if( orientation == UIDeviceOrientationLandscapeRight )
      [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;

    CGSize screenSize = [UIApplication currentSize];
    
    g_MaxPixelWidth  = screenSize.width;
    g_MaxPixelHeight = screenSize.height;

    LogDebugf( "** LANDSCAPE: %d x %d", g_MaxPixelWidth, g_MaxPixelHeight );
  }
    
  if( orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown )
  {
    if( orientation == UIDeviceOrientationPortrait )
      [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationPortrait;
    else
    if( orientation == UIDeviceOrientationPortraitUpsideDown )
      [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationPortraitUpsideDown;

    CGSize screenSize = [UIApplication currentSize];
    
    g_MaxPixelWidth  = screenSize.width;
    g_MaxPixelHeight = screenSize.height;
    
    LogDebugf( "** PORTRAIT: %d x %d", g_MaxPixelWidth, g_MaxPixelHeight  );
  }
  
  for (UIView *view in self.view.subviews)
  {
    //    if ([view isKindOfClass:[Sprite class]])
    [view removeFromSuperview];
  }

  //[self addMyContent];
 // [self.view setAutoresizesSubviews: YES];
//shit - not adding items at correct place
  //[self loadView];

}
*/

//-----------------------------------------------------------------------------------------
// layoutSubviews
//-----------------------------------------------------------------------------------------
-(void) layoutSubviews
{
  LogDebugf( "- layoutSubviews" );
}

//-----------------------------------------------------------------------------------------
// viewWillLayoutSubviews
//-----------------------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  /*
  LogDebugf( "- viewWillLayoutSubviews" );
  
  // PDS: Scrollview window is the same size as the screen..
  int nScrollViewWidth  = self.view.bounds.size.width; //self.view.frame.size.width;
  int nScrollViewHeight = self.view.bounds.size.height; //self.view.frame.size.height;
  
  LogDebugf( "### BOUNDS %3d x %3d ###", nScrollViewWidth, nScrollViewHeight );
  
  [self addMyContent];
   */
}

/*
// -------------------------------------------------------------------------------
//	supportedInterfaceOrientations
//  Support either landscape orientation (iOS 6).
// -------------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation
//  Support either landscape orientation (IOS 5 and below).
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//  return UIInterfaceOrientationIsLandscape(interfaceOrientation);
  return YES;
}
*/

@end
