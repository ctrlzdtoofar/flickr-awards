//
//  SyncPhoto.h
//  Flckr1
//
//  Created by Heather Stevens on 2/9/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"


@interface SyncPhoto : NSOperation

- (id)initWithPhotoList:(NSArray *)photoList haveWifi:(BOOL)haveWifi;
- (id)initWithPhoto:(Photo *)photo onCompleteCell:(UITableViewCell *) inCell;

@end
