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


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+(NSString*) ipAddress {
    /*char iphone_ip[255];
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
    /*struct ifaddrs *interfaces = NULL;
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
    return address;
}

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

+ (OTDataSockets*) reachabilityForInternetConnection;
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self reachabilityWithAddress: &zeroAddress];
}

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



+(NSString*) networkType {
    //type of internet connection :  http://developer.apple.com/library/ios/#samplecode/Reachability/Introduction/Intro.html
    OTDataSockets* curReach = [OTDataSockets reachabilityForInternetConnection];
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus] ;
    NSString* statusString= @"";
    
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"access not vvailable";
            //NSLog(statusString); 
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"WWAN";
            //NSLog(statusString);
            break;
        }
        case ReachableViaWiFi:
        {
            statusString= @"wifi";
            //NSLog(statusString);
            break;
        }
    }
    return statusString;
}

+(NSString*) screenWidth {
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    return [NSString stringWithFormat:@"%3.0f",  cgSize.width];
}

+(NSString*) screenHeight {
    CGRect cgRect =[[UIScreen mainScreen] bounds];
    CGSize cgSize = cgRect.size;
    return [NSString stringWithFormat:@"%3.0f",  cgSize.height];
}

+(NSString*) appVersion {
    //see:  http://www.iphonedevsdk.com/forum/iphone-sdk-development/17740-how-get-app-version-number.html
   return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+(NSString*) device {
    //see:  http://www.iphonedevsdk.com/forum/iphone-sdk-development/17740-how-get-app-version-number.html
    return [[UIDevice currentDevice] systemName];
}

- (NSString*) locationCoordinates { 
    
    // locationManager update as location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self; 
    locationManager.desiredAccuracy = kCLLocationAccuracyBest; 
    locationManager.distanceFilter = kCLDistanceFilterNone; 
    [locationManager startUpdatingLocation];
    
    CLLocation *location = [locationManager location];
    
    
    // Configure the new event with information from the location
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    NSString *latitude = [NSString stringWithFormat:@"%f", coordinate.latitude]; 
    NSString *longitude = [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    //NSLog(@"dLatitude : %@", latitude); 
    //NSLog(@"dLongitude : %@",longitude);
    
    NSString *locationCoordinates = [NSString stringWithFormat:@"%@,%@",latitude, longitude];
    
    return locationCoordinates;
    
}
@end
