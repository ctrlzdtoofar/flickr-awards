//
//  LoginDelegate.h
//  Flckr1
//
//  Created by Heather Stevens on 1/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunicationsUtil.h"
#import "UserSessionModel.h"
#import "ApiResponse.h"

@interface LoginDelegate : NSObject

@property (nonatomic, retain) UserSessionModel *userSessionModel;

- (BOOL)completeUserAuthorization;
- (BOOL)finishUserAuthorization:(NSString *)queryFromYahoo;

- (NSString *)errorMessage;
- (NSString *)userName;

@end
