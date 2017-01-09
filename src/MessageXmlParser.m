//
//  MessageXmlParser.m
//  FlickrAwards
//
//  Created by Heather Stevens on 3/8/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "MessageXmlParser.h"

@implementation MessageXmlParser

@synthesize message = _message;
@synthesize commentId = _commentId;
@synthesize successfulApiInvocation = _successfulApiInvocation;

/*
 <?xml version="1.0" encoding="utf-8" ?>
 <rsp stat="fail">
 <err code="2" msg="Unknown user" />
 </rsp>
 */

static NSString * const kRsp                = @"rsp";
static NSString * const kErr                = @"err";
static NSString * const kStat               = @"stat";
static NSString * const kFail               = @"fail";
static NSString * const kOk                 = @"ok";
static NSString * const kMsg                = @"msg";
static NSString * const kComment            = @"comment";
static NSString * const kId                 = @"id";

/*
 Parser found an element within the document.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    //NSLog(@"XmlParser.didStartElement elementName %@, namespaceURI %@, qualifiedName %@", elementName, namespaceURI, qName);
    
    if ([elementName isEqual:kRsp]) {
        if ([[attributeDict objectForKey:kStat] isEqualToString:kOk]) {
            self.successfulApiInvocation = YES;
        }
        else {
            self.successfulApiInvocation = NO;
        }
    }
    else if ([elementName isEqual:kErr]) {        
        self.message = [attributeDict objectForKey:kMsg];     
    } 
    else if ([elementName isEqual:kComment]) {        
        self.commentId = [attributeDict objectForKey:kId];     
    } 

}
@end
