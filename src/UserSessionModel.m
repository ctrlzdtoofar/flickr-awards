//
//  UserSessionModel.m
//  Flckr1
//
//  Created by Heather Stevens on 1/13/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "UserSessionModel.h"
#import "Photo.h"
#import "Group.h"

@implementation UserSessionModel

@synthesize wifiConnected = _wifiConnected;
@synthesize lowMemory = _lowMemory;
@synthesize userName = _userName;
@synthesize fullName = _fullName;
@synthesize userNsid = _userNsid;
@synthesize oauthToken = _oauthToken;
@synthesize oauthTokenSecret = _oauthTokenSecret;
@synthesize oauthVerifier = _oauthVerifier;
@synthesize accessToken = _accessToken;
@synthesize accessTokenSecret = _accessTokenSecret;
@synthesize errorMessage = _errorMessage;
@synthesize responseMessage = _responseMessage;

@synthesize sessionStore = _sessionStore;
@synthesize photoList = _photoList;
@synthesize groupList = _groupList;
@synthesize networkStatus = _networkStatus;

// Groups with awards already defined and loaded from db or newly added.
@synthesize groupWithAwardList = _groupWithAwardList;
@synthesize cachedImages = _cachedMediumImages;

static NSString * const kAccessToken  = @"accessToken";
static NSString * const kAccessTokenSecret  = @"accessTokenSecret";
static NSString * const kUserName  = @"userName";
static NSString * const kFullName  = @"fullName";
static NSString * const kUserNsid  = @"userNsid";
static NSString * const kSessionStore  = @"FlickrAwards.sessionStore";

// Lazy create the dict for caching images.
- (NSMutableDictionary *)cachedImages {
    if (!_cachedMediumImages) {
        _cachedMediumImages = [[NSMutableDictionary alloc] init];
    }
    
    return _cachedMediumImages;
}

// Lookup image from cache
- (UIImage *)getCachedImage:(NSString *)photoId {
    
    return [self.cachedImages objectForKey:photoId];
}

// Add new ui image to cache.
- (void)addImageToCache:(UIImage *)image withKey:(NSString *)photoId {
    [self.cachedImages setObject:image forKey:photoId];
}

// Clear out the image cache to save memory and get rid of dated photos.
- (void)clearImageCache {
    [self.cachedImages removeAllObjects];
}

// Lazy load the standard user defaults dictionary.
- (NSDictionary *)sessionStore {

    if (!_sessionStore) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _sessionStore = [[defaults objectForKey:kSessionStore] mutableCopy];
        
        if (_sessionStore) {
            NSLog(@"UserSessionModel.sessionStore, got sessionStore from user defaults");
        }
        
        if (!_sessionStore) {
            _sessionStore = [[NSMutableDictionary alloc] init];
            [defaults setObject:_sessionStore forKey:kSessionStore];
            [defaults synchronize];
            NSLog(@"UserSessionModel.sessionStore, synced user defaults after creation.");
        }        
    }   
    
    return _sessionStore;
}

// Make sure any session changes are stored to user defaults.
- (void) syncSessionStore {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_sessionStore forKey:kSessionStore];
    [defaults synchronize];    
    //NSLog(@"UserSessionModel.syncSessionStore, synced user defaults after creation.");
}

// Determine if the list of photos in this model should be reloaded.
- (BOOL)shouldLoadNewPhotos {
    
    if (!self.photoList || self.photoList.count == 0) {
        return YES;
    }
    
    // Just check the first photo in the list, if it is expired, they all are.
    Photo *photo = [self.photoList objectAtIndex:0];        
    if ([photo isPhotoInfoExpired]) {
        [self clearImageCache];
        return YES;
    }
    
    return NO;
}

// Determine if the list of groups in this model should be reloaded.
- (BOOL)shouldLoadNewGroups {
    
    if (!self.groupList || self.groupList.count == 0) {
        return YES;
    }
    
    // Just check the first photo in the list, if it is expired, they all are.
    Group *group = [self.groupList objectAtIndex:0];        
    if ([group isGroupInfoExpired]) {
        return YES;
    }
    
    return NO;
}

// Get user name from local property or session store.
- (NSString *)userName {    
    if (!_userName) {
        _userName = [self.sessionStore objectForKey:kUserName];
        //NSLog(@"UserSessionModel.userName, found user %@ in session store.", _userName);
    }    
    return _userName;
}
// Set user name to session store and property.
- (void) setUserName:(NSString *)userName {
    _userName = userName;
    [self.sessionStore setObject:_userName forKey:kUserName];
}


// Get full name from local property or session store.
- (NSString *)fullName {    
    if (!_fullName) {
        _fullName = [self.sessionStore objectForKey:kFullName];
    }    
    return _fullName;
}
// Set full name to session store and property.
- (void) setFullName:(NSString *)fullName {
    _fullName = fullName;
    [self.sessionStore setObject:_fullName forKey:kFullName];
}


// Get userNsid from local property or session store.
- (NSString *)userNsid {    
    if (!_userNsid) {
        _userNsid = [self.sessionStore objectForKey:kUserNsid];
    }    
    return _userNsid;
}
// Set userNsid to session store and property.
- (void) setUserNsid:(NSString *)userNsid {
    _userNsid = userNsid;
    [self.sessionStore setObject:_userNsid forKey:kUserNsid];
}


// Get accessToken from local property or session store.
- (NSString *)accessToken {    
    if (!_accessToken) {
        _accessToken = [self.sessionStore objectForKey:kAccessToken];
    }  
    
    //NSLog(@"UserSessionModel.accessToken val %@", _accessToken);
    return _accessToken;
}
// Set accessToken to session store and property.
- (void) setAccessToken:(NSString *)accessToken {
    _accessToken = accessToken;
    [self.sessionStore setObject:_accessToken forKey:kAccessToken];
    //NSLog(@"UserSessionModel.setAccessToken val %@", _accessToken);
}


// Get accessTokenSecret from local property or session store.
- (NSString *)accessTokenSecret {    
    if (!_accessTokenSecret) {
        _accessTokenSecret = [self.sessionStore objectForKey:kAccessTokenSecret];
    }    
    return _accessTokenSecret;
}

// Set accessToken to session store and property.
- (void) setAccessTokenSecret:(NSString *)accessTokenSecret {
    _accessTokenSecret = accessTokenSecret;
    [self.sessionStore setObject:_accessTokenSecret forKey:kAccessTokenSecret];
}

// Determine if the outside world is open for chatting.
- (BOOL)haveInternetBeOptimistic:(BOOL) beOptimistic {
    
    if (beOptimistic && (self.networkStatus == wiFiConnection || self.networkStatus == cellularConnection)) {
        
        return YES;
    }
    
    // Check to see how things are going...
    NetworkAvailability *networkAvailability = [[NetworkAvailability alloc] init];
    self.networkStatus = [networkAvailability getNetworkStatus];  	
    self.wifiConnected = self.networkStatus == wiFiConnection;
    
    // Did we get connectivity back?
    if (self.networkStatus == wiFiConnection || self.networkStatus == cellularConnection) {
           
        return YES;
    }
    
    // No internet
    self.errorMessage = kNoNetworkConnectivity;
    return NO;
}

@end
