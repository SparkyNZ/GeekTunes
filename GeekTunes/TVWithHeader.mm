#import "TVWithHeader.h"

@implementation TVWithHeader

@synthesize  pCustomHeaderTitle;
@synthesize  m_TableView;

extern int g_MaxPixelWidth;
extern int g_CellHeight;

int g_PopoverWidth = 320;

-(UITableView*) tableView
{
  return m_TableView;
}

- (void)setTableView:(UITableView *)newTableView
{
  if( newTableView != m_TableView )
  {
    m_TableView = newTableView;
  }
}

//-----------------------------------------------------------------------------------------
// loadView
//-----------------------------------------------------------------------------------------
- (void)loadView
{
  [super loadView];
  
  //save current tableview, then replace view with a regular uiview
  self.m_TableView = (UITableView*)self.view;
  self.view = [[UIView alloc] initWithFrame:self.tableView.frame];
  
  [self.view addSubview:self.m_TableView];
  
  //code below adds some custom stuff above the table
  UIView *customHeader = [[UIView alloc] initWithFrame:CGRectMake( 0, 0, self.view.frame.size.width, g_CellHeight )];
  
  // PDS: Configure header and add various components..
  customHeader.backgroundColor = [UIColor redColor];
  
  // PDS: Not sure why but text doesn't appear in centre so need to try PopoverWidth..
  pCustomHeaderTitle = [UILabel alloc];
  [pCustomHeaderTitle initWithFrame: CGRectMake( 0.0, 0.0, g_PopoverWidth - 40, g_CellHeight ) ];
  
  pCustomHeaderTitle.backgroundColor = [UIColor clearColor];
  pCustomHeaderTitle.textAlignment   = UITextAlignmentCenter; 
  pCustomHeaderTitle.textColor       = [UIColor whiteColor];
  
	[pCustomHeaderTitle setFont:[UIFont boldSystemFontOfSize:24]];
  [pCustomHeaderTitle setShadowColor:[UIColor blackColor] ];
	[pCustomHeaderTitle setShadowOffset:CGSizeMake(0, -1)];
 
  [pCustomHeaderTitle setText: @""];
  [customHeader addSubview: pCustomHeaderTitle];

  // PDS: Add header to table view..
  [self.view addSubview:customHeader];
  
  self.m_TableView.frame = CGRectMake(0, customHeader.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - customHeader.frame.size.height);
}

//-----------------------------------------------------------------------------------------
// viewDidUnload
//-----------------------------------------------------------------------------------------
-(void) viewDidUnload
{
  self.m_TableView = nil;
  [super viewDidUnload];
}

@end