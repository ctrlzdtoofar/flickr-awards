//
//  PhotoXmlParser.h
//  Flckr1
//
//  Created by Heather Stevens on 1/26/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XmlMapperDelegate.h"
#import "Photo.h"

@interface PhotoXmlParser : NSObject <XmlMapperDelegate>

@property (nonatomic, retain) NSMutableArray *photoList;

@end
