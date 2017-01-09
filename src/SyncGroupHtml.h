//
//  SyncGroupHtml.h
//  Flckr1
//
//  Created by Heather Stevens on 2/13/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"
@interface SyncGroupHtml : NSOperation

- (id)initWithGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate;

@end
