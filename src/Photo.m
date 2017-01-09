//
//  Photo.m
//  Flckr1
//
//  Created by Heather Stevens on 1/18/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "Photo.h"

@implementation Photo

@synthesize photoId = _photoId;
@synthesize owner = _owner;
@synthesize secret = _secret;
@synthesize server = _server;
@synthesize farm = _farm;
@synthesize title = _title;
@synthesize commentId = _commentId;
@synthesize views = _views;
@synthesize isPublic = _isPublic;
@synthesize isFriend = _isFriend;
@synthesize isFamily = _isFamily;
@synthesize photoValuesCachedAt = _photoValuesCachedAt;
@synthesize photoWasAwarded = _photoWasAwarded;

@synthesize photoImageSmall = _photoImageSmall;
@synthesize photoImageMedium = _photoImageMedium640;

//Init and set properties, mark time Flckr values were set for caching.
-(id) initWithId:(NSString *)photoId owner:(NSString *)owner secret:(NSString *)secret 
          server:(NSString *)server farm:(NSString *)farm title:(NSString *)title isPublic:(BOOL) isPublic isFriend:(BOOL)isFriend isFamily:(BOOL)isFamily {
    
    if (self = [super init]) {
        self.photoId = photoId;
        self.owner = owner;
        self.secret = secret;
        self.server = server;
        self.farm = farm;
        self.title = title;
        self.isPublic = isPublic;
        self.isFriend = isFriend;
        self.isFamily = isFamily;     
        
        self.photoValuesCachedAt = [NSDate date];
        self.photoWasAwarded = NO;
    }    
    
    return self;
}

/*
 http ://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
 or
 http ://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
 
 s	small square 75x75
 t	thumbnail, 100 on longest side
 m	small, 240 on longest side
 -	medium, 500 on longest side
 z	medium 640, 640 on longest side
 b	large, 1024 on longest side*
 
 http ://farm1.staticflickr.com/2/1418878_1e92283336_m.jpg
 
 farm-id: 1
 server-id: 2
 photo-id: 1418878
 secret: 1e92283336
 size: m
 
 */
static NSString * const kHttpRequest        = @"http://farm";
static NSString * const kStaticFlickr       = @".staticflickr.com/";
static NSString * const kSlash              = @"/";
static NSString * const kUnderBar           = @"_";
static NSString * const kSmallJpg           = @"_s.jpg";
static NSString * const kMedium640Jpg       = @".jpg";
static NSString * const kLargeJpg          = @"_b.jpg";

// CHeck to see if the cached values can still be used.
- (BOOL)isPhotoInfoExpired {

    NSComparisonResult secsApart = abs([self.photoValuesCachedAt compare:[NSDate date]]);
    //NSLog(@"Photo.getSmallImage secApart %d", secsApart);
    
    // Check to make sure the cached image values from Flickr are still valid.
    if (secsApart > (20*60)) {
        return YES;
    }
    
    return NO;
}


// Build the base url to get a flickr photo
- (NSMutableString *)buildBasePhotoUrl {
   
    NSMutableString *urlStr = [[NSMutableString alloc] initWithCapacity:64];
    
    if (self.photoId && self.owner && self.secret && self. server && self.farm) {        
        
        [urlStr appendString:kHttpRequest];
        [urlStr appendString:self.farm];
        [urlStr appendString:kStaticFlickr];
        [urlStr appendString:self.server];
        [urlStr appendString:kSlash];
        [urlStr appendString:self.photoId];
        [urlStr appendString:kUnderBar];
        [urlStr appendString:self.secret];
    }
    
    return urlStr;
}

// Use properties to build string for URL of photo.
- (NSString *)getSmallUrlString {
    if (self.photoId && self.owner && self.secret && self. server && self.farm) {
        
        NSMutableString *urlStr = [self buildBasePhotoUrl];
        [urlStr appendString:kSmallJpg];
        
        return urlStr;
    }
    
    return nil;
}

// Use properties to build a URL for the photo.
- (NSURL *)createSmallPhotoUrl {

    NSString *urlStr = [[NSMutableString alloc] initWithString:[self getSmallUrlString]];
    if (urlStr) {
            
        return [[NSURL alloc] initWithString:urlStr];
    }
    
    return nil;
}

// Use properties to build a URL for the photo.
- (NSURL *)createMedium640PhotoUrl{
    
    if (self.photoId && self.owner && self.secret && self. server && self.farm) {
        
       NSMutableString *urlStr = [self buildBasePhotoUrl];
       [urlStr appendString:kMedium640Jpg];
        
       return [[NSURL alloc] initWithString:urlStr];
    }
    
    return nil;
}

// Use properties to build a URL for the photo.
- (NSURL *)createLargePhotoUrl{
    
    if (self.photoId && self.owner && self.secret && self. server && self.farm) {
        
        NSMutableString *urlStr = [self buildBasePhotoUrl];
        [urlStr appendString:kLargeJpg];
        
        return [[NSURL alloc] initWithString:urlStr];
    }
    
    return nil;
}

// Get and cache small image
- (UIImage *)getSmallImage {
    
    // Make sure two threads don't try this at the same time.
    @synchronized(self) { 
        
        // Check to make sure the cached image values from Flickr are still valid.
        if (![self isPhotoInfoExpired]) {
            if (self.photoImageSmall) {
                return self.photoImageSmall;
            }
            
            NSURL *smallPhotoUrl = [self createSmallPhotoUrl];
            if (!smallPhotoUrl) {
                return nil;
            }            
            
            // This image wasn't pulled down yet. Get it from Flicker and then hang on to it for one day.
            NSData *imageData = [NSData dataWithContentsOfURL:smallPhotoUrl];
            
            if (imageData) {
                self.photoImageSmall = [[UIImage alloc] initWithData:imageData];     
            }
            
            //NSLog(@"Loading small image %@", [self title]);
            return self.photoImageSmall;
        }
        
    }
    
    return nil;
}

// Get and cache medium image.
- (UIImage *)getMediumImage {
    
    // Check to make sure the cached image values from Flickr are still valid.
    if (![self isPhotoInfoExpired]) {

        if (self.photoImageMedium) {
            return self.photoImageMedium;
        }        
        
        NSURL *mediumPhotoUrl = [self createMedium640PhotoUrl];
        if (!mediumPhotoUrl) {
            return nil;
        }
        
        // This image wasn't pulled down yet. Get it from Flicker and then hang on to it for one day.
        //NSLog(@"loading medium image from flickr, %@", self.title);
        NSData *imageData = [NSData dataWithContentsOfURL:mediumPhotoUrl];
        
        if (imageData) {
            self.photoImageMedium = [[UIImage alloc] initWithData:imageData];     
        }
        else {
            self.photoImageMedium = nil;
        }
        
        return self.photoImageMedium;
    }
    
    return nil;
}

// Check to see if we already have a small image.
- (BOOL)smallImageLoaded {
    
    if (self.photoImageSmall && ![self isPhotoInfoExpired]) {
        return YES;
    }
    
    return NO;    
}

// Check to see if we already have a medium image.
- (BOOL)mediumImageLoaded {
    
    if (self.photoImageMedium && ![self isPhotoInfoExpired]) {
        return YES;
    }
    
    return NO;  
}

// Implemented to safeguard updates to the wrong photo.
- (id)copy {
    Photo *copyOfPhoto = [[Photo alloc] initWithId:self.photoId owner:self.owner secret:self.secret server:self.server farm:self.farm title:self.title isPublic:self.isPublic isFriend:self.isFriend isFamily:self.isFamily];
    
    copyOfPhoto.title = self.title;
    copyOfPhoto.photoValuesCachedAt = self.photoValuesCachedAt;
    copyOfPhoto.photoWasAwarded = self.photoWasAwarded;
    copyOfPhoto.photoImageSmall = self.photoImageSmall;
    copyOfPhoto.photoImageMedium = self.photoImageMedium;
    
    return copyOfPhoto;
}

@end
