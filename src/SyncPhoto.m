//
//  SyncPhoto.m
//  Flckr1
//
//  Created by Heather Stevens on 2/9/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "SyncPhoto.h"

@interface SyncPhoto() {
    BOOL haveWifi;
    UITableViewCell *cell;
}

@property (nonatomic, retain) NSArray *photoList;
@end

@implementation SyncPhoto

@synthesize photoList = _photoList;

// Initialize the operation with the photo list and callback obj.
- (id)initWithPhotoList:(NSArray *)photoList haveWifi:(BOOL)inHaveWifi {
    
    self = [super init];
    if (self) {
        self.photoList = photoList;
        haveWifi = inHaveWifi;
    }
    
    return self;
}

// Init with one photo, known to not be in cache.
- (id)initWithPhoto:(Photo *)photo onCompleteCell:(UITableViewCell *) inCell {
    
    self = [super init];
    if (self) {
        self.photoList = [[NSMutableArray alloc] initWithObjects:photo,nil];
        cell = inCell;
    }
    
    return self;
}

// Remove all references to make sure we cleanup properly.
-(void)cleanupTime {
    self.photoList = nil;
    cell = nil;
}

// Pull list of photos into memory.
- (void)main {
    if (self.photoList) {
        
        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        }
        
        // Get the images from Flickr.com
        int count = 0;
        for (Photo *photo in self.photoList) {            
            
            [photo getSmallImage];
            count++;
            
            if ([self isCancelled]) {
                [self cleanupTime];
                return;
            }
            else if (!haveWifi && count > 15) {
                break;
            }
        }
        
        if ([self isCancelled]) {
            [self cleanupTime];
            return;
        }
        
        // Lazy display image in table cell.
        if (self.photoList.count == 1 && cell) {
            
            cell.imageView.image = [[self.photoList objectAtIndex:0] getSmallImage];
            [cell setNeedsLayout];                       
        }
        //NSLog(@"SyncPhoto.main, finished caching small photos.");
    }
    
    [self cleanupTime];
}

@end
