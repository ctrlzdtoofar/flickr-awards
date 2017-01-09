//
//  TrailrUtil.h
//  FlickrAwards
//
//  Created by Heather Stevens on 4/4/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrailrUtil : NSObject

+ (NSString *)getAwardTextAfterBeginTrailerForLine:(NSString *) line;

+ (NSString *)getAwardTextInFrontOfTrailerForLine:(NSString *) line;

+(BOOL)hasGeneralTrailrMarker:(NSString *)currentLine;

//Check for trailr end award marker
+(BOOL)hasTrailrEndAwardMarker:(NSString *)currentLine;

//Check for trailr end invite marker
+(BOOL)hasTrailrEndInviteMarker:(NSString *)currentLine;

@end
