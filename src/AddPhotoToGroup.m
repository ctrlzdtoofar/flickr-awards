//
//  AddPhotoToGroup.m
//  Flckr1
//
// Adds user's photo to a group.
//
//  Created by Heather Stevens on 2/15/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "AddPhotoToGroup.h"

@interface AddPhotoToGroup() 
@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) Group *group;

@end

@implementation AddPhotoToGroup

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;
@synthesize photo = _photo;
@synthesize group = _group;

// Init with group that needs the award.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector{
    self = [super init];
    if (self) {
        self.flkrApiDelegate = flkrApiDelegate;
        self.objToUpdate = inObjToUpdate;
        self.objSelector = objSelector;
    }
    
    return self;
}

// Set the photo to add and the group it will be added to.
- (void)setPhoto:(Photo *) photo andGroup:(Group *) group {
    self.photo = photo;
    self.group = group;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objSelector = nil;
    self.flkrApiDelegate = nil;
    self.group = nil;
    self.photo = nil;
}

// Add photo to Group Pool.
- (void)main {
    

    if (!self.photo || !self.group) {
        NSLog(@"AddPhotoToGroup.main, Failed, photo and group required!");

    }
    // Add the user's photo to the group.
    else if (![self.flkrApiDelegate addPhotoToGroup:self.group.nsid forPhoto:self.photo.photoId]) {
     
        NSLog(@"AddPhotoToGroup.main, failed to add photo with id %@ to group with nsid %@",self.photo.photoId,self.group.nsid);

    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
        
    
    [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                  withObject:nil
                               waitUntilDone:YES];
    [self cleanupTime];
}

@end
