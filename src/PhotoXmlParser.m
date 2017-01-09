//
//  PhotoXmlParser.m
//  Flckr1
//
//  Created by Heather Stevens on 1/26/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "PhotoXmlParser.h"

@implementation PhotoXmlParser

@synthesize photoList = _photoList;

// Lazy create list for xml elements.
- (NSMutableArray *)photoList {
    
    if (!_photoList) {
        _photoList = [[NSMutableArray alloc ] init];
    }
    
    return _photoList;
}

/*
 2012-01-19 22:03:03.150 Flckr1[407:f803] XmlParser.didStartElement elementName photo, namespaceURI (null), qualifiedName (null)
 2012-01-19 22:03:03.150 Flckr1[407:f803] found key secret, value bea51c7b66
 2012-01-19 22:03:03.151 Flckr1[407:f803] found key id, value 5810589294
 2012-01-19 22:03:03.151 Flckr1[407:f803] found key server, value 2481
 2012-01-19 22:03:03.152 Flckr1[407:f803] found key farm, value 3
 2012-01-19 22:03:03.152 Flckr1[407:f803] found key owner, value 59195110@N02
 2012-01-19 22:03:03.153 Flckr1[407:f803] found key ispublic, value 1
 2012-01-19 22:03:03.154 Flckr1[407:f803] found key isfriend, value 0
 2012-01-19 22:03:03.154 Flckr1[407:f803] found key isfamily, value 0
 2012-01-19 22:03:03.155 Flckr1[407:f803] found key title, value Bridalveil Creek
 
 From group pool:
 <photo id="6867673493" owner="47649083@N03" secret="742e1facd8" server="7052" farm="8" title="Mary's Grove" ispublic="1" isfriend="0" isfamily="0" ownername="desertdude11" dateadded="1329454531" />

 */

static NSString * const kPhoto              = @"photo";
static NSString * const kPhotoId            = @"id";
static NSString * const kOwner              = @"owner";
static NSString * const kSecret             = @"secret";
static NSString * const kServer             = @"server";
static NSString * const kFarm               = @"farm";
static NSString * const kTitle              = @"title";
static NSString * const kViews              = @"views";
static NSString * const kIsPublic           = @"ispublic";
static NSString * const kIsFriend           = @"isfriend";
static NSString * const kIsFamily           = @"isfamily";
/*
 Parser found an element within the document.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    //NSLog(@"XmlParser.didStartElement elementName %@, namespaceURI %@, qualifiedName %@", elementName, namespaceURI, qName);
    
    if ([elementName isEqual:kPhoto]) {
        
        Photo *photo = [[Photo alloc] initWithId:[attributeDict objectForKey:kPhotoId] 
                                           owner:[attributeDict objectForKey:kOwner] 
                                          secret:[attributeDict objectForKey:kSecret] 
                                          server:[attributeDict objectForKey:kServer] 
                                            farm:[attributeDict objectForKey:kFarm] 
                                           title:[attributeDict objectForKey:kTitle] 
                                        isPublic:(BOOL) [attributeDict objectForKey:kIsPublic] 
                                        isFriend:(BOOL)[attributeDict objectForKey:kIsFriend] 
                                        isFamily:(BOOL)[attributeDict objectForKey:kIsFamily]];
        
        photo.views = [attributeDict objectForKey:kViews];

        if (photo.photoId && photo.secret && photo.server && photo.farm) {
            [self.photoList addObject:photo]; 
        }
    }    
}


@end
