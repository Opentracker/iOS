//
//  OTSend.h
//  opentracker
//
//  Created by Pavitra on 9/29/11.
//  Copyright 2011 Opentracker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTSend : NSObject

/*!
 * @method urlEncoded
 * @abstract This method url encodes a given string
 * @param url The url paramter string to be encoded.
 */
+(NSString *) urlEncoded : (NSString*) url;
/*!
 * @method send
 * @abstract Sends the key value pairs to Opentracker's logging/ analytics engines via
 * HTTP POST requests.
 * Based on sending key value pairs documentated at:
 * http://api.opentracker.net/api/inserts/insert_event.jsp
 * @param keyValuePairs the key value pairs 
 *(plain text utf-8 strings) to send to the logging service.
 * @return a response string generated in opentracker.net
 * or nil if an exception is caught
 */
+(NSString*) send: (NSMutableDictionary*) keyValuePairs;

/*!
 * @method sendUrl
 * @abstract Sends a post request with the url via HTTP POST requests.
 * @return the response as string, null if an exception is caught
 */
+(NSString*) sendUrl: (NSString*) url;

/*!
 * @method uploadFile
 * @abstract Method used for uploading a file to the default upload server
 * @param fileToSend The file name to append to
 * @param uploadServer the url link of the upload server.
 * @return response string on upload.
 */
+(BOOL) uploadFile:(NSString*) fileToSend toServer:(NSString*) uploadServer;

+(NSString *)UUID;

@end
