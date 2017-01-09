//
//  PickPhotoTableViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/21/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "XmlParser.h"

@interface PickPhotoTableViewController : UITableViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;

// Reload the table to show new data.
- (void)reloadPhotoTable;
- (void)setPhotoListLoading;

@end
