//
//  AwardGroupPhoto.m
//  Flckr Awards
//
// Adds an award from a group to a photo in the group.
//
//  Created by Heather Stevens on 2/17/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "AwardGroupPhoto.h"

@interface AwardGroupPhoto() 

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) NSString *awardHtml;

@end

@implementation AwardGroupPhoto

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;
@synthesize photo = _photo;
@synthesize awardHtml = _awardHtml;

// Init with photo and award to add to it.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withPhoto:(Photo *)photo withAward:(NSString *)awardHtml onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector {
    self = [super init];
    if (self) {
        self.flkrApiDelegate = flkrApiDelegate;
        self.photo = photo;
        self.awardHtml = awardHtml;
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
    self.awardHtml = nil;
    self.photo = nil;
}

// Add an award to a photo in the selected Group.
- (void)main {
    //NSLog(@"AwardGroupPhoto.main for photo with id %@ adding award %@", self.photo.photoId, self.awardHtml);
    
    if (!self.photo || !self.awardHtml) {
        [self cleanupTime];
        return;
    }   
    
    // Get this user's 1st 100 photo list.
    Photo *photoToAward = self.photo;
    if (![self.flkrApiDelegate addAward:self.awardHtml toPhoto:&photoToAward]) {
        
        NSLog(@"AwardGroupPhoto.main, failed to add award to photo %@ due to: %@",self.photo.photoId, self.flkrApiDelegate.userSessionModel.errorMessage);
    }
    
    self.photo.commentId = photoToAward.commentId;
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                  withObject:self.photo
                               waitUntilDone:YES];
    
    [self cleanupTime];
}

@end
