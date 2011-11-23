//
//    OTSend.h
//    opentracker
//
//    Created by Pavitra on 9/29/11.
//    Copyright 2011 Opentracker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTSend : NSObject

/*!
 * @method urlEncoded
 * @abstract This method url encodes a given string
 * @param url The url parameter string to be encoded.
 * @return The Encoded url as string 
 */
+(NSString *) urlEncoded : (NSString*) url;
/*!
 * @method sendNewThread
 * @abstract Sends the key value pairs to Opentracker's logging/ analytics engines via
 *			 HTTP POST requests.
 *			 Based on sending key value pairs documented at:
 *			 http://api.opentracker.net/api/inserts/insert_event.jsp
 * @param keyValuePairs the key value pairs 
 *		    (plain text utf-8 strings) to send to the logging service.
 */
+(void) sendNewThread : (NSString*) url;
/*!
 * @method send
 * @abstract Creates new thread which calls the method send:keyValuePairs
 * @param keyValuePairs the key value pairs 
 *		    (plain text utf-8 strings) to send to the logging service.
 */
+(void) send: (NSMutableDictionary*) keyValuePairs;

/*!
 * @method sendUrl
 * @abstract Sends a post request with the url via HTTP POST requests.
 * @param url The url parameter string to be sent.
 * @return the response as string, null if an exception is caught
 */
+(NSString*) sendUrl: (NSString*) url;

/*!
 * @method uploadFile
 * @abstract Creates a new thread which calls uploadFileNewThread
 * @param fileToSend The file name to append to
 */
+(void) uploadFile:(NSString*) fileToSend;


/*!
 * @method uploadFileNewThread
 * @abstract Method used for uploading a file to the default upload server
 *           If the file upload is succesful then the fileToSend and zipped file are deleted.
 *           If unsuccessful, only the zipped file is deleted.
 * @param fileToSend The file name to append to
 */
+(void) uploadFileNewThread:(NSString*) fileToSend;

/*!
 * @method UUID 
 * @abstract Use to get the current device UUID - Universal Unique Identifier,
 *                     Based on Apple's latest guidelines 2011.
 *                     see discussion: 
 * @return The UUID as a string 
 */
+(NSString *)UUID;  


@end