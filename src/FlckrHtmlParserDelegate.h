//
//  FlckrHtmlParserDelegate.h
//  Flckr1
//
//  Created by Heather Stevens on 2/5/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"
#import "FindAwardHolder.h"
#import "CommunicationsUtil.h"
#import "TrailrUtil.h"
#import "ApiResponse.h"

@interface FlckrHtmlParserDelegate : NSObject

@property (nonatomic, retain) ApiResponse *apiResponse;
@property (atomic, retain) NSMutableArray *awardList;

// Constructor, requires selected group.
- (id)initWithSelectedGroup:(Group *)selectedGroup;

- (NSString *)getGroupWebPageHtmlContent;
- (NSInteger)determineNumberOfRequiredAwards:(NSString *)awardHtml;
- (Award *)getBestAwardFromList;
- (void)getAwardAutomaticallyFromWebPage;

@end
