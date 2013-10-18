//
//  BackupRestoreVC.m
//  LawyerApp
//
//  Created by Paul Spark on 16/04/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "BackupRestoreVC.h"
#import "CFtpServer.h"
#import "IPAddress.h"
#include "BarbUtils.h"
#include "Utils.h"

extern UIApplication *g_App;

@implementation BackupRestoreVC

@synthesize editUserName;
@synthesize editPassword;
@synthesize editPort;

@synthesize currentTextField;

@synthesize timerUpdate;

@synthesize strUserName;
@synthesize strPassword;
@synthesize strPort;
@synthesize strOutput;
@synthesize nsFTPButton;

@synthesize doneButton;

#define MAX_CHARS_FTP_USERNAME 20
#define MAX_CHARS_FTP_PASSWORD 20
#define MAX_CHARS_FTP_PORT     5

enum
{
  AV_NOTIFY = 0,
  AV_RESTORE_CONFIRM,
  AV_BACKUP_CONFIRM,
};

#define HEIGHT_SECTION_OUTPUT 60

enum
{
  SECTION_FTP_DETAILS = 0,
  SECTION_OUTPUT,
  SECTION_FTP,
  
  MAX_BR_SECTIONS
};

int    g_xTextField      = 15;
int    g_yTextField      = 12;
int    g_TextFieldWidth  = 290;
int    g_TextFieldHeight = 30;
int    g_nFTPPort        = 4444;
char   g_FTPUsername[ MAX_CHARS_FTP_USERNAME ] = "guest";
char   g_FTPPassword[ MAX_CHARS_FTP_PASSWORD ] = "password";

CFtpServer             *g_FTPServer  = nil;
CFtpServer::CUserEntry *g_pFTPUser   = nil;
NSString               *g_DocumentsDirectory = nil;
char                    g_txFTPPath[ MAX_PATH ];
char                    g_txFTPHome[ MAX_PATH ];
BOOL                    g_FTPStarted = FALSE;
char                    g_Output[ 200 ];
BackupRestoreVC        *g_Self = nil;
BOOL                    g_StatusUpdated = FALSE;



//-----------------------------------------------------------------------------------------
// Backup & Restore
//-----------------------------------------------------------------------------------------
enum
{
  FTP_USERNAME = 0,
  FTP_PASSWORD,
  FTP_PORT,
  
  FTP_MAX_NUM_ROWS  
};

//-----------------------------------------------------------------------------------------
// titleForHeaderInSection
//-----------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
  switch ( section ) 
  {
    case SECTION_FTP_DETAILS:    return @"FTP Details";
    case SECTION_OUTPUT:         return @"Status";
    //case SECTION_BACKUP:         return @"Reports";
    //case SECTION_RESTORE:        return @"Report Headings";
    default:                               break;
  }
  return 0;
}

//-----------------------------------------------------------------------------------------
// heightForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  switch( [indexPath section] )
  {
    case SECTION_OUTPUT: 
      // PDS: Return a bigger section for comments..
      return HEIGHT_SECTION_OUTPUT;
      
    default: 
      break;
  }
  
  // PDS: DO NOT call default method as it crashes.. Use tableView.rowHeight instead..
  //return [super tableView:tableView heightForRowAtIndexPath:indexPath];
  return tableView.rowHeight;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

//-----------------------------------------------------------------------------------------
// dealloc
//-----------------------------------------------------------------------------------------
- (void)dealloc
{
  doneButton  = nil;
  timerUpdate = nil;
}

//-----------------------------------------------------------------------------------------
// OnServerEvent
//-----------------------------------------------------------------------------------------
void OnServerEvent( int Event )
{
  switch( Event )
  {
    case CFtpServer::START_LISTENING:
      NSLog( @"* Server is listening !\r\n");
      
      //sprintf( g_Output, "Server listening." );
      //g_StatusUpdated = TRUE;
      break;
      
    case CFtpServer::START_ACCEPTING:
      LogDebugf( "* Server is accepting incoming connexions !\r\n");
      break;
      
    case CFtpServer::STOP_LISTENING:
      LogDebugf( "* Server stopped listening !\r\n");
      break;
      
    case CFtpServer::STOP_ACCEPTING:
      LogDebugf( "* Server stopped accepting incoming connexions !\r\n");
      break;
    case CFtpServer::MEM_ERROR:
      LogDebugf( "* Warning, the CFtpServer class could not allocate memory !\r\n");
      break;
    case CFtpServer::THREAD_ERROR:
      LogDebugf( "* Warning, the CFtpServer class could not create a thread !\r\n");
      break;
    case CFtpServer::ZLIB_VERSION_ERROR:
      LogDebugf( "* Warning, the Zlib header version differs from the Zlib library version !\r\n");
      break;
    case CFtpServer::ZLIB_STREAM_ERROR:
      LogDebugf( "* Warning, error during compressing/decompressing data !\r\n");
      break;
  }
}

//-----------------------------------------------------------------------------------------
// OnUserEvent
//-----------------------------------------------------------------------------------------
void OnUserEvent( int Event, CFtpServer::CUserEntry *pUser, void *pArg )
{
  switch( Event )
  {
    case CFtpServer::NEW_USER:
      LogDebugf( "* A new user has been created:\r\n"
            "\tLogin: %s\r\n" "\tPassword: %s\r\n" "\tStart directory: %s\r\n",
            pUser->GetLogin(), pUser->GetPassword(), pUser->GetStartDirectory() );
      break;
      
    case CFtpServer::DELETE_USER:
      LogDebugf( "* \"%s\"user is being deleted: \r\n", pUser->GetLogin() );
      break;
  }
}

//-----------------------------------------------------------------------------------------
// OnClientEvent
//-----------------------------------------------------------------------------------------
void OnClientEvent( int Event, CFtpServer::CClientEntry *pClient, void *pArg )
{
  if( Event == CFtpServer::CLIENT_AUTH )
  {  
    sprintf( g_Output, "Client connected." );
    g_StatusUpdated = TRUE;
    return;
  }
  
  if( Event == CFtpServer::CLIENT_DISCONNECT )
  {
    sprintf( g_Output, "Client disconnected." );
    g_StatusUpdated = TRUE;      
    return;
  }
  

  /*
  switch( Event )
  {
    case CFtpServer::NEW_CLIENT:
      LogDebugf( "* A new client has been created:\r\n"
            "\tClient IP: [%s]\r\n\tServer IP: [%s]\r\n",
            inet_ntoa( *pClient->GetIP() ), inet_ntoa( *pClient->GetServerIP() ) );
      break;
      
    case CFtpServer::DELETE_CLIENT:
      LogDebugf( "* A client is being deleted.\r\n" );
      break;
      
    case CFtpServer::CLIENT_AUTH:
      LogDebugf( "* A client has logged-in as \"%s\".\r\n", pClient->GetUser()->GetLogin() );
      
      sprintf( g_Output, "Client connected." );
      g_StatusUpdated = TRUE;
      break;
      
    case CFtpServer::CLIENT_SOFTWARE:
      LogDebugf( "* A client has proceed the CLNT FTP command: %s.\r\n", (char*) pArg );
      break;
      
    case CFtpServer::CLIENT_DISCONNECT:
      LogDebugf( "* A client has disconnected.\r\n" );
      sprintf( g_Output, "Idle." );
      g_StatusUpdated = TRUE;      
      [g_Self stopFTP];      
      break;
      
    case CFtpServer::CLIENT_UPLOAD:
      LogDebugf( "* A client logged-on as \"%s\" is uploading a file: \"%s\"\r\n",
            pClient->GetUser()->GetLogin(), (char*)pArg );
      break;
      
    case CFtpServer::CLIENT_DOWNLOAD:
      LogDebugf( "* A client logged-on as \"%s\" is downloading a file: \"%s\"\r\n",
            pClient->GetUser()->GetLogin(), (char*)pArg );
      break;
      
    case CFtpServer::CLIENT_LIST:
      LogDebugf( "* A client logged-on as \"%s\" is listing a directory: \"%s\"\r\n",
            pClient->GetUser()->GetLogin(), (char*)pArg );
      break;
      
    case CFtpServer::CLIENT_CHANGE_DIR:
      LogDebugf( "* A client logged-on as \"%s\" has changed its working directory:\r\n"
            "\tFull path: \"%s\"\r\n\tWorking directory: \"%s\"\r\n",
            pClient->GetUser()->GetLogin(), (char*)pArg, pClient->GetWorkingDirectory() );
      break;
      
    case CFtpServer::RECVD_CMD_LINE:
      LogDebugf( "* Received: %s (%s)> %s\r\n",
            pClient->GetUser() ? pClient->GetUser()->GetLogin() : "(Not logged in)",
            inet_ntoa( *pClient->GetIP() ),
            (char*) pArg );
      break;
      
    case CFtpServer::SEND_REPLY:
      LogDebugf( "* Sent: %s (%s)> %s\r\n",
            pClient->GetUser() ? pClient->GetUser()->GetLogin() : "(Not logged in)",
            inet_ntoa( *pClient->GetIP() ),
            (char*) pArg );
      break;
      
    case CFtpServer::TOO_MANY_PASS_TRIES:
      LogDebugf( "* Too many pass tries for (%s)\r\n",
            inet_ntoa( *pClient->GetIP() ) );
      break;
  }
   */
}

//-----------------------------------------------------------------------------------------
// viewDidLoad
//-----------------------------------------------------------------------------------------
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  //g_App.idleTimerDisabled = YES;
  
  //[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  
  g_Self = self;
    
  nsFTPButton = @"Start FTP";
  
  InitAddresses();
  GetIPAddresses();
  
  sprintf( g_Output, "Idle." );
  
  doneButton = [UIBarButtonItem alloc];
  
  // add the "Done" button to the nav bar
  self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]
                                         initWithTitle:@"Back" 
                                         style:UIBarButtonItemStylePlain 
                                         target:self 
                                         action:@selector( backButtonHit ) ]; 
  
 
  fSettingsChanged  = FALSE;
  fDoneButtonPressed = FALSE;
  
  // PDS: Re-establish timer..
  timerUpdate = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                 target: self selector:@selector( UpdateOutput )
                                               userInfo: nil
                                                repeats: YES];  
  
}



- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//-----------------------------------------------------------------------------------------
// numberOfSectionsInTableView
//-----------------------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return MAX_BR_SECTIONS;
}

//-----------------------------------------------------------------------------------------
// numberOfRowsInSection
//-----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch ( section ) 
  {
    case SECTION_FTP_DETAILS:  return FTP_MAX_NUM_ROWS;
    case SECTION_OUTPUT:       return 1;
    case SECTION_FTP:          return 1;
  }
  
  return 1;
}

//-----------------------------------------------------------------------------------------
// textForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (NSString *)textForRowAtIndexPath: (NSIndexPath *) indexPath
{
  switch( indexPath.section )
  {
    case SECTION_FTP_DETAILS:
    {
      switch ( indexPath.row ) 
      {
        case FTP_USERNAME:        return @"Username";
        case FTP_PASSWORD:        return @"Password";
        case FTP_PORT:            return @"Port";
          
        default:                  break;
      }
      break;
    }
      
    case SECTION_FTP:             return nsFTPButton;
     
  }
      
  return nil;
}

//-----------------------------------------------------------------------------------------
// cellForRow
//-----------------------------------------------------------------------------------------
- (UITableViewCell *) cellForRow: (UITableView *)tableView atRow: (int) nRow  withPlaceHolder: (NSString *) nsPlaceHolder
{
  UITableViewCell *cell = nil;
  NSString        *CellIdentifier;
  
  static NSString *idName   = @"CellFName";
  static NSString *idPass   = @"CellFPass";
  static NSString *idPort   = @"CellFPort";
  
  switch( nRow )
  {            
    case FTP_USERNAME:  CellIdentifier = idName;  break;
    case FTP_PASSWORD:  CellIdentifier = idPass;  break;
    case FTP_PORT:      CellIdentifier = idPort;  break;  
  }
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil) 
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  UITextField *tf;
  
  // Configure the cell...
  switch( nRow )
  {
    case FTP_USERNAME: 
      strUserName      = @"guest";//[NSString stringWithUTF8String: g_SettingsRec.txFTPName];
      cell.textLabel.text       = @"Username";
      cell.detailTextLabel.text = strUserName;
      
      if( editUserName == nil )
      {
        editUserName = [MyUtils makeTextField: strUserName placeholder: @"Username"];    
      }
      
      [cell addSubview: editUserName];  
      
      tf = editUserName;
      break;
      
    case FTP_PASSWORD: 
      strPassword      = @"password"; //[NSString stringWithUTF8String: g_SettingsRec.txFTPPassword];
      cell.textLabel.text       = @"Password";
      cell.detailTextLabel.text = strPassword;
      
      if( editPassword == nil )
      {
        editPassword = [MyUtils makeTextField: strPassword placeholder: @"Password"]; 
        editPassword.secureTextEntry = YES;
      }
      
      [cell addSubview: editPassword];  
      
      tf = editPassword;
      break;      
      
    case FTP_PORT:
      if( editPort == nil )
      {        
        char txPort[ 50 ]; 
        sprintf( txPort, "%d", 7410 ); //g_SettingsRec.nFTPPort);
        strPort      = [NSString stringWithUTF8String: txPort];
        cell.textLabel.text       = @"Port";
        cell.detailTextLabel.text = strPort;
        
        if( editPort == nil )
        {
          editPort = [MyUtils makeTextField: strPort placeholder: @"Port"];    
        }
        
        [cell addSubview: editPort];  
      }
      
      tf = editPort;
      break;
  }
  
  // Workaround to dismiss keyboard when Done/Return is tapped
  [tf addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];	

  tf.frame = CGRectMake( g_xTextField + 200, g_yTextField, g_TextFieldWidth - 200, g_TextFieldHeight );  
  
  // We want to handle textFieldDidEndEditing
  tf.delegate = self;    
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// cellForFTP
//-----------------------------------------------------------------------------------------
-(UITableViewCell *) cellForFTP: (UITableView *)tableView
{
  NSString        *CellIdentifier; 
  UITableViewCell *cell;
  
  CellIdentifier = @"CellFTP";
  
  UITableViewCell *cellFTP = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cellFTP == nil)
  {    
    cellFTP = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    [cellFTP init];
    
    //cellFTP.selectionStyle = UITableViewCellSelectionStyleNone;
    cellFTP.textLabel.textAlignment = UITextAlignmentCenter;
    cellFTP.textLabel.text = nsFTPButton;
  }
  
  cell = (UITableViewCell*) cellFTP;
  
  return cell;
}


//-----------------------------------------------------------------------------------------
// cellForRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if( indexPath.section == SECTION_FTP )
    return [self cellForFTP: tableView];  
  
  if( indexPath.section == SECTION_OUTPUT )
    return [self cellForOutput: tableView];
  
  UITableViewCell *cell;
  NSString *nsPlaceHolder;
  
  // PDS> Need to make use of makeTextField here so we get the placeholder text as well as content when available..
  nsPlaceHolder = [self textForRowAtIndexPath: indexPath];
  
  // Configure the cell...
  cell = [self cellForRow: tableView atRow: [indexPath row] withPlaceHolder: nsPlaceHolder ];
  
  return cell;
}

//-----------------------------------------------------------------------------------------
// shouldChangeCharactersInRange
//-----------------------------------------------------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string
{
  int nMaxLength;
  
  if( textField == editUserName )
  {    
    nMaxLength = MAX_CHARS_FTP_USERNAME;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > nMaxLength) ? NO : YES;    
  }
  
  if( textField == editPassword )
  {    
    nMaxLength = MAX_CHARS_FTP_PASSWORD;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > nMaxLength) ? NO : YES;    
  }  

  if( textField == editPort )
  {    
    nMaxLength = MAX_CHARS_FTP_PORT;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > nMaxLength) ? NO : YES;    
  }  
  
  return YES;
}

//-----------------------------------------------------------------------------------------
// finishedEdit
//-----------------------------------------------------------------------------------------
//-(IBAction) finishedEdit: (id) sender
-(void) finishedEdit
{  
  /*
  char txPort[ 10 ];
  
  strcpy( g_SettingsRec.txFTPName,           [editUserName.text  UTF8String] );
  strcpy( g_SettingsRec.txFTPPassword,       [editPassword.text  UTF8String] ); 
  strcpy( txPort,                            [editPort.text      UTF8String] ); 
  
  strtrim( g_SettingsRec.txFTPName );
  strtrim( g_SettingsRec.txFTPPassword );
  strtrim( txPort );
  
  if( strlen( txPort ) < 1 )
  {
    [MyUtils Alert: @"Error" withText: @"Port invalid." ];
    return;
  }
  
  if( strlen( g_SettingsRec.txFTPName ) < 1 )
  {
    [self Alert: @"Error" withText: @"Username cannot be blank." ];
    return;
  }  
  
  if( strlen( g_SettingsRec.txFTPPassword ) < 1 )
  {
    [self Alert: @"Error" withText: @"Password cannot be blank." ];
    return;
  }  
  
  g_SettingsRec.nFTPPort = Safe_atoi( txPort );
  
  // PDS: Update database..
  UpdateSettings( &g_SettingsRec );
  
  // PDS: Check that something has registered to listen for the delegate..
#if 0 
  if( [delegateChargeCodeDetailsChanged respondsToSelector: @selector( chargeCodeDetailsChanged: ) ] )
  {
    // PDS: Call the xxxxDetailsChanged delegate method on the parent..
    [delegateChargeCodeDetailsChanged chargeCodeDetailsChanged: rCode.nID];
  }  
#endif
  */
  // PDS: Dismiss screen..
  [self.navigationController popViewControllerAnimated:YES];
}


//-----------------------------------------------------------------------------------------
// cellForOutput
//-----------------------------------------------------------------------------------------
-(UITableViewCell *) cellForOutput: (UITableView *)tableView
{
  static NSString *CellIdentifier = @"CellOutput";
  UITableViewCell *cell;
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  strOutput = [NSString stringWithUTF8String: g_Output];
  
  if (cell == nil)
  {    
    cell =  [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle   
                                                              reuseIdentifier: CellIdentifier];
  }
  
  cell.textLabel.numberOfLines       = 3; 
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.textLabel.textAlignment = UITextAlignmentLeft;
  cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation; 
  cell.textLabel.text = strOutput;
  
  cell.detailTextLabel.numberOfLines = 0;
  //cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation; 
  //cell.detailTextLabel.text = [strOutput copy];
    
  return cell;
}

//-----------------------------------------------------------------------------------------
// donePressed
//-----------------------------------------------------------------------------------------
-(void) donePressed: (id)sender
{
  [self stopFTP];
  
  [self.navigationController popViewControllerAnimated:NO];
}

//-----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath
//-----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  switch ( indexPath.section ) 
  {
    case SECTION_FTP:
    {
      char *pAddress;
      
      FreeAddresses();
      InitAddresses();    // PDS: May need to remove this! May suck resources..      
      GetIPAddresses();
      
      pAddress = GetIPAddress();
      
      if( ( pAddress == nil ) || ( strcmp( pAddress, "127.0.0.1" ) == 0 ) )
      {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"No Network"];
        [alert setMessage:@"Please enable Wifi or 3G."];
        [alert setDelegate:self];
        [alert addButtonWithTitle:@"OK"];
        [alert show];
        return;
      }
      
      if( g_FTPStarted )
      {
        [self stopFTP];
        nsFTPButton = @"Start FTP";
        g_StatusUpdated = TRUE;
      }
      else
      {
        [self startFTP];
        nsFTPButton = @"Stop FTP";        
        g_StatusUpdated = TRUE;
      }
      break;
    }
      
    default:
      break;
  }
}

//-----------------------------------------------------------------------------------------
// UpdateOutput
//-----------------------------------------------------------------------------------------
-(void) UpdateOutput
{
  if( g_StatusUpdated != TRUE )
    return;
  
  NSArray *arrUpdateRows = [NSArray arrayWithObjects: 
                            [NSIndexPath indexPathForRow: 0 inSection: SECTION_OUTPUT ],
                            [NSIndexPath indexPathForRow: 0 inSection: SECTION_FTP ],
                            nil
                            ];
  
  [self.tableView beginUpdates];    
  [self.tableView reloadRowsAtIndexPaths: arrUpdateRows withRowAnimation:UITableViewRowAnimationNone];
  [self.tableView endUpdates];  
  
  g_StatusUpdated = FALSE;  
}

//-----------------------------------------------------------------------------------------
// stopFTP
//-----------------------------------------------------------------------------------------
-(void) stopFTP
{
  sprintf( g_Output, "Idle." );
  g_StatusUpdated = TRUE;
  
  /*
   if( g_FTPServer )
   {
   delete g_FTPServer;
   g_FTPServer = nil;
   g_pFTPUser  = nil;
   }
   */
  
  if( g_FTPServer )
    g_FTPServer->StopListening();
  
  g_FTPStarted = FALSE;    
}


//-----------------------------------------------------------------------------------------
// startFTP
//-----------------------------------------------------------------------------------------
- (void) startFTP
{    
  if( g_FTPStarted )
    return;
    
  char *pAddress = GetIPAddress();
  
  sprintf( g_Output, "Waiting for connection.\nAddress %s, port %d", pAddress, g_nFTPPort );
  g_StatusUpdated = TRUE;
    
  if( g_FTPServer == nil )
  {
    g_FTPServer = new CFtpServer();
  
  //  g_FTPServer->SetServerCallback( OnServerEvent );
  //  g_FTPServer->SetUserCallback( OnUserEvent );
    g_FTPServer->SetClientCallback( OnClientEvent );      
    
    
    g_FTPServer->SetMaxPasswordTries( 3 );
    g_FTPServer->SetNoLoginTimeout( 45 ); // seconds
    g_FTPServer->SetNoTransferTimeout( 90 ); // seconds
  }
  
  if( g_pFTPUser )
    g_FTPServer->DeleteUser( g_pFTPUser );

  g_pFTPUser = g_FTPServer->AddUser( g_FTPUsername, g_FTPPassword, g_txFTPHome /*g_txFTPPath*/ );      

  BYTE bPrivAll = CFtpServer::READFILE | CFtpServer::WRITEFILE | CFtpServer::DELETEFILE | CFtpServer::LIST;
  
  g_pFTPUser->SetPrivileges( bPrivAll );
  g_FTPServer->StartListening( INADDR_ANY, g_nFTPPort );
  g_FTPServer->StartAccepting();
  
  g_FTPStarted = TRUE;
}

//-----------------------------------------------------------------------------------------
// alertView
//-----------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{  
  if( alertView.tag == AV_BACKUP_CONFIRM )
  {
    if( buttonIndex == 0 )
    {
      //[self.navigationController popViewControllerAnimated:YES];
    }
    return;
  }  
}

//-----------------------------------------------------------------------------------------
// backButtonHit
//-----------------------------------------------------------------------------------------
-(void) backButtonHit
{
  [self stopFTP];
  [self settingsChanged];

  [editUserName resignFirstResponder];
  [editPassword resignFirstResponder];
  [editPort resignFirstResponder];
  
  [self.navigationController popViewControllerAnimated:YES];
}

//-----------------------------------------------------------------------------------------
// settingsChanged
//-----------------------------------------------------------------------------------------
-(void) settingsChanged
{
  // PDS: This should be called when settings have been changed and should be saved into database..
  [MyUtils CopyUITextField: editUserName   ToPSZ: g_FTPUsername ];
  [MyUtils CopyUITextField: editPassword   ToPSZ: g_FTPPassword ];
  
  if( editPort != nil )
    g_nFTPPort = Safe_atoi( (char *) [ editPort.text  UTF8String ] );
  
  // PDS: Update database..
  //UpdateSettings( &g_SettingsRec );
}

//-----------------------------------------------------------------------------------------
// doneButtonPressed
//-----------------------------------------------------------------------------------------
-(void) doneButtonPressed
{
  fDoneButtonPressed = TRUE;
  [self settingsChanged];
  [self.navigationController popViewControllerAnimated:YES]; 
}

//-----------------------------------------------------------------------------------------
// selectField
//-----------------------------------------------------------------------------------------
-(void) selectField: (UITextField *) textField  editBegun: (BOOL) fEditBegun
{
  static UITextField *pLastTextField = nil;
  
  // PDS: As soon as edit starts, regard as changed..
  if( fEditBegun )
    fSettingsChanged = TRUE;
  
  currentTextField = textField;
  
  if( ( currentTextField != nil            ) &&
     ( currentTextField != pLastTextField ) )
  {
    // PDS: Don't do the below line if already has become responder (ie. edit has begun because tap took place on UITextField
    //      rather than UITableView cell
    [currentTextField becomeFirstResponder];
  }
  
  if( ! fEditBegun )
  {
    if( ( pLastTextField != nil ) &&
       ( currentTextField != pLastTextField ) )
      [pLastTextField resignFirstResponder];
  }
  
  pLastTextField = currentTextField;
}

//-----------------------------------------------------------------------------------------
// textFieldDidBeginEditing
//-----------------------------------------------------------------------------------------
-(void) textFieldDidBeginEditing:(UITextField *) textField
{
  [self selectField: textField editBegun: TRUE];
}


@end
