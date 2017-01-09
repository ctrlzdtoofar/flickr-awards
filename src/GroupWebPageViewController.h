//
//  GroupWebPageViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 2/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"
#import "FlkrApiDelegate.h"

@interface GroupWebPageViewController : UIViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Group *selectedGroup;

- (void) htmlSyncComplete:(NSString *) htmlContent;
- (void)grabAwardPopController:(id)sender;

@end
