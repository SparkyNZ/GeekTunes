//
//  CommonVectors.h
//  GeekTunes
//
//  Created by Admin on 1/10/13.
//
//

#ifndef GeekTunes_CommonVectors_h
#define GeekTunes_CommonVectors_h

#include "PaulPlayer.h"

class Vector;

extern Vector  g_vTunesName;
extern Vector  g_vTunesType;
extern Vector  g_vTunesPath;
extern Vector  g_vTunesRating;
extern Vector  g_vTunesTrack;
extern Vector  g_vTunesArtistIndex;
extern Vector  g_vTuneIndicesForArtist;
extern Vector  g_vArtist;
extern Vector  g_vAlbum;
extern Vector  g_vAlbumArtistIndex;

extern Vector  g_vTunesRating;
extern Vector  g_vPlayList[ MODE_MAX_MODES ];

extern Vector  g_vPlayListExpPath;
extern Vector  g_vPlayListExpPathMD5;
extern Vector  g_vModeText;
extern Vector  g_vTypeText;
extern Vector  g_vOrderText;

extern Vector *g_pvCurrPlayList;
extern Vector *g_pvCurrPlayListMD5;

extern Vector  g_vTunesAlbumIndex;


extern Vector  g_vTunesRatingMD5;
extern Vector  g_vPlayListMD5[ MODE_MAX_MODES ];

extern Vector  g_vPlaylistsActive;
extern Vector  g_vSIDSubTuneLengths;


#endif
