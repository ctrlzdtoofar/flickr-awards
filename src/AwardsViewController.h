//
//  AwardSetupViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/27/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "Group.h"
#import "GroupAwardManager.h"

@interface AwardsViewController : UIViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Photo *selectedPhoto;
@property (nonatomic,retain) Group *selectedGroup;
@property (atomic,retain) GroupAwardManager *groupAwardManager;
@property (nonatomic) BOOL isReturning;

@end
