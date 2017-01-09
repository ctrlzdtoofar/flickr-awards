//
//  ViewUtil.m
//  Flckr1
//
//  Created by Heather Stevens on 1/29/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "ViewUtil.h"

@implementation ViewUtil

// Determines the best size and placement for the image and image view.
+ (CGRect)scalePhotoImage:(UIImage *) photoImage usingBounds:(CGRect) rect {
    
    CGSize viewSize = rect.size;
    //NSLog(@"viewSize size %@",NSStringFromCGSize(viewSize));
        
    
    CGSize imageViewSize = photoImage.size;
    //NSLog(@"imageViewSize (%f,%f)",imageViewSize.width,imageViewSize.height);
    
    float xScale = viewSize.width/imageViewSize.width;
    float yScale = viewSize.height/imageViewSize.height;
    //NSLog(@"Scale X: %f, Y: %f)",xScale,yScale);
    
    float useScale = yScale;
    if (xScale <= yScale) {
        useScale = xScale;
    }
    //NSLog(@"Using Scale: %f)",useScale);
    
    imageViewSize.width = imageViewSize.width * useScale;
    imageViewSize.height = imageViewSize.height * useScale;
    //NSLog(@"New imageViewSize (%f,%f)",imageViewSize.width,imageViewSize.height);
    
    float xOrigin = 0;
    float yOrigin = 0;
    if (xScale > yScale) {
        xOrigin = (viewSize.width - imageViewSize.width)/2;
    }
    else {
        yOrigin = (viewSize.height - imageViewSize.height)/2;
    }
    
    return CGRectMake(xOrigin, yOrigin, imageViewSize.width, imageViewSize.height);
}

@end
