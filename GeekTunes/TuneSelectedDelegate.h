//
//  TuneSelectedDelegate.h
//  GeekTunes
//
//  Created by Paul Spark on 3/07/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef GeekTunes_TuneSelectedDelegate_h
#define GeekTunes_TuneSelectedDelegate_h


//-----------------------------------------------------------------------------------------
// TuneSelectedDelegate
//-----------------------------------------------------------------------------------------
@protocol TuneSelectedDelegate <NSObject>
@optional

// PDS: This is the method that gets called on the parent class!
-(void) tuneSelected: (int) nTuneIndexInLib;

-(void) tuneSelected: (int) nTuneIndexInLib continueArtist: (int) nArtistIndex;

-(void) tuneSelectedInPlayList: (int) nTuneIndex inPlayList: (int) nPlayList;

-(void) tuneSelectedInAlbum: (int) nTuneIndex inAlbum: (int) nAlbum;

@end


#endif
