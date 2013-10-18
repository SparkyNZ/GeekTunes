//
//  ViewController.h
//  GeekTunes
//
//  Created by Paul Spark on 2/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "TuneSelectedDelegate.h"
#include "DismissDelegate.h"

void SetupExportPaths( void );
void IncProgress( void );


@interface ViewController : UIViewController <TuneSelectedDelegate, DismissDelegate, UIAlertViewDelegate>

-(void) addLocalFilesToLibrary;
-(void) RebuildTuneLibrary;
-(void) LoadTuneLibrary;
-(void) UploadTunes;

-(void) DisplaySettings;
-(void) DisplayDrillDown;

-(void) SetStatusInfo: (BOOL) fShowFader;

void PlayTuneWithURL(char *pURL );
void PlayTune( char *pszTune, int nTuneLibIndex );
-(void) ResumeTune;
-(void) PauseTune;
-(void) LikeTune;
-(void) HateTune;
-(void) PlaySelected;
-(void) PlayStopTune;
-(void) UpdatePlayStopButton;
-(void) StopTune;
-(void) PrevTune;
-(void) NextTune;
-(void) PrevSubTune;
-(void) NextSubTune;
-(void) TuneFinishedPlaying;

void StartSIDorMOD( void );
void StopSIDorMOD( void );

void PlayMODAtPath( char *txPath );
void PlaySIDAtPath( char *txPath, int nTuneLibIndex );

-(void) tuneSelectedInPlayList: (int) nTuneIndex inPlayList: (int) nPlayList;
-(void) tuneSelected: (int) nTuneIndexInLib;
-(void) tuneSelected: (int) nTuneIndexInLib continueArtist: (int) nArtistIndex;

-(void) dismissAll;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
