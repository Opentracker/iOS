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


@implementation OTLogService
static OTLogService *sharedOtagent = nil;
static int sessionLapseTimeMs= 30000; //TODO 30*1000 after testing
@synthesize appname;


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        isSessionStarted = NO;
    }
    
    
    return self;
}

/* a function which initializes the static instance of type OTLogService  */
+ (OTLogService *) sharedOTLogService {    
	@synchronized(self) {
		if (sharedOtagent == nil) {
			sharedOtagent = [[self alloc] init];
            
		}
	}
    
	return sharedOtagent;
}

-(void) onLaunch : (NSString*) applicationName {
    NSLog(@"onLaunch");    
    self.appname = applicationName;
}

-(void) onEnteringBackground {
    NSLog(@"onEnteringBackground");
    [self uploadCompressedFile];
}

-(void) onTerminate {
    isSessionStarted = NO;
    sharedOtagent = nil;
}

-(int) registerSessionEvent {
    NSLog(@"registerSessionEvent");
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *otuifilename = @"otui";

    @try {
        
       [OTFileUtils  makeFile: otuifilename];
    }
    @catch (NSException *exception) {
         NSLog(@"Can't make file otui");
         NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Can't make file otui" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];

    }
    
    // read the users data file
    NSString *otUserData = nil; 
    @try{
        otUserData = [OTFileUtils  readFile:otuifilename];
    }
    @catch (NSException *exception) {
        NSLog(@"Can't read file otui");
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Can't read file otui" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];

    }
    
    // create default/ initial session data
    int randomNumberClient = (int) (1000 * rand());
    //see: http://stackoverflow.com/questions/358207/iphone-how-to-get-current-milliseconds
    double  firstVisitStartUnixTimestamp = [[NSDate date] timeIntervalSince1970] *1000;
    NSLog(@"date unix timestamp: %.0f", firstVisitStartUnixTimestamp);
    double previousVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
    double currentVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
    int sessionCount = 1;
    int lifeTimeEventCount = 1;
    double currentTime =   ([[NSDate date] timeIntervalSince1970] * 1000);
    // 2. if data doesn't exist -> create data with initial parameters
    if (otUserData != Nil) {
        // initialize the data
        NSArray *userData = [otUserData componentsSeparatedByString: @"."];
        // see :http://borkware.com/quickies/one?topic=NSString
        if ([userData count] != 6) {
            NSLog(@"Data is corrupted length: %i, userData: %@" ,[userData count] ,  otUserData);
            //handle corruption
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
            [logDictionary setObject:@"Got corrupt otui, wrong length." forKey:@"message"];
            [OTSend send:logDictionary];
            [logDictionary  release];
            
            
            //reinitialize everything
            randomNumberClient = (int) (1000 * rand());
            firstVisitStartUnixTimestamp =  ([[NSDate date] timeIntervalSince1970] * 1000);
            previousVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
            currentVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
            sessionCount = 1;
            lifeTimeEventCount = 1;
            
        }else {
            // see exception handling:  http://stackoverflow.com/questions/3363612/try-catch-block-in-objective-c-problem
            @try{
                // parse the user data
                randomNumberClient = [[userData objectAtIndex:0] intValue];
                firstVisitStartUnixTimestamp = [[userData objectAtIndex:1] doubleValue] ;
                previousVisitStartUnixTimestamp =[[userData objectAtIndex:2] doubleValue] ;
                currentVisitStartUnixTimestamp = [[userData objectAtIndex:3] doubleValue] ;
                sessionCount =  [[userData objectAtIndex:4] intValue];
                lifeTimeEventCount = [[userData objectAtIndex:5] intValue] ;
                
                // if the session is already started then just update the
                // event count
                if (isSessionStarted) {
                   lifeTimeEventCount++;
                } else {
                    // do the work, to start a new session
                    if (currentTime - currentVisitStartUnixTimestamp >= sessionLapseTimeMs) {
                        previousVisitStartUnixTimestamp = currentVisitStartUnixTimestamp;
                        currentVisitStartUnixTimestamp =  ([[NSDate date] timeIntervalSince1970] * 1000);
                        sessionCount++;
                        lifeTimeEventCount++;
                    } else {
                        // not a new session, just update lifeTimeEventCount
                        lifeTimeEventCount++;
                    }
                }
            } @catch (NSException *e) {
                NSLog(@"otui has corrupted data: %@", [e reason]);
                 NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
                [logDictionary setObject:@"otui has corrupted data" forKey:@"message"];
                [logDictionary setObject:[e reason] forKey:@"reason"];
                [logDictionary setObject:[e callStackSymbols] forKey:@"exception"];
                [OTSend send:logDictionary];
                [logDictionary  release];
                
                // handle corruption: reinitialize everything
                randomNumberClient = rand();
                firstVisitStartUnixTimestamp =  ([[NSDate date] timeIntervalSince1970] * 1000);
                previousVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
                currentVisitStartUnixTimestamp = firstVisitStartUnixTimestamp;
                sessionCount = 1;
                lifeTimeEventCount = 1;
                
            }
        }
    }
   
    //see http://www.cocoadev.com/index.pl?NSLog
    // format the otUserData
    otUserData = [NSString stringWithFormat:@"%d.%.0f.%.0f.%.0f.%d.%d", randomNumberClient, firstVisitStartUnixTimestamp, previousVisitStartUnixTimestamp, currentVisitStartUnixTimestamp, sessionCount, lifeTimeEventCount ];
    
    @try {
        [OTFileUtils  writeFile:otuifilename withString:otUserData];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while writing to otui: %@", [exception reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Exception while writing to otui" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        //TODO: send this to OTSend.send(hashmap)
        [logDictionary  release];
    }
    NSLog(@"otui write: %@", otUserData);
    
    // same thing for session data
    NSString *otsfilename = @"ots";
    @try {
        [OTFileUtils  makeFile: otsfilename];
    }
    @catch (NSException *exception) {
        NSLog(@"Can't make file ots");
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Can't make file ots" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
    
    // Create data with initial parameters
    int sessionEventCount = 1;
    double currentSessionStartUnixTimestamp = currentVisitStartUnixTimestamp;
    double previousEventStartUnixTimestamp = currentSessionStartUnixTimestamp;
    double currentEventStartUnixTimestamp = currentSessionStartUnixTimestamp;
    NSString *otSessionData = nil;

    // if session is already started
    if (isSessionStarted) {
        @try{
            otSessionData = [OTFileUtils readFile:otsfilename];
        }
        @catch (NSException *exception) {
            NSLog(@"Can't read file ots");
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
            [logDictionary setObject:@"Can't read file ots" forKey:@"message"];
            [logDictionary setObject:[exception reason] forKey:@"reason"];
            [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
            [logDictionary  release];
            //TODO: send this to OTSend.send(hashmap)
        }
        // if data doesn't exist -> create data with initial parameters
        if (otUserData != nil) {
            // initialize the data
            NSArray *sessionData = [otSessionData componentsSeparatedByString: @"."];
            if ([sessionData count] != 4) {
                NSLog(@"Data is corrupted length: %d, sessionData: %@" ,[sessionData count], sessionData);
                NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
                [logDictionary setObject:@"Got corrupt ots, wrong length." forKey:@"message"];
                //TODO: send this to OTSend.send(hashmap)
                [logDictionary  release];
                // data is corrupted, and intialized
                
            } else {
                @try {
                    // parse the user data
                    sessionEventCount = [[sessionData objectAtIndex:0] intValue];
                    currentSessionStartUnixTimestamp = [[sessionData objectAtIndex:1] doubleValue];
                    previousEventStartUnixTimestamp = [[sessionData objectAtIndex:2] doubleValue];
                    currentEventStartUnixTimestamp = [[sessionData objectAtIndex:3] doubleValue];
                    
                    // do the work, to start a new event
                    sessionEventCount++;
                    previousEventStartUnixTimestamp = currentEventStartUnixTimestamp;
                    currentEventStartUnixTimestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
                } @catch (NSException * e) {
                    NSLog(@"ots has corrupted data: %@", [e reason]);
                    NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                    [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
                    [logDictionary setObject:@"ots has corrupted data" forKey:@"message"];
                    [logDictionary setObject:[e reason] forKey:@"reason"];
                    [logDictionary setObject:[e callStackSymbols] forKey:@"exception"];
                    [OTSend send:logDictionary];
                    [logDictionary  release];
                    
                    // just reinitialize everything
                    sessionEventCount = 1;
                    currentSessionStartUnixTimestamp = currentVisitStartUnixTimestamp;
                    previousEventStartUnixTimestamp = currentSessionStartUnixTimestamp;
                    currentEventStartUnixTimestamp = currentSessionStartUnixTimestamp;
                }
            }
        }
    }
    
    otSessionData = [NSString stringWithFormat:@"%d.%.0f.%.0f.%.0f", sessionEventCount, currentSessionStartUnixTimestamp, previousEventStartUnixTimestamp, currentEventStartUnixTimestamp ];
    
    @try {
        [OTFileUtils writeFile:otsfilename withString:otSessionData];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while writing to ots: %@", [exception reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Exception while writing to ots" forKey:@"message"];
        [logDictionary setObject:[exception reason] forKey:@"reason"];
        [logDictionary setObject:[exception callStackSymbols] forKey:@"exception"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
    NSLog(@"ots write: %@" ,otSessionData); 

    isSessionStarted = YES;
    
    [pool release];
    return sessionEventCount;
}

//see mutable dictionary : http://stackoverflow.com/questions/1760371/how-can-we-store-into-an-nsdictionary-what-is-the-difference-between-nsdictionar

-(void)sendEvent:(NSObject *)object {
    NSLog(@"sendEvent: %@",object);
    //see :  http://stackoverflow.com/questions/1144629/in-objective-c-how-do-i-test-the-object-type
    if([object isKindOfClass:[NSString class]]) {
        [self sendEventString:object addSessionState:YES];
    } else  {
        [self sendEventDictionary:object addSessionState:YES];
    }
    
}


-(void) sendEventString :(NSString *)event addSessionState:(BOOL) appendSessionStateData {
    NSLog(@"sendEventString:%@ addSessionState: %@", event , appendSessionStateData ? @"YES" : @"NO");
    
    // update the sessionData
    int eventCount = [self registerSessionEvent];
    NSMutableDictionary *keyValuePairs = [[NSMutableDictionary alloc] init];
    //TODO : make appname static string assigned using init
    [keyValuePairs setObject:appname forKey:@"si"];
    [keyValuePairs setObject:event forKey:@"ti"];
    [keyValuePairs setObject:[OTDataSockets networkType] forKey:@"connection"];
    //TODO : make appname static string assigned using init
    [keyValuePairs setObject:[NSString stringWithFormat:@"http://app.opentracker.net/%@/%@",appname,[event stringByReplacingOccurrencesOfString:@"/" withString:@"."]] forKey:@"lc" ];
    @try {
        [keyValuePairs setObject:[OTFileUtils readFile:@"otui"] forKey:@"otui"];
        [keyValuePairs setObject:[OTFileUtils readFile:@"ots"] forKey:@"ots"];
    } @catch (NSException *e) {
       NSLog(@"Exception while reading to ots/ otui: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:@"Exception while reading to ots/ otui" forKey:@"message"];
        [logDictionary setObject:[e reason] forKey:@"reason"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
    if (eventCount == 1) {
        [keyValuePairs setObject:[OTDataSockets screenHeight] forKey:@"sh"];
        [keyValuePairs setObject:[OTDataSockets screenWidth] forKey:@"sw"];
        [keyValuePairs setObject:[OTDataSockets appVersion] forKey:@"version"];
        //[keyValuePairs setObject:[OTDataSockets ipAddress] forKey:@"ip"];
    }
    
    // also add any session state data
    NSMutableDictionary *keyValuePairsMerged =[[NSMutableDictionary alloc] init];
    
    if (appendSessionStateData) {
       NSMutableDictionary *dataFiles = nil;
        @try {
            //TODO make gtSessionStateDataPairs
            //dataFiles = otFileUtil.getSessionStateDataPairs();
        } @catch (NSException *e) {
            NSLog(@"Exception while getting fileName data pairs");
            NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
            [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
            [logDictionary setObject:[e reason] forKey:@"message"];
            [OTSend send:logDictionary];
            [logDictionary  release];
        }
        if (dataFiles != nil)
            [keyValuePairsMerged addEntriesFromDictionary:dataFiles];
    }
    if (keyValuePairs != nil)
    [keyValuePairsMerged addEntriesFromDictionary:keyValuePairs];
    @try {
        [self appendDataToFile:keyValuePairsMerged];
    } @catch (NSException *e) {
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
}

-(void) sendEventDictionary :(NSMutableDictionary *)keyValuePairs addSessionState:(BOOL)appendSessionStateData {
     NSLog(@"sendEventDictionary(%@)" , appendSessionStateData ? @"YES" : @"NO");
    
    // also add any session state data
    NSMutableDictionary *keyValuePairsMerged =[[NSMutableDictionary alloc] init];
    [keyValuePairsMerged setObject:appname forKey:@"si"];
    
     if (appendSessionStateData) {
            NSMutableDictionary *dataFiles = nil;
            @try {
                //TODO make gtSessionStateDataPairs
                //dataFiles = otFileUtil.getSessionStateDataPairs();
            } @catch (NSException *e) {
                NSLog(@"Exception while getting fileName data pairs");
                NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
                [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
                [logDictionary setObject:[e reason] forKey:@"message"];
                [OTSend send:logDictionary];
                [logDictionary  release];
            }
         if (dataFiles != nil)
             [keyValuePairsMerged addEntriesFromDictionary:dataFiles];
     }
    if (keyValuePairs != nil)
        [keyValuePairsMerged addEntriesFromDictionary:keyValuePairs];
    @try {
        [self appendDataToFile:keyValuePairsMerged];
    } @catch (NSException *e) {
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
        //TODO: send this to OTSend.send(hashmap)
        [logDictionary  release];
    }
}

-(void) appendDataToFile : (NSMutableDictionary*) dataDictionary {
    NSLog(@"appendDataToFile");
    NSString *devicename = [[UIDevice currentDevice] systemName];

    NSString *url = @"http://log.opentracker.net/?";

    [dataDictionary setObject:[NSString stringWithFormat:@"%.0f", ([[NSDate date] timeIntervalSince1970] *1000 ) ] forKey:@"t"];
    for (id key in dataDictionary) {
        NSString *value = [dataDictionary objectForKey:key];
        url = [NSString stringWithFormat:@"%@%@=%@&", url, [OTSend urlEncoded:key], [OTSend urlEncoded:value]];
        
    }
    NSLog(@"appending url: %@", url);
    @try {
        [OTFileUtils makeFile: @"fileToSend"];
        [OTFileUtils appendToFile:@"fileToSend" writeString:url];
    } @catch (NSException *e) {
        NSLog(@"Exception while appending data to file: %@", [e reason]);
        NSMutableDictionary *logDictionary = [[NSMutableDictionary alloc] init];
        [logDictionary setObject:@"errors" forKey:@"si"]; // log to error appName
        [logDictionary setObject:[e reason] forKey:@"message"];
        [OTSend send:logDictionary];
        [logDictionary  release];
    }
}


-(void) uploadCompressedFile {
    NSLog(@"uploadCompressedFile");

    @try {

        
        NSString *gzippedFile = [self compress:@"fileToSend"];
        double time1 = [[NSDate date] timeIntervalSince1970];
        NSString *url = @"http://upload.opentracker.net/api/upload/upload.jsp";
        BOOL response  = [OTSend uploadFile:gzippedFile toServer:url];
        double time2 = [[NSDate date] timeIntervalSince1970];
        if (response) {
            //NSLog(@"The response : %@", response);
            [OTFileUtils removeFile:gzippedFile];
            [OTFileUtils removeFile:@"fileToSend"];
            NSLog(@"cleared files");
        } else {
            NSLog(@"File did not empty!");
            [OTFileUtils removeFile:gzippedFile];
        }
    } 
    @catch (NSException *e) {
        NSLog(@"gzip file not created/uploaded");
    }
}


-(NSString *) urlEncoded : (NSString*) url
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)url,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
    // NSLog(@"url encoded format: %@", urlString);
    return [(NSString *)urlString autorelease];
}

-(NSString*) compress : (NSString*) fileToCompress {
    NSLog(@"uploadZippedFile");
    NSString *gzippedfilename = fileToCompress;
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    
    // File we want to create in the documents directory 
    // Result is: /Documents/file1.txt
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:fileToCompress];
    
	if ([fileMgr isReadableFileAtPath:filePath] && [NSFileTypeRegular isEqual: [[fileMgr attributesOfItemAtPath:filePath error:nil] fileType]]) {
		@try {
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
