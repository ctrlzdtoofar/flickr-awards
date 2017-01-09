//
//  AwardGroupPhotosViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 2/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "Photo.h"
#import "Group.h"


#define RADIANS_INA_DEGREE 0.017453293


@interface AwardGroupPhotosViewController : UIViewController
@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Photo *selectedPhoto;
@property (nonatomic,retain) Group *selectedGroup;
@property (nonatomic,retain) Photo *currentGroupPhoto;
@property (nonatomic,retain) UIImageView *photoImageView;

- (void)moveToNextPhoto;
- (void)awardRemovedFromPhoto:(Photo *) unawardedPhoto;
- (void)awardAddedToPhoto:(Photo *)awardedPhoto;
- (void)photoAddedToGroup;
- (void)photoInGroup:(NSString *) isPhotoInGroup;
- (void)photosRetrievedFromGroup:(NSArray *) groupPhotoList;
- (void)displayPhotoImageView;

- (IBAction)handleTapFrom:(UITapGestureRecognizer *)recognizer;
- (IBAction)handleLeftSwipeFrom:(UISwipeGestureRecognizer *)recognizer;
- (IBAction)handleRightSwipeFrom:(UISwipeGestureRecognizer *)recognizer;

@end
