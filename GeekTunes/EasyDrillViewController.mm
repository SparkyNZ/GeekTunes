//
//  EasyDrillViewController.m
//  GeekTunes
//
//  Created by Admin on 16/09/13.
//
//

#import "EasyDrillViewController.h"
#import "GlossyButton.h"

#import "ViewController.h"
#import "ContainerVC.h"

#include "PaulPlayer.h"
#include "Events.h"
#include "Utils.h"
#include "CommonVectors.h"

@interface EasyDrillViewController ()

@end

@implementation EasyDrillViewController


@synthesize pvStringItems;
@synthesize vItems;
@synthesize vMatchedItems;
@synthesize vMatchedItemsIdx;
@synthesize nSelectedIndex;
@synthesize nArtistIndex;
@synthesize nAlbumIndex;
@synthesize nTuneIndex;
@synthesize nSelectStep;

@synthesize tuneSelectedDelegate;

extern ViewController *g_MainViewController;
extern ContainerVC    *g_ContainerVC;

static Vector          g_vAlbumsForArtist;
static Vector          g_vAlbumsIndexForArtist;


EasyDrillViewController *g_EasyDrillViewController = nil;

static UILabel *g_LabTitle[ 3 ]   = { nil, nil, nil };

static int      g_PageWidth  = 0;
static int      g_PageHeight = 0;

UIColor                   *g_ColourDarkBgnd = nil;
UIScrollView              *g_ScrollAlpha    = nil;
UIScrollView              *g_ScrollCategory = nil;
UIButton                  *g_AlphaButton[ 26 ];
UIButton                  *g_ButResult      = nil;
UILabel                   *g_LabResult      = nil;
UIButton                  *g_ButBackspace   = nil;
UITapGestureRecognizer    *g_TapGestureRecognizer = nil;

extern UIImage            *g_ImageBackspace;

static int      g_nNumCategories = 3;

#undef MAX_INPUT
#define MAX_INPUT 100


char            g_TxInput         [ MAX_INPUT + 1 ] = { 0 };
char            g_TxInputCompleted[ MAX_INPUT + 1 ] = { 0 };
NSMutableAttributedString *g_AttrInput =  nil;



extern float    g_ButInset;
extern float    g_ButWidth;
extern float    g_ButHeight;

//-----------------------------------------------------------------------------------------
// addButton
//-----------------------------------------------------------------------------------------
-(UIButton *) addButton: (NSString *) nsText subTitle: (NSString *) nsSubtitle atX: (float) x atY: (float) y
                  width: (float) w height: (float) h
               selector: (SEL) fn
             bgndColour: (UIColor*) bgndColour
               subLabel: (UILabel **) pSubLabel
                  image: (UIImage *) image
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake( x+g_ButInset, y+g_ButInset, w-(g_ButInset*2), h-(g_ButInset*2) );
  
	// Configure background image(s)
	[button setBackgroundToGlossyRectOfColor: bgndColour              withBorder: YES forState: UIControlStateNormal];
	[button setBackgroundToGlossyRectOfColor:[UIColor blackColor ] withBorder: YES forState:UIControlStateHighlighted];
  
	// Configure title(s)
  button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
  button.titleLabel.textAlignment = UITextAlignmentCenter;
  
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor colorWithRed:.25 green:.25 blue:.25 alpha:1] forState:UIControlStateNormal];
	[button setTitleShadowOffset:CGSizeMake(0, -1)];
	[button setFont:[UIFont boldSystemFontOfSize:40]];
  
  [button addTarget:self
             action: fn
   forControlEvents:UIControlEventTouchUpInside];
  
  [button setTitle: nsText forState:UIControlStateNormal];
  [button setImage: image forState: UIControlStateNormal];
  //[pView addSubview:button];
  
  return button;
}

static BOOL g_Dragging = FALSE;

//-----------------------------------------------------------------------------------------
// scrollViewWillBeginDragging
//-----------------------------------------------------------------------------------------
-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
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
// scrollToCategory
//-----------------------------------------------------------------------------------------
-(void) scrollToCategory: (int) nPage
{
  g_Dragging = TRUE;
  [g_ScrollCategory setContentOffset: CGPointMake( g_MaxPixelWidth * nPage, 0 ) animated:YES];
  g_Dragging = FALSE;
}

//-----------------------------------------------------------------------------------------
// scrollViewDidScroll
//-----------------------------------------------------------------------------------------
-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
  if( scrollView != g_ScrollCategory )
    return;
  
  static NSInteger previousPage = 0;
  
  if( g_Dragging )
    return;
  
  CGFloat pageWidth      = g_ScrollCategory.frame.size.width;
  float   fractionalPage = g_ScrollCategory.contentOffset.x / pageWidth;
  
  NSInteger page = lround(fractionalPage);
  
  if( previousPage != page )
  {
    switch( page )
    {
      case CATEGORY_ARTIST:  [self MovedToSelectArtist];  break;
      case CATEGORY_ALBUM:   [self MovedToSelectAlbum ];  break;
      case CATEGORY_TUNE:    [self MovedToSelectSong  ];  break;
    }
    
    // Page has changed
    // Do your thing!
    previousPage = page;
  }
}


//-----------------------------------------------------------------------------------------
// reset
//-----------------------------------------------------------------------------------------
-(void) reset
{
  LogDebugf( "Reset!" );
  g_TxInput[ 0 ] = 0;
  pvStringItems = &g_vArtist;
  g_LabResult.text = [NSString stringWithUTF8String: g_TxInput];
  
  nSelectStep = SELECT_ARTIST;
  
  nArtistIndex = -1;
  nAlbumIndex  = -1;
  nTuneIndex   = -1;
  
  g_ScrollAlpha.contentOffset    = CGPointMake( 0, 0 );
  g_ScrollCategory.contentOffset = CGPointMake( 0, 0 );
  
  vMatchedItemsIdx.removeAll();
  vMatchedItems.removeAll();
  
  [self scrollToCategory: CATEGORY_ARTIST ];
}

//-----------------------------------------------------------------------------------------
// RefreshInputLabel
//-----------------------------------------------------------------------------------------
-(void) RefreshInputLabel
{
  int  nCurLen = strlen( g_TxInput );
  
  if( ( g_TxInput[ 0 ] == 0 ) && ( nSelectStep == SELECT_ALBUM_FOR_ARTIST ) )
  {
    strcpy( g_TxInputCompleted, "*Random Tracks*" );
  }
  else
  {
    [self searchAutocompleteEntriesWithSubstring: g_TxInput ];

    // PDS: Here we copy in what we've typed for the autocompletion. BUT.. thats all capitals..
    if( vMatchedItems.elementCount() > 0 )
    {
      strcpy( g_TxInputCompleted, vMatchedItems.elementStrAt( 0 )  );
    }
    else
    {
      strcpy( g_TxInputCompleted, g_TxInput );
    }
  }
  
  int nAutoRemainder = strlen( g_TxInputCompleted ) - nCurLen;
    
  if( nAutoRemainder < 1 )
    nAutoRemainder = 0;
    
  // PDS: Make the attributed text (entered in white), rest of autocompletion in grey..
  g_AttrInput = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithUTF8String: g_TxInputCompleted] ];
  
  [g_AttrInput addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range: NSMakeRange( 0, nCurLen ) ];
  
  // PDS: Now the autocompletion text..
  if( nAutoRemainder > 0 )
  {
    [g_AttrInput addAttribute:NSForegroundColorAttributeName
                        value:[UIColor grayColor]
                        range:NSMakeRange( nCurLen, nAutoRemainder ) ];
  }
  
  g_LabResult.attributedText = g_AttrInput;
}

//-----------------------------------------------------------------------------------------
// backspacePressed
//-----------------------------------------------------------------------------------------
-(void) backspacePressed
{
  int nCurLen = strlen( g_TxInput );

  if( nCurLen < 1 )
    return;
  
  g_TxInput[ nCurLen - 1 ] = 0;
  
  [self RefreshInputLabel];
}

//-----------------------------------------------------------------------------------------
// alphaPressed
//-----------------------------------------------------------------------------------------
-(void) alphaPressed: (id) sender
{
  UIButton *buttonClicked = (UIButton *)sender;
  
  int nCurLen = strlen( g_TxInput );
  
  if( nCurLen >= MAX_INPUT )
    return;
  
  g_TxInput[ nCurLen ] = buttonClicked.tag;
  nCurLen ++;
  
  g_TxInput[ nCurLen ] = 0;

  [self RefreshInputLabel];
}


//-----------------------------------------------------------------------------------------
// searchAutocompleteEntriesWithSubstring
//-----------------------------------------------------------------------------------------
-(void) searchAutocompleteEntriesWithSubstring: (char *) pSubStr
{
  vMatchedItems.removeAll();
  vMatchedItemsIdx.removeAll();
  
  LogDebugf( "Try match: %s", pSubStr );
  
  char *pItem;
  
  for( int i = 0; i < pvStringItems->elementCount(); i ++ )
  {
    pItem = pvStringItems->elementStrAt( i );
    
    // PDS: Match text starting with..
    if( SubStrMatchAnyCase( pItem, pSubStr ) )
    {
      vMatchedItems.addElement( pItem );
      vMatchedItemsIdx.addElement( i );
      
      LogDebugf( "Matched %s", pItem );
      
      // PDS: Only going to have 1 match! Don't even need vectors..
      break;
    }
  }
}

//-----------------------------------------------------------------------------------------
// UnknownAlbumForArtist()
//-----------------------------------------------------------------------------------------
BOOL UnknownAlbumForArtist( int nArtistIndex )
{
  int nAlbumCount = g_vAlbumsForArtist.elementCount();
  
  if( nAlbumCount > 1 )
    return FALSE;
  
  if( nAlbumCount <= 0 )
    return TRUE;
  
  int nAlbumIndex = g_vAlbumsForArtist.elementIntAt( 0 );
  
  LogDebugf( "Album Index %d", nAlbumIndex );
  
  return FALSE;
}

//-----------------------------------------------------------------------------------------
// MovedToSelectArtist
//-----------------------------------------------------------------------------------------
-(void) MovedToSelectArtist
{
  LogDebugf( "MovedToSelectArtist" );
  
  [self reset];
}

//-----------------------------------------------------------------------------------------
// MovedToSelectAlbum
//-----------------------------------------------------------------------------------------
-(void) MovedToSelectAlbum
{
  LogDebugf( "MoveToSelectAlbum" );
  
  g_TxInput[ 0 ]  = 0;
  
  if( vMatchedItemsIdx.elementCount() > 0 )
  {
    LogDebugf( "MoveToSelectAlbum, artist chosen.." );
    
    nArtistIndex = vMatchedItemsIdx.elementIntAt( 0 );
    nSelectStep  = SELECT_ALBUM_FOR_ARTIST;
    pvStringItems   = &g_vAlbumsForArtist;
    
    // PDS: Find all albums for the artist..
    for( int a = 0; a < g_vAlbum.elementCount(); a ++ )
    {
      if( g_vAlbumArtistIndex.elementIntAt( a ) == nArtistIndex )
      {
        char *pszAlbumName = g_vAlbum.elementStrAt( a );
        g_vAlbumsForArtist.addElement( pszAlbumName );
        g_vAlbumsIndexForArtist.addElement( a );
        
        LogDebugf( "Album for artist: %s (index: %d)", pszAlbumName, nArtistIndex );
      }
    }
    
    if( UnknownAlbumForArtist( nArtistIndex ) )
    {
      // PDS: If no albums (eg. SIDs or MODs).. then accumulate all of the artists efforts..
      g_CurrentArtistIndexPlaying = nArtistIndex;
      
      PostPlayerEvent( evCREATE_PLAYLIST_ARTIST );
      
      SetMode( MODE_NORMAL_PLAY );

      g_PlayListIndex[ g_CurrentMode ] = 0;
      
      PostPlayerEvent( evNEXT_TUNE );
      [g_ContainerVC scrollToPage: 1];
      g_TxInput[ 0 ]  = 0;
      
      return;
    }
    
    // PDS: Leave matching item in input label..
    [self  RefreshInputLabel];
    
    vMatchedItems.removeAll();
    vMatchedItemsIdx.removeAll();
    
    return;
  }
  else
  {
    LogDebugf( "MovedToSelectAlbum, no matching items.." );
    
    nSelectStep   = SELECT_ALBUM;
    pvStringItems = &g_vAlbum;
  }
  
  g_vAlbumsForArtist.removeAll();
  g_vAlbumsIndexForArtist.removeAll();
  
  vMatchedItems.removeAll();
  vMatchedItemsIdx.removeAll();
  
  // PDS: Assume we are continuing onto album selection..
  [self RefreshInputLabel];
}

//-----------------------------------------------------------------------------------------
// MovedToSelectSong
//-----------------------------------------------------------------------------------------
-(void) MovedToSelectSong
{
  LogDebugf( "MovedToSelectSong" );
  
  g_TxInput[ 0 ]  = 0;
  
  pvStringItems   = &g_vTunesName;
  
  nSelectStep  = SELECT_TUNE;

  [self RefreshInputLabel];
  
  g_vAlbumsForArtist.removeAll();
  g_vAlbumsIndexForArtist.removeAll();
  
  vMatchedItems.removeAll();
  vMatchedItemsIdx.removeAll();
}

//-----------------------------------------------------------------------------------------
// labelTouched
//-----------------------------------------------------------------------------------------
-(void) labelTouched
{
  LogDebugf( "Label Touched, nSelectStep: %d", nSelectStep );
  
  if( vMatchedItems.elementCount() > 0 )
  {
    LogDebugf( "- Matching items" );
    
    switch( nSelectStep )
    {
      case SELECT_ARTIST:

        LogDebugf( "Label Touched: SELECT_ARTIST, Move to Album.." );
        
        // PDS: Scroll to album category..
        [self scrollToCategory: CATEGORY_ALBUM];
       
        break;
        
      case SELECT_ALBUM_FOR_ARTIST:
        
        LogDebugf( "Label Touched: SELECT_ALBUM_FOR_ARTIST" );
        
        // PDS: Get index of string in album subset..
        nAlbumIndex = vMatchedItemsIdx.elementIntAt( 0 );

        if( nAlbumIndex >= 0 )
        {
          // PDS: Now get album true index..
          g_CurrentAlbumIndexPlaying = g_vAlbumsIndexForArtist.elementIntAt( nAlbumIndex );

          SetMode( MODE_NORMAL_PLAY );
          g_PlayListIndex[ g_CurrentMode ] = 0;
          SelectCurrentPlayList( MODE_NORMAL_PLAY );
          
          PostPlayerEvent( evCREATE_PLAYLIST_ALBUM );
          PostPlayerEvent( evNEXT_TUNE );
        }

        vMatchedItems.removeAll();
        vMatchedItemsIdx.removeAll();
        
        [g_ContainerVC scrollToPage: 1];
        g_TxInput[ 0 ]  = 0;
        break;
        
      case SELECT_ALBUM:
        LogDebugf( "Label Touched: SELECT_ALBUM" );
        
        // PDS: Get index of string in album subset..
        nAlbumIndex = vMatchedItemsIdx.elementIntAt( 0 );
        
        if( nAlbumIndex >= 0 )
        {
          // PDS: Now get album true index..
          g_CurrentAlbumIndexPlaying = nAlbumIndex;
          
          SetMode( MODE_NORMAL_PLAY );
          g_PlayListIndex[ g_CurrentMode ] = 0;
          SelectCurrentPlayList( MODE_NORMAL_PLAY );
          
          PostPlayerEvent( evCREATE_PLAYLIST_ALBUM );
          PostPlayerEvent( evNEXT_TUNE );
        }
        
        vMatchedItems.removeAll();
        vMatchedItemsIdx.removeAll();
        
        [g_ContainerVC scrollToPage: 1];
        g_TxInput[ 0 ]  = 0;
        break;
        
      case SELECT_TUNE:
        LogDebugf( "Label Touched: SELECT_TUNE" );
        
        // PDS: Get index of string in album subset..
        nTuneIndex = vMatchedItemsIdx.elementIntAt( 0 );
        
        if( nTuneIndex >= 0 )
        {
          // PDS: Now get album true index..
          g_CurrentTuneLibIndexPlaying = nTuneIndex;

          // PDS: Continue playing artists tunes after selected tune..
          nArtistIndex = g_vTunesArtistIndex.elementIntAt( nTuneIndex );
          
          g_vTuneIndicesForArtist.removeAll();
          
          // PDS: Find all tunes for the artist..
          for( int a = 0; a < g_vTunesArtistIndex.elementCount(); a ++ )
          {
            if( g_vTunesArtistIndex.elementIntAt( a ) == nArtistIndex )
            {
              int nRating = g_vTunesRating.elementIntAt( a );
                  
              if( nRating < 0 )
                continue;

              g_vTuneIndicesForArtist.addElement( a );
            }
          }

          [g_MainViewController tuneSelected: nTuneIndex continueArtist: nArtistIndex];
        }
        
        vMatchedItems.removeAll();
        vMatchedItemsIdx.removeAll();
        
        [g_ContainerVC scrollToPage: 1];
        g_TxInput[ 0 ]  = 0;
        break;
    }
  }
  else
  if( nSelectStep == SELECT_ALBUM_FOR_ARTIST )
  {
    // PDS: If no album chosen, start playing all artist tracks..
    g_CurrentArtistIndexPlaying = nArtistIndex;

    SetMode( MODE_NORMAL_PLAY );
    g_PlayListIndex[ g_CurrentMode ] = 0;
    SelectCurrentPlayList( MODE_NORMAL_PLAY );

    vMatchedItems.removeAll();
    vMatchedItemsIdx.removeAll();
    
    LogDebugf( "Artist: index: %d", nArtistIndex );
    
    // PDS: This selects random play of the artist..
    PostPlayerEvent( evCREATE_PLAYLIST_ARTIST );
    PostPlayerEvent( evNEXT_TUNE );
    
    [g_ContainerVC scrollToPage: 1];
    g_TxInput[ 0 ]  = 0;
  }
}

//-----------------------------------------------------------------------------------------
// addCategoryScroll
//-----------------------------------------------------------------------------------------
-(void) addCategoryScroll
{
  int nScrollViewWidth = g_MaxPixelWidth * g_nNumCategories;
  int nTitleHeight     = 50;

  g_ScrollCategory = [[UIScrollView alloc] initWithFrame: CGRectMake( 0, 0,
                                                                      g_MaxPixelWidth, nTitleHeight )];
  g_ScrollCategory.pagingEnabled = YES;
  g_ScrollCategory.directionalLockEnabled = YES;
  g_ScrollCategory.bounces = NO;
  
  g_ScrollCategory.contentSize   = CGSizeMake( nScrollViewWidth, nTitleHeight );
  
  g_ColourDarkBgnd = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.25 alpha:1];
  
  for( int c = 0; c < g_nNumCategories; c ++ )
  {
    g_LabTitle[ c ] = [[UILabel alloc] initWithFrame: CGRectMake( c * g_PageWidth, 0, g_PageWidth, nTitleHeight )];
    
    [g_LabTitle[ c ] setBackgroundColor: g_ColourDarkBgnd];
    [g_LabTitle[ c ] setFont:[UIFont boldSystemFontOfSize:24]];
    
    switch( c )
    {
      case 0:   g_LabTitle[ c ].text = @"Artist";  break;
      case 1:   g_LabTitle[ c ].text = @"Album";   break;
      case 2:   g_LabTitle[ c ].text = @"Song";    break;
    }
    
    g_LabTitle[ c ].textAlignment = UITextAlignmentCenter;
    
    [g_LabTitle[ c ] setTextColor:[UIColor yellowColor]];
  
    // PDS: Position scroll strip..
    g_ScrollCategory.contentOffset = CGPointMake( 0, 0 );
    
    [g_ScrollCategory addSubview: g_LabTitle[ c ] ];
  }
  
  g_ScrollCategory.delegate = self;
}


//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
-(void) viewDidLoad
{
  [super viewDidLoad];
  
  // PDS: Main view controller is what will kick off playing of tunes..
  tuneSelectedDelegate = g_MainViewController;
  
  // PDS: Point to internal vector (pointer can be later reassigned).
  pvStringItems = &g_vArtist; //&vItems;
  
  int i;
  
  for( i = 0; i < 26; i ++ )
    g_AlphaButton[ i ] = nil;
  
  g_PageWidth  = self.view.frame.size.width;
  g_PageHeight = self.view.frame.size.height;
  
  int nTitleHeight      = 50;
  
  int nAlphaKeysPerRowInScroll = 3;
  
  int nAlphaKeyWidth    = g_PageWidth / nAlphaKeysPerRowInScroll;
  int nAlphaLines       = 4;
  
  int nKeysPerPage      = ( nAlphaKeysPerRowInScroll * nAlphaLines );
  int nNumPages         = 26 / nKeysPerPage;
  int nKeysOnFullPages  = nNumPages * nKeysPerPage;
  int nRemainderKeys    = 26 - nKeysOnFullPages;
  
  if( nRemainderKeys > 0 )
    nNumPages ++;
  
  int yAlphaStrip       = nTitleHeight + 4;
  int nAlphaStripWidth  = nNumPages * g_PageWidth;
  int nAlphaKeyHeight   = g_ButHeight * 2;
  int nAlphaStripHeight = nAlphaKeyHeight * nAlphaLines;
  
  int nScrollViewWidth  = g_PageWidth;
  int nScrollViewHeight = nAlphaStripHeight;
  
  int yButResult        = yAlphaStrip + nAlphaStripHeight;
  int nButResultHeight  = g_PageHeight - yButResult;
  
  // PDS: Make category scroll view.. This will allow 3 titles: ARTIST -> ALBUM -> SONG
  if( g_ScrollCategory == nil )
    [self addCategoryScroll];
  
  // PDS: Below we make the scroll view ("window" on the bigger picture) the same size as the full screen.
  if( g_ScrollAlpha == nil )
    g_ScrollAlpha = [[UIScrollView alloc] initWithFrame: CGRectMake( 0, yAlphaStrip,
                                                                    nScrollViewWidth, nScrollViewHeight )];
  g_ScrollAlpha.pagingEnabled = YES;
  g_ScrollAlpha.directionalLockEnabled = YES;
  g_ScrollAlpha.bounces = NO;
  
  g_ScrollAlpha.contentSize   = CGSizeMake( nAlphaStripWidth, nAlphaStripHeight );
  
  // PDS: Position scroll strip..
  g_ScrollAlpha.contentOffset = CGPointMake( 0, 0 );
  
  int  xAlphaKeyOffset[ 26 ];
  int  yAlphaKeyOffset[ 26 ];
  char txKey[ 1 + 1 ];
  int  nButIndex;
  int  nRow, nCol;
  BOOL fDone = FALSE;
  
  // PDS: Do the pages..
  for( int p = 0; p < nNumPages; p ++ )
  {
    for( nRow = 0; nRow < nAlphaLines; nRow ++ )
    {
      for( nCol = 0; nCol < nAlphaKeysPerRowInScroll; nCol ++ )
      {
        nButIndex = ( p * nKeysPerPage ) + ( nRow * nAlphaKeysPerRowInScroll ) + nCol;
        
        if( nButIndex >= 26 )
        {
          fDone = TRUE;
          break;
        }
      
        xAlphaKeyOffset[ nButIndex ] = ( nCol * nAlphaKeyWidth  ) + ( p * g_PageWidth );
        yAlphaKeyOffset[ nButIndex ] = ( nRow * nAlphaKeyHeight );
        
        txKey[ 0 ] = nButIndex + 'A';
        txKey[ 1 ] = 0;
        
        g_AlphaButton[ nButIndex ] = [self addButton: [NSString stringWithUTF8String: txKey]
                                            subTitle: @""
                                                 atX: xAlphaKeyOffset[ nButIndex ]
                                                 atY: yAlphaKeyOffset[ nButIndex ]
                                               width: nAlphaKeyWidth
                                              height: nAlphaKeyHeight
                                            selector: @selector( alphaPressed: )
                                          bgndColour: [UIColor colorWithRed: 0.2 green: 0.2 blue: 0.8 alpha: 1.0]
                                            subLabel: nil
                                               image: nil];
        
        g_AlphaButton[ nButIndex ].tag = txKey[ 0 ];
        
        [g_ScrollAlpha addSubview: g_AlphaButton[ nButIndex ] ];
      }
      
      if( fDone )
        break;
    }
  }
  
  g_ScrollAlpha.delegate = self;
  
  g_LabResult.attributedText = nil;
  
  int nBSWidth = nAlphaKeyWidth / 2;
  
  g_LabResult = [[UILabel alloc] initWithFrame: CGRectMake( 0, yButResult, g_PageWidth - nBSWidth, nButResultHeight )];
  [g_LabResult setBackgroundColor: g_ColourDarkBgnd];
	[g_LabResult setFont:[UIFont boldSystemFontOfSize:30]];
  g_LabResult.attributedText = g_AttrInput;
  g_LabResult.textAlignment = UITextAlignmentLeft;
  
  [g_LabResult setUserInteractionEnabled:YES];
  
  g_ButBackspace = [self addButton: @""
                          subTitle: @""
                               atX: g_PageWidth - nBSWidth
                               atY: yButResult
                             width: nBSWidth
                            height: nButResultHeight
                          selector: @selector( backspacePressed )
                        bgndColour: [UIColor redColor]
                          subLabel: nil
                             image: g_ImageBackspace];
  
  [g_ButBackspace setBackgroundColor: g_ColourDarkBgnd];
  
  
  g_TapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector( labelTouched )];
  [g_TapGestureRecognizer setNumberOfTapsRequired:1];
  [g_LabResult addGestureRecognizer: g_TapGestureRecognizer];
  
  
  [self.view addSubview: g_ScrollCategory];
  [self.view addSubview: g_ScrollAlpha];
  [self.view addSubview: g_LabResult];
  [self.view addSubview: g_ButBackspace];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

@end
