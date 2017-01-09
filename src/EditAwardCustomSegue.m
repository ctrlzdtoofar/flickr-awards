//
//  FlipSegue.m
//  Flckr1
//
//  Created by Heather Stevens on 2/11/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "EditAwardCustomSegue.h"

@implementation EditAwardCustomSegue

@synthesize appDelegate = _appDelegate;

-(void) perform{
    
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    UIViewController *srcVC = (UIViewController *) self.sourceViewController; 
    UIViewController *destVC = (UIViewController *) self.destinationViewController; 
    
    
    [UIView transitionWithView:srcVC.navigationController.view duration:0.75
            options:UIViewAnimationOptionTransitionCrossDissolve     
            animations:^{                       
                       [srcVC.navigationController pushViewController:destVC animated:NO];                        
            }    
            completion:NULL];
        

}
@end
