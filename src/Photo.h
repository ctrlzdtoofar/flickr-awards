//
//  Photo.h
//  Flckr1
//
//  Created by Heather Stevens on 1/18/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject

@property (nonatomic, retain) NSString *photoId;
@property (nonatomic, retain) NSString *owner;
@property (nonatomic, retain) NSString *secret;
@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *farm;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *commentId;
@property (nonatomic, retain) NSString *views;
@property (nonatomic) BOOL isPublic;
@property (nonatomic) BOOL isFriend;
@property (nonatomic) BOOL isFamily;
@property (atomic, retain) NSDate *photoValuesCachedAt;
@property (nonatomic)  BOOL photoWasAwarded;

@property (atomic, retain) UIImage *photoImageSmall;
@property (atomic, retain) UIImage *photoImageMedium;

//Init and set properties.
-(id) initWithId:(NSString *)photoId owner:(NSString *)owner secret:(NSString *)secret 
          server:(NSString *)server farm:(NSString *)farm title:(NSString *)title isPublic:(BOOL) isPublic isFriend:(BOOL)isFriend isFamily:(BOOL)isFamily;

- (BOOL)isPhotoInfoExpired;
- (NSString *)getSmallUrlString;
- (UIImage *)getSmallImage;
- (UIImage *)getMediumImage;  

- (BOOL)smallImageLoaded;
- (BOOL)mediumImageLoaded;

@end
