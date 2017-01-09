//
//  Award.h
//  Flckr1
//
//  Created by Heather Stevens on 2/3/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Award : NSObject

/*
typedef enum {
    GeneralAward = 0,
    GroupAward,
    BeggingGroupAward,
    GroupInvitation,
} AwardType;
*/

@property (nonatomic, retain) NSString *groupNsid;
@property (nonatomic, retain) NSString *groupName;
@property (nonatomic, retain) NSString *awardType;
@property (nonatomic, retain) NSString *htmlAward;
@property (nonatomic, retain) NSDate *created;
@property (nonatomic, retain) NSString *rules;
@property (nonatomic) NSInteger maxPhotosPerDay;
@property (nonatomic) NSInteger requiredAwards;
@property (nonatomic) int confidenceScore;

@end
