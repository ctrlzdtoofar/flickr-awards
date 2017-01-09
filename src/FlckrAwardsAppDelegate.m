//
//  FlckrAwardsAppDelegate.m
//  FlickrAwards
//
//  Created by Heather Stevens on 2/26/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "FlckrAwardsAppDelegate.h"
#import "Flickr1NavigationController.h"
#import "FlckrViewController.h"
#import "NetworkAvailability.h"

@interface FlckrAwardsAppDelegate() {
    BOOL networkAvailabilityNotifierStarted;
}

@property (nonatomic, retain) NetworkAvailability *networkAvailability;

@end
@implementation FlckrAwardsAppDelegate

@synthesize window = _window;
@synthesize networkAvailability = _networkAvailability;

// Start the network notifier if it isn't already running.
- (void)startNetworkAvailabilityNotifierIfNeeded {
    
    @synchronized(self.networkAvailability) {
        if (!networkAvailabilityNotifierStarted) {
            networkAvailabilityNotifierStarted = YES;
            
            // Get the user session model from the nav controller.
            UserSessionModel *userSessionModel = ((Flickr1NavigationController *)self.window.rootViewController).userSessionModel;
            
            // Update the nav controller's user session model
            if (userSessionModel) {
            
                userSessionModel.networkStatus = [self.networkAvailability getNetworkStatus];
            }
        }
    }
}

// Stop the network notifier if it is running.
- (void)stopNetworkAvailabilityNotifierIfNeeded {
    
    @synchronized(self.networkAvailability) {
        if (networkAvailabilityNotifierStarted) {
                    
            networkAvailabilityNotifierStarted = NO;
        }
    }
}

// Lazy create the network availability notifier.
- (NetworkAvailability *) networkAvailability {
    if (!_networkAvailability) {
        _networkAvailability = [[NetworkAvailability alloc] init];
    }
    
    return _networkAvailability;
}

// Called when application opens this app with a URL.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    [self startNetworkAvailabilityNotifierIfNeeded];
    
    if ([url.relativeString hasPrefix:@"flickrawards://oauthlogin"] && url.query) {
        
        //NSLog(@"Application %@ with query %@ matches", sourceApplication, url.relativeString);
        
        NSArray *ctrlArray = ((UINavigationController *)self.window.rootViewController).viewControllers;
        for (UIViewController *ctrl in ctrlArray) {
            
            if ([ctrl isKindOfClass:[FlckrViewController class]]) {
                
                FlckrViewController *flckrViewController = (FlckrViewController *)ctrl;
                [flckrViewController continueLoginProcess:url.query];                        
                return YES;        
            }                    
        }    
    }
    
    NSLog(@"Failed to set Yahoo query, url: %@", url.relativeString);
    
    return NO;
}

// Upon becoming active start network connectivity notifications.
- (void)applicationDidBecomeActive:(UIApplication *)application {
   // NSLog(@"FlckrAwardsAppDelegate.applicationDidBecomeActive");
    
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    [self startNetworkAvailabilityNotifierIfNeeded];
    
    //NetworkAvailability *net = [[NetworkAvailability alloc] init];    
    //[net getNetworkStatus];
}

// Upon becoming inactive stop network connectivity notifications.
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    //NSLog(@"FlckrAwardsAppDelegate.applicationWillResignActive");
    
    [self stopNetworkAvailabilityNotifierIfNeeded];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //NSLog(@"FlckrAwardsAppDelegate.didFinishLaunchingWithOptions");
    
    // Override point for customization after application launch.
    [self startNetworkAvailabilityNotifierIfNeeded];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   // NSLog(@"FlckrAwardsAppDelegate.applicationDidEnterBackground");
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self stopNetworkAvailabilityNotifierIfNeeded];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    //NSLog(@"FlckrAwardsAppDelegate.applicationWillEnterForeground");
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [self startNetworkAvailabilityNotifierIfNeeded];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //NSLog(@"FlckrAwardsAppDelegate.applicationWillTerminate");
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self stopNetworkAvailabilityNotifierIfNeeded];
    
}

@end
