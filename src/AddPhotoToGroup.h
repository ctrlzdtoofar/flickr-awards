//
//  AddPhotoToGroup.h
//  Flckr1
//
//  Created by Heather Stevens on 2/15/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "Group.h"

@interface AddPhotoToGroup : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector;
- (void)setPhoto:(Photo *) photo andGroup:(Group *) group;
@end
