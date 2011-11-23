//
//  opentrackerAgent.m
//  opentracker
//
//  Created by Pavitra on 9/7/11.
//  Copyright 2011 Opentracker. All rights reserved.
//

#import "OTLogService.h"
#import "OTFileUtils.h"
#import "OTDataSockets.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "OTSend.h"

@interface OTLogService () //note the empty category name
//define private methods here
//see: http://stackoverflow.com/questions/172598/best-way-to-define-private-methods-for-a-class-in-objective-c
/*!
 @method sendEventObject
 @abstract Allows a session to register a particular event as having occurred,
 this data will be recorded and sent to www.opentracker.net.  
 @param description of the event or a set of key value pairs.
 */
-(void) sendEventObject : (id)object ; 
@end

@implementation OTLogService
static OTLogService *sharedOtagent = nil;
OTDataSockets *otdataSockets ; 
static int sessionLapseTimeMs= 1000*60*30; //TODO,testing
static bool directSend = NO; 
@synthesize appname;



- (id)init
{
    self = [super init];
    if (self) {
        //Initialize code here.
        //isSessionStarted = NO;
    }
    
    
    return self;
}
#pragma mark sharedOtagent
/* A function which initializes the static instance of type OTLogService  */
+ (OTLogService *) sharedOTLogService {    
	@synchronized(self) {
		if (sharedOtagent == nil) {
			sharedOtagent = [[self alloc] init];
            otdataSockets = [[OTDataSockets alloc] init];
            
		}
	}
    
	return sharedOtagent;
}

#pragma mark Set Direct Send
+(void) setDirectSend:(BOOL)directSendParam {
    directSend = directSendParam; 
}

#pragma mark On Launch
/*
 This Function will be called on start of the application
 */
-(void) onLaunch : (NSString*) applicationName {
    NSLog(@"onLaunch");    
    self.appname = applicationName;
}

#pragma mark On Entering Background
/*
 This Function will be called while the application goes to background
 */

-(void) onEnteringBackground {
    NSLog(@"onEnteringBackground");
    //upload compressed file only if the requests were appended to fileToSend.
    //This happens only if connection is not type and directSend is set to NO.
    if ([otdataSockets networkType]!=@"Wi-Fi" && !directSend) {
        [self uploadCompressedFile];
    }
}


#pragma mark On Terminate
/*
 This Function will be called while the application terminates
 */
-(void) onTerminate {
    isSessionStarted = NO;
    // sharedOtagent = nil;
    // [sharedOtagent release];
    [self release];
}


#pragma mark Register Session Event
/*
 this method updates the session and event information each time when an event occurs. 
 */
-(int) registerSessionEvent {
    NSLog(@"registerSessionEvent");
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *otuifilename = @"otui";
    
    @try {
        [OTFileUtils  makeFile: otuifilename];
    }
    @catch (NSException *exception) {
		//Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Can't make file otui");
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:@"Can't make file otui" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];		
        [logDictionary  release];
    }
    
    //same thing for session data
    NSString *otsfilename = @"ots";
    @try {
        [OTFileUtils  makeFile: otsfilename];
    }
    @catch (NSException *exception) {
		//Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Can't make file ots");
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:@"Can't make file ots" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
    
    // read the users data file
    NSString *otUserData = nil; 
    @try{
        otUserData = [OTFileUtils  readFile:otuifilename];
		NSLog(@"otUserData %@",otUserData);
    }
    @catch (NSException *exception) {
        NSLog(@"Can't read file otui");
		//Sending the error message occurred as Dictionary to opentracker.net
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:@"Can't read file otui" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];
        
    }
    
    NSString *otSessionData = nil;
    // read the session data
    @try{
        otSessionData = [OTFileUtils readFile:otsfilename];
    }
    @catch (NSException *exception) {
        //Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Can't read file ots");
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:@"Can't read file ots" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [logDictionary  release];
    }
    
    //create default/initial session data
    int randomNumberClient = (int) (1000 * rand());
    double currentUnixTimestampMs =   ([[NSDate date] timeIntervalSince1970]  * 1000 );
    //see: http://stackoverflow.com/questions/358207/iphone-how-to-get-current-milliseconds
    double  firstSessionStartUnixTimestamp = currentUnixTimestampMs;
    double previousSessionStartUnixTimestamp = currentUnixTimestampMs;
    double currentSessionStartUnixTimestamp = currentUnixTimestampMs;
    int sessionCount = 1;
    int lifeTimeEventCount = 1;
    
    //2. if data doesn't exist-> create data with initial parameters
    if (otUserData != Nil) {
        //initialize the data
        NSArray *userData = [otUserData componentsSeparatedByString: @"."];
        // see :http://borkware.com/quickies/one?topic=NSString
        if ([userData count] != 6) {
            //NSLog(@"Data is corrupted length: %i, userData: %@" ,[userData count] ,  otUserData);
            //handle corruption
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
            [logDictionary setObject:@"Got corrupt otui, wrong length." forKey:@"message"];
            [OTSend send:logDictionary];
            [logDictionary  release];     
        } else {
            //see exception handling:  http://stackoverflow.com/questions/3363612/try-catch-block-in-objective-c-problem
            // as per
            // http://api.opentracker.net/api/inserts/browser/reading_cookie.jsp
            
            // _otui <random number client site>. <first visit start unix
            // timestamp>. <previous visit start unix timestamp>. <current
            // visit start unix timestamp>. <session count>. <life time
            // event view count>
            @try{
                //parse the user data
                randomNumberClient = [[userData objectAtIndex:0] intValue];
                firstSessionStartUnixTimestamp = [[userData objectAtIndex:1] doubleValue] ;				
                previousSessionStartUnixTimestamp =[[userData objectAtIndex:2] doubleValue] ;
                currentSessionStartUnixTimestamp = [[userData objectAtIndex:3] doubleValue] ;
                sessionCount =  [[userData objectAtIndex:4] intValue];
                lifeTimeEventCount = [[userData objectAtIndex:5] intValue] ;
                
                // update the event count
                lifeTimeEventCount++;

            } @catch (NSException *e) {
				//Sending the error message occurred as Dictionary to opentracker.net
                NSLog(@"otui has corrupted data: %@", [e reason]);
                NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
                [logDictionary setObject:@"otui has corrupted data" forKey:@"message"];
                [logDictionary setObject:[e reason] forKey:@"reason"];
                [logDictionary setObject:[e callStackSymbols] forKey:@"exception"];
                [OTSend send:logDictionary];
                [logDictionary  release];
                
                //handle corruption: reinitialize everything
                randomNumberClient =(int) (1000 * rand());
                firstSessionStartUnixTimestamp =  currentUnixTimestampMs;				
                previousSessionStartUnixTimestamp = currentUnixTimestampMs;
                currentSessionStartUnixTimestamp = currentUnixTimestampMs;
                sessionCount = 1;
                lifeTimeEventCount = 1;
                
            }
        }
    }

    
    //Create data with initial parameters
    int sessionEventCount = 1;
    double previousEventUnixTimestamp = currentUnixTimestampMs;

    BOOL isNewSession = YES;
        if (otSessionData != nil) {
            //initialize the data
            NSArray *sessionData = [otSessionData componentsSeparatedByString: @"."];
            if ([sessionData count] != 4) {
                NSLog(@"Data is corrupted length: %d, sessionData: %@" ,[sessionData count], sessionData);
                NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
                [logDictionary setObject:@"Got corrupt ots, wrong length." forKey:@"message"];
                //TODO: send this to OTSend.send(hashmap)
                [logDictionary  release];
                //data is corrupted, and initialized
                
            } else {
                @try {
                    // as per
                    // http://api.opentracker.net/api/inserts/browser/reading_cookie.jsp
                    
                    // _ots <session event view count>. <current visit start
                    // unix timestamp>. <previous event view unix timestamp>.
                    // <current event view unix timestamp>
                    previousEventUnixTimestamp = [[sessionData objectAtIndex:3] doubleValue];
                    double diff = (currentUnixTimestampMs - previousEventUnixTimestamp);
                    //do the work, to start a new event
                    NSLog(@"Got: %.0f[ms]", diff);
                    NSLog(@"Got currentUnixTimestampMs: %.0f [ms]", currentUnixTimestampMs );
                    NSLog(@"Got previousEventUnixTimestamp: %.0f [ms]", previousEventUnixTimestamp);
                    // make sure we have a ongoing session
                    if (diff < sessionLapseTimeMs) {
                        NSLog(@"Continuing starting.");
                        // ongoing session, parse the session data
                        sessionEventCount = [[sessionData objectAtIndex:0] intValue];
                        // currentSessionStartUnixTimestamp =
                        // Long.parseLong(sessionData[1]);
                        
                        // do the work, to start a new event
                        sessionEventCount++;
                        
                        // use initial session values
                        isNewSession = NO;
                        

                    }
                } @catch (NSException * e) {
					//Sending the error message occurred as Dictionary to opentracker.net
                    NSLog(@"ots has corrupted data: %@", [e reason]);
                    NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                    [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
                    [logDictionary setObject:@"ots has corrupted data" forKey:@"message"];
                    [logDictionary setObject:[e reason] forKey:@"reason"];
                    [logDictionary setObject:[e callStackSymbols] forKey:@"exception"];
                    [OTSend send:logDictionary];
                    [logDictionary  release];
                    
                    //just reinitialize everything
                    sessionEventCount = 1;
                    previousEventUnixTimestamp = currentSessionStartUnixTimestamp;

                }
            }
        }
        if (isNewSession) {
            NSLog(@"Updating data with new session.");
            previousEventUnixTimestamp = currentSessionStartUnixTimestamp;
            currentSessionStartUnixTimestamp = currentUnixTimestampMs;
            sessionCount++;
        }
        
        otSessionData = [NSString stringWithFormat:@"%d.%.0f.%.0f.%.0f", sessionEventCount, currentSessionStartUnixTimestamp, previousEventUnixTimestamp, currentUnixTimestampMs ];
        
        @try {
            NSLog(@ "Writing session: %@", otSessionData);
            NSLog(@"Writing current: %.0f", currentUnixTimestampMs);
            NSLog(@"Writing previous: %.0f", previousEventUnixTimestamp);
            NSLog(@"Writing current: ", [NSDate dateWithTimeIntervalSince1970:currentUnixTimestampMs/1000 ] );
            NSLog(@"Writing previous: ", [NSDate dateWithTimeIntervalSince1970:previousEventUnixTimestamp/1000 ]);
            [OTFileUtils writeFile:otsfilename withString:otSessionData];
        }
        @catch (NSException *exception) {
            //Sending the error message occurred as Dictionary to opentracker.net
            NSLog(@"Exception while writing to ots: %@", [exception reason]);
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
            [logDictionary setObject:@"Exception while writing to ots" forKey:@"message"];
            [logDictionary setObject:[exception reason] forKey:@"reason"];
            [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
            [OTSend send:logDictionary];
            [logDictionary  release];
        }

        NSLog(@"ots write: %@" ,otSessionData); 
        
        
        //see http://www.cocoadev.com/index.pl?NSLog
        //format the otUserData
        otUserData = [NSString stringWithFormat:@"%d.%.0f.%.0f.%.0f.%d.%d", randomNumberClient, firstSessionStartUnixTimestamp, previousSessionStartUnixTimestamp, currentSessionStartUnixTimestamp, sessionCount, lifeTimeEventCount ];
        
        
        @try {
            [OTFileUtils  writeFile:otuifilename withString:otUserData];
        }
        @catch (NSException *exception) {
            //Sending the error message occurred as Dictionary to opentracker.net
            NSLog(@"Exception while writing to otui: %@", [exception reason]);
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
            [logDictionary setObject:@"Exception while writing to otui" forKey:@"message"];
            [logDictionary setObject:[exception reason] forKey:@"reason"];
            [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
            //TODO: send this to OTSend.send(hashmap)
            [logDictionary  release];
        }
        NSLog(@"otui write: %@", otUserData);
          
    [pool release];
    return sessionEventCount;
}

#pragma mark Send Event
-(void)sendEvent:(id)object 
{	
    NSLog(@"sendEvent: %@",object);
    //see :  http://stackoverflow.com/questions/1144629/in-objective-c-how-do-i-test-the-object-type
    if([object isKindOfClass:[NSString class]]) {
		//Convert the received object type into NSString while passing
        [self sendEventString:(NSString*)object addSessionState:YES];
        
    } else  {
		//Convert the received object type into NSMutableDictionary while passing
        [self sendEventDictionary:(NSMutableDictionary*)object addSessionState:YES];
    }
    
}



#pragma mark Send Event String
/*
 This method will send the event which occurred.
 It can be used to get the status of the session, whether the session is started or resumed. 
 */
-(void) sendEventString :(NSString *)event addSessionState:(BOOL) appendSessionStateData  {
    
    NSLog(@"sendEventString:%@ addSessionState: %@", event, appendSessionStateData ? @"YES" : @"NO");
    
    //update the sessionData
    int eventCount = [self registerSessionEvent];
	NSLog(@"eventCount %d",eventCount);
    NSMutableDictionary *keyValuePairs = [[NSMutableDictionary alloc] init];
    //TODO : make appname static string assigned using init
    [keyValuePairs setObject:appname forKey:@"si"];
    [keyValuePairs setObject:event forKey:@"ti"];
    //TODO : make appname static string assigned using init
    [keyValuePairs setObject:[NSString stringWithFormat:@"http://app.opentracker.net/%@/%@",appname,[event stringByReplacingOccurrencesOfString:@"/" withString:@"."]] forKey:@"lc" ];
    [keyValuePairs setObject:[otdataSockets networkType] forKey:@"connection"];
    [keyValuePairs setObject:[OTDataSockets platform] forKey:@"platform"];	
    [keyValuePairs setObject:[OTDataSockets screenHeight] forKey:@"sh"];
    [keyValuePairs setObject:[OTDataSockets screenWidth] forKey:@"sw"];
    [keyValuePairs setObject:[OTDataSockets appVersion] forKey:@"app version"];
    [keyValuePairs setObject:[OTDataSockets platformVersion]  forKey:@"platform version"];
    [keyValuePairs setObject:[OTDataSockets device] forKey:@"device"];
    //if latitude and longitude value is 0,0 do not add it to the hashmap
    NSString *location = [OTDataSockets locationCoordinates];
    if(![ location isEqual:@"0.000000,0.000000"]) {
        [keyValuePairs setObject:location forKey:@"location"];
    }
    
    //also add any session state data
    NSMutableDictionary *keyValuePairsMerged =[[NSMutableDictionary alloc] init];
    
    if (appendSessionStateData) {
        @try {
            [keyValuePairs setObject:[OTFileUtils readFile:@"otui"] forKey:@"otui"];
            [keyValuePairs setObject:[OTFileUtils readFile:@"ots"] forKey:@"ots"];
        } @catch (NSException *e) {
			//Sending the error message occurred as Dictionary to opentracker.net
            NSLog(@"Exception while reading to ots/ otui: %@", [e reason]);
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
            [logDictionary setObject:@"Exception while reading to ots/ otui" forKey:@"message"];
            [logDictionary setObject:[e reason] forKey:@"reason"];
            [OTSend send:logDictionary];
            [logDictionary  release];
        }
    }
    if (keyValuePairs != nil)
        [keyValuePairsMerged addEntriesFromDictionary:keyValuePairs];
    
    @try {
        if ([otdataSockets networkType]==@"Wi-Fi") {
            [OTSend send:keyValuePairsMerged];
        } else if (directSend) {
            [OTSend send:keyValuePairsMerged];
        } else {
            [self appendDataToFile:keyValuePairsMerged];
        }
    } @catch (NSException *e) {
		//Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
	[keyValuePairsMerged release];
	[keyValuePairs release];
    
}


#pragma mark Send Event Dictionary
-(void) sendEventDictionary :(NSMutableDictionary *)keyValuePairs addSessionState:(BOOL)appendSessionStateData {
    NSLog(@"sendEventDictionary(%@)" , appendSessionStateData ? @"YES" : @"NO");
    
    int eventCount = [self registerSessionEvent];
    
    //also add any session state data
    NSMutableDictionary *keyValuePairsMerged =[[NSMutableDictionary alloc] init];
    [keyValuePairsMerged setObject:appname forKey:@"si"];
    //it is default title tag
    if ([keyValuePairs objectForKey:@"ti"] == nil)
        if ([keyValuePairs objectForKey:@"title"] == nil) {
            [keyValuePairs setObject:@"[No title]" forKey:@"ti"];
            [keyValuePairs setObject:[NSString stringWithFormat:@"http://app.opentracker.net/%@/%@",appname, @"[No title]"] forKey:@"lc" ];
        } else {
            [keyValuePairs setObject:[keyValuePairs objectForKey:@"title"] forKey:@"ti"];
            [keyValuePairs setObject:[NSString stringWithFormat:@"http://app.opentracker.net/%@/%@",appname,[[keyValuePairs objectForKey:@"title"] stringByReplacingOccurrencesOfString:@"/" withString:@"."]] forKey:@"lc" ];
            [keyValuePairs removeObjectForKey:@"title"];
        }
    [keyValuePairs setObject:[otdataSockets networkType] forKey: @"connection"];
    [keyValuePairs setObject:[OTDataSockets platform] forKey:@"platform"];
    [keyValuePairs setObject:[OTDataSockets screenHeight] forKey:@"sh"];
    [keyValuePairs setObject:[OTDataSockets screenWidth] forKey:@"sw"];
    [keyValuePairs setObject:[OTDataSockets appVersion] forKey:@"app version"];
    [keyValuePairs setObject:[[UIDevice currentDevice] systemVersion]  forKey:@"platform version"];
    [keyValuePairs setObject:[OTDataSockets device] forKey:@"device"];
    //if latitude and longitude value is 0,0 do not add it to the hashmap
    NSString *location = [OTDataSockets locationCoordinates];
    if(![ location isEqual:@"0.000000,0.000000"]) {
        [keyValuePairs setObject:location forKey:@"location"];
    }
    
    if (appendSessionStateData) {
        @try {
            //TODO make gtSessionStateDataPairs
            [keyValuePairs setObject:[OTFileUtils readFile:@"otui"] forKey:@"otui"];
            [keyValuePairs setObject:[OTFileUtils readFile:@"ots"] forKey:@"ots"];
        } @catch (NSException *e) {
            //Sending the error message occurred as Dictionary to opentracker.net
            NSLog(@"Exception while getting fileName data pairs");
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
            [logDictionary setObject:[e reason] forKey:@"message"];
            [OTSend send:logDictionary];
            [logDictionary  release];
        }
    }
    if (keyValuePairs != nil)
        [keyValuePairsMerged addEntriesFromDictionary:keyValuePairs];
    @try {
        if ([otdataSockets networkType]==@"Wi-Fi") { 
            [OTSend send:keyValuePairsMerged];
        } else if (directSend) {
            [OTSend send:keyValuePairsMerged];
        } else {
            [self appendDataToFile:keyValuePairsMerged];
        }
    } @catch (NSException *e) {
		//Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
		//TODO: send this to OTSend.send(hashmap)
		[OTSend send:logDictionary];        
        [logDictionary  release];
    }
}
#pragma mark Append Data To File
/*
 This will create a url by appending the keys and its values of the input parameter dataDictionary
 The created url will be sent to appendToFile Function of OTFileUtils class.
 */

-(void) appendDataToFile : (NSMutableDictionary*) dataDictionary {
    NSLog(@"appendDataToFile");
    //NSString *devicename = [[UIDevice currentDevice] systemName];
    
    NSString *url = @"http://log.opentracker.net/?";
    
    [dataDictionary setObject:[NSString stringWithFormat:@"%.0f", ([[NSDate date] timeIntervalSince1970] *1000 ) ] forKey:@"t_ms"];
    for (id key in dataDictionary) {
        NSString *value = [dataDictionary objectForKey:key];
        url = [NSString stringWithFormat:@"%@%@=%@&", url, [OTSend urlEncoded:key], [OTSend urlEncoded:value]];
        
    }
    NSLog(@"appending url: %@", url);
    @try {
        [OTFileUtils makeFile: @"fileToSend"];
        [OTFileUtils appendToFile:@"fileToSend" writeString:url];
    } @catch (NSException *e) {
		//Sending the error message occurred as Dictionary to opentracker.net
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; //log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
}
#pragma mark Upload Compressed File
/*
 This function will uploads the compressed file to opentracker.net server
 */
-(void) uploadCompressedFile {
    NSLog(@"uploadCompressedFile");
    
    @try {
        
        NSString *gzippedFile = [self compress:@"fileToSend"];
        //double time1 = [[NSDate date] timeIntervalSince1970];
        //NSString *url = @"http://upload.opentracker.net/upload/upload.jsp";
        [OTSend uploadFile:gzippedFile ];
        //double time2 = [[NSDate date] timeIntervalSince1970];
    } 
    @catch (NSException *e) {    
        NSLog(@"gzip file not created/uploaded");
    }
}

#pragma mark URL Encoded

/*
 This function will encodes the string specified
 */
-(NSString *) urlEncoded : (NSString*) url
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)url,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
    return [(NSString *)urlString autorelease];
}

#pragma mark Compress
/*
 Use to compress a file.
 The fileToCompress string will specifies the file name to compress
 The file should be present in the document directory.
 This function calls the compressFile function of OTFileUtils class.
 */
-(NSString*) compress : (NSString*) fileToCompress {
    NSLog(@"uploadZippedFile %@",fileToCompress);
    NSString *gzippedfilename = fileToCompress;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    //File we want to create in the documents directory 
    //Result is: /Documents/file1.txt
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:fileToCompress];
    
	if ([fileMgr isReadableFileAtPath:filePath] && [NSFileTypeRegular isEqual: [[fileMgr attributesOfItemAtPath:filePath error:nil] fileType]]) {
		@try {
			NSLog(@"gzippedfilename %@",gzippedfilename);
			gzippedfilename = [OTFileUtils compressFile:gzippedfilename];
			NSLog(@"Gzip archive has been created successfully! filename:%@", gzippedfilename);
            
		}
		@catch (NSException * e) {
			NSLog(@"error occured %@ reason being: %@", [e name], [e reason] );
            
		}
	} else {
        NSLog(@"You must select file to be gzipped");
        
		//UIAlertView *someError = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must select file to be gzipped" delegate: nil cancelButtonTitle: @"Ok" otherButtonTitles: nil];
		//[someError show];
		//[someError release];
	}
    NSLog(@"gzipped file name: %@", gzippedfilename);
    return gzippedfilename;
}
@end
