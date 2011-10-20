//
//  OTExampleAppDelegate.h
//  OTExample
//
//  Created by Pavitra on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTExampleViewController;

@interface OTExampleAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet OTExampleViewController *viewController;

@end
