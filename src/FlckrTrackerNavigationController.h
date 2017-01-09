//
//  Flckr1NavigationController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserSessionModel.h"

@interface Flckr1NavigationController : UINavigationController

@property (nonatomic, retain) UserSessionModel *userSessionModel;

@end
