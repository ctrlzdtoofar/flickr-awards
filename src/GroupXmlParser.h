//
//  GroupXmlParser.h
//  Flckr1
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XmlMapperDelegate.h"
#import "Group.h"


@interface GroupXmlParser : NSObject < XmlMapperDelegate >

@property (nonatomic, retain) NSMutableArray *groupList;


@end
