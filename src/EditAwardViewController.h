//
//  EditAwardViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 2/5/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "Group.h"
#import "GroupAwardManager.h"

@interface EditAwardViewController : UIViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Photo *selectedPhoto;
@property (nonatomic,retain) Group *selectedGroup;
@property (atomic,retain) GroupAwardManager *groupAwardManager;

- (void) awardSyncComplete:(Award *) award;
- (void) doneEditingAward;
- (void) cancelledEditingAward;

@end
