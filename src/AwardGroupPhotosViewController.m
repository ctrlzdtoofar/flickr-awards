//
//  AwardGroupPhotosViewController.m
//  Flckr1
//
//
//  Allow user to award other photos in the selected group and adds user's photo to group.
//  Created by Heather Stevens on 2/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "AwardGroupPhotosViewController.h"
#import "AddPhotoToGroup.h"
#import "GetGroupPoolPhotos.h"
#import "AwardGroupPhoto.h"
#import "GetDisplayPhoto.h"
#import "DelayOperation.h"
#import "RemoveCommentOperation.h"
#import "CheckPhotosGroupMembership.h"
#import "ViewUtil.h"
#import <AudioToolbox/AudioToolbox.h>


@interface AwardGroupPhotosViewController() <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    int awardedPhotos;
    int currentGroupPhotoIndex;
    BOOL usersPhotoWasAdded; // The user has their photo added to this group.
    SystemSoundID clickSound;
}
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicatorView;
@property (weak, nonatomic) IBOutlet UIScrollView *groupPhotoListScrollView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGuestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipegestureRecognizer;
@property (weak, nonatomic) IBOutlet UILabel *noPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *awardedLabel;

@property (strong, nonatomic) UILabel *groupTitleLabel;
@property (strong, nonatomic) UILabel *groupAwardsRequiredLabel;
@property (strong, nonatomic) UIWebView *groupWebView;
@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@property (atomic, retain) NSArray *groupPhotoList;

@end

@implementation AwardGroupPhotosViewController
@synthesize busyIndicatorView;
@synthesize groupPhotoListScrollView;
@synthesize tapGuestureRecognizer = _tapGuestureRecognizer;
@synthesize rightSwipGestureRecognizer = _rightSwipGestureRecognizer;
@synthesize leftSwipegestureRecognizer = _leftSwipegestureRecognizer;
@synthesize noPhotosLabel = _noPhotosLabel;
@synthesize awardedLabel = _awardedLabel;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize selectedGroup = _selectedGroup;
@synthesize groupTitleLabel = _groupTitleLabel;
@synthesize groupAwardsRequiredLabel = _groupAwardsRequiredLabel;
@synthesize groupWebView = _groupWebView;
@synthesize operationsQueue = _operationsQueue;
@synthesize groupPhotoList = _groupPhotoList;
@synthesize currentGroupPhoto = _currentGroupPhoto;
@synthesize photoImageView = _photoImageView;

// getter for the operations queue.
- (NSOperationQueue *)operationsQueue {
    
    if (!_operationsQueue) {
        _operationsQueue = [[NSOperationQueue alloc] init];
    }
    
    return _operationsQueue;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Show error message to user on popup.
-(void)displayErrorMessage:(NSString *) message withTitle:(NSString *)title {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show]; 
    
    [self.busyIndicatorView stopAnimating];
    self.busyIndicatorView.hidden = YES;     
}

// Show error message that occurred with Flickr's API.
-(void)displayApiErrorWithTitle:(NSString *)title {
    // Display error.
    [self displayErrorMessage:[self.flkrApiDelegate.userSessionModel.errorMessage copy] withTitle:title];  
    
    self.flkrApiDelegate.userSessionModel.errorMessage = nil;
}

// Get the indicator to show
- (void)showBusyIndicator {
    [self.busyIndicatorView startAnimating];
    self.busyIndicatorView.hidden = NO;    
    if (self.photoImageView) {
        self.photoImageView.alpha = 0.75;
    }
}

//Display the photo on the screen.
- (void)displayImage:(UIImage *)photoToDisplay forController:(AwardGroupPhotosViewController *) controller {
    
    [controller.busyIndicatorView stopAnimating];
    controller.busyIndicatorView.hidden = YES;

    // Remove the current photo from it super view to get ready for the new one.
    if (controller.photoImageView) {
        [controller.busyIndicatorView removeFromSuperview];
        [controller.photoImageView removeFromSuperview];
        controller.photoImageView.image = nil;
    }   
    
    CGRect photoImageViewBounds = [ViewUtil scalePhotoImage:photoToDisplay usingBounds:controller.groupPhotoListScrollView.frame];                 
    controller.photoImageView = [[UIImageView alloc] initWithFrame:photoImageViewBounds];  
    controller.photoImageView.frame = photoImageViewBounds;
    controller.photoImageView.bounds = photoImageViewBounds;
    controller.photoImageView.image = photoToDisplay;
     
    [controller.photoImageView addSubview:controller.busyIndicatorView];
    
    [controller.groupPhotoListScrollView addSubview:controller.photoImageView];  
    controller.groupPhotoListScrollView.zoomScale = 1.0;
    
    if (controller.currentGroupPhoto.photoWasAwarded) {
        controller.photoImageView.alpha = 0.5;
        controller.awardedLabel.hidden = NO; 
        [controller.groupPhotoListScrollView bringSubviewToFront:controller.awardedLabel];
    }
    else {
        controller.photoImageView.alpha = 1.0;
        controller.awardedLabel.hidden = YES;
    }
}

// Check dimensions to determine the size and location of the photo view after a rotation has completed.
- (void)resizeImageViewAfterRotation {
    if (self.currentGroupPhoto) {        
        
        __weak AwardGroupPhotosViewController *weakSelf = self;
        
        if (self.photoImageView.alpha == 1.0) {
            [UIView
             animateWithDuration:0.3
             animations:^{       
                 weakSelf.groupPhotoListScrollView.zoomScale = 1.0;
                 CGRect photoImageViewBounds = [ViewUtil scalePhotoImage:weakSelf.photoImageView.image usingBounds:weakSelf.groupPhotoListScrollView.bounds];
                 weakSelf.photoImageView.frame = photoImageViewBounds;
                 weakSelf.photoImageView.bounds = photoImageViewBounds;
                 
                 weakSelf.busyIndicatorView.center = weakSelf.view.center;
             }];
            
            // Redisplay image quickly to fix swiping and movement issues.
            [self displayImage:self.photoImageView.image forController:self];
        }
        // The first time the image view needs to become opaque.
        else  {
            CGRect photoImageViewBounds = [ViewUtil scalePhotoImage:self.photoImageView.image usingBounds:self.groupPhotoListScrollView.bounds];
            self.photoImageView.frame = photoImageViewBounds;
            self.photoImageView.bounds = photoImageViewBounds;
            
            [UIView
             animateWithDuration:0.3
             animations:^{             
                 weakSelf.photoImageView.alpha = 1.0;
                 weakSelf.busyIndicatorView.center = weakSelf.groupPhotoListScrollView.center;
             }];           
        }       
    }
}

// Update photo view to display current photo after change.
// Check dimensions to determine the size and location of the photo view.
- (void)displayPhotoImageView {
    //NSLog(@"PhotoVC.createPhotoImageView view.bounds %@", NSStringFromCGRect(self.view.bounds));        
    //NSLog(@"PhotoVC.createPhotoImageView view.frame %@", NSStringFromCGRect(self.view.frame));       
    //NSLog(@"PhotoVC.createPhotoImageView groupPhotoListScrollView.bounds %@", NSStringFromCGRect(self.groupPhotoListScrollView.bounds));        
    //NSLog(@"PhotoVC.createPhotoImageView groupPhotoListScrollView.frame %@", NSStringFromCGRect(self.groupPhotoListScrollView.frame));  
    
    if (self.currentGroupPhoto) {                
        
        __weak UIImage *photoToDisplay = [self.currentGroupPhoto getMediumImage];        
        __weak AwardGroupPhotosViewController *weakSelf = self;
        if (photoToDisplay) {    
            
            [UIView animateWithDuration:0.50 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^{             
                
                [weakSelf displayImage:photoToDisplay forController:weakSelf];                    
            } completion:nil];
            
            // Is there another photo after this one to pre-load?
            if (currentGroupPhotoIndex +1 < self.groupPhotoList.count) {
                
                // Pull down the next photo to get ahead of the game.
                Photo *nextPhoto = [self.groupPhotoList objectAtIndex:currentGroupPhotoIndex+1];
                
                // Is the next photo already loaded?
                if (!nextPhoto.mediumImageLoaded) {                
                    // Pull the next photo image down from Flickr in the bg.
                    
                    //NSLog(@"AwardGroupPhotosViewController.displayPhotoImageView loading the next image.");
                    GetDisplayPhoto *getDisplayPhoto = [[GetDisplayPhoto alloc] initWithApiDelegate:self.flkrApiDelegate  andPhoto:nextPhoto onCompleteUpdate:nil withSelector:nil];                                                
                    [self.operationsQueue addOperation:getDisplayPhoto];   
                }
            }
        }
        else {
            // Image went missing
            // Display error.
            [self displayApiErrorWithTitle:@"Photo Unavailable"];  
         }
    }
}

// Show that the user's photo was added to the group.
- (void)showUsersPhotoHasBeenAdded {
   
    self.groupAwardsRequiredLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 290, 100)];
    self.groupAwardsRequiredLabel.text = @"Photo Added to Group!";
    self.groupAwardsRequiredLabel.textColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1.0];
    self.groupAwardsRequiredLabel.font = [UIFont boldSystemFontOfSize:22];
    self.groupAwardsRequiredLabel.textAlignment = UITextAlignmentCenter;
    self.groupAwardsRequiredLabel.alpha = 0.0;
    [self.groupAwardsRequiredLabel setBackgroundColor:UIColor.clearColor];
    self.groupAwardsRequiredLabel.transform = CGAffineTransformMakeRotation(-35*RADIANS_INA_DEGREE);
        
    // Swap out the current group photo with the user's photo tempoarily.
    id saveGroupPhoto = self.currentGroupPhoto;
    self.currentGroupPhoto = self.selectedPhoto;
    
    __weak UIImage *photoToDisplay = [self.selectedPhoto getMediumImage];        
    __weak AwardGroupPhotosViewController *weakSelf = self;
                 
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{             
        
        [weakSelf displayImage:photoToDisplay forController:weakSelf]; 
        [weakSelf.photoImageView addSubview:weakSelf.groupAwardsRequiredLabel];
        weakSelf.groupAwardsRequiredLabel.center = weakSelf.photoImageView.center;
        [weakSelf.photoImageView bringSubviewToFront:weakSelf.groupAwardsRequiredLabel];
        weakSelf.groupAwardsRequiredLabel.alpha = 1.0;
        
    } completion:nil];

    // Now put the group photo back.
    self.currentGroupPhoto = saveGroupPhoto;
}

// Figure out the next photo to display, pull it down from FLickr, hide the buttons and start the indicator animation.
- (void)moveToNextPhoto {
    
    if (self.groupPhotoList.count > 0) {
        
        currentGroupPhotoIndex++;
        //NSLog(@"AwardGroupPhotosViewController.moveToNextPhoto, currentGroupPhotoIndex %d", currentGroupPhotoIndex);
        
        // Deal with out of bounds issues.
        if (currentGroupPhotoIndex < 0) {
            currentGroupPhotoIndex = 0;
            //NSLog(@"AwardGroupPhotosViewController.moveToNextPhoto, redisplaying first photo: currentGroupPhotoIndex %d", currentGroupPhotoIndex);
            [self displayPhotoImageView]; 
            
            return;
        }  
        else if (currentGroupPhotoIndex >= self.groupPhotoList.count) {
            currentGroupPhotoIndex = self.groupPhotoList.count-1;
            
            // Redisplay current photo incase it was awarded.
            //NSLog(@"AwardGroupPhotosViewController.moveToNextPhoto, redisplaying photo: currentGroupPhotoIndex %d", currentGroupPhotoIndex);
            [self displayPhotoImageView]; 
            
            return;
        }
        
        self.currentGroupPhoto = [self.groupPhotoList objectAtIndex:currentGroupPhotoIndex];
        
        // See if we already have the medim image to use.
        if (self.currentGroupPhoto.mediumImageLoaded) {            
            [self displayPhotoImageView]; 
        }
        else {
            // Pull the photo image down from FLickr in the bg.
            GetDisplayPhoto *getDisplayPhoto = [[GetDisplayPhoto alloc] initWithApiDelegate:self.flkrApiDelegate  andPhoto:self.currentGroupPhoto onCompleteUpdate:self withSelector:@selector(displayPhotoImageView)];    
            [self.operationsQueue addOperation:getDisplayPhoto];  
            //NSLog(@"AwardGroupPhotosViewController.moveToNextPhoto, currentGroupPhotoIndex %d needs to be loaded from Flickr", currentGroupPhotoIndex);
        }       
    }
    else {
        [self displayErrorMessage:@"No photos loaded from Flickr for this group" withTitle:@"No Group Photos"];  
    }
}

// Called from queued bg operation 
// User's photo was added to the group.
- (void)photoAddedToGroup {
    
    [self.busyIndicatorView stopAnimating];
    self.busyIndicatorView.hidden = YES;
    
    if (self.flkrApiDelegate.userSessionModel.errorMessage) {
        
        if ([self.flkrApiDelegate.userSessionModel.errorMessage rangeOfString:@"Pending Queue"].length > 0) {
            [self displayApiErrorWithTitle:@"Photo Addition Pending"];
        }
        else {
            [self displayApiErrorWithTitle:@"Failed to Add Photo"];
        }
    }
    else {
    
        //NSLog(@"AwardGroupPhotosViewController.photoAddedToGroup");
       
        // Mark the photo as added so it won't get dbl added.
        usersPhotoWasAdded = YES;
        self.navigationController.navigationBar.topItem.prompt =  [NSString stringWithFormat:@"Awards (%d/%d) Photo Added", awardedPhotos,self.selectedGroup.award.requiredAwards];  
    
        [self showUsersPhotoHasBeenAdded];
    }
    
    // Call move to next photo after a delay
    DelayOperation *delayOperation = [[DelayOperation alloc] initWith:self callSel:@selector(moveToNextPhoto)];                                  
    delayOperation.secsToDelay = 3.0;
    
    [self.operationsQueue addOperation:delayOperation];  
}

// Show animation of award being taken from photo.
- (void)showAwardBeingTakenFromPhoto {
    
    // Make sure the award web view has been scaled to .01
    self.groupWebView.transform = CGAffineTransformMakeScale(.01, .01);
    // Get the web view to be centered.
    self.groupWebView.center = self.view.center;
    
    [self.view bringSubviewToFront:self.groupWebView];
    
    __weak AwardGroupPhotosViewController *weakSelf = self;
    
    [UIView animateWithDuration:0.60 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{             
        
        weakSelf.groupWebView.transform = CGAffineTransformMakeScale(.7, .7);
                
        // Get the web view to be close to the right edge, but out of view.
        int xPointToHide = weakSelf.view.bounds.size.width * 1.3;            
        weakSelf.groupWebView.center = CGPointMake(xPointToHide, 30);

        
    } completion:^(BOOL finished) {    
        
        // After the animation is completed, move award web view out of the way.
        weakSelf.groupWebView.center = CGPointMake(700, 30);
        
    }];
}

// Show animation of award being given to photo.
- (void)showAwardBeingGivenToPhoto {

    
    // Get the web view to be close to the right edge, but still out of view.
    int xPointToHide = self.view.bounds.size.width * 1.3;            
    self.groupWebView.center = CGPointMake(xPointToHide, 30);
    
    // Make sure it has been rescaled to .3
    self.groupWebView.transform = CGAffineTransformMakeScale(.7, .7);
    
    [self.view bringSubviewToFront:self.groupWebView];
    __weak AwardGroupPhotosViewController *weakSelf = self;
    
    [UIView animateWithDuration:0.60 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{             
                
        weakSelf.groupWebView.transform = CGAffineTransformMakeScale(.01, .01);
        weakSelf.groupWebView.center = weakSelf.view.center;
        
    } completion:^(BOOL finished) {    
        
        // After the animation is completed, move award web view out of the way.
        weakSelf.groupWebView.center = CGPointMake(700, 30);
        
    }];
}

//Add the user's photo to the group.
-(void)addUserPhotoToGroup {
    usersPhotoWasAdded = YES;
    
    AddPhotoToGroup *addPhotoToGroup = [[AddPhotoToGroup alloc] initWithApiDelegate:self.flkrApiDelegate onCompleteUpdate:self  withSelector:@selector(photoAddedToGroup)];  
    
    //NSLog(@"AwardGroupPhotosViewController.awardAddedToCurrentPhoto adding user photo");
    [addPhotoToGroup setPhoto:self.selectedPhoto andGroup:self.selectedGroup]; 
    [self.operationsQueue addOperation:addPhotoToGroup];
}

// Use the photo's id to find a group photo.
-(Photo *)lookupGroupPhoto:(NSString *)photoId {
 
    for (Photo *photo in self.groupPhotoList) {
        if ([photo.photoId isEqualToString:photoId]) {
            return photo;
        }
    }
    return nil;            
}

// Called from queued operation, AddPhotoToGroup
// Shows success msg and start group photo request operation.
- (void)awardAddedToPhoto:(Photo *)awardedPhoto {
    
    // Deal with any error.
    if (self.flkrApiDelegate.userSessionModel.errorMessage) {
        
        // Photo wasn't awarded afterall.
        self.currentGroupPhoto.photoWasAwarded = NO;
        
        if ([self.flkrApiDelegate.userSessionModel.errorMessage isEqualToString:@"Unknown internal error"]) {
            self.flkrApiDelegate.userSessionModel.errorMessage = @"Flickr limits how fast comments can be posted. Wait 10 to 30+ seconds and try again.";
        }
        else if ([self.flkrApiDelegate.userSessionModel.errorMessage isEqualToString:@"User is posting comments too fast."]) {
            self.flkrApiDelegate.userSessionModel.errorMessage = @"The Flickr comment posting limit has been reached for the next 1 to 4 minutes.";
        }
        [self displayApiErrorWithTitle:@"Failed to Give Award"];
        return;
    }
    
    awardedPhotos++;  
    BOOL awardedPhotoOnScreen = NO;
    Photo *photoToUpdate;
    if ([awardedPhoto.photoId isEqualToString:self.currentGroupPhoto.photoId]) {
        awardedPhotoOnScreen = YES;
        photoToUpdate = self.currentGroupPhoto;
    } 
    else {
        photoToUpdate = [self lookupGroupPhoto:awardedPhoto.photoId];
    }
    
    if (!photoToUpdate) {
        NSLog(@"Updated photo with id %@ not found!", awardedPhoto.photoId);
        return;
    }
    
    photoToUpdate.commentId = awardedPhoto.commentId;
    photoToUpdate.photoWasAwarded = YES;

    self.navigationController.navigationBar.topItem.prompt = [NSString stringWithFormat:@"Awards (%d/%d)", awardedPhotos,self.selectedGroup.award.requiredAwards];  
    
    // If enough awards were given by the user, then
    // go ahead and add the user's photo to the group.
    if (awardedPhotos >= self.selectedGroup.award.requiredAwards || awardedPhotos == self.groupPhotoList.count || self.groupPhotoList.count == 0) {
        
        // Don't add the user's photo twice
        if (!usersPhotoWasAdded) {
            [self addUserPhotoToGroup];
        }
        else {
            self.navigationController.navigationBar.topItem.prompt =
                [NSString stringWithFormat:@"Extra Award Given (%d/%d)", awardedPhotos,self.selectedGroup.award.requiredAwards];
            
            // Determine what to do next.
            if (awardedPhotoOnScreen) {
                [self moveToNextPhoto];
            }
        }
    }
    else { 
        
        // Determine what to do next.
        if (awardedPhotoOnScreen) {
            [self moveToNextPhoto];
        }
    }
}

-(void)displayCurrentPhotoAsUnawarded {
    [self.busyIndicatorView stopAnimating];
    self.busyIndicatorView.hidden = YES;
    self.photoImageView.alpha = 1.0;
    self.awardedLabel.hidden = YES; 
}

// Called from queued operation, RemoveCommentOperation
// Shows success or error message.
- (void)awardRemovedFromPhoto:(Photo *) unawardedPhoto {
    
    // Deal with any error.
    if (self.flkrApiDelegate.userSessionModel.errorMessage) {
        
        // Photo wasn't UN-awarded afterall.
        self.currentGroupPhoto.photoWasAwarded = YES; 
        
        [self displayApiErrorWithTitle:@"Failed to Remove Award"];
        return;
    }
    
    awardedPhotos--;
    Photo *photoToUpdate;
    if ([unawardedPhoto.photoId isEqualToString:self.currentGroupPhoto.photoId]) {
        photoToUpdate = self.currentGroupPhoto;
        [self displayCurrentPhotoAsUnawarded];
    } 
    else {
        photoToUpdate = [self lookupGroupPhoto:unawardedPhoto.photoId];
    }
    
    if (!photoToUpdate) {
        NSLog(@"Un-awarded photo with id %@ not found!", unawardedPhoto.photoId);
        return;
    }
    photoToUpdate.commentId = nil;
    photoToUpdate.photoWasAwarded = NO;
    
    self.navigationController.navigationBar.topItem.prompt = [NSString stringWithFormat:@"Awards (%d/%d)", awardedPhotos,self.selectedGroup.award.requiredAwards]; 
}

// Takes away the current photo's award. (Must have been given an award)
-(void)removeAwardFromCurrentPhoto {
    @synchronized(self.currentGroupPhoto) {
        if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
            
            // Show award animation
            [self showAwardBeingTakenFromPhoto];
            
            RemoveCommentOperation *removeAwardFromGroupPhoto = [[RemoveCommentOperation alloc] initWithApiDelegate:self.flkrApiDelegate fromPhoto:self.currentGroupPhoto onCompleteUpdate:self withSelector:@selector(awardRemovedFromPhoto:)];
            [self.operationsQueue addOperation:removeAwardFromGroupPhoto];            
            [self showBusyIndicator];
        }      
        else {
            [self displayApiErrorWithTitle:@"Failed to Remove Award"];
        }
    }
}

// Adds comment with award to group photo.
-(void)giveAwardToCurrentPhoto {
    // process one tap at a time.
    @synchronized(self.currentGroupPhoto) {
        
        // Only award a photo once.
        if (self.currentGroupPhoto && !self.currentGroupPhoto.photoWasAwarded) { 
            
            if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
                
                // Sound effects.                
                AudioServicesPlaySystemSound(clickSound);
                
                // Show award animation
                [self showAwardBeingGivenToPhoto];
                Photo *photoToAward = [self.currentGroupPhoto copy];
                
                AwardGroupPhoto *awardGroupPhoto = [[AwardGroupPhoto alloc] initWithApiDelegate:self.flkrApiDelegate withPhoto:photoToAward withAward:self.selectedGroup.award.htmlAward onCompleteUpdate:self withSelector:@selector(awardAddedToPhoto:)];
                
                [self.operationsQueue addOperation:awardGroupPhoto];                
                [self showBusyIndicator];
                self.busyIndicatorView.hidden = NO;
                self.currentGroupPhoto.photoWasAwarded = YES;            }      
            else {
                [self displayApiErrorWithTitle:@"Failed to Give Award"];
            }
        }
    }
}

// Give the group award to the currently displayed photo.
// (Photo was tapped)
// bg operation calls awardAddedToCurrentPhoto upon completion.
- (IBAction)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    //NSLog(@"AwardGroupPhotosViewController.handleTapFrom");    
       
    if (self.currentGroupPhoto && self.currentGroupPhoto.photoWasAwarded) {
        [self removeAwardFromCurrentPhoto];
    }
    else if (self.currentGroupPhoto && !self.currentGroupPhoto.photoWasAwarded) {
        [self giveAwardToCurrentPhoto];
    }
}

// User swiped photo to skip it.
- (IBAction)handleLeftSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    //NSLog(@"AwardGroupPhotosViewController.handleLeftSwipeFrom left");
    
    [self showBusyIndicator];    
    [self moveToNextPhoto]; 
}

// User swiped photo to skip it.
- (IBAction)handleRightSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    //NSLog(@"AwardGroupPhotosViewController.handleLeftSwipeFrom right");
    
    [self showBusyIndicator];
    
    // Play trick to reuse moveToNextPhoto method to move to previous photo.
    currentGroupPhotoIndex -= 2;    
    
    [self moveToNextPhoto];
}

// Called from queued bg operation, GetGroupPoolPhotos
// Load this group's photos. Called only once by bg thread after view first loads.
- (void)photosRetrievedFromGroup:(NSArray *) groupPhotoList {
    self.groupPhotoList = groupPhotoList;
    
    if (self.groupPhotoList.count > 0) {
        
        // Reset which photos that may have the awarded flag set.
        for (Photo *photo in self.groupPhotoList) {
            photo.photoWasAwarded = NO;
        }
        
        // Finish setting up the first photo in group list.
        currentGroupPhotoIndex = -1;
        [self moveToNextPhoto];
        
        // Get a weak reference to this object.
        __weak AwardGroupPhotosViewController *weakSelf = self;

        // Hide the initial title and awards required text.
        [UIView animateWithDuration:0.2 delay:1.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{ 
            weakSelf.groupTitleLabel.alpha = 0.0;
            weakSelf.groupAwardsRequiredLabel.alpha = 0.0;
        } 
        completion:nil];
        
        // Rip the award web view away from the screen using twirl effect displaying the first group
        // photo beneath it.
        [UIView animateWithDuration:1.2 delay:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{   
            
            // Create a point off screen.
            int xPointToHide = weakSelf.view.bounds.size.width * 1.3;            
            weakSelf.groupWebView.center = CGPointMake(xPointToHide, 30);
            
            // Move the award web view off screen.
            CGAffineTransform rotate = CGAffineTransformMakeRotation(100*RADIANS_INA_DEGREE);
            CGAffineTransform scaleDown = CGAffineTransformMakeScale(.3, .3);
            weakSelf.groupWebView.transform = CGAffineTransformConcat(rotate, scaleDown);
            
            // Ease the photo from invisible to full visibility.
            weakSelf.groupPhotoListScrollView.alpha = 1.0;
            
        } completion:^(BOOL finished) {    
        
            // After the animation is completed, clean up some memory.
            [weakSelf.groupTitleLabel removeFromSuperview];
            weakSelf.groupTitleLabel = nil;
            [weakSelf.groupAwardsRequiredLabel removeFromSuperview];
            weakSelf.groupAwardsRequiredLabel = nil;
            
            // Reset the webview off screen for later use.
            weakSelf.groupWebView.center = CGPointMake(700, 30);
            weakSelf.groupWebView.transform = CGAffineTransformMakeRotation(-100*RADIANS_INA_DEGREE);

        }];
    }
    else {
        // Flickr API call couldn't complete. iPhone may have lost connectivity with Flickr.
        [self displayApiErrorWithTitle:@"Group Photos Unavailable"]; 
    }
}

// Load the group photos from Flckr.
// Starts queued bg operation.
- (void)loadGroupPhotosDisplayFirstPhoto {
    
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        
        // This operation pulls down the photo list and gets the first image. It also sleeps for a short bit for
        // the group info view to be seen.
        GetGroupPoolPhotos *getGroupPoolPhotos = [[GetGroupPoolPhotos alloc] initWithApiDelegate:self.flkrApiDelegate withGroup:self.selectedGroup onCompleteUpdate:self]; // Hard coded to call photosRetrievedFromGroup.
        [self.operationsQueue addOperation:getGroupPoolPhotos];  
     }
     else {  
         [self displayApiErrorWithTitle:@"Photo Unavailable"]; 
     }
}

// Called from queued bg operation, CheckPhotosGroupMembership
- (void) photoInGroup:(NSString *) isPhotoInGroup {
    
    if ([@"YES" isEqualToString:isPhotoInGroup]) {
        [self displayErrorMessage:@"The selected photo has already been added to this group."
                        withTitle: @"Photo Previously Added"];
    }
}

// Load the group photos from Flckr.
// Starts queued bg operation.
- (void)checkPhotoMembership {
    
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        
        // This operation determines if the selected photo is already in the selected group and then wanrs the users
        // if it is found in the group.
        CheckPhotosGroupMembership *checkGroupMembership =
            [[CheckPhotosGroupMembership alloc]
                initWithApiDelegate:self.flkrApiDelegate withPhoto:self.selectedPhoto
                                                   withGroup:self.selectedGroup.nsid onCompleteUpdate:self
                                                   withSelector:@selector(photoInGroup:)];
        
        [self.operationsQueue addOperation:checkGroupMembership];
    }

}

// Creates a view to display key aspects of the group choosen by the user.
- (void)showGroupTitleRequiredAwardsandAwardHTMLBriefly {
    
    self.groupTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 290, 20)];
    self.groupTitleLabel.text = self.selectedGroup.name;
    self.groupTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.groupTitleLabel.textColor = [UIColor blueColor];   
    self.groupTitleLabel.alpha = 0.0;
    [self.view addSubview:self.groupTitleLabel];    
    
    self.groupAwardsRequiredLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 290, 20)];
    self.groupAwardsRequiredLabel.text = [NSString stringWithFormat:@"Awards Required to Add Photo: %d", self.selectedGroup.award.requiredAwards];
    self.groupAwardsRequiredLabel.textColor = [UIColor blueColor];
    self.groupAwardsRequiredLabel.alpha = 0.0;
    [self.view addSubview:self.groupAwardsRequiredLabel];
    
    self.groupWebView = [[UIWebView alloc] initWithFrame:CGRectMake(20, 70, 300, 390)];
    NSString *awardToDisplayOnWebView = [CommunicationsUtil swapCRLFforHtmlBreak:self.selectedGroup.award.htmlAward];
    awardToDisplayOnWebView = [CommunicationsUtil removeErrantEmbeddedTags:awardToDisplayOnWebView];
    
    [self.groupWebView loadHTMLString:awardToDisplayOnWebView baseURL:nil];
    self.groupWebView.userInteractionEnabled = NO;
    [self.groupWebView setContentScaleFactor:0.30];
    self.groupWebView.alpha = 0.0;
    [self.view addSubview:self.groupWebView];
    
    __weak AwardGroupPhotosViewController *weakSelf = self;
    
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{             
        weakSelf.groupTitleLabel.alpha = 1.0;
        weakSelf.groupAwardsRequiredLabel.alpha = 1.0;
        weakSelf.groupWebView.alpha = 1.0;
    } 
    completion:nil];
}

#pragma mark - View lifecycle
- (void) viewDidAppear:(BOOL)animated {
    
    self.busyIndicatorView.center = self.view.center;
        
    if (self.selectedGroup && self.selectedPhoto) {
        [self checkPhotoMembership];
        [self showGroupTitleRequiredAwardsandAwardHTMLBriefly];      
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;  
    self.groupPhotoListScrollView.delegate = self;
    self.groupPhotoListScrollView.alpha = 0.0;
    [self.groupPhotoListScrollView addGestureRecognizer:self.tapGuestureRecognizer];
    [self.groupPhotoListScrollView addGestureRecognizer:self.leftSwipegestureRecognizer];
    [self.groupPhotoListScrollView addGestureRecognizer:self.rightSwipGestureRecognizer];
    self.tapGuestureRecognizer.delegate = self;
    self.leftSwipegestureRecognizer.delegate = self;
    self.rightSwipGestureRecognizer.delegate = self;   
    
    if (self.selectedGroup && self.selectedPhoto) {
        [self loadGroupPhotosDisplayFirstPhoto];
    }
    
    awardedPhotos = 0;
    usersPhotoWasAdded = NO;

    [self.busyIndicatorView startAnimating];
    [self.view bringSubviewToFront:self.busyIndicatorView];
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"Click" ofType:@"wav"];
    CFURLRef soundURL = (__bridge CFURLRef)[NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID(soundURL, &clickSound);
   
}

// Cleanup time.
- (void)viewDidUnload {
    [self setBusyIndicatorView:nil];
    [self setGroupPhotoListScrollView:nil];
    self.flkrApiDelegate = nil;
    self.currentGroupPhoto = nil;
    self.selectedGroup = nil;
    self.selectedPhoto = nil;
    self.groupPhotoList = nil;
    self.operationsQueue = nil;
    self.photoImageView = nil;
    
    [self setTapGuestureRecognizer:nil];
    [self setRightSwipGestureRecognizer:nil];
    [self setLeftSwipegestureRecognizer:nil];
    [self setNoPhotosLabel:nil];
    [self setAwardedLabel:nil];
    self.groupWebView = nil;
    self.groupTitleLabel = nil;
    self.groupAwardsRequiredLabel = nil;

    AudioServicesDisposeSystemSoundID(clickSound);
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// This isn't good.
- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@@@AwardGroupPhotosVC.didReceiveMemoryWarning@@@@");
}

// return a view that will be scaled. if delegate returns nil, nothing happens
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.photoImageView;
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self resizeImageViewAfterRotation];    
}
@end
