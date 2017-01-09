//
//  RemoveCommentOperation.h
//  FlickrAwards
//
//  Created by Heather Stevens on 5/10/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"

@interface RemoveCommentOperation : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate fromPhoto:(Photo *) photo onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector;

@end
