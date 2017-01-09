//
//  SyncGroupHtml.m
//  Flckr1
//
// Returns the html for the group's home page.
//
//  Created by Heather Stevens on 2/13/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SyncGroupHtml.h"
#import "FlckrHtmlParserDelegate.h"

@interface SyncGroupHtml() 

@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) id objToUpdate;

@end

@implementation SyncGroupHtml

@synthesize group = _group;
@synthesize objToUpdate = _objToUpdate;

// Init with group that needs the award.
- (id)initWithGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate {
    self = [super init];
    if (self) {
        self.group = group;
        self.objToUpdate = inObjToUpdate;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.group = nil;
}

// Operation to be executed.
- (void)main {
        
    // Get the group's html from its home page and parse it to get the award.
    FlckrHtmlParserDelegate *htmlParser = [[FlckrHtmlParserDelegate alloc] initWithSelectedGroup:self.group];
    NSString *htmlContent = [htmlParser getGroupWebPageHtmlContent];
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:@selector(htmlSyncComplete:)
                                  withObject:htmlContent
                               waitUntilDone:YES];
    
    [self cleanupTime];
}
@end
