//
//  AwardModelEntity.h
//  Flckr1
//
//  Created by Heather Stevens on 2/13/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AwardModelEntity : NSManagedObject

@property (nonatomic, retain) NSString * awardHtml;
@property (nonatomic, retain) NSString * awardNsid;
@property (nonatomic, retain) NSString * awardType;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSNumber * maxPhotosPerDay;
@property (nonatomic, retain) NSNumber * requiredAwards;
@property (nonatomic, retain) NSString * rules;

@end
