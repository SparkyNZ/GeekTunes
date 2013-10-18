//--------------------------------------------------------------------------------------------
// MODULE:      ZIPDelete.h
//
// AUTHOR:      Paul D. Spark
//
// DESCRIPTION: ZIP file deletion functions
//--------------------------------------------------------------------------------------------

#ifndef _ZIPDELETE_H
#define _ZIPDELETE_H

#pragma pack(1)

//-------------------------------------------------------------------------------------------------------
// ZLOCALFILEHEADER
//--------------------------------------------------------------------------------------------------------
typedef struct
{
  BYTE signature         [ 4 ]; // 0x04034b50  
  BYTE extractVer        [ 2 ];
  BYTE generalPurposeBits[ 2 ];
  BYTE compression       [ 2 ];
  BYTE lastModTime       [ 2 ];
  BYTE lastModDate       [ 2 ];
  BYTE crc               [ 4 ];
  BYTE compressedSize    [ 4 ];
  BYTE uncompressedSize  [ 4 ];
  BYTE filenameLength    [ 2 ];
  BYTE extraFieldLength  [ 2 ];

  // File name...

  // Extra field...

} ZLOCALFILEHEADER;

//-------------------------------------------------------------------------------------------------------
// ZDATADESCRIPTOR
//--------------------------------------------------------------------------------------------------------
typedef struct
{
  BYTE crc               [ 4 ];
  BYTE compressedSize    [ 4 ];
  BYTE uncompressedSize  [ 4 ];

} ZDATADESCRIPTOR;

//-------------------------------------------------------------------------------------------------------
// ZCENTRALDIRHEADER
//-------------------------------------------------------------------------------------------------------
typedef struct
{
  BYTE signature         [ 4 ]; // 0x02014b50
  BYTE versionMadeBy     [ 2 ];
  BYTE versionForExtract [ 2 ];
  BYTE generalPurposeBits[ 2 ];
  BYTE compression       [ 2 ];
  BYTE lastModTime       [ 2 ];
  BYTE lastModDate       [ 2 ];
  BYTE crc               [ 4 ];
  BYTE compressedSize    [ 4 ];
  BYTE uncompressedSize  [ 4 ];
  BYTE filenameLength    [ 2 ];
  BYTE extraFieldLength  [ 2 ];
  BYTE commentLength     [ 2 ];
  BYTE diskNumberStart   [ 2 ];
  BYTE internalFileAttr  [ 2 ];
  BYTE externalFileAttr  [ 4 ];
  BYTE offsetLocalHeader [ 4 ];

  // File name..
  // Extra field..
  // File comment..

} ZCENTRALDIRHEADER;

//-------------------------------------------------------------------------------------------------------
// ZENDCENTRALDIR
//-------------------------------------------------------------------------------------------------------
typedef struct
{
  BYTE signature         [ 4 ]; // 0x06054b50
  BYTE diskNum           [ 2 ];
  BYTE diskNumWithStart  [ 2 ];

  BYTE numEntriesThisDisk[ 2 ];
  BYTE numEntriesTotal   [ 2 ];
  BYTE centralDirSize    [ 4 ];
  BYTE centralDirOffset  [ 4 ]; 
  BYTE commentLength     [ 2 ];

  // Zip file comment..

} ZENDCENTRALDIR;

#pragma pack()


void ZIPDelete( char *pZipFilename, Vector *pvFilesToDelete );
void ZipList( char *pZipFile, Vector *pvFiles );

#endif