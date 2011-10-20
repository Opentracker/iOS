//
//  OTDataSockets.h
//  opentracker
//
//  Created by Pavitra on 10/3/11.
//  Copyright 2011 Opentracker. All rights reserved.
//  This file also includes code from Reachability. (check below documentation for details)
/*!
 @class OTDataSockets 
 @discussion This class contains all methods used to access data from the phone such 
 as IP addresses, screen resolution ,  connectivity etc
 This file includes functions from Reachability (An Object Class created by Apple), the copyright details from Reachability
 Object class have been copied below :
 */

/*
 File: Reachability.h
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef enum {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;
#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"
@interface OTDataSockets : NSObject {
      CLLocationManager *locationManager;
      BOOL localWiFiRef;
      SCNetworkReachabilityRef reachabilityRef;
}
@property (nonatomic,retain) CLLocationManager *locationManager;

+(NSString*) ipAddress ; 
+(NSString*) screenWidth ; 
+(NSString*) screenHeight ;


//reachabilityWithAddress- Use to check the reachability of a particular IP address. 
+ (OTDataSockets*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;

//reachabilityForInternetConnection- checks whether the default route is available.  
//  Should be used by applications that do not connect to a particular host
+ (OTDataSockets*) reachabilityForInternetConnection;
- (NetworkStatus) currentReachabilityStatus;
- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags;
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags;

/*!
 * @method networkType
 * @abstract Gets the string for the type of network being used
 * @return wifi , wlan or no netowrk depending on the connection.
 */
+(NSString*) networkType ;
/*!
 * @method appVersion
 * @abstract Gets the pretty string for this application's version.
 * @return The application's version as a pretty string
 */
+(NSString*) appVersion ; 
+(NSString*) getLocation ; //not necessary
/*!
 * @method locationCoordinates
 * @abstract Gets the pretty string for the latitude
 * and longitude coordinates of the current location.
 * @return latitude and longitude string sepearted by a ','
 */
+(NSString*) locationCoordinates;

@end
