//
//  PickGroupTableViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "XmlParser.h"
#import "Photo.h"
#import "Group.h"

@interface PickGroupTableViewController : UITableViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Photo *selectedPhoto;

// Reload the table to show new data.
- (void)reloadGroupTable;

- (void)groupEditMode;
- (void)groupAwardMode;

- (void)setGroupListLoading;

@end
