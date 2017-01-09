//
//  Group.m
//  Flckr1
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "Group.h"

@implementation Group

@synthesize nsid = _nsid;
@synthesize name = _name;
@synthesize groupValuesCachedAt = _groupValuesCachedAt;
@synthesize award = _award;
@synthesize groupPhotoList = _groupPhotoList;

//Init and set properties, mark time Flckr values were set for caching.
-(id) initWithNsid:(NSString *)nsid name:(NSString *)name {
    
    if (self = [super init]) {
        self.nsid = nsid;
        self.name = name;
        self.award = [[Award alloc] init];
        
        self.groupValuesCachedAt = [NSDate date];
    }    
    return self;
}

// CHeck to see if the cached values can still be used.
- (BOOL)isGroupInfoExpired {
    
    NSComparisonResult secsApart = abs([self.groupValuesCachedAt compare:[NSDate date]]);    
    
    // Check to make sure the cached group values from Flickr are still valid.
    if (secsApart > (20*60)) {
        //NSLog(@"Group.isGroupInfoExpired, Expired! secApart %d", secsApart);
        return YES;
    }
    
    return NO;
}

// Compare groups by name. 
- (NSComparisonResult) compareGroupsByNames:(Group *) otherGroup {
    
    return [self.name.uppercaseString compare:otherGroup.name.uppercaseString];
}

@end
