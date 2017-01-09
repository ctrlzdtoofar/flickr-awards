//
//  SyncGroupList.h
//  Flckr1
//
//  Created by Heather Stevens on 2/23/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Group.h"

@interface SyncGroupList : NSOperation
@property (nonatomic, retain) id objToUpdate2;

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate onCompleteUpdate:(id) inObjToUpdate;

@end
