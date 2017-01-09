//
//  SyncPhotoList.m
//  Flckr1
//
// Get the user's photos from Flickr
//
//  Created by Heather Stevens on 2/9/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SyncPhotoList.h"
#import "XmlParser.h"
#import "PhotoXmlParser.h"

@interface SyncPhotoList() 

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;

@end

@implementation SyncPhotoList

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;

// Init with group that needs the award.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate onCompleteUpdate:(id) inObjToUpdate {
    self = [super init];
    if (self) {

        self.flkrApiDelegate = flkrApiDelegate;
        self.objToUpdate = inObjToUpdate;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.flkrApiDelegate = nil;
}

// Load and parse list of photos from flickr.
- (void)main {    

    // Get this user's 1st 100 photo list.
    NSString *photoXml = [self.flkrApiDelegate peopleGetPhotos];
    NSArray *photoList = nil;
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    if (photoXml) {
        
        XmlParser *xmlParser = [[XmlParser alloc] init];

        PhotoXmlParser *photoXmlParser = [[PhotoXmlParser alloc] init];

        [xmlParser parseXmlDocument:photoXml withMapper:photoXmlParser]; 

        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        }
        
        photoList = photoXmlParser.photoList;        
    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:@selector(photoListSyncComplete:)
                                  withObject:photoList
                               waitUntilDone:YES];
        
    [self cleanupTime];
}
@end
