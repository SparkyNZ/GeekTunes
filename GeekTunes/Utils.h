#ifndef _UTILS_H
#define _UTILS_H

#ifndef _WIN32
#include "MyTypes.h"
#endif

#include "vector.h"
#include "md5.h"

//#ifdef DEBUG
//#define LogDebugf(fmt, ...) NSLog((@"%s (%d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define LogDebugf(fmt, ...) NSLog((@"" fmt), ##__VA_ARGS__);
//#else
#define LogDebugf(...)
//#endif


#define VK_PGUP VK_PRIOR          
#define VK_PGDN VK_NEXT           
#define VK_ENTER VK_RETURN

#define MAX_ALPHA_SECTIONS 28

extern int    g_xTextField;
extern int    g_yTextField;
extern int    g_TextFieldWidth;
extern int    g_TextFieldHeight;

BYTE  *AddDWORD( BYTE *ptr, DWORD dw );
BYTE  *AddBYTE( BYTE *ptr, BYTE b );
BYTE  *AddWORD( BYTE *ptr, WORD w );
BYTE  *AddString( BYTE *ptr, char *s, BOOL fIncludeNull = TRUE );
BYTE  *AddData( BYTE *ptr, BYTE *pData, DWORD dwLen );

BYTE  *GetDWORD( BYTE *ptr, DWORD *dw );
BYTE  *GetBYTE( BYTE *ptr, BYTE *b );
BYTE  *GetWORD( BYTE *ptr, WORD *w );
BYTE  *GetString( BYTE *ptr, char *s, BOOL fIncludeNull = TRUE );
BYTE  *GetData( BYTE *ptr, BYTE *pData, DWORD dwLen );

//void LogDebugf( char *pchFormat, ... );
//void LogDebug( char *s );

char *stristr( char *pStringToSearch, char *pChunk );

int  stricmp( char *s1, char *s2 );
BOOL ValidString( char *s );
char Normalise( char c );
int  ParseWordsIntoVector( char *pWords, Vector *pvSubStrings );
BOOL SubStrMatchAnyCase( char *pBig, char *pSub );
BOOL SubStrMatchAnyCaseMultiple( char *pBig, Vector *pvSubstrings );

void JustifyTwoItems( char *pItemLeft, char *pItemRight, char *pDest, int nMaxWidth );

int _strnicmp( char *pStr1, char *pStr2, size_t Count );

void strtrim( char *s );
void    ClearVector( Vector *pv );

BOOL    FileExists( char *path );
BOOL    FileExistsInPath( char *pszPath, char *pszInsensFile, char *pszSensFile );


long    FileSize( char *s );
time_t  FileTime( char *pFile );
int     Safe_atoi( char *p );

void    GetFilenameOnly( char *txPath, char *txFilenameOnly );
BOOL    UnzipAllFiles( char *pZipFile, char *pDestFolder );
BOOL    UnzipAllFilesBody( char *pZipFile, char *pDestFolder, Vector *pvInnerFiles );
BOOL    UnzipGetInnerFilename( char *txFullUnzipPath, char *txUnzipPath, char *txInnerFilename );
void    UnzipFileInZip( char *txFullUnzipPath, char *txDestFolder, char *txInnerFilename );
void    GetZIPInnerFilenames( char *pZipFile, Vector *pvFiles );

void    RemoveAllIn( char *pDir );

int     Full28IndexFromChar( char c );
void    ClearAlphaSectionedVector( Vector pvAlphaSectionedList[] );
void    LoadSectionHeadingVector( Vector *pvSectionHeadings, Vector pvAlphaSectionedList[] );
void    PopulateAlphaSectionedVector( Vector pvAlphaSectionedList[], Vector *pvItems, Vector *pvIndices );

long    SecondsNow( void );
long    SecondsElapsed( long lStart );


// Graphics utils..
void    DrawRoundedRect( CGContext *context, CGRect rect, int radius );
void    DrawFilledRoundedRect( CGContext *context, CGRect rect, int radius );

#endif