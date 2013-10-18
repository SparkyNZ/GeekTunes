//--------------------------------------------------------------------------------------------
// MODULE:      BarbUtils.h
//
// AUTHOR:      Paul D. Spark
//
// DESCRIPTION: Utility functions
//--------------------------------------------------------------------------------------------

#ifndef _BARBUTILS_H
#define _BARBUTILS_H

#include "Common.h"
#include "Vector.h"

#define ONE_SECOND 1000
#define WEEK_SECS  604800

#define ALIGN_LEFT      0
#define ALIGN_RIGHT     1
#define ALIGN_CENTER    2
#define ALIGN_JUSTIFIED 3

extern char g_TxtAll[];
extern char g_TxtAny[];
extern char g_TxtSelect[];

@interface MyUtils : NSObject
{
  // PDS: Variables only go in here
}

+(void) CopyUITextField: (UITextField *) tf ToPSZ: (char *) psz;

+(UITextField*) makeTextField: (NSString*)text	
                  placeholder: (NSString*)placeholder;


+(UITextField *) addCellWordCapitalise: (UITableViewCell *) cell 
                               usingTx: (char *) txValue 
                            withString: (NSString *) nsString
                           placeHolder: (NSString *) nsPlaceHolder;

+(UITextField *) addCellNumeric: (UITableViewCell *) cell 
                         usingTx: (char *) txValue                  
                      withString: (NSString *) nsString
                     placeHolder: (NSString *) nsPlaceHolder;

+(UITextField *) addCellTextNormal: (UITableViewCell *) cell 
                           usingTx: (char *) txValue                  
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder;

+(UITextField *) addCellTextNormal: (UITableViewCell *) cell 
                           usingTx: (char *) txValue            
                         withTitle: (NSString *) nsTitle
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder;

+(UITextField *) addCellTextNormal: (UITableViewCell *) cell 
                          usingInt: (int) nValue                    
                        withString: (NSString *) nsString
                       placeHolder: (NSString *) nsPlaceHolder;

+(UITextField*) addCellIntSimple: (UITableViewCell *) cell 
                        usingInt: (int) nVal 
                      withString: (NSString *) nsString                             
                       withTitle: (NSString *) nsTitle 
                 withPlaceHolder: (NSString *) nsPlaceHolder;

+(void) CopyFile: (char *) src to: (char *) dst;
+(void) MoveFile: (char *) src to: (char *) dst;

+(void) Alert: (NSString *) nsTitle withText: (NSString *) nsText;
+(void) findAllFilesInPath: (NSString *)directoryPath populate: (Vector *) pvFiles;
+(void) findAllFilesInPath: (NSString *)directoryPath containing: (char *) pszPattern populate: (Vector *) pvFiles;

+(void) findAllFilesInPath: (NSString *)directoryPath containing: (char *) pszPattern
                   andAlso: (char *) pszPattern2 populate: (Vector *) pvFiles;

+(void) DumpFolder: (char*) pszPath;
+(UIImage*) scaleImage: (UIImage*) sourceImage scaledToWidth: (float) i_width;

@end


#endif