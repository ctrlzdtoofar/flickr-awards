//
//  GeneralUtil.m
//  FlickrAwards
//
//  Created by Family on 10/18/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GeneralUtil.h"

@implementation GeneralUtil

+ (NSString *) concatenateStrings:(NSString *) firstString with:(NSString *) secondString {
    
    NSMutableString *concatStr = [[NSMutableString alloc] initWithCapacity:firstString.length+secondString.length];
    
    [concatStr appendString:firstString];
    [concatStr appendString:secondString];
    
    return concatStr;
}
@end
