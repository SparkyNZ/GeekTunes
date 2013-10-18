//--------------------------------------------------------------------------------------------
// MODULE:      BarbUtils.cpp
//
// AUTHOR:      Paul D. Spark
//
// DESCRIPTION: Utility functions
//--------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#include "Common.h"
#include "vector.h"
#include "BarbUtils.h"
#include "Utils.h"

#include <sys/stat.h>


//-----------------------------------------------------------------------------------------
// MyUtils class
//-----------------------------------------------------------------------------------------
@implementation  MyUtils

//-----------------------------------------------------------------------------------------
// makeTextField
//-----------------------------------------------------------------------------------------
+(UITextField *) makeTextField: (NSString*) text	
                   placeholder: (NSString*) placeholder  
{
  UITextField *tf = [[UITextField alloc] init];

  tf.placeholder = placeholder ;
  
  if( text == nil )
    tf.text = @"";
  else
    tf.text = text ;
  
  tf.autocorrectionType        = UITextAutocorrectionTypeNo ;
  tf.autocapitalizationType    = UITextAutocapitalizationTypeNone;
  tf.adjustsFontSizeToFitWidth = YES;
  tf.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f]; 	
//  tf.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f]; 	 
  return tf ;
}


//-----------------------------------------------------------------------------------------
// addCellIntSimple
//-----------------------------------------------------------------------------------------
+(UITextField*) addCellIntSimple: (UITableViewCell *) cell 
                          usingInt: (int) nVal 
                       withString: (NSString *) nsString                             
                        withTitle: (NSString *) nsTitle 
                  withPlaceHolder: (NSString *) nsPlaceHolder
{
  UITextField *tf;
  UILabel     *labTitle;  
  
  char         txVal[ 50 ];
  
  sprintf( txVal, "%0d", nVal );
  nsString = [NSString stringWithUTF8String: txVal];
  
  // PDS: I'll use a UITextEdit field for now but I reckon this should be a UIPickerView on a seperate VC to allow 
  //      entry of new rates.
  tf = [MyUtils makeTextField: nsString placeholder: nsPlaceHolder];
  
  labTitle   = [[UILabel alloc] init];
  
  labTitle.frame = CGRectMake( g_xTextField, 7, 180, 30 );
  labTitle.text  = nsTitle;
  labTitle.backgroundColor = [UIColor clearColor];    
    
  [tf setKeyboardType:UIKeyboardTypeDecimalPad];
  
  [cell addSubview: labTitle];   
  [cell addSubview: tf];        
  
  return tf;
}

//-----------------------------------------------------------------------------------------
// addCellNumeric
//-----------------------------------------------------------------------------------------
+(UITextField *) addCellNumeric: (UITableViewCell *) cell 
                           usingTx: (char *) txValue                    
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder
{
  UITextField *tf;
  
  nsString                  = [NSString stringWithUTF8String: txValue];
  cell.textLabel.text       = @" ";
  cell.detailTextLabel.text = nsString;
  
  tf = [MyUtils makeTextField: nsString placeholder: nsPlaceHolder];
  tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [tf setKeyboardType: UIKeyboardTypeNumberPad];
  
  [cell addSubview: tf];
  return tf;
}


//-----------------------------------------------------------------------------------------
// addCellTextNormal
//-----------------------------------------------------------------------------------------
+(UITextField *) addCellTextNormal: (UITableViewCell *) cell 
                           usingTx: (char *) txValue                    
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder
{
  UITextField *tf;
  
  nsString                  = [NSString stringWithUTF8String: txValue];
  cell.textLabel.text       = @" ";
  cell.detailTextLabel.text = nsString;
  
  tf = [MyUtils makeTextField: nsString placeholder: nsPlaceHolder];
  tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
  
  [cell addSubview: tf];
  return tf;
}
 
//-----------------------------------------------------------------------------------------
// addCellTextNormal
//-----------------------------------------------------------------------------------------
+(UITextField *) addCellTextNormal: (UITableViewCell *) cell 
                          usingInt: (int) nValue                    
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder
{
  UITextField *tf;
  char txStr[ 100 ];
  
  sprintf( txStr, "%d", nValue );
  
  nsString                  = [NSString stringWithUTF8String: txStr];
  cell.textLabel.text       = @" ";
  cell.detailTextLabel.text = nsString;
  
  tf = [MyUtils makeTextField: nsString placeholder: nsPlaceHolder];
  tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
  
  [cell addSubview: tf];
  return tf;
}

//-----------------------------------------------------------------------------------------
// CopyUITextField
//-----------------------------------------------------------------------------------------
+(void) CopyUITextField: (UITextField *) tf ToPSZ: (char *) psz
{
  if( tf == nil )
    return;
  
  strcpy( psz, [tf.text UTF8String] );
}

//-----------------------------------------------------------------------------------------
// Alert()
//-----------------------------------------------------------------------------------------
+(void) Alert: (NSString *) nsTitle withText: (NSString *) nsText
{
  UIAlertView *alert = [[UIAlertView alloc] init];
  [alert setTitle:   nsTitle];
  [alert setMessage: nsText];
  [alert setDelegate:self];
  [alert addButtonWithTitle:@"OK"];
  [alert show];
}

//-----------------------------------------------------------------------------------------
// MoveFile
//-----------------------------------------------------------------------------------------
+(void) MoveFile: (char *) src to: (char *) dst
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError       *error;
  
  NSString *nsSrc = [NSString stringWithUTF8String: src];
  NSString *nsDst = [NSString stringWithUTF8String: dst];
  
  if( [fileManager fileExistsAtPath: nsDst ] != YES )
  {  
    [fileManager moveItemAtPath: nsSrc toPath: nsDst error: &error];
  }
}
  
//-----------------------------------------------------------------------------------------
// CopyFile
//-----------------------------------------------------------------------------------------
+(void) CopyFile: (char *) src to: (char *) dst
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError       *error;
  
  NSString *nsSrc = [NSString stringWithUTF8String: src];
  NSString *nsDst = [NSString stringWithUTF8String: dst];
  
  if( [fileManager fileExistsAtPath: nsDst ] == YES )
    remove( dst );
  
  [fileManager copyItemAtPath: nsSrc toPath: nsDst error: &error];
}

//-----------------------------------------------------------------------------------------
// findAllFilesInPath 
//-----------------------------------------------------------------------------------------
+(void) findAllFilesInPath: (NSString *)directoryPath populate: (Vector *) pvFiles
{  
  pvFiles->removeAll();
  
  //NSMutableArray *filePaths = [[[NSMutableArray alloc] init] retain];
  //g_txFTPPath
  
  // Enumerators are recursive
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath: directoryPath];
  
  NSString *filePath;
  
  while ( (filePath = [enumerator nextObject] ) != nil )
  {
    pvFiles->addUnique( (char *) [filePath UTF8String] );
    
    // If we have the right type of file, add it to the list
    // Make sure to prepend the directory path
    //if( [[filePath pathExtension] isEqualToString:type] ){
    //[filePaths addObject:[directoryPath stringByAppendingString: filePath]];
    //  }
  }
  
}

//-----------------------------------------------------------------------------------------
// findAllFilesInPath containing: 
//-----------------------------------------------------------------------------------------
+(void) findAllFilesInPath: (NSString *)directoryPath containing: (char *) pszPattern populate: (Vector *) pvFiles
{  
  pvFiles->removeAll();
    
  // Enumerators are recursive
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath: directoryPath];
  
  NSString *filePath;
  char     *pszPath;
  
  while ( (filePath = [enumerator nextObject] ) != nil )
  {
    pszPath = (char *) [filePath UTF8String];
    
    if( stristr( pszPath, pszPattern ) )
      pvFiles->addUnique( pszPath );
    
    // If we have the right type of file, add it to the list
    // Make sure to prepend the directory path
    //if( [[filePath pathExtension] isEqualToString:type] ){
    //[filePaths addObject:[directoryPath stringByAppendingString: filePath]];
    //  }
  }
}

//-----------------------------------------------------------------------------------------
// findAllFilesInPath containing: andAlso:
//-----------------------------------------------------------------------------------------
+(void) findAllFilesInPath: (NSString *)directoryPath
                containing: (char *) pszPattern
                   andAlso: (char *) pszPattern2
                  populate: (Vector *) pvFiles
{  
  pvFiles->removeAll();
  
  // Enumerators are recursive
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath: directoryPath];
  
  NSString *filePath;
  char     *pszPath;
  
  while ( (filePath = [enumerator nextObject] ) != nil )
  {
    pszPath = (char *) [filePath UTF8String];
    
    if( ( stristr( pszPath, pszPattern  ) ) &&
        ( stristr( pszPath, pszPattern2 ) ) )
      pvFiles->addUnique( pszPath );
    
    // If we have the right type of file, add it to the list
    // Make sure to prepend the directory path
    //if( [[filePath pathExtension] isEqualToString:type] ){
    //[filePaths addObject:[directoryPath stringByAppendingString: filePath]];
    //  }
  }
}


//-----------------------------------------------------------------------------------------
// DumpFolder 
//-----------------------------------------------------------------------------------------
+(void) DumpFolder: (char*) pszPath
{
  Vector vFiles;
  
  [MyUtils findAllFilesInPath: [NSString stringWithUTF8String: pszPath] populate: &vFiles];
  
  LogDebugf( "Folder dump for: %s", pszPath );
  
  for( int i = 0; i < vFiles.elementCount(); i ++ )
  {
    char *pFile = vFiles.elementStrAt( i );
    LogDebugf( "->[%s]", pFile );
  }
}

//-----------------------------------------------------------------------------------------
// scaleImage
//-----------------------------------------------------------------------------------------
+(UIImage*) scaleImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
  float oldWidth = sourceImage.size.width;
  float scaleFactor = i_width / oldWidth;
  
  float newHeight = sourceImage.size.height * scaleFactor;
  float newWidth = oldWidth * scaleFactor;
  
  UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
  [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

@end
