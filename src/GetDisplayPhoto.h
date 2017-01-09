//
//  GetDisplayPhoto.h
//  Flckr1
//
//  Created by Heather Stevens on 2/20/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"

@interface GetDisplayPhoto : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate  andPhoto:(Photo *)photo onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector;

@end
