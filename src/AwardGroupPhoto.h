//
//  AwardGroupPhoto.h
//  Flckr1
//
//  Created by Heather Stevens on 2/17/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"

@interface AwardGroupPhoto : NSOperation

- (id)initWithApiDelegate:(FlkrApiDelegate *)flkrApiDelegate withPhoto:(Photo *)photo withAward:(NSString *)awardHtml onCompleteUpdate:(id) inObjToUpdate withSelector:(SEL)objSelector;

@end
