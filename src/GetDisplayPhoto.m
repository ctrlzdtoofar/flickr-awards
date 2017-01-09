//
//  GetDisplayPhoto.m
//  Flckr1
//
// Pulls a photo's content down from Flickr.
// 
//  Created by Heather Stevens on 2/20/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GetDisplayPhoto.h"

@interface GetDisplayPhoto() 
@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@property (nonatomic, retain) Photo *photo;

@end

@implementation GetDisplayPhoto

@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;
@synthesize photo = _photo;
@synthesize flkrApiDelegate = _flkrApiDelegate;

// Init with photo to pull image for.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate andPhoto:(Photo *)photo onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector {
    self = [super init];
    if (self) {
        self.photo = photo;
        self.objToUpdate = inObjToUpdate;
        self.objSelector = objSelector;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objSelector = nil;
    self.photo = nil;
    self.flkrApiDelegate = nil;
}

// Pull image from FLickr site and update calling controller on main thread.
- (void)main {
    
    if (!self.photo) {
        [self cleanupTime];
        return;
    }   
    
    // Attempt to get the photo from the cache.
    UIImage *photoToDisplay = [self.flkrApiDelegate.userSessionModel getCachedImage:self.photo .photoId];
    if (!photoToDisplay) {
        
        // Pull photo and then add it to the cache.
        photoToDisplay = [self.photo getMediumImage]; 
        
        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        }
        
        if (photoToDisplay) {
            [self.flkrApiDelegate.userSessionModel addImageToCache:photoToDisplay withKey:self.photo.photoId];
        }
    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    // Only update obj if we have one to update.
    if (self.objToUpdate && self.objSelector) {
        [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                  withObject:nil
                               waitUntilDone:YES];
    }
    
    [self cleanupTime];
}

@end
