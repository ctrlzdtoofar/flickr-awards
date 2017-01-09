//
//  Group.h
//  Flckr1
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Award.h"

@interface Group : NSObject
@property (nonatomic, retain) NSString *nsid;
@property (nonatomic, retain) NSString *name;
@property (atomic, retain) Award *award;
@property (atomic, retain) NSDate *groupValuesCachedAt;
@property (atomic, retain) NSArray *groupPhotoList;

-(id) initWithNsid:(NSString *)nsid name:(NSString *)name;
- (BOOL)isGroupInfoExpired;
- (NSComparisonResult) compareGroupsByNames:(Group *) otherGroup;
@end
