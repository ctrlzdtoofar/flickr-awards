//
//  SyncGroupList.m
//  Flckr1
//
// Gets user's groups from Flickr and their awards for each group that has them from the local db.
//
//  Created by Heather Stevens on 2/23/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SyncGroupList.h"
#import "XmlParser.h"
#import "GroupXmlParser.h"
#import "GroupAwardManager.h"
#import "Award.h"

@interface SyncGroupList() 

@property (nonatomic, retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic, retain) id objToUpdate;
@property (atomic) BOOL complete;
@end

@implementation SyncGroupList
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize objToUpdate = _objToUpdate;
@synthesize objToUpdate2 = _objToUpdate2;
@synthesize complete = _complete;

// Init with group that needs the award.
- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate onCompleteUpdate:(id) inObjToUpdate {
    self = [super init];
    if (self) {
        self.flkrApiDelegate = flkrApiDelegate;
        self.objToUpdate = inObjToUpdate;
        self.complete = NO;
    }
    
    return self;
}

// Now another object needs to know when the load is done.
// Make sure the two threads don't update this 2nd obj isn't updated twice.
- (void)setObjToUpdate2:(id)inObjToUpdate2 {
    
    @synchronized(self) {
        _objToUpdate2 = inObjToUpdate2;
    
        // The bg thread already completed, run the selector directly.
        if (self.complete) {
            [inObjToUpdate2 performSelector:@selector(groupListSyncComplete)];        
        }    
    }
}

// Load awards for groups from local db lite.
- (NSMutableArray *)lookupAwardsForGroups:(NSArray *)groupList {
    
    NSMutableArray *groupsWithAwards = [[NSMutableArray alloc] initWithCapacity:groupList.count];
    
    GroupAwardManager *groupAwardManager = [[GroupAwardManager alloc] init];    
    [groupAwardManager createContext]; 
    
    for (Group *group in groupList) {
        
        // Update the group from the db if found.
        Award *award = [groupAwardManager getAwardWithGroupNsid:group.nsid];
        if (award) {
           group.award = award;
            [groupsWithAwards addObject:group];               
        }  
    }    
      
    return groupsWithAwards;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objToUpdate2 = nil;
    self.flkrApiDelegate = nil;
}

// Load and parse list of groups from flickr.
- (void)main {  
    
    NSString *groupXml = [self.flkrApiDelegate getUserGroups];
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    if (groupXml) {
        
        XmlParser *xmlParser = [[XmlParser alloc] init];
        GroupXmlParser *groupXmlParser = [[GroupXmlParser alloc] init];
        
        [xmlParser parseXmlDocument:groupXml withMapper:groupXmlParser]; 
        
        NSArray *groupList = [groupXmlParser.groupList sortedArrayUsingSelector:@selector(compareGroupsByNames:)];
        //NSArray *groupList = groupXmlParser.groupList;
        
        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        }
        
        if (groupList) {
            self.flkrApiDelegate.userSessionModel.groupList = groupList; 
            
            // Now see which groups have awards stored in the sqlite db.
            self.flkrApiDelegate.userSessionModel.groupWithAwardList = [self lookupAwardsForGroups:groupList];
        }
    }      
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    [self.objToUpdate performSelectorOnMainThread:@selector(groupListSyncComplete)
                                  withObject:nil
                               waitUntilDone:YES];

    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    @synchronized(self) {
        if (self.objToUpdate2) {
            [self.objToUpdate2 performSelectorOnMainThread:@selector(groupListSyncComplete)
                                  withObject:nil
                               waitUntilDone:YES];
        }
        self.complete = YES;
    }
    
    [self cleanupTime];    
}

@end
