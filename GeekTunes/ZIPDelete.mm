//--------------------------------------------------------------------------------------------
// MODULE:      ZIPDelete.cpp
//
// AUTHOR:      Paul D. Spark
//
// DESCRIPTION: ZIP file deletion functions
//--------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

#include "Common.h"
#include "MyTypes.h"
#include "vector.h"
#include "Utils.h"
#include "PaulPlayer.h"

#include <stdio.h>
#include <time.h>

#include "ZIPDelete.h"

static BYTE  g_ReadBuffer[ 5000000 ];
static long  g_ZipSize   = 0;
static FILE *g_fZip      = NULL;
static char  g_txZipFileIn [ MAX_PATH ];
static char  g_txZipFileOut[ MAX_PATH ] = "ZIPDelete.tmp";

// PDS: The vectors below are for files which are going to be deleted..
static Vector g_vLocFileHdrOffset;
static Vector g_vLocFileAndHdrLen;
static Vector g_vCentralDirRecOffset;
static Vector g_vCentralDirRecLen;

// PDS: The vectors below are for the complete set of OLD files..
static Vector g_vOldLocFileHdrOffset;
static Vector g_vOldLocFileAndHdrLen;
static Vector g_vOldCentralDirRecOffset;
static Vector g_vOldCentralDirRecLen;
static Vector g_vOldFileName;

static Vector g_vOldCentralDirRecords;

static Vector g_vNewLocFileHdrOffsetFromOld;
static Vector g_vNewLocFileHdrOffset;
static Vector g_vNewLocFileAndHdrLen;
static Vector g_vNewCentralDirRecOffset;
static Vector g_vNewCentralDirRecLen;
static Vector g_vNewCentralDirRecords;

static Vector *g_pvFilesToDelete = NULL;

ZCENTRALDIRHEADER  g_zCentralDirHdr;
ZENDCENTRALDIR     g_zCentralDirEnd;
ZLOCALFILEHEADER   g_zLocFileHdr;

DWORD  g_dwCentralDirSize        = 0;
DWORD  g_dwCentralDirOffset      = 0;
WORD   g_wCentralDirTotalEntries = 0;
WORD   g_wCentralDirCommentLen   = 0;

WORD   g_wGeneralPurposeBits     = 0;

#define SIG_CENTRAL_DIR_HDR 0x02014b50
#define SIG_LOCAL_FILE_HDR  0x04034b50
#define SIG_DIGITAL_SIG     0x05054b50
#define SIG_CENTRAL_DIR_END 0x06054b50


//--------------------------------------------------------------------------------------------------------
// LMBackFind()
//--------------------------------------------------------------------------------------------------------
long LMBackFind( BYTE *pItemToFind, int nItemLen )
{
  long lOffset;
  long lOffsetFound = -1;

  for( ;; )
  {
    lOffset = ftell( g_fZip );

    //printf( "lOffset: %ld 0x%08lx\n", lOffset, lOffset );

    if( lOffset < nItemLen )
      break;

    int nSeekAmount;

    // PDS: Skip back to next potential position..
    if( g_ZipSize - lOffset < nItemLen )
      nSeekAmount = nItemLen;
    else
      nSeekAmount = 1;

    if( fseek( g_fZip, -nSeekAmount, SEEK_CUR ) )
    {
      //printf( "fseek() failed\n" );
      break;
    }

    lOffset = ftell( g_fZip );

    int nRead = (int) fread( g_ReadBuffer, 1, nItemLen, g_fZip );

    //printf( "fread: %ld\n", nRead );

    if( nRead < nItemLen )
      break;

    if( memcmp( pItemToFind, g_ReadBuffer, nItemLen ) == 0 )
    {
      // PDS: Found what we want.. return offset..
      lOffsetFound = lOffset;
      break;
    }

    // PDS: Rewind what we just read..
    if( fseek( g_fZip, -nItemLen, SEEK_CUR ) )
    {
      //printf( "fseek() failed\n" );
      break;
    }
  }
  
  return lOffsetFound;
}

//--------------------------------------------------------------------------------------------------------
// ReadCentralDirAtOffset()
//--------------------------------------------------------------------------------------------------------
long ReadCentralDirAtOffset( long lSigOffset, ZCENTRALDIRHEADER *pzCentralDirRec )
{
  fseek( g_fZip, lSigOffset, SEEK_SET );
  fread( pzCentralDirRec, 1, sizeof( ZCENTRALDIRHEADER ), g_fZip );

  return 0;
}

//--------------------------------------------------------------------------------------------------------
// ReadCentralEndAtOffset()
//--------------------------------------------------------------------------------------------------------
long ReadCentralEndAtOffset( long lSigOffset, ZENDCENTRALDIR *pzCentralDirEnd )
{
  fseek( g_fZip, lSigOffset, SEEK_SET );
  fread( pzCentralDirEnd, 1, sizeof( ZENDCENTRALDIR ), g_fZip );

  return 0;
}

//--------------------------------------------------------------------------------------------------------
// BackFindCentralDirEnd()
//--------------------------------------------------------------------------------------------------------
long BackFindCentralDirEnd( long *plCentralEndRecSize )
{
  long lOffset = -1;
  long lCentralEndSigOffset;

  // PDS: Go to end of file..
  fseek( g_fZip, 0, SEEK_END );

  lOffset = ftell( g_fZip );
  
  if( lOffset < sizeof( SIG_CENTRAL_DIR_END ) )
    return 0;

  BYTE abSig[ 4 ];

  AddDWORD( abSig, SIG_CENTRAL_DIR_END );

  lCentralEndSigOffset = LMBackFind( abSig, sizeof( abSig ) );

  if( lCentralEndSigOffset < 0 )
    return 0;

  ReadCentralEndAtOffset( lCentralEndSigOffset, &g_zCentralDirEnd );

  GetDWORD( g_zCentralDirEnd.centralDirSize,   &g_dwCentralDirSize );
  GetDWORD( g_zCentralDirEnd.centralDirOffset, &g_dwCentralDirOffset );
  GetWORD(  g_zCentralDirEnd.numEntriesTotal,  &g_wCentralDirTotalEntries );
  GetWORD(  g_zCentralDirEnd.commentLength,    &g_wCentralDirCommentLen );

  //printf( "Central Dir Size   (from end record): %8ld\n", g_dwCentralDirSize );
  //printf( "Central Dir Offset (from end record): %8ld\n", g_dwCentralDirOffset );
  //printf( "Central Total Entries               : %8d\n",  g_wCentralDirTotalEntries );
  //printf( "Zip Comment Len                     : %8d\n",  g_wCentralDirCommentLen );

  (*plCentralEndRecSize) = sizeof( ZENDCENTRALDIR ) + g_wCentralDirCommentLen;

  return lCentralEndSigOffset;
}

//--------------------------------------------------------------------------------------------------------
// ProcessZipLowMemory()
//--------------------------------------------------------------------------------------------------------
void ProcessZipLowMemory( void )
{
  g_fZip    = fopen( g_txZipFileIn, "rb" );

  long lCentralDirEndOffset = 0;
  long lEndRecordLen        = 0;
  int  i;

  lCentralDirEndOffset = BackFindCentralDirEnd( &lEndRecordLen );

  //printf( "End Rec Len: %8ld\n", lEndRecordLen );

  // PDS: Should be pointing to start of central dir records..
  long lNextCentralOffset = g_dwCentralDirOffset;

  LogDebugf( "g_wCentralDirTotalEntries: %ld", (long) g_wCentralDirTotalEntries );

  DWORD dwLocalOffset    = 0;
  DWORD dwCompressedSize = 0;
  WORD  wFilenameLen     = 0;
  WORD  wExtraLen        = 0;
  WORD  wCommentLen      = 0;
  long  lCentralRecSize  = 0;
  char  txFilename[ MAX_PATH ];
  long  lLocalHeaderSize;

  // PDS: Go to first central dir record..
  fseek( g_fZip, lNextCentralOffset, SEEK_SET );
  
  // PDS: Now build a complete list of old file data..
  for( int r = 0; r < g_wCentralDirTotalEntries; r ++ )
  {
    if( r % 1000 == 0 )
      LogDebugf( "%5d processed..", r );
   
    //g_vOldCentralDirRecOffset.addElement( ftell( g_fZip ) );
    g_vOldCentralDirRecOffset.addElement( lNextCentralOffset );

    // PDS: Read central dir record..
    fread( &g_zCentralDirHdr, 1, sizeof( ZCENTRALDIRHEADER ), g_fZip );
    
    lNextCentralOffset += sizeof( ZCENTRALDIRHEADER );

    GetDWORD( g_zCentralDirHdr.offsetLocalHeader, &dwLocalOffset );
    //GetDWORD( g_zCentralDirHdr.compressedSize,    &dwCompressedSize );
    GetWORD(  g_zCentralDirHdr.filenameLength,    &wFilenameLen );
    GetWORD(  g_zCentralDirHdr.extraFieldLength,  &wExtraLen );
    GetWORD(  g_zCentralDirHdr.commentLength,     &wCommentLen );
    
    lCentralRecSize = (long) ( sizeof( ZCENTRALDIRHEADER ) 
                                   + wFilenameLen 
                                   + wExtraLen 
                                   + wCommentLen );

    g_vOldCentralDirRecLen.addElement( lCentralRecSize );

    ZCENTRALDIRHEADER *pRec  = (ZCENTRALDIRHEADER *) malloc( lCentralRecSize );
    BYTE              *pbRec = (BYTE *) pRec;

    memcpy( pRec, &g_zCentralDirHdr, sizeof( ZCENTRALDIRHEADER ) );
    fread( &pbRec[ sizeof( ZCENTRALDIRHEADER ) ], 1, lCentralRecSize - sizeof( ZCENTRALDIRHEADER ), g_fZip );

    lNextCentralOffset += lCentralRecSize - sizeof( ZCENTRALDIRHEADER );
    
    char *pFilename = (char *) &pbRec[ sizeof( ZCENTRALDIRHEADER ) ];

    memcpy( txFilename, pFilename, wFilenameLen );
    txFilename[ wFilenameLen ] = 0;

    g_vOldFileName.addElement( txFilename );

    g_vOldCentralDirRecords.addElement( (void *) pRec );
    g_vOldLocFileHdrOffset.addElement( dwLocalOffset );
  }

  WORD  wExtraFieldLen   = 0;
  long  lLocalOffset;
  long  lCurrentPosn = 0;
  long  lDistanceToMove;
  
  fseek( g_fZip, 0, SEEK_SET );
  
  for( i = 0; i < g_vOldCentralDirRecords.elementCount(); i ++ )
  {
    if( i % 1000 == 0 )
      LogDebugf( "Central %5d processed..", i );
    
    lLocalOffset    = g_vOldLocFileHdrOffset.elementIntAt( i );
    
    lDistanceToMove = lLocalOffset - lCurrentPosn;
    
    fseek( g_fZip, lDistanceToMove, SEEK_CUR );
    lCurrentPosn += lDistanceToMove;
    
    int nRead = (int) fread( &g_zLocFileHdr, 1, sizeof( ZLOCALFILEHEADER ), g_fZip );
    
    if( nRead < sizeof( ZLOCALFILEHEADER ) )
      break;
    
    lCurrentPosn += sizeof( ZLOCALFILEHEADER );
    
    GetWORD( g_zLocFileHdr.filenameLength,     &wFilenameLen );
    GetWORD( g_zLocFileHdr.extraFieldLength,   &wExtraFieldLen );
    GetDWORD( g_zLocFileHdr.compressedSize,    &dwCompressedSize );
    
    //GetWORD( g_zLocFileHdr.generalPurposeBits, &g_wGeneralPurposeBits );
    
    lLocalHeaderSize = sizeof( ZLOCALFILEHEADER ) + (long) wFilenameLen + (long) wExtraFieldLen;
    
    g_vOldLocFileAndHdrLen.addElement( lLocalHeaderSize + dwCompressedSize );
  }

  fclose( g_fZip );
}

//--------------------------------------------------------------------------------------------------------
// BufferedCopy()
//--------------------------------------------------------------------------------------------------------
void BufferedCopy( FILE *fOut, long lOffset, long lSize )
{
  long lRemaining = lSize;
  long lChunkSize;
  long lRead;

  fseek( g_fZip, lOffset, SEEK_SET );

  while( lRemaining > 0 )
  {
    if( lRemaining > sizeof( g_ReadBuffer ) )
      lChunkSize = sizeof( g_ReadBuffer );
    else
      lChunkSize = lRemaining;

    lRead = fread( g_ReadBuffer, 1, lChunkSize, g_fZip );

    if( lRead > 0 )
      lRemaining -= lRead;
    else
      break;

    fwrite( g_ReadBuffer, 1, lRead, fOut );
  }
}

//--------------------------------------------------------------------------------------------------------
// ZIPDelete()
//--------------------------------------------------------------------------------------------------------
void ZIPDelete( char *pZipFilename, Vector *pvFilesToDelete )
{
  g_pvFilesToDelete = pvFilesToDelete;

  strcpy( g_txZipFileIn, pZipFilename );

  g_ZipSize = FileSize( g_txZipFileIn );

  if( g_ZipSize < 1 )
    return;

  //DWORD dwStart = ::GetTickCount();

  // PDS: Parse ZIP file with buffer (lower memory)..
  ProcessZipLowMemory();

  //printf( "Took %ld seconds\n", ( ::GetTickCount() - dwStart ) / 1000 );

  int nOldFileCount  = g_wCentralDirTotalEntries;

  long lNewOffset   = 0;
  long lOldOffset   = 0;

  int  i;

  LogDebugf( "Calc local hdr stuff.." );
  
  // PDS: Add local file header details..
  for( i = 0; i < nOldFileCount; i ++ )
  {
    // PDS: Also mark which ones are to be removed..
    char *pOldFile = g_vOldFileName.elementStrAt( i );

    long lOldFileAndHdrLen    = g_vOldLocFileAndHdrLen.elementIntAt( i );
    long lOldCentralDirRecLen = g_vOldCentralDirRecLen.elementIntAt( i );

    // PDS: Don't add if deleting..
    if( g_pvFilesToDelete->contains( pOldFile ) )
    {
      lOldOffset += lOldFileAndHdrLen;
      continue;
    }

    //printf( "Old file: %s  (New) LocOffset: %8ld (0x%06lx)\n", pOldFile, lNewOffset, lNewOffset );

    g_vNewLocFileHdrOffsetFromOld.addElement( lOldOffset );
    g_vNewLocFileHdrOffset.addElement( lNewOffset );
    g_vNewLocFileAndHdrLen.addElement( lOldFileAndHdrLen );

    lOldOffset += lOldFileAndHdrLen;
    lNewOffset += lOldFileAndHdrLen;

    g_vNewCentralDirRecLen.addElement( lOldCentralDirRecLen );

    ZCENTRALDIRHEADER *pRec = (ZCENTRALDIRHEADER *) g_vOldCentralDirRecords.elementPtrAt( i );

    // PDS: Copy pointer to old record only.. I'll modify them since I've already allocated them..
    g_vNewCentralDirRecords.addElement( (void *) pRec );
  }

  LogDebugf( "Calc central local hdr stuff.." );
  
  WORD  wNewCount          = g_vNewLocFileHdrOffset.elementCount();
  DWORD dwCentralDirOffset = lNewOffset;
  DWORD dwCentralDirSize   = 0;

  // PDS: Now add central dir values.. 
  for( int nf = 0; nf < wNewCount; nf ++ )
  {
    g_vNewCentralDirRecOffset.addElement( lNewOffset );

    long lNewCentralDirRecLen = g_vNewCentralDirRecLen.elementIntAt( nf );

    lNewOffset += lNewCentralDirRecLen;

    // PDS: Update central dir records themselves..
    ZCENTRALDIRHEADER *pRec = (ZCENTRALDIRHEADER *) g_vNewCentralDirRecords.elementPtrAt( nf );

    DWORD dwLocalHeaderOffset = g_vNewLocFileHdrOffset.elementIntAt( nf );

    // PDS: Update the important stuff - offsets ..
    AddDWORD( pRec->offsetLocalHeader, dwLocalHeaderOffset );
  }

  dwCentralDirSize = lNewOffset - dwCentralDirOffset;

  // PDS: Now do End Record..
  AddWORD( g_zCentralDirEnd.numEntriesThisDisk, wNewCount );
  AddWORD( g_zCentralDirEnd.numEntriesTotal,    wNewCount );

  AddDWORD( g_zCentralDirEnd.centralDirOffset,  dwCentralDirOffset );
  AddDWORD( g_zCentralDirEnd.centralDirSize,    dwCentralDirSize );
  
  LogDebugf( "Start writing new ZIP.." );
  
  MakeDocumentsPath( "ZIPDelete.tmp", g_txZipFileOut );
  
  // PDS: OK, now lets copy a new .ZIP, minus deleted chunks..
  FILE *op = fopen( g_txZipFileOut, "wb" );
  
  g_fZip    = fopen( g_txZipFileIn, "rb" );

  long lReadStart;
  long lSize;
  
  // PDS: Copy local header and file content..
  for( i = 0; i < wNewCount; i ++ )
  {
    // PDS: Get offset within the old file for reading..
    lReadStart = g_vNewLocFileHdrOffsetFromOld.elementIntAt( i );
    lSize      = g_vNewLocFileAndHdrLen.elementIntAt( i );

    BufferedCopy( op, lReadStart, lSize );
  }

  LogDebugf( "Local headers written.." );
  
  for( i = 0; i < wNewCount; i ++ )
  {
    ZCENTRALDIRHEADER *pRec = (ZCENTRALDIRHEADER *) g_vNewCentralDirRecords.elementPtrAt( i );

    lSize   = g_vNewCentralDirRecLen.elementIntAt( i );

    fwrite( pRec, 1, lSize, op );

    //printf( "(CEN) Write                Out @ 0x%08lx -> %ld bytes [%s]\n", lOffsetOut, lSize, txFileName );
  }

  LogDebugf( "Central headers written.." );
  
  //printf( "(END) Write                Out @ 0x%08lx -> %ld bytes\n", lOffsetOut, sizeof( g_zCentralDirEnd ) );

  fwrite( &g_zCentralDirEnd, 1, sizeof( g_zCentralDirEnd ), op );

  fclose( g_fZip );
  fclose( op );

  LogDebugf( "Done. Freeing mem.." );
  
  // PDS: Free up memory..
  for( i = 0; i < g_vOldCentralDirRecords.elementCount(); i ++ )
  {
    BYTE *p = (BYTE *) g_vOldCentralDirRecords.elementPtrAt( i );
    free( p );
  }

  // PDS: Replace original zip file..
  remove( g_txZipFileIn );
  rename( g_txZipFileOut, g_txZipFileIn );
}

//--------------------------------------------------------------------------------------------------------
// ZipList()
//--------------------------------------------------------------------------------------------------------
void ZipList( char *pZipFile, Vector *pvFiles )
{
  pvFiles->removeAll();
  
  g_ZipSize = FileSize( pZipFile );
  
  if( g_ZipSize < 1 )
    return;
  
  g_fZip    = fopen( pZipFile, "rb" );
  
  // PDS: Parse ZIP file with buffer (lower memory)..
  BYTE abDummy[ 65536 ];
  
  long lCentralDirEndOffset = 0;
  long lEndRecordLen        = 0;
  
  lCentralDirEndOffset = BackFindCentralDirEnd( &lEndRecordLen );
  
  // PDS: Should be pointing to start of central dir records..
  long lNextCentralOffset = g_dwCentralDirOffset;
  
  WORD  wFilenameLen     = 0;
  WORD  wExtraLen        = 0;
  WORD  wCommentLen      = 0;
  long  lCentralRecSize  = 0;
  char  txFilename[ MAX_PATH ];
  
  // PDS: Go to first central dir record..
  fseek( g_fZip, lNextCentralOffset, SEEK_SET );
  
  // PDS: Now build a complete list of old file data..
  for( int r = 0; r < g_wCentralDirTotalEntries; r ++ )
  {
    //if( r % 1000 == 0 )
    //  printf( "%5d processed..\r", r );
    
    g_vOldCentralDirRecOffset.addElement( lNextCentralOffset );
    
    // PDS: Read central dir record..
    fread( &g_zCentralDirHdr, 1, sizeof( ZCENTRALDIRHEADER ), g_fZip );
    
    lNextCentralOffset += sizeof( ZCENTRALDIRHEADER );
    
    //GetDWORD( g_zCentralDirHdr.compressedSize,    &dwCompressedSize );
    GetWORD(  g_zCentralDirHdr.filenameLength,    &wFilenameLen );
    GetWORD(  g_zCentralDirHdr.extraFieldLength,  &wExtraLen );
    GetWORD(  g_zCentralDirHdr.commentLength,     &wCommentLen );
    
    lCentralRecSize = (long) ( sizeof( ZCENTRALDIRHEADER )
                              + wFilenameLen
                              + wExtraLen
                              + wCommentLen );
    
    BYTE              *pbRec = (BYTE *) abDummy;
    
    fread( &pbRec[ sizeof( ZCENTRALDIRHEADER ) ], 1, lCentralRecSize - sizeof( ZCENTRALDIRHEADER ), g_fZip );
    
    lNextCentralOffset += lCentralRecSize - sizeof( ZCENTRALDIRHEADER );
    
    char *pFilename = (char *) &pbRec[ sizeof( ZCENTRALDIRHEADER ) ];
    
    memcpy( txFilename, pFilename, wFilenameLen );
    txFilename[ wFilenameLen ] = 0;
    
    pvFiles->addElement( txFilename );
  }
  
  fclose( g_fZip );
  
  //printf( "Took %ld seconds\n", ( ::GetTickCount() - dwStart ) / 1000 );
}