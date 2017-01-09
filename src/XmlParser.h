//
//  XmlParser.h
//  Flckr1
//
//  Created by Heather Stevens on 1/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"
#import "XmlMapperDelegate.h"

@interface XmlParser : NSObject < NSXMLParserDelegate > 

@property (nonatomic, retain) id <XmlMapperDelegate> xmlMapper;

- (BOOL)parseXmlDocument:(NSString *)xmlToParse withMapper:(id <XmlMapperDelegate>)xmlMapper;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
// sent when the parser finds an element start tag.
// In the case of the cvslog tag, the following is what the delegate receives:
//   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
// In the case of the radar tag, the following is what's passed in:
//    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
// If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
// This returns the string of the characters encountered thus far. You may not necessarily get the longest character run. The parser reserves the right to hand these to the delegate as potentially many calls in a row to -parser:foundCharacters:

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
// sent when an end tag is encountered. The various parameters are supplied as above.

@end
