//
//  SyncGroupWard.m
//  Flckr1
//
// Gets award by parsing html from group's web page
//
//  Created by Heather Stevens on 2/8/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SyncGroupAward.h"
#import "FlckrHtmlParserDelegate.h"

@interface SyncGroupAward() {
    id objToUpdate;
    SEL objSelector;
}

@property (nonatomic, retain) Group *group;

@end

@implementation SyncGroupAward

@synthesize group = _group;

// Init with group that needs the award.
- (id)initWithGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate selector:(SEL) inObjSelector {
    self = [super init];
    if (self) {
        self.group = group;
        objToUpdate = inObjToUpdate;
        objSelector = inObjSelector;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    objToUpdate = nil;
    objSelector = nil;
    self.group = nil;
}

// Operation to be executed.
- (void)main {
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    FlckrHtmlParserDelegate *htmlParser = [[FlckrHtmlParserDelegate alloc] initWithSelectedGroup:self.group];
    [htmlParser getAwardAutomaticallyFromWebPage];
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    Award *award = [htmlParser getBestAwardFromList];
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [objToUpdate performSelectorOnMainThread:objSelector
                                           withObject:award
                                           waitUntilDone:YES];
    
    [self cleanupTime];
}

@end
