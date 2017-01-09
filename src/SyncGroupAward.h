//
//  SyncGroupWard.h
//  Flckr1
//
//  Created by Heather Stevens on 2/8/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"

@interface SyncGroupAward : NSOperation

- (id)initWithGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate selector:(SEL) inObjSelector;
@end
