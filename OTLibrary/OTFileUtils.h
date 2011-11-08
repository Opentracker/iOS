//
//  OTFileUtils.h
//  opentracker
//
//  Created by Pavitra on 9/8/11.
//  Copyright 2011 Opentracker. All rights reserved.
// Please visit www.opentracker.net for more information.

#import <Foundation/Foundation.h>
/*!
 @class OTFileUtils 
 @discussion The class which manages file I/O operations like file creation, read , write , append data , deletion and compression .
 @author Opentracker
 @version 1.0
 */
@interface OTFileUtils : NSObject

/*!
 * @method makeFile
 * @abstract Creates/Makes an empty file in the default Documents directory with the file name specified
 * @param fileName The file name to Create/Makes the directory
 */
+(void) makeFile : (NSString*) filename;

/*!
 * @method writeFile
 * @abstract Writes the writeString to the fileName given in the Documents directory.
 * @param fileName The file name write to
 * @param str The string to write in the file 
 */
+(void) writeFile: (NSString*) filename withString: (NSString*) str;

/*!
 * @method removeFile
 * @abstract Method to remove a file with the name fileName present in the Documents directory 
 * @param fileName The file name to remove from the Documents Directory
 */
+(void) removeFile: (NSString*) filename;

/*!
 * @method readFile
 * @abstract Method to read a file with the name fileName in the Documents directory 
 *			 and get its contents as a string 
 * @param filename The file name to read
 * @returns string which contains the contents present in the file
 */
+(NSString*) readFile : (NSString*) filename;

/*!
 * @method appendToFile
 * @abstract Method to append a string to a file with the name fileName.
 If file does not exist, it is created and string is written in the file.
 * @param fileName The file name to append to
 * @param writeString The string to be written
 */
+(void) appendToFile:(NSString *)filename writeString:(NSString *) writeString ;
            
/*!
 * @method compressFile
 * @abstract Method to compress a file with a GZIPOutputStream with the name fileName present in the Documents directory
 * @param filename, The file name to compress
 * @returns The name of the compressed file as a string.
 */
+(NSString*) compressFile : (NSString*) filename ;
@end
    
