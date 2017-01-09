//
//  Flckr1NavigationController.m
//  Flckr1
//
//  Created by Heather Stevens on 1/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//
#import "Flckr1NavigationController.h"

@implementation Flckr1NavigationController 
@synthesize userSessionModel = _userSessionModel;

// Create nav controller from nib.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //...
    }
    
    return self;
}

// Cleanup the cache to help the mem situation.
- (void)didReceiveMemoryWarning {
    NSLog(@"@@@Flckr1NavigationController.didReceiveMemoryWarning@@@");
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    if (self.userSessionModel) {
        [self.userSessionModel.cachedImages removeAllObjects];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

@end
