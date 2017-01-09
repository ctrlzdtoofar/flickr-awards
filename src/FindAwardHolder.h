//
//  FindAward.h
//  Flckr1
//
//  Created by Heather Stevens on 2/7/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FindAwardHolder : NSObject

#define START                 0
#define PRE_AWARD_TAGS_FOUND  1
#define COMMENT_WILL_BEGIN    2
#define COMMENT_DELIMITER_REQ 3
#define AWARD_WILL_START      4
#define AWARD_STARTED         5
#define AWARD_ENDED           6

@property (nonatomic) int startLocation;
@property (nonatomic) int awardPoints;
@property (nonatomic) int parseState;
@property (nonatomic) int linesSincePointsIncreased;
@property (nonatomic) int pointsForLastLine;
@property (nonatomic, retain)  NSMutableString *awardText;

-(id) init;
- (void)reset;

@end
