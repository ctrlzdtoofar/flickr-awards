//
//  NetworkAvailability.m
//  FlickrAwards
//
//  Created by Heather Stevens on 2/27/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "NetworkAvailability.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface NetworkAvailability() {
    SCNetworkReachabilityRef defaultRouteReachability;   
}
@end

@implementation NetworkAvailability

@synthesize statusMsg = _statusMsg;

// Get address to test connectivity.
- (struct sockaddr_in)getZeroAddress {
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return zeroAddress;
}

// Lazy create zero address reachability reference.
- (SCNetworkReachabilityRef) getNetworkReachabilityReference {
    if (!defaultRouteReachability) {
        struct sockaddr_in address = [self getZeroAddress];
        defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
    }
    
    return defaultRouteReachability;
}

// Get flags to findout what connectivity is available.
- (SCNetworkReachabilityFlags)getReachabilityFlaqs {
    
    SCNetworkReachabilityFlags reachabilityFlags;
    
    BOOL gotFlags = SCNetworkReachabilityGetFlags([self getNetworkReachabilityReference], &reachabilityFlags);
    if (!gotFlags) {
        NSLog(@"NetworkAvailability.getReachabilityFlaqsUsingZeroAddress failed.");
    }    
    
    return reachabilityFlags;
}

/*
 kSCNetworkReachabilityFlagsTransientConnection     = 1<<0,
 kSCNetworkReachabilityFlagsReachable               = 1<<1,
 kSCNetworkReachabilityFlagsConnectionRequired      = 1<<2,
 kSCNetworkReachabilityFlagsConnectionOnTraffic     = 1<<3,
 kSCNetworkReachabilityFlagsInterventionRequired	= 1<<4,
 kSCNetworkReachabilityFlagsConnectionOnDemand      = 1<<5,
 kSCNetworkReachabilityFlagsIsLocalAddress          = 1<<16,
 kSCNetworkReachabilityFlagsIsDirect                = 1<<17,
 kSCNetworkReachabilityFlagsIsWWAN                  = 1<<18,
 */
// Get network connectivity status
- (NetworkStatus)getNetworkStatus {
    
    NetworkStatus status;
    
    SCNetworkReachabilityFlags flags = [self getReachabilityFlaqs];    
    
    self.statusMsg = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c",
                      (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-', // when connection is Cellular
                      (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-', // when there is a connection
                      (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-', // got this both times too.
                      (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
                      (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
                      (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
                      (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
                      (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-', // not sure, got it on both times.
                      (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
    
    
    //NSLog(@"NetworkAvailability.getNetworkStatus Reachability Flag Status: %@",self.statusMsg);
    
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
        status = cellularConnection;
        //NSLog(@"NetworkAvailability.getNetworkStatus have cellular");
    }
    else if (flags & kSCNetworkReachabilityFlagsReachable) {
        status = wiFiConnection;
        //NSLog(@"NetworkAvailability.getNetworkStatus have wifi");
    }
    else {
        status = noConnection;
        //NSLog(@"NetworkAvailability.getNetworkStatus no connection");
    }
    
    return status;
}

@end
