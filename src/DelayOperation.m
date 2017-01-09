//
//  DelayOperation.m
//  Flckr1
//
// Delays for ~3 secs and then calls performSegueToAwards on the specified object.
//
//  Created by Heather Stevens on 2/22/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "DelayOperation.h"

@interface DelayOperation() {
    
}
@property (nonatomic, retain) id objToUpdate;
@property (nonatomic) SEL objSelector;
@end

@implementation DelayOperation
@synthesize objToUpdate = _objToUpdate;
@synthesize objSelector = _objSelector;
@synthesize shouldDelay = _shouldDelay;
@synthesize secsToDelay = _secsToDelay;

- (id)initWith:(id) inObjToUpdate callSel:(SEL) objSelector {
    self = [super init];
    if (self) {
        
        self.objToUpdate = inObjToUpdate;
        self.objSelector = objSelector;
        self.shouldDelay = YES;
        self.secsToDelay = 3;
    }
    
    return self; 
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.objToUpdate = nil;
    self.objSelector = nil;
}

- (void)main {
        
    // loop by quarter seconds
    float delayIntervals = self.secsToDelay * 4;
    
    for (int index = 0; index < delayIntervals; index++) {
        [NSThread sleepForTimeInterval:0.25];
        
        if (!self.shouldDelay) {
            break;
        }
        
        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        } 
    }
    
    [self.objToUpdate performSelectorOnMainThread:self.objSelector
                                  withObject:nil
                               waitUntilDone:YES];
    [self cleanupTime];
}

@end
