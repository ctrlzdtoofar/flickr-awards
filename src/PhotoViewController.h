//
//  PhotoViewController.h
//  Flckr1
//
//  Created by Heather Stevens on 1/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlkrApiDelegate.h"
#import "XmlParser.h"
#import "Photo.h"
#import "ViewUtil.h"

@interface PhotoViewController : UIViewController

@property (nonatomic,retain) FlkrApiDelegate *flkrApiDelegate;
@property (nonatomic,retain) Photo *selectedPhoto;

@property (nonatomic) BOOL isPhotoFullScreen;
@property (nonatomic,retain) UIImageView *photoImageView;

@end
