//
//  GetGroupPoolPhotos.h
//  Flckr1
//
//  Created by Heather Stevens on 2/16/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "Group.h"

@interface GetGroupPoolPhotos : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withGroup:(Group *)group onCompleteUpdate:(id) inObjToUpdate;

@end
