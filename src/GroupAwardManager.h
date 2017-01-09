//
//  GroupAwardManager.h
//  Flckr1
//
//  Created by Heather Stevens on 2/3/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AwardModelEntity.h"
#import "Award.h"

@interface GroupAwardManager : NSObject

@property (nonatomic, retain) NSError *persistenceError;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;

- (void)createContext;
- (BOOL) saveAward:(Award *) award;
- (Award *)getAwardWithGroupNsid:(NSString *) groupNsid;

@end
