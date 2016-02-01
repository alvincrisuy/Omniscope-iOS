//
//  AppDelegate.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 31/01/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSRootViewController;

@interface OSAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) OSRootViewController *rootViewController;

@end

