//
//  RemoveCommentOperation.m
//  FlickrAwards
//
//  Created by Heather Stevens on 5/10/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "RemoveCommentOperation.h"
@interface RemoveCommentOperation() 

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@property (nonatomic, retain) Photo *photoWithComment;

@end

@implementation RemoveCommentOperation

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize photoWithComment = _photoWithComment;
@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate fromPhoto:(Photo *)photo onCompleteUpdate:(id)inObjToUpdate withSelector:(SEL)objSelector {
    
    self = [super init];
    if (self) {
        self.flkrApiDelegate = flkrApiDelegate;
        self.photoWithComment = photo;
        self.objToUpdate = inObjToUpdate;
        self.objSelector = objSelector;
    }
    
    return self;}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objSelector = nil;
    self.flkrApiDelegate = nil;
    self.photoWithComment = nil;

}

// Remove an award to a photo in the selected Group.
- (void)main {
     
    if (!self.photoWithComment.commentId) {
        [self cleanupTime];
        return;
    }   
    
    // Delete the comment/award
    if (![self.flkrApiDelegate removeAward:self.photoWithComment.commentId]) {
        
        NSLog(@"RemoveCommentOperation.main, failed to remove award %@ due to: %@",self.photoWithComment.commentId, self.flkrApiDelegate.userSessionModel.errorMessage);
    }
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                       withObject:self.photoWithComment
                                    waitUntilDone:YES];
    
    [self cleanupTime];
}

@end
