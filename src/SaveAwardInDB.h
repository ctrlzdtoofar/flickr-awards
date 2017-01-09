//
//  SaveAwardInDB.h
//  Flckr1
//
// Saves an award for a group in the local db.
//
//  Created by Heather Stevens on 2/9/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GroupAwardManager.h"

@interface SaveAwardInDB : NSOperation

- (id)initWithAward:(Award *)award addWith:(GroupAwardManager *)groupAwardManager;

@end
