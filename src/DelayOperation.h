//
//  DelayOperation.h
//  Flckr1
//
//  Created by Heather Stevens on 2/22/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DelayOperation : NSOperation

@property (atomic) BOOL shouldDelay;
@property (nonatomic) float secsToDelay;

- (id)initWith:(id) inObjToUpdate callSel:(SEL) objSelector;

@end
