#import <UIKit/UIKit.h>

#include "Common.h"
#include "Utils.h"
#include "XUnzip.h"
#include "BarbUtils.h"
#include "ZIPDelete.h"

#include <sys/stat.h>
#include <time.h>

char g_TxtAll   [] = "- All -";
char g_TxtAny   [] = "- Any -";
char g_TxtSelect[] = "- Select -";

extern char *g_DocumentsDirectory;

/*
//--------------------------------------------------------------------------------------------
// LogDebug()
//--------------------------------------------------------------------------------------------
void LogDebug( char *s )
{
#ifndef _WIN32  
  LogDebugf( "%s", s );
  #else  
  static int x = 0;

  if( x == 0 )
  {
    x = 1;
    remove( "w:\\log.pds" );
  }

  FILE *op = fopen( "w:\\log.pds", "a" );
  fprintf( op, "%s\n", s );
  fclose( op );
#endif
}

//-------------------------------------------------------------------------------------------- 
// LogDebugf() 
//-------------------------------------------------------------------------------------------- 
void LogDebugf( char *pchFormat, ... ) 
{ 
  char pchFormatMessageBuf[250]; 
  
  va_list argp; 
  char* tmp; 
  
  pchFormatMessageBuf[0] = 0; 
  
  if( pchFormat != 0 ) 
  { 
    tmp = strchr(pchFormat, '%'); 
    
    if( tmp ) 
    { 
      va_start( argp, pchFormat ); 
      vsprintf( pchFormatMessageBuf, pchFormat, argp ); 
      va_end( argp ); 
    } 
    else 
      strcpy( pchFormatMessageBuf, pchFormat ); 
  } 
  
  LogDebug( pchFormatMessageBuf ); 
}
*/

/*
#ifndef _WIN32
//--------------------------------------------------------------------------------------------
// stricmp()
//--------------------------------------------------------------------------------------------
int stricmp( char *s1, char *s2 )
{
  return strcasecmp( s1, s2 );
}
#endif
*/

//--------------------------------------------------------------------------------------------------
// JustifyTwoItems()                                                  
//                                                                    
// Justifies one item to the left and one to the right                
//--------------------------------------------------------------------------------------------------
void JustifyTwoItems( char *pItemLeft, char *pItemRight, char *pDest, int nMaxWidth )
{
  int nLenLeft;
  int nLenRight;
  int nPadding;
  int p;

  nLenLeft  = strlen( pItemLeft  );
  nLenRight = strlen( pItemRight );
  nPadding  = nMaxWidth - (nLenLeft + nLenRight);

  strcpy( pDest, pItemLeft );

  if( ( nLenLeft + nPadding + nLenRight ) > nMaxWidth )
    return;

  for( p = 0; p < nPadding; p ++ )
    pDest[ p + nLenLeft ] = ' ';

  pDest[ nPadding + nLenLeft ] = '\0';

  strcat( pDest, pItemRight );
}


//--------------------------------------------------------------------------------------------
// Normalise()
//--------------------------------------------------------------------------------------------
char Normalise( char c )
{
  if( ( c >= 'a' ) && ( c <= 'z' ) )
    return (char)(c - ('a' - 'A'));
  
  return c;
}


//--------------------------------------------------------------------------------------------
// IsDigit()                                                        
//--------------------------------------------------------------------------------------------
BOOL IsDigit( char b )
{
  return ( ( b >= '0' ) && ( b <= '9' ) );
}


//--------------------------------------------------------------------------------------------
// stristr()
//
// PDS: Case insensitive substring search..
//--------------------------------------------------------------------------------------------
char *stristr( char *pStringToSearch, char *pChunk )
{
  if( ! pStringToSearch )
    return NULL;
  
  int   nMatched    = 0;
  int   nChunkLen   = strlen( pChunk );
  int   nSearchLen  = strlen( pStringToSearch );
  char *pMatchStart = NULL;
  
  for( int i = 0; i < nSearchLen; i ++ )
  {
    if( nMatched >= nChunkLen )
      return pMatchStart;
    
    if( Normalise( pStringToSearch[ i ] ) == Normalise( pChunk[ nMatched ] ) )
    {
      if( ! pMatchStart )
        pMatchStart = &pStringToSearch[ i ];
      
      nMatched ++;
    }
    else
    {
      pMatchStart = NULL;
      nMatched    = 0;
    }
  }
  
  if( nMatched >= nChunkLen )
    return pMatchStart;
  
  return NULL;
}

//-----------------------------------------------------------------------------------------
// SubStrMatchAnyCase()
//
// PDS: Returns true if substring is matched case insensitively at the start of the big
//      string
//-----------------------------------------------------------------------------------------
BOOL SubStrMatchAnyCase( char *pBig, char *pSub )
{
  BOOL fMatch = FALSE;
  char *pB = pBig;
  char *pS = pSub;
  
  for( ;; )
  {
    if( *pS == 0 )
      break;
    
    if( *pB == 0 )
      return FALSE;
    
    if( Normalise( *pB ) == Normalise( *pS ) )
      fMatch = TRUE;
    else
    {
      fMatch = FALSE;
      break;
    }
    
    pS ++;
    pB ++;
  }
  
  return fMatch;
}

//-----------------------------------------------------------------------------------------
// ParseWordsIntoVector()
//-----------------------------------------------------------------------------------------
int ParseWordsIntoVector( char *pWords, Vector *pvSubStrings )
{
  char txCopy[ 1024 ];
  char txWord[ 1024 ];
  int  nWords = 0;
  
  strcpy( txCopy, pWords );
  
  char *p = txCopy;
  
  p = strtok( p, " " );
  
  for( ;; )
  {
    if( ! p )
      break;
    
    strcpy( txWord, p );
    
    pvSubStrings->addElement( txWord );
    nWords ++;
    
    p = strtok( NULL, " " );
  }
  
  return nWords;
}

//-----------------------------------------------------------------------------------------
// SubStrMatchAnyCaseMultiple()
//
// PDS: Returns true if first substring is matched case insensitively at the start of the big
//      string, then matches the subsequent strings.
//-----------------------------------------------------------------------------------------
BOOL SubStrMatchAnyCaseMultiple( char *pBig, Vector *pvSubstrings )
{
  int    nWords = pvSubstrings->elementCount();

  // PDS: Must match first word..
  if( ! SubStrMatchAnyCase( pBig, pvSubstrings->elementStrAt( 0 ) ) )
    return FALSE;
  
  // PDS: Now just need to find occurrence of any of the additional words - don't care what order..
  for( int w = 1; w < nWords; w ++ )
  {
    if( ! stristr( pBig, pvSubstrings->elementStrAt( w ) ) )
      return FALSE;
  }
  
  // PDS: If we get here then all of the words must have been matched..
  return TRUE;
}


//--------------------------------------------------------------------------------------------
// FileExists()
//
// PDS: We can't use stat() on iPhone because its case sensitive!!
//--------------------------------------------------------------------------------------------
BOOL FileExists( char *path )
{
  int   nLen = strlen( path );
  int   nIdx = nLen - 1;
  char  txFileOnly[ MAX_PATH ] = { 0 };
  char  txPathOnly[ MAX_PATH ] = { 0 };
  
  for( ;; )
  {
    if( nIdx <= 0 )
      return FALSE;

    char cTmp = path[ nIdx ];
    
    if( cTmp == '/' )
    {
      strcpy( txFileOnly, &path[ nIdx + 1 ] );
      path[ nIdx ] = 0;
      
      strcpy( txPathOnly, path );
      path[ nIdx ] = cTmp;
      break;
    }
    
    nIdx --;
  }
  
  LogDebugf( "FileExists(%s) File(%s) Path(%s)", path, txFileOnly, txPathOnly );
  
  if( txFileOnly[ 0 ] == 0 )
    return FALSE;

  if( txPathOnly[ 0 ] == 0 )
    strcpy( txPathOnly, g_DocumentsDirectory );

  Vector vFiles;
  
  [MyUtils findAllFilesInPath: [NSString stringWithUTF8String: txPathOnly]
                     populate: &vFiles];
  
  for( int i = 0; i < vFiles.elementCount(); i ++ )
  {
    char *pszFile = vFiles.elementStrAt( i );
  
    if( stricmp( pszFile, txFileOnly ) == 0 )
      return TRUE;
  }
  
  return FALSE;
}

//--------------------------------------------------------------------------------------------
// FileExistsInPath()
//--------------------------------------------------------------------------------------------
BOOL FileExistsInPath( char *pszPath, char *pszInsensFile, char *pszSensFile )
{
  Vector vFiles;
  
  [MyUtils findAllFilesInPath: [NSString stringWithUTF8String: pszPath]
                     populate: &vFiles];
              
  for( int i = 0; i < vFiles.elementCount(); i ++ )
  {
    char *pszFile = vFiles.elementStrAt( i );
    
    if( stricmp( pszFile, pszInsensFile ) == 0 )
    {
      strcpy( pszSensFile, pszFile );
      return TRUE;
    }
  }
  
  return FALSE;
}   
   
//--------------------------------------------------------------------------------------------
// FileSize()
//--------------------------------------------------------------------------------------------
long FileSize( char *s )
{
  struct stat st;
  
  memset( &st, 0, sizeof( st ) );
  
  stat( s, &st );
  
  return st.st_size;
}

//-------------------------------------------------------------------------------------------- 
// ClearVector()
// 
// PDS: Clears out a void* vector and its allocated node records
//-------------------------------------------------------------------------------------------- 
void ClearVector( Vector *pv )
{
  int   nNumNodes = pv->elementCount();
  void *pRecord;
  
  for( int i = 0; i < nNumNodes; i ++ )
  {
    pRecord = pv->elementPtrAt( i );
    
    if( pRecord )
      free( pRecord );
  }
  
  pv->removeAll();
}

//--------------------------------------------------------------------------------------------
// GetCSV()
//--------------------------------------------------------------------------------------------
int GetCSV( int nFieldIndex, char *pCommaList )
{
  return -1;
  /*  
   if( strlen( pCommaList ) < 2 )
   return -1;
   
   Vector vFields;
   
   ParseCommaListToVector( pCommaList, &vFields );
   
   if( nFieldIndex >= vFields.elementCount() )
   return -1;
   
   int n = atoi( vFields.elementStrAt( nFieldIndex ) );
   
   return n;
   */
}

//--------------------------------------------------------------------------------------------
// _strnicmp()
//--------------------------------------------------------------------------------------------
int _strnicmp( char *pStr1, char *pStr2, size_t Count )
{
  char c1, c2;
  int  v;
  
  if( Count == 0 )
    return 0;
  
  do 
  {
    c1 = *pStr1++;
    
    c2 = *pStr2++;
    
    // the casts are necessary when pStr1 is shorter & char is signed */
    v = (int) tolower(c1) - (int) tolower(c2);
    
  } while ((v == 0) && (c1 != '\0') && (--Count > 0));
  
  return v;
}

//--------------------------------------------------------------------------------------------
// SafeStrCpy()
//--------------------------------------------------------------------------------------------
void SafeStrCpy( char *pDest, char *pSrc )
{
  if( ( ! pSrc ) || ( ! pSrc[ 0 ] ) )
  {
    pDest[ 0 ] = 0;
    return;
  }
  
  strcpy( pDest, pSrc );
}

//--------------------------------------------------------------------------------------------
// Safe_atoi()
//--------------------------------------------------------------------------------------------
int Safe_atoi( char *p )
{
  if( ( ! p ) || ( ! p[ 0 ] ) )
    return 0;
  
  return atoi( p );
  
}

//--------------------------------------------------------------------------------------------
// Safe_atof()
//--------------------------------------------------------------------------------------------
float Safe_atof( char *p )
{
  if( ( ! p ) || ( ! p[ 0 ] ) )
    return 0;
  
  return (float) atof( p );
}


//--------------------------------------------------------------------------------------------
// TrimLastChar()
//--------------------------------------------------------------------------------------------
void TrimLastChar( char *pTxt, char c )
{
  if( ( ! pTxt ) || ( pTxt[ 0 ] == 0 ) )
    return;
  
  int nLen = strlen( pTxt );
  
  if( pTxt[ nLen - 1 ] == c )
    pTxt[ nLen - 1 ] = 0;
}


//----------------------------------------------------------------------------------------------------
// strtrim() - Trims trailing spaces from a string                
//----------------------------------------------------------------------------------------------------
void strtrim( char *s )
{
  int  index;
  int  length;
  BOOL bailed_out = FALSE;
  
  length = strlen( s );
  
  // Scan through for last non-space character.
  for( index = length - 1; index >= 0; index -- )
  {
    // If the current character is not a space, bail out here.
    // Also make sure that the next character is a null.
    if( s[ index ] != ' ' )
    {
      s[ index + 1 ] = '\0';
      bailed_out = TRUE;
      break;
    }
  }
  
  // If we made it all the way to the first index, we didn't null
  // terminate the string at any stage, so let's do it now.
  
  if( ! bailed_out )
    s[ 0 ] = '\0';
}

//-----------------------------------------------------------------------------------------
// ValidString()
//-----------------------------------------------------------------------------------------
BOOL ValidString( char *s )
{
  if( ! s )
    return FALSE;
  
  if( s[ 0 ] == 0 )
    return FALSE;
  
  return TRUE;
}

//-----------------------------------------------------------------------------------------
// GetFilenameOnly()
//-----------------------------------------------------------------------------------------
void GetFilenameOnly( char *txPath, char *txFilenameOnly )
{
  if( strchr( txPath, '/' ) )
  {
    int nLen = strlen( txPath );
    char *p  = txPath;
    
    for( int i = nLen - 1; i > 0; i -- )
    {
      if( txPath[ i ] == '/' )
      {
        p = &txPath[ i + 1 ];
        
        strcpy( txFilenameOnly, p ); 
        break;
      }
    }
  }
  else
  {
    strcpy( txFilenameOnly, txPath ); 
  }
}

//--------------------------------------------------------------------------------------------
// RemoveAllIn()
//--------------------------------------------------------------------------------------------
void RemoveAllIn( char *pDir )
{
  Vector vFiles;
  char   txFullPath[ MAX_PATH ];
  
  [MyUtils findAllFilesInPath: [NSString stringWithUTF8String: pDir] populate: &vFiles];
  
  for( int i = 0; i < vFiles.elementCount(); i ++ )
  {
    char *pFile = vFiles.elementStrAt( i );
    strcpy( txFullPath, pDir );
    strcat( txFullPath, "/" );
    strcat( txFullPath, pFile ); 
    remove( txFullPath );
  }
}

//--------------------------------------------------------------------------------------------
// GetZIPInnerFilenames()
//--------------------------------------------------------------------------------------------
void GetZIPInnerFilenames( char *pZipFile, Vector *pvFiles )
{
  // PDS: Use my faster method..
  ZipList( pZipFile, pvFiles );
  
  /* PDS: SLOW... old method..
	ZIPENTRY  ze; 
	ZRESULT   zr     = 0;
  HZIP      hz;
  
  pvFiles->removeAll();
  
  memset( &ze, 0, sizeof( ze ) );
  
  hz = OpenZip( pZipFile, 0, ZIP_FILENAME );

  for( int f = 0; ; f ++ )
  {
    // PDS: Make sure the zip file does contain at least one file..
    zr = GetZipItemA( hz, f, &ze );
    
    // PDS: Get out if no more files..
    if( zr != 0 )
      break;
    
    pvFiles->addElement( ze.name );
  }
  
  CloseZip( hz );
  */
}


//--------------------------------------------------------------------------------------------
// UnzipAllFilesBody()
//--------------------------------------------------------------------------------------------
BOOL UnzipAllFilesBody( char *pZipFile, char *pDestFolder, Vector *pvInnerFiles )
{
	ZIPENTRY  ze; 
	ZRESULT   zr     = 0;
  HZIP      hz;
  char      txZipFullPath[ MAX_PATH ];
    
  if( pvInnerFiles )
    pvInnerFiles->removeAll();
  
  strcpy( txZipFullPath, pZipFile );
  
  memset( &ze, 0, sizeof( ze ) );
    
  hz = OpenZip( txZipFullPath, 0, ZIP_FILENAME );
  
  for( int f = 0; ; f ++ )
  {
    // PDS: Make sure the zip file does contain at least one file..
    zr = GetZipItemA( hz, f, &ze );
    
    // PDS: Get out if no more files..
    if( zr != 0 )
      break;
    
    /* PDS: Windows only..
    for( WORD i = 0; i < strlen( ze.name ); i ++ )
    {
      if( ze.name[ i ] == '/' )
        ze.name[ i ] = '\\';
    }
    */
    
    if( pvInnerFiles )
      pvInnerFiles->addElement( ze.name );
    
    // PDS: Forcibly remove the resulting file if it already exists..
    if( FileExists( ze.name ) )
      remove( ze.name );
    
    // PDS: Unzip to g_DstPath..
	  zr = UnzipItem( hz, f, ze.name, 0, ZIP_FILENAME );    
  }
  
  CloseZip( hz );
    
  return TRUE;
}

//--------------------------------------------------------------------------------------------
// UnzipAllFiles()
//--------------------------------------------------------------------------------------------
BOOL UnzipAllFiles( char *pZipFile, char *pDestFolder )
{
  return UnzipAllFilesBody( pZipFile, pDestFolder, NULL );
}

//--------------------------------------------------------------------------------------------
// UnzipGetInnerFilename()
//--------------------------------------------------------------------------------------------
BOOL UnzipGetInnerFilename( char *txFullUnzipPath, char *txUnzipPath, char *txInnerFilename )
{
  Vector vFiles;
  BOOL   rc;
  
  rc = UnzipAllFilesBody( txFullUnzipPath, txUnzipPath, &vFiles );
  
  if( vFiles.elementCount() > 0 )
    strcpy( txInnerFilename, vFiles.elementStrAt( 0 ) );
  
  return rc;
}

//--------------------------------------------------------------------------------------------
// UnzipFileInZip()
//--------------------------------------------------------------------------------------------
void UnzipFileInZip( char *txFullUnzipPath, char *txDestFolder, char *txInnerFilename )
{
  ZIPENTRY  ze; 
  ZRESULT   zr     = 0;
  HZIP      hz;
  int       nIndex;
  
  memset( &ze, 0, sizeof( ze ) );

  LogDebugf( "UNZIP Open[%s]", txFullUnzipPath );
  
  hz = OpenZip( txFullUnzipPath, 0, ZIP_FILENAME );
  
  if( ! hz )
  {
    LogDebugf( "** UNZIP FAIL(1)" );
    return;
  }
  
  zr = FindZipItem( hz, txInnerFilename, TRUE, &nIndex, &ze );

  if( zr == 0 )
  {
    char txFilenameOnly[ MAX_PATH ];
    char txDestFile    [ MAX_PATH ];
    
    GetFilenameOnly( txInnerFilename, txFilenameOnly );

    sprintf( txDestFile, "%s/%s", txDestFolder, txFilenameOnly );
    
    LogDebugf( "Found1[%s] -> [%s]", ze.name, txDestFile );

    // PDS: Forcibly remove the resulting file if it already exists..
    if( FileExists( txDestFile ) )
      remove( txDestFile );
    
    // PDS: Unzip will automatically put file in Unzip folder..
    zr = UnzipItem( hz, nIndex, txFilenameOnly, 0, ZIP_FILENAME ); 
  }
  
  CloseZip( hz );
}

//-----------------------------------------------------------------------------------------
// LoadSectionHeadingVector()
//-----------------------------------------------------------------------------------------
void LoadSectionHeadingVector( Vector *pvSectionHeadings, Vector pvAlphaSectionedList[] )
{
  if( pvAlphaSectionedList[ 0 ].elementCount() > 0 )
    pvSectionHeadings->addElement( "0" );
  
  char txHeading[ 20 ];
  
  for( int i = 0; i < 26; i ++ )
  {
    if( pvAlphaSectionedList[ 1 + i ].elementCount() < 1 )
      continue;
    
    txHeading[ 0 ] = 'A' + i;
    txHeading[ 1 ] = 0;
    
    pvSectionHeadings->addElement( txHeading );
  }
  
  if( pvAlphaSectionedList[ MAX_ALPHA_SECTIONS - 1 ].elementCount() > 0 )
    pvSectionHeadings->addElement( "#" );
}

//-----------------------------------------------------------------------------------------
// ClearAlphaSectionedVector()
//-----------------------------------------------------------------------------------------
void ClearAlphaSectionedVector( Vector pvAlphaSectionedList[] )
{
  for( int i = 0; i < MAX_ALPHA_SECTIONS; i ++ )
    pvAlphaSectionedList[ i ].removeAll();
}

//-----------------------------------------------------------------------------------------
// Full28IndexFromChar()
//-----------------------------------------------------------------------------------------
int Full28IndexFromChar( char c )
{
  char cUppCaseStart = c;
  
  // PDS: Convert char to upper case..
  if( ( cUppCaseStart >= 'a' ) && ( cUppCaseStart <= 'z' ) )
    cUppCaseStart = cUppCaseStart - ( 'a' - 'A' );
  
  // PDS: Decide which vector we're going to add the item to - 0, A, B, C etc... # (for all other items)
  if( ( cUppCaseStart >= 'A' ) && ( cUppCaseStart <= 'Z' ) )
    return 1 + cUppCaseStart - 'A';
  
  if( ( cUppCaseStart >= '0' ) && ( cUppCaseStart <= '9' ) )
    return 0;
  
  return MAX_ALPHA_SECTIONS - 1;
}

//-----------------------------------------------------------------------------------------
// PopulateAlphaSectionedVector()
//
// PDS: Helper function for grouped/indexed UITableViews - this one expects 28 sections
//      consisting of 0, A,B,C etc and # for other characters.
//-----------------------------------------------------------------------------------------
void PopulateAlphaSectionedVector( Vector pvAlphaSectionedList[], Vector *pvItems, Vector *pvIndices )
{
  Vector *pvCurrSection;  
  char   *pszItem;
  char    cUppCaseStart;
  
  for( int i = 0; i < pvItems->elementCount(); i ++ )
  {
    pszItem = pvItems->elementStrAt( i );
    
    cUppCaseStart = pszItem[ 0 ];
    
    // PDS: Convert char to upper case..
    if( ( cUppCaseStart >= 'a' ) && ( cUppCaseStart <= 'z' ) )
      cUppCaseStart = cUppCaseStart - ( 'a' - 'A' );
    
    // PDS: Decide which vector we're going to add the item to - 0, A, B, C etc... # (for all other items)
    if( ( cUppCaseStart >= 'A' ) && ( cUppCaseStart <= 'Z' ) )
      pvCurrSection = &pvAlphaSectionedList[ 1 + cUppCaseStart - 'A' ];
    else
    if( ( cUppCaseStart >= '0' ) && ( cUppCaseStart <= '9' ) )
      pvCurrSection = &pvAlphaSectionedList[ 0 ];
    else
      pvCurrSection = &pvAlphaSectionedList[ MAX_ALPHA_SECTIONS - 1 ];
    
    pvCurrSection->addElement( pszItem );
    
    if( pvIndices )
    {
      int nAddedIdx = pvCurrSection->elementCount() - 1;
      int nLibIndex = pvIndices->elementIntAt( i );
      
      // PDS: Set the secondary element.. this means our index will be sorted with the string ;-)
      pvCurrSection->setSecondaryAt( nAddedIdx, (void*) nLibIndex );
    }
  }
  
  for( int s = 0; s < MAX_ALPHA_SECTIONS; s ++ )
  {  
    pvCurrSection = &pvAlphaSectionedList[ s ];    
    pvCurrSection->sortStrAscending();
  }
}

//-----------------------------------------------------------------------------------------
// SecondsNow()
//-----------------------------------------------------------------------------------------
long SecondsNow( void )
{
  return (long) time( NULL );
}

//-----------------------------------------------------------------------------------------
// SecondsElapsed()
//-----------------------------------------------------------------------------------------
long SecondsElapsed( long lStart )
{
  return (long) time( NULL ) - lStart;
}

//--------------------------------------------------------------------------------------------------------
// AddDWORD()
//
// Adds a DWORD at the specified location and returns an incremented pointer
// Maintains the LO-HI byte ordering that Intel loves to much
//--------------------------------------------------------------------------------------------------------
BYTE *AddDWORD( BYTE *ptr, DWORD dw )
{
  BYTE b1, b2, b3, b4;
  
  b4 = (BYTE)((dw & 0xff000000) >> 24);
  b3 = (BYTE)((dw & 0x00ff0000) >> 16);
  b2 = (BYTE)((dw & 0x0000ff00) >>  8);
  b1 = (BYTE) (dw & 0x000000ff) ;
  
  *ptr ++ = b1;
  *ptr ++ = b2;
  *ptr ++ = b3;
  *ptr ++ = b4;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// AddWORD()
//
// Adds a WORD at the specified location and returns an incremented pointer
// Maintains the LO-HI byte ordering that Intel loves to much
//--------------------------------------------------------------------------------------------------------
BYTE *AddWORD( BYTE *ptr, WORD w )
{
  BYTE b1, b2;
  
  b2 = (BYTE)((w & 0xff00) >> 8);
  b1 = (BYTE) (w & 0x00ff) ;
  
  *ptr ++ = b1;
  *ptr ++ = b2;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// AddBYTE()
//
// Adds a BYTE at the specified location and returns an incremented pointer
//--------------------------------------------------------------------------------------------------------
BYTE *AddBYTE( BYTE *ptr, BYTE b )
{
  *ptr ++ = b;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// AddString()
//--------------------------------------------------------------------------------------------------------
BYTE *AddString( BYTE *ptr, char *s, BOOL fIncludeNull )
{
  int nLen = strlen( s );
  
  if( fIncludeNull )
    nLen ++;
  
  memcpy( ptr, s, nLen );
  ptr += nLen;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// AddData()
//--------------------------------------------------------------------------------------------------------
BYTE *AddData( BYTE *ptr, BYTE *pData, DWORD dwLen )
{
  memcpy( ptr, pData, dwLen );
  ptr += dwLen;
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// GetDWORD()
//--------------------------------------------------------------------------------------------------------
BYTE *GetDWORD( BYTE *ptr, DWORD *dw )
{
  DWORD dwTemp = 0;
  BYTE b1, b2, b3, b4;
  
  // PDS: DWORDs are stored in LO-HI byte ordering that Intel loves to much..
  
  b1 = *ptr ++;
  b2 = *ptr ++;
  b3 = *ptr ++;
  b4 = *ptr ++;
  
  dwTemp |= (DWORD)  b1;
  dwTemp |= (DWORD) (b2 <<  8);
  dwTemp |= (DWORD) (b3 << 16);
  dwTemp |= (DWORD) (b4 << 24);
  
  (*dw) = dwTemp;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// GetWORD()
//--------------------------------------------------------------------------------------------------------
BYTE *GetWORD( BYTE *ptr, WORD *w )
{
  WORD wTemp = 0;
  BYTE b1, b2;
  
  // PDS: WORDs are stored in LO-HI byte ordering that Intel loves to much..
  b1 = *ptr ++;
  b2 = *ptr ++;
  
  wTemp |= (DWORD)  b1;
  wTemp |= (DWORD) (b2 <<  8);
  
  (*w) = wTemp;
  
  return ptr;
}


//--------------------------------------------------------------------------------------------------------
// GetBYTE()
//--------------------------------------------------------------------------------------------------------
BYTE *GetBYTE( BYTE *ptr, BYTE *b )
{
  // PDS: WORDs are stored in LO-HI byte ordering that Intel loves to much..
  (*b) = *ptr ++;
  
  return ptr;
}

//--------------------------------------------------------------------------------------------------------
// GetString()
//
// PDS: Use at your peril - this assumes that the string *IS* null terminated!!!
//--------------------------------------------------------------------------------------------------------
BYTE *GetString( BYTE *ptr, char *s, BOOL fIncludeNull )
{
  char *pStr = (char*) ptr;
  int   nLen = strlen( pStr );
  
  if( fIncludeNull )
    nLen ++;
  
  memcpy( s, ptr, nLen );
  ptr += nLen;
  
  return ptr;
}

//--------------------------------------------------------------------------------------------------------
// GetData()
//--------------------------------------------------------------------------------------------------------
BYTE *GetData( BYTE *ptr, BYTE *pData, DWORD dwLen )
{
  memcpy( pData, ptr, dwLen );
  ptr += dwLen;
  return ptr;
}

//-----------------------------------------------------------------------------------------
// DrawFilledRoundedRect()
//-----------------------------------------------------------------------------------------
void DrawFilledRoundedRect( CGContext *context, CGRect rect, int radius )
{
  CGContextMoveToPoint( context, rect.origin.x, rect.origin.y + radius);
  CGContextAddLineToPoint( context, rect.origin.x, rect.origin.y + rect.size.height - radius);
  CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                  radius, M_PI, M_PI / 2, 1); //STS fixed
  CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius,
                          rect.origin.y + rect.size.height);
  CGContextAddArc(context, rect.origin.x + rect.size.width - radius,
                  rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
  CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
  CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                  radius, 0.0f, -M_PI / 2, 1);
  CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
  CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius,
                  -M_PI / 2, M_PI, 1);
  
  CGContextFillPath( context );
}

//-----------------------------------------------------------------------------------------
// DrawRoundedRect()
//-----------------------------------------------------------------------------------------
void DrawRoundedRect( CGContext *context, CGRect rect, int radius )
{
  CGContextMoveToPoint( context, rect.origin.x, rect.origin.y + radius);
  CGContextAddLineToPoint( context, rect.origin.x, rect.origin.y + rect.size.height - radius);
  CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                  radius, M_PI, M_PI / 2, 1); //STS fixed
  CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius,
                          rect.origin.y + rect.size.height);
  CGContextAddArc(context, rect.origin.x + rect.size.width - radius,
                  rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
  CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
  CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                  radius, 0.0f, -M_PI / 2, 1);
  CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
  CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius,
                  -M_PI / 2, M_PI, 1);
  
  CGContextStrokePath( context );
}


