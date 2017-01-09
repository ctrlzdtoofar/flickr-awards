//
//  CheckPhotosGroupMembership.h
//  FlickrAwards
//
//  Created by Family on 10/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"

@interface CheckPhotosGroupMembership : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withPhoto:(Photo *)photo withGroup:(NSString *)groupNsid onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector;

@end
