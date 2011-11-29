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
@interface OTDataSockets : NSObject<CLLocationManagerDelegate> 
{
    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;
    NSMutableDictionary *cacheType ; 
}
@property (nonatomic, retain) NSMutableDictionary *cacheType ; 
/*!
 * @method ipAddress
 * @abstract Gets the string for ipAddress.
 * @return The ipAddress as a string 
 */

+(NSString*) ipAddress ; 

/*!
 * @method screenWidth
 * @abstract Gets the string for current screen Width.
 * @return The current screen Width as a string 
 */
+(NSString*) screenWidth ; 

/*!
 * @method screenHeight
 * @abstract Gets the string for current screen Height.
 * @return The current screen Height as a string 
 */
+(NSString*) screenHeight ;

/*!
 * @method reachabilityWithAddress
 * @abstract Use to check the reachability of a particular IP address. 
 * @return An object of the class OTDataSockets
 */
+ (OTDataSockets*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;

/*!
 * @method reachabilityForInternetConnection
 * @abstract checks whether the default route is available.  
 Should be used by applications that do not connect to a particular host 
 * @return An object of the class OTDataSockets
 */  
+ (OTDataSockets*) reachabilityForInternetConnection;

/*!
 * @method currentReachabilityStatus
 * @abstract Use to check the current reachability status of a particular IP address. 
 * @return	NotReachable variable if no reachability found
 *          ReachableViaWiFi variable if the device is using WIFI for network connection
 *          ReachableViaWWAN variable if the device is using WWAN for network connection 
 */     
- (NetworkStatus) currentReachabilityStatus;

/*!
 * @method localWiFiStatusForFlags
 * @abstract Use to get NetworkStatus flag for local WIFI status
 * @return BOOL based on the local WiFi Status
 */
- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags;

/*!
 * @method networkStatusForFlags
 * @abstract Use to get NetworkStatus flag 
 * @return BOOL based on NotReachable or ReachableViaWiFi or ReachableViaWWAN
 */
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags;

/*!
 * @method networkType
 * @abstract Gets the string for the type of network being used
 * @return wifi , wlan or no network depending on the network connection.
 */
- (NSString*) networkType ;

/*!
 * @method appVersion
 * @abstract Gets the pretty string for this application's version.
 * @return The application's version as a pretty string
 */
+(NSString*) appVersion ; 

/*!
 * @method locationCoordinates
 * @abstract Gets the pretty string for the latitude
 *			 and longitude coordinates of the current location.
 * @return latitude and longitude string seperated by a ','
 */
+(NSString*) locationCoordinates;
/*!
 * @method platform
 * @abstract Gets the string of the platform on which
 *           the current device is running.
 * @return platform name as a pretty string.
 */
+(NSString*) platform;
/*!
 * @method platformVersion
 * @abstract Gets the string of the platform version of
 *           the current device is running.
 * @return platform name as a pretty string.
 */
+(NSString*) platformVersion;
/*!
 * @method device
 * @abstract Gets the string of the model name of
 *           the current device which is running.
 * @return model name as a pretty string.
 */
+(NSString*) device;

/*!
 * @method carrier
 * @abstract Gets the string of the carrier service
 *           provider of the current device.
 * @return carrier name as a pretty string.
 */
+(NSString*) carrier;
/*!
 * @method locale
 * @abstract Gets the string of the current language
 *           set on the phone. If it en_US, fr_FR
 * @return language as a string.
 */
+(NSString*) locale;
@end
    