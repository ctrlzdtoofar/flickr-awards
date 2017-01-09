//
//  SaveAwardInDB.m
//  Flckr1
//
// Saves an award for a group in the local db.
//
//  Created by Heather Stevens on 2/9/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SaveAwardInDB.h"

@interface SaveAwardInDB() 

@property (nonatomic, retain) Award *award;
@property (nonatomic, retain) GroupAwardManager *groupAwardManager;
@end

@implementation SaveAwardInDB

@synthesize award = _award;
@synthesize groupAwardManager = _groupAwardManager;

// Initialize with an award to be saved in the db.
- (id)initWithAward:(Award *)award addWith:(GroupAwardManager *)groupAwardManager {
    
    self = [super init];
    if (self) {
        self.award = award;
        self.groupAwardManager = groupAwardManager;
    }
    
    return self;  
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.award = nil;
    self.groupAwardManager = nil;
}

// Save or update a group with its award in the db.
- (void)main {
    
     //NSLog(@"SaveAwardInDB.main, called.");
    
    if ([self isCancelled]) {
        [self cleanupTime];
        return;
    }
    
    if (!self.award) {
        NSLog(@"SaveAwardInDB.main, Error, no award to save. self.award is nil.");
    }
    
    if (!self.award.groupNsid) {
        NSLog(@"SaveAwardInDB.main, Error, no group nsid.");
    }
    
    if (self.award && self.award.groupNsid) {
        
        if (![self.groupAwardManager saveAward:self.award]) {    
            NSLog(@"SaveAwardInDB.main, Error, failed to save award in db.");
        }
    }
    
    [self cleanupTime];
    
    //NSLog(@"SaveAwardInDB.main done");
}

@end
