//
//  NetworkAvailability.h
//  FlickrAwards
//
//  Created by Heather Stevens on 2/27/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface NetworkAvailability : NSObject

@property (nonatomic, retain) NSString *statusMsg;

typedef enum {
    noConnection = 0,
    canGetCellularConnection,
    cellularConnection,
    wiFiConnection    
} NetworkStatus;

// Key used with network change notifications.
#define kNoNetworkConnectivity @"No Internet Connection"
// Returns the current network connectivity/reachability status.
- (NetworkStatus)getNetworkStatus;

@end
