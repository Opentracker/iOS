//
//  OTLogService.h
//  opentracker
//
//  Created by Pavitra on 9/7/11.
//  Copyright 2011 Opentracker. All rights reserved.
/*!
 @class OTLogService 
 @discussion This class is responsible for creation and logging and uploading the session 
 data to the opentracker servers.
 OTLogService should be instantiated in the function : applicationDidFinishLaunching
 in your projectNameAppDelegate.m 
 The session should be closed inside applicationWillTerminate function.
 The uploading should be done under applicationDidEnterBackground.
 Event logging can be done anywhere necessary(Example : on a click of a button etc) 
 It is best recommended to avoid event logging inside loops.
 @author Opentracker
 @version 1.0
 */

#import <Foundation/Foundation.h>


@interface OTLogService : NSObject {
    BOOL isSessionStarted ;
    NSString *appname ;
}
@property (nonatomic, retain) NSString *appname ;

/*!
 @method sharedOTLogService
 @abstract returns the singleton object of this class.
 Only one instance of this class will be used in the entire application.
 All the functions to be accessed in this class should be of the syntax:
 [[OTLogService sharedOTLogService] myFunction]
 */
+(OTLogService *) sharedOTLogService;

/*!
 @method onLaunch
 @abstract initializes the OTLogService object. 
 It is recommended to place this call in applicationDidFinishLaunching.
 @param the name of the application registered at www.opentracker.net
 */
-(void) onLaunch : (NSString*) applicationName;

/*!
 @method setDirectSend
 @abstract Sets if the data is sent directly to the log service (directSend = true).
 The default behavior is to send the event data directly if the device is
 connected to the Internet via WiFi (larger bandwidth). If the device is
 not connected via WiFi the data will be sent to a file which is then sent
 to the log service at a later time. This helps save bandwidth and helps
 with network performance.
 @param directSend: If log service should sent event data directly, indifferent of
 the connection.
 */
+(void) setDirectSend : (BOOL) directSendParam ; 

/*!
 @method registerSessionEvent
 @abstract A method which updates the session and event information each time when an event occurs. 
 Start of a session is also an event. 
 */
-(int) registerSessionEvent ; 

/*!
 @method sendEvent
 @abstract Allows a session to register a particular event as having occurred.
           This function creates a new thread for each event being sent.
 @param description of the event or a set of key value pairs.
 */
//-(void) sendEvent : (NSObject*) object ; 
-(void) sendEvent : (id)object ; 

/*!
 @method sendEventString
 @abstract Allows a session to register a particular event as having occurred,
 this data will be recorded and sent to www.opentracker.net.  
 @param event, description of the event.
 */
-(void) sendEventString:(NSString *)event addSessionState:(BOOL) appendSessionStateData ;
/*!
 @method sendEventString
 @abstract Allows a session to register a particular event as having occurred,
 this data will be recorded and sent to www.opentracker.net.  
 @param keyValuePairs, an event map.
 */
-(void) sendEventDictionary:(NSMutableDictionary *) keyValuePairs addSessionState:(BOOL) appendSessionStateData;

/*!
 @method onEnteringBackground
 @abstract Uploads the necessary data. Closes the session.
 This should be called in
 applicationWillResignActive or
 applicationDidEnterBackground.
 In order to get realtime updates, you can include this
 method after every sendEvent method. But this might 
 result in slow processing .
 */
-(void) onEnteringBackground ; 

/*!
 @method onTerminate
 @abstract Closes the session.  This should be called in
 applicationWillTerminate.
 Any events being sent after this method being called 
 will result in a new session.
 */
-(void) onTerminate ; 

/*!
 @method uploadCompressedFile
 @abstract uploads the compressed file to opentracker.net.
 This file contains all the data needed for tracking. It is called when 
 any events being sent after this method being called 
 will result in a new session.
 */
-(void) uploadCompressedFile;

/*!
 @method uploadCompressedFile
 @abstract handles the compression of the fileToCompress ,
 @param name of the file to be compressed, This file contains the data appended
 on each tag event.
 @return the name of the compressed file. If an error was encountered 
 , the name of the uncompressed file is returned.
 */
-(NSString*) compress : (NSString*) fileToCompress ;


/*!
 @method appendDataToFile
 @abstract makes a url with by appending the 
 key value pairs as parameters to the url, this 
 url is appended to the file which is later compressed.
 @param dataDictionary which holds the key value pairs.
 */
-(void) appendDataToFile : (NSMutableDictionary*) dataDictionary;

/*!
 @method OTUI
 @abstract get the unique id of the user from the otui file
 @return The UUID as a string 
 */
-(NSString*) OTUI  ;



@end
