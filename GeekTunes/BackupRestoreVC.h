//
//  BackupRestoreVC.h
//  LawyerApp
//
//  Created by Paul Spark on 16/04/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Common.h"

extern NSString               *g_DocumentsDirectory;
extern char                    g_txFTPPath[ MAX_PATH ];
extern char                    g_txFTPHome[ MAX_PATH ];
extern char                    g_PathSafe [ MAX_PATH ];


@interface BackupRestoreVC : UITableViewController  <UITextFieldDelegate,UIAlertViewDelegate>
{
  UITextField *editUserName;  
  UITextField *editPassword;
  UITextField *editPort;    

  NSString    *strUserName;
  NSString    *strPassword;  
  NSString    *strPort;  
  NSString    *strOutput;
  NSString    *nsFTPButton;
  NSTimer     *timerUpdate;
  
  UITextField  *currentTextField;      
  
  UIBarButtonItem *doneButton;  
  
  BOOL fDoneButtonPressed;
  BOOL fSettingsChanged;  
  
  
}

-(void) startFTP;
-(void) stopFTP;
-(void) UpdateOutput;
-(UITableViewCell *) cellForOutput: (UITableView *)tableView;
-(UITableViewCell *) cellForBackup: (UITableView *)tableView;
-(UITableViewCell *) cellForRestore: (UITableView *)tableView;
-(UITableViewCell *) cellForDone: (UITableView *)tableView;

@property (nonatomic, retain) UITextField *editUserName;  
@property (nonatomic, retain) UITextField *editPassword;
@property (nonatomic, retain) UITextField *editPort;


@property (nonatomic, retain) NSTimer     *timerUpdate;
@property (nonatomic, retain) NSString    *strUserName;
@property (nonatomic, retain) NSString    *strPassword;  
@property (nonatomic, retain) NSString    *strPort; 
@property (nonatomic, retain) NSString    *strOutput; 
@property (nonatomic, retain) NSString    *nsFTPButton;

@property (nonatomic, retain) UITextField  *currentTextField;    


@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;

@end
