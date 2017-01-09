//
//  XmlMapperDelegate.h
//  Flckr1
//
//  Created by Heather Stevens on 1/26/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XmlMapperDelegate <NSObject>

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;

@end
