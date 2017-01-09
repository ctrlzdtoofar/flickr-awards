//
//  HomeViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FlkrApiDelegate.h"
#import "XmlParser.h"
#import "SyncPhoto.h"
#import "SyncPhotoList.h"
#import "SyncGroupList.h"

@interface HomeViewController : UIViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) SyncGroupList *syncGroupList;

- (void)startGetPhotoJob;
- (void)startGroupsJob;

- (void) photoListSyncComplete:(NSArray *) photoList;
- (void) groupListSyncComplete;

@end
