//
//  ApiResponse.h
//  Flckr1
//
//  Created by Heather Stevens on 1/17/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiResponse : NSObject

@property (nonatomic, retain) NSString *response;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSString *errorDetails;

@end
