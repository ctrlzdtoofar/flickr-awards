//
//  GetGroupPoolPhotos.m
//  Flckr1
//
// Gets a list of photos from a group.
//
//  Created by Heather Stevens on 2/16/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GetGroupPoolPhotos.h"
#import "XmlParser.h"
#import "PhotoXmlParser.h"
#import "Photo.h"

@interface GetGroupPoolPhotos() 

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic, retain) Group *group;

@end

@implementation GetGroupPoolPhotos

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;
@synthesize group = _group;

// Init with group that needs the award.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate {
    self = [super init];
    if (self) {
        //NSLog(@"GetGroupPoolPhotos.initWithApiDelegate");
        self.flkrApiDelegate = flkrApiDelegate;
        self.group = group;
        self.objToUpdate = inObjToUpdate;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.flkrApiDelegate = nil;
    self.group = nil;
}

// Get list of photos from Group Pool.
- (void)main {    
    NSArray *photoList = nil;
    NSString *photoXml = nil;
    
    if (!self.group) {
        [self cleanupTime];
        return;
    }
    
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        // Get this user's 1st 100 photo list.
        photoXml = [self.flkrApiDelegate getPhotoPoolFromGroup:self.group.nsid];    
        if (!photoXml) {
            NSLog(@"GetGroupPoolPhotos.main, failed to get photos for group with nsid %@",self.group.nsid);
        }
    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    // If we have the xml with the group's photo list and we are online
    if (photoXml && [self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {

        // Parse the photo list.
        XmlParser *xmlParser = [[XmlParser alloc] init];        
        PhotoXmlParser *photoXmlParser = [[PhotoXmlParser alloc] init];        
        [xmlParser parseXmlDocument:photoXml withMapper:photoXmlParser];         
        photoList = photoXmlParser.photoList;
        
        // Pull the first image from Flickr
        if (photoList && photoList.count > 0) {
            Photo *firstPhoto = [photoList objectAtIndex:0];
            
            UIImage *photoToDisplay = [self.flkrApiDelegate.userSessionModel getCachedImage:firstPhoto.photoId];
            if (!photoToDisplay) {
                photoToDisplay = [firstPhoto getMediumImage]; 
                
                if ([self isCancelled]) {
                    [self cleanupTime];
                    return;
                }
                
                if (photoToDisplay) {
                    [self.flkrApiDelegate.userSessionModel addImageToCache:photoToDisplay withKey:firstPhoto.photoId];
                }                
            }
        }
    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:@selector(photosRetrievedFromGroup:)
                                  withObject:photoList
                               waitUntilDone:YES];
    
    [self cleanupTime];
}

@end
