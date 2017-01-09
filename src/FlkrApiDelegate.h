//
//  FlkrApiDelegate.h
//  Flckr1
//
//  Created by Heather Stevens on 1/15/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunicationsUtil.h"
#import "UserSessionModel.h"
#import "ApiResponse.h"
#import "Group.h"
#import "Photo.h"
#import "NetworkAvailability.h"

@interface FlkrApiDelegate : NSObject

@property (nonatomic, retain) UserSessionModel *userSessionModel;

- (id) init;
- (BOOL)testLogin;
- (NSString *)peopleGetPhotos;
- (NSString *)getUserGroups;
- (BOOL)addPhotoToGroup:(NSString *)groupNsid forPhoto:(NSString *)photoId;
- (NSString *)getPhotoPoolFromGroup:(NSString *)groupNsid;
- (BOOL)addAward:(NSString *) awardHtml toPhoto:(Photo **)photo;
// Remove award (comment) from photo using the comment id.
- (BOOL)removeAward:(NSString *) commentId;
- (NSString *)getUsersPhotosFromGroup:(NSString *)groupNsid;

@end
