//
//  TrailrUtil.m
//  FlickrAwards
//
//  Created by Heather Stevens on 4/4/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "TrailrUtil.h"

@implementation TrailrUtil


static NSString * const kEndOfBeginTrailrMarker = @"</a>";
// Look for hidden text before trailr link.
+ (NSString *)getAwardTextAfterBeginTrailerForLine:(NSString *) line {
    
    NSRange range = [line rangeOfString:kEndOfBeginTrailrMarker options:NSCaseInsensitiveSearch ];
    if (range.length > 0 && line.length - range.location - range.length > 2) {
        return [line substringFromIndex:range.location+range.length];
    }
    
    return nil;
}

static NSString * const kFullTrailrMarker = @"<a href=\"http://trailr";
// Look for hidden text before trailr link.
+ (NSString *)getAwardTextInFrontOfTrailerForLine:(NSString *) line {
    
    NSRange range = [line rangeOfString:kFullTrailrMarker options:NSCaseInsensitiveSearch ];
    if (range.length > 0 && range.location > 2) {
        return [line substringToIndex:range.location];
    }
    
    return nil;
}

//Check for trailr begin marker
static NSString * const kTrailrMarker = @"trailr.info/main.php";
static NSString * const kTrailrEndAwardMarker = @"[TLR-OOS]";
static NSString * const kTrailrEndInviteMarker = @"[TLR-OOI]";
//Check for trailr begin marker, the end marker should not be present.
+(BOOL)hasGeneralTrailrMarker:(NSString *)currentLine {
    
    NSRange trailrMarkersRange =[currentLine rangeOfString:kTrailrMarker options:NSCaseInsensitiveSearch];       
    
    if (trailrMarkersRange.length != 0) {        
        return YES;
    }
    
    return NO;
}

//Check for trailr end award marker
+(BOOL)hasTrailrEndAwardMarker:(NSString *)currentLine {
    
    NSRange trailrMarkersRange =[currentLine rangeOfString:kTrailrMarker options:NSCaseInsensitiveSearch];
    
    if (trailrMarkersRange.length != 0) {
        
        NSRange trailrEndRange =[currentLine rangeOfString:kTrailrEndAwardMarker options:NSLiteralSearch];
        
        if (trailrEndRange.length != 0) {
            return YES;
        }
    }
    
    return NO;
}

//Check for trailr end invite marker
+(BOOL)hasTrailrEndInviteMarker:(NSString *)currentLine {
    
    NSRange trailrMarkersRange =[currentLine rangeOfString:kTrailrMarker options:NSCaseInsensitiveSearch];
    
    if (trailrMarkersRange.length != 0) {
        
        NSRange trailrEndRange =[currentLine rangeOfString:kTrailrEndInviteMarker options:NSLiteralSearch];
        
        if (trailrEndRange.length != 0) {
            return YES;
        }
    }
    
    return NO;
}

@end
