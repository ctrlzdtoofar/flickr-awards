//
//  UserSessionModel.h
//  Flckr1
//
//  Created by Heather Stevens on 1/13/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAvailability.h"

@interface UserSessionModel : NSObject

@property (nonatomic) BOOL wifiConnected;
@property (nonatomic) BOOL lowMemory;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *fullName;
@property (nonatomic, retain) NSString *userNsid;
@property (nonatomic, retain) NSString *oauthToken;
@property (nonatomic, retain) NSString *oauthTokenSecret;
@property (nonatomic, retain) NSString *oauthVerifier;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSString *accessTokenSecret;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSString *responseMessage;

@property (nonatomic, retain) NSMutableDictionary *sessionStore;

@property (atomic, retain) NSArray *photoList;
@property (atomic, retain) NSArray *groupList;

// Groups that have awards already defined in the local db.
@property (atomic, retain) NSMutableArray *groupWithAwardList;
@property (atomic) NetworkStatus networkStatus;

@property (nonatomic, retain) NSMutableDictionary *cachedImages;

- (void)syncSessionStore;
- (BOOL)shouldLoadNewPhotos;
- (BOOL)shouldLoadNewGroups;

// Image cache for expediency.
- (void)addImageToCache:(UIImage *)image withKey:(NSString *)photoId ;
- (UIImage *)getCachedImage:(NSString *)photoId;
- (void)clearImageCache;

- (BOOL)haveInternetBeOptimistic:(BOOL) beOptimistic;

@end
