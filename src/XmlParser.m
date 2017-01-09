//
//  XmlParser.m
//  FlckrAwards
//
//  Parses XML documents using delegate to map elements and attributes.
//
//  Created by Heather Stevens on 1/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "XmlParser.h"

@implementation XmlParser

@synthesize xmlMapper = _xmlMapper;

// Setup to parse the xml document.
// Returns YES if successful.
- (BOOL)parseXmlDocument:(NSString *)xmlToParse withMapper:(id <XmlMapperDelegate>)xmlMapper {
    
    self.xmlMapper = xmlMapper;
    
    NSData *xmlData = [xmlToParse dataUsingEncoding:NSUTF8StringEncoding];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData]; 
    [xmlParser setDelegate:self];
    
    if (![xmlParser parse]) {
        NSLog(@"Failed to parse document, %@", xmlParser.parserError.localizedDescription);
        return NO;
    }
    
    // Success
    return YES;
}

/*
 Parser found an element within the document.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    [self.xmlMapper parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //NSLog(@"XmlParser.foundCharacters %@", string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    //NSLog(@"XmlParser.didEndElement elementName %@, namespaceURI %@, qualifiedName %@", elementName, namespaceURI, qName);
    

    
}
// sent when an end tag is encountered. The various parameters are supplied as above.

@end
