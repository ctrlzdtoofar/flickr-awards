//
//  FlckrViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/11/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginDelegate.h"
#import "FlkrApiDelegate.h"

@interface FlckrViewController : UIViewController

@property (nonatomic,retain) LoginDelegate *loginDelegate;
@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;

- (void)continueLoginProcess:(NSString *)queryFromYahoo;

@end
