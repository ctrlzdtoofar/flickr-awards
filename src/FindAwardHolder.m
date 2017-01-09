//
//  FindAward.m
//  Flckr1
//
//  Created by Heather Stevens on 2/7/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "FindAwardHolder.h"

@implementation FindAwardHolder

@synthesize startLocation = _startLocation;
@synthesize awardPoints = _awardPoints;
@synthesize parseState = _parseState;
@synthesize linesSincePointsIncreased = _linesSincePointsIncreased;
@synthesize pointsForLastLine = _pointsForLastLine;
@synthesize awardText = _awardText;

//Init and set properties, mark time Flckr values were set for caching.
-(id) init {
    
    if (self = [super init]) {
        [self reset];
    }    
    
    return self;
}

- (void)reset {
    self.startLocation = 0;
    self.awardPoints = 0;
    self.parseState = START;
    self.linesSincePointsIncreased = 0;
    self.pointsForLastLine = 0;
    self.awardText = [[NSMutableString alloc] initWithCapacity:1000]; 
}

@end
