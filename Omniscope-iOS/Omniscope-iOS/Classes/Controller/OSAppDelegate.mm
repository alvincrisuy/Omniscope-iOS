//
//  AppDelegate.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 31/01/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSAppDelegate.h"
#import "OSRootViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface OSAppDelegate ()

@end

@implementation OSAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    if (!self.rootViewController) {
        OSRootViewController *vc = [[OSRootViewController alloc] init];
        vc.view.frame = [[UIScreen mainScreen] bounds];
        self.rootViewController = vc;
        [self.window addSubview:self.rootViewController.view];
        self.window.rootViewController = self.rootViewController;
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    if (self.glResourceHandler) {
        // As per Apple's documentation,
        // we call glFinish in applicationWillResignActive
        [self.glResourceHandler finishOpenGLESCommands];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if (self.glResourceHandler) {
        // Delete OpenGL resources (e.g. framebuffer) of the SampleApp AR View
        [self.glResourceHandler freeOpenGLESResources];
        [self.glResourceHandler finishOpenGLESCommands];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}


@end
