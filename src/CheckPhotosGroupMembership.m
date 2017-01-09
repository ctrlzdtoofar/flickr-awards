//
//  CheckPhotosGroupMembership.m
//  FlickrAwards
//
//  Created by Heather Stevens on 10/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "CheckPhotosGroupMembership.h"
#import "XmlParser.h"
#import "PhotoXmlParser.h"

@interface CheckPhotosGroupMembership()

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) NSString *groupNsid;

@end

@implementation CheckPhotosGroupMembership

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;
@synthesize photo = _photo;
@synthesize groupNsid = _groupNsid;

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withPhoto:(Photo *)photo withGroup:(NSString *)groupNsid onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector {
    
    self = [super init];
    if (self) {
        self.flkrApiDelegate = flkrApiDelegate;
        self.photo = photo;
        self.groupNsid = groupNsid;
        self.objToUpdate = inObjToUpdate;
        self.objSelector = objSelector;
    }
    
    return self;
}


// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objSelector = nil;
    self.flkrApiDelegate = nil;
    self.groupNsid = nil;
    self.photo = nil;
}

// Call Flickr's API to get group photos that belong to user.
- (NSString *) invokeFlickrApi {
    NSString *photoXml = nil;
    
    // Get list of user's photos that are in the group already.
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        // Get this user's 1st 100 photo list.
        photoXml = [self.flkrApiDelegate getUsersPhotosFromGroup:self.groupNsid];
        if (!photoXml) {
            NSLog(@"CheckPhotosGroupMembership, failed to get photos from group with nsid %@",self.groupNsid);
        }
    }
    
    return photoXml;
}

// Build list of photos from the xml.
// Returns list of Photo objects.
- (NSArray *)parsePhotoXml: (NSString *)photoXml {
    
    // Parse the xml photo list.
    XmlParser *xmlParser = [[XmlParser alloc] init];
    PhotoXmlParser *photoXmlParser = [[PhotoXmlParser alloc] init];
    [xmlParser parseXmlDocument:photoXml withMapper:photoXmlParser];

    return photoXmlParser.photoList;
}

// Determines if user's photo is in the group's list of photos.
- (BOOL)isPhoto: (Photo *)userPhoto inGroupList: (NSArray *)photoList {
    
    for (Photo *groupPhoto in photoList) {
        if ([userPhoto.photoId isEqualToString:groupPhoto.photoId]) {
            
            NSLog(@"found photo %@ in the list %@", userPhoto.photoId,groupPhoto.photoId );
            return YES;
        }
    }
    return NO;
}

// Attempt to find the specified photo in the specified group.
- (void)main {
    NSArray *photoList = nil;
    NSString *photoXml = nil;
    
    // Don't get started if app was switched away from.
    if (!self.photo || !self.groupNsid) {
        [self cleanupTime];
        return;
    }
    
    photoXml = [self invokeFlickrApi];
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    photoList = [self parsePhotoXml:photoXml];
    
    NSString *wasFound = @"NO";
    if ([self isPhoto:self.photo inGroupList:photoList]) {
        wasFound = @"YES";
    }

    if (!self.photo || !self.groupNsid) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                       withObject:wasFound
                                    waitUntilDone:YES];    
    [self cleanupTime];
}


@end
