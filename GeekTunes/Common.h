//
//  Common.h
//  GeekTunes
//
//  Created by Paul Spark on 4/06/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef GeekTunes_Common_h
#define GeekTunes_Common_h

typedef unsigned char  BYTE;

typedef unsigned long  ULONG;
typedef unsigned short USHORT;

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define MAX_PATH 1024

extern int      g_MaxPixelHeight;
extern int      g_MaxPixelWidth;

enum 
{
  UNIT_SID = 0,
  UNIT_MOD,
  UNIT_MP3,
  UNIT_UNKNOWN
};

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#endif
