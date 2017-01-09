//
//  MessageXmlParser.h
//  FlickrAwards
//
//  Created by Heather Stevens on 3/8/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XmlMapperDelegate.h"

@interface MessageXmlParser : NSObject < XmlMapperDelegate >

@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *commentId;
@property (nonatomic) BOOL successfulApiInvocation;

@end
