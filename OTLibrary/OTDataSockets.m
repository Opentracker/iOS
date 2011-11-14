//
//  OTDataSockets.m
//  opentracker
//
//  Created by Pavitra on 10/3/11.
//  Copyright 2011 Opentracker. All rights reserved.
//

#import "OTDataSockets.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>
#define kShouldPrintReachabilityFlags 1

// Global

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment)
{
#if kShouldPrintReachabilityFlags
    
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
          
          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          comment
          );
#endif
}


@implementation OTDataSockets
@synthesize cacheType;
static long EXPIRE_S =  60l;


- (id)init
{
    self = [super init];
    cacheType = [[NSMutableDictionary alloc] init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#pragma mark IP Address

+(NSString*) ipAddress {
    /*
     char iphone_ip[255];
     strcpy(iphone_ip,"127.0.0.1"); // if everything fails
     NSHost* myhost =[NSHost currentHost];
     if (myhost)
     {
     NSString *ad = [myhost address];
     if (ad)
     strcpy(iphone_ip,[ad cStringUsingEncoding: NSISOLatin1StringEncoding]);
     }
     return [NSString stringWithFormat:@"%s",iphone_ip]; */
    NSString *address = @"error";
    /*
	 struct ifaddrs *interfaces = NULL;
     struct ifaddrs *temp_addr = NULL;
     int success = 0;
     // retrieve the current interfaces - returns 0 on success
     success = getifaddrs(&interfaces);
     if (success == 0)
     {
     // Loop through linked list of interfaces
     temp_addr = interfaces;
     while(temp_addr != NULL)
     {
     if(temp_addr->ifa_addr->sa_family == AF_INET)
     {
     // Check if interface is en0 which is the wifi connection on the iPhone
     if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
     {
     // Get NSString from C String
     address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
     }
     }
     temp_addr = temp_addr->ifa_next;
     }
     }
     // Free memory
     freeifaddrs(interfaces);*/
	NSLog(@"address %@",address);
    return address;
}

#pragma mark Network Reachability With Address

+ (OTDataSockets*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    OTDataSockets* retVal = NULL;
    if(reachability!= NULL)
    {
        retVal= [[[self alloc] init] autorelease];
        if(retVal!= NULL)
        {
            retVal->reachabilityRef = reachability;
            retVal->localWiFiRef = NO;
        }
    }
    return retVal;
}

#pragma mark  Network Reachability For Internet Connection

+ (OTDataSockets*) reachabilityForInternetConnection;
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self reachabilityWithAddress: &zeroAddress];
}

#pragma mark Current Network Reachability Status

- (NetworkStatus) currentReachabilityStatus
{
    NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
    NetworkStatus retVal = NotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
    {
        if(localWiFiRef)
        {
            retVal = [self localWiFiStatusForFlags: flags];
        }
        else
        {
            retVal = [self networkStatusForFlags: flags];
        }
    }
    return retVal;
}
#pragma mark Network Flag Handling

- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags
{
    PrintReachabilityFlags(flags, "localWiFiStatusForFlags");
    
    BOOL retVal = NotReachable;
    if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
    {
        retVal = ReachableViaWiFi;  
    }
    return retVal;
}

#pragma mark Network Status For Flags

- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags
{
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // if target host is not reachable
        return NotReachable;
    }
    
    BOOL retVal = NotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = ReachableViaWiFi;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            retVal = ReachableViaWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = ReachableViaWWAN;
    }
    return retVal;
}

#pragma mark Network Type

-(NSString*) networkType {
    if ([cacheType objectForKey:@"last modified time"]!= nil && (([[cacheType objectForKey:@"last modified time"] doubleValue]) > ([[NSDate date] timeIntervalSince1970]- EXPIRE_S)) ) {
        return [cacheType objectForKey:@"networkType"];
    }
    
    //type of internet connection :  http://developer.apple.com/library/ios/#samplecode/Reachability/Introduction/Intro.html
    OTDataSockets* curReach = [OTDataSockets reachabilityForInternetConnection];
    NetworkStatus netStatus = [curReach currentReachabilityStatus] ;
    NSString* statusString= @"no network";
    
    
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"no network";
            //NSLog(statusString); 
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"mobile";
            //NSLog(statusString);
            break;
        }
        case ReachableViaWiFi:
        {
            statusString= @"Wi-Fi";
            //NSLog(statusString);
            break;
        }
    }
    
    [cacheType setObject:statusString forKey:@"networkType"];
    [cacheType setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"last modified time"];

    return [cacheType objectForKey:@"networkType"];
}

#pragma mark Screen Width

+(NSString*) screenWidth {
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    return [NSString stringWithFormat:@"%3.0f",  cgSize.width];
}

#pragma mark Screen Height

+(NSString*) screenHeight {
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    return [NSString stringWithFormat:@"%3.0f",  cgSize.height];
}

#pragma mark Application Version
/*
 This method will returns you the current app version
 */
+(NSString*) appVersion {
    //see:  http://www.iphonedevsdk.com/forum/iphone-sdk-development/17740-how-get-app-version-number.html
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

#pragma mark Current Location Coordinates
/*
 This Method will return you the current location coordinates in string.
 For this we have used CLLocationManager.
 */
+ (NSString*) locationCoordinates { 
    
    // locationManager update as location
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest; 
    locationManager.distanceFilter = kCLDistanceFilterNone; 
    locationManager.delegate = self;
	//start update location will starts finding the location coordinates and updates 
    [locationManager startUpdatingLocation];
    
    CLLocation *location = [locationManager location];
    
    // Configure the new event with information from the location
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    NSString *latitude = [NSString stringWithFormat:@"%f", coordinate.latitude]; 
    NSString *longitude = [NSString stringWithFormat:@"%f", coordinate.longitude];
    

    
    NSString *locationCoordinates = [NSString stringWithFormat:@"%@,%@",latitude, longitude];
    
	NSLog(@"12345 locationCoordinates  %@",locationCoordinates);
        
    return locationCoordinates;
    
    
}
#pragma mark Current Platform
/*
 This Method will return the Operating system of the current device
 */
+(NSString*) platform {
   return [[UIDevice currentDevice] systemName];
}

#pragma mark Current Platform Version
/*
 This Method will return the Operating system version of the current device
 */
+(NSString*) platformVersion {
    return [[UIDevice currentDevice] systemVersion];
}

#pragma mark Device
/*
 This method will return the current device
 Whether the application in on iPhone or iPod Touch or iPad
 */
+(NSString*) device {
    //see:  http://www.iphonedevsdk.com/forum/iphone-sdk-development/4960-how-identify-device-user.html
    return [[UIDevice currentDevice] model];
}
@end
