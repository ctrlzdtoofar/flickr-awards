//
//  GroupXmlParser.m
//  Flckr1
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GroupXmlParser.h"

@implementation GroupXmlParser

@synthesize groupList = _groupList;

- (NSMutableArray *)groupList {
    
    if (!_groupList) {
        _groupList = [[NSMutableArray alloc ] init];
    }
    
    return _groupList;
}

/*
<groups>
 <group nsid="597501@N21" id="597501@N21" name="♥Pretty Kitty♥ Post 3, Comment on 3" admin="" privacy="3" photos="29820" iconserver="2147" iconfarm="3" />
 <group nsid="991859@N20" id="991859@N20" name="✿*DIAMOND NATURE & STYLE*✿{P1. G4}{Admin-INVITE ONLY}" admin="" privacy="3" photos="48676" iconserver="3334" iconfarm="4" />
</groups>
*/

static NSString * const kGroup              = @"group";
static NSString * const kNsid               = @"nsid";
static NSString * const kName               = @"name";

/*
 Parser found an element within the document.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    //NSLog(@"XmlParser.didStartElement elementName %@, namespaceURI %@, qualifiedName %@", elementName, namespaceURI, qName);
    
    if ([elementName isEqual:kGroup]) {
        
        Group *group = [[Group alloc] initWithNsid:[attributeDict objectForKey:kNsid] 
                                           name:[attributeDict objectForKey:kName]];
        
        if (group.nsid && group.name) {
            

            [self.groupList addObject:group];
          
        }
    }    
}

@end
