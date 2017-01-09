//
//  PhotoViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 1/19/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoXmlParser.h"
#import "GroupXmlParser.h"
#import "PickGroupTableViewController.h"
#import "GetDisplayPhoto.h"
#import "DelayOperation.h"

@interface PhotoViewController()  <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;    
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicatorView;
@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation PhotoViewController
@synthesize scrollView = _scrollView;
@synthesize busyIndicatorView = _busyIndicatorView;
@synthesize operationsQueue = _operationsQueue;
@synthesize titleView = _titleView;
@synthesize titleLabel = _titleLabel;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize photoImageView = _photoImageView;
@synthesize isPhotoFullScreen = _isPhotoFullScreen;

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
        self.view.contentMode = UIViewContentModeScaleAspectFit;
        self.isPhotoFullScreen = NO;
    }
    return self;
}

// Display error message to user on the login screen.
- (void)displayErrorMessage:(NSString *) message withTitle:(NSString *) title {    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];    
}

//Display the photo on the screen.
// Checks dimensions to determine the size and location of the photo view.
- (void)displayImage:(UIImage *)photoToDisplay forController:(PhotoViewController *) controller {
    // Remove the current photo from it super view to get ready for the new one.
    if (controller.photoImageView) {
        [controller.photoImageView removeFromSuperview];
        controller.photoImageView.image = nil;
           }   
    
    CGRect photoImageViewBounds = [ViewUtil scalePhotoImage:photoToDisplay usingBounds:controller.scrollView.frame];                 
    controller.photoImageView = [[UIImageView alloc] initWithFrame:photoImageViewBounds];  
    controller.photoImageView.frame = photoImageViewBounds;
    controller.photoImageView.bounds = photoImageViewBounds;
    controller.photoImageView.alpha = 1.0;
    controller.photoImageView.image = photoToDisplay;
    
    [controller.scrollView addSubview:controller.photoImageView];  
    controller.scrollView.zoomScale = 1.0;
    [controller.busyIndicatorView stopAnimating];
     
}

// Hide the photo's title
- (void)hideTitle {
    
    __weak PhotoViewController *weakSelf = self;
        
    [UIView
     animateWithDuration:1.5
     animations:^{       
             
         weakSelf.titleView.alpha = 0.0;
    }]; 
}

// Display the photo's title and then hide it.
- (void)showTitleBriefly {
    
    if (self.selectedPhoto.title) {
        
        CGRect titleViewFrame = self.titleView.frame;
        titleViewFrame.size.width = self.scrollView.frame.size.width;
        self.titleView.frame = titleViewFrame;
        self.titleView.bounds = titleViewFrame;
        
        self.titleLabel.text = self.selectedPhoto.title;        
        self.titleView.alpha = 1.0;
        [self.scrollView bringSubviewToFront:self.titleView];
        
        DelayOperation *delayOperation = [[DelayOperation alloc] initWith:self callSel:@selector(hideTitle)];                                  
        delayOperation.secsToDelay = 2.75;
        
        [self.operationsQueue addOperation:delayOperation];  

    }
    else {
        [self hideTitle];
    }
}

// Check dimensions to determine the size and location of the photo view after a rotation has completed.
- (void)resizeImageViewAfterRotation {
    
    __weak PhotoViewController *weakSelf = self;
    
    if (self.selectedPhoto) {        

            [UIView
             animateWithDuration:0.4
             animations:^{       

                 [weakSelf displayImage:weakSelf.photoImageView.image forController:weakSelf];
                 weakSelf.busyIndicatorView.center = weakSelf.view.center;
             }];        
    }
}

// Handle tap guestures by changing photo size or scale.
- (IBAction)resizePhotoPerTapGesture:(UITapGestureRecognizer *)sender {
// not used for now...
}

// Pass on the delegate for Flickr API comm. Get models ready to display flickr content.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 
    // Make sure the api delegate is set.
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    
    if ([segue.identifier isEqualToString:@"Select Group for Photo"]) {       
        [segue.destinationViewController setSelectedPhoto: self.selectedPhoto];
        
        // In award mode
        [segue.destinationViewController groupAwardMode];
    }    
    self.photoImageView.alpha = 0.0;
}

// trouble...
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@@PhotoVC.didReceiveMemoryWarning@@@@");
}

// Determine the image to display then call display.
- (void)createPhotoImageView {
    if (self.selectedPhoto && self.selectedPhoto.mediumImageLoaded) {
        
        //NSLog(@"PhotoVC.createPhotoImageView view.bounds %@", NSStringFromCGRect(self.view.bounds));        
        //NSLog(@"PhotoVC.createPhotoImageView view.frame %@", NSStringFromCGRect(self.view.frame));    
        
        //NSLog(@"PhotoVC.createPhotoImageView scrollView.bounds %@", NSStringFromCGRect(self.scrollView.bounds));        
        //NSLog(@"PhotoVC.createPhotoImageView scrollView.frame %@", NSStringFromCGRect(self.scrollView.frame));  

        
        __weak UIImage *photoToDisplay = [self.selectedPhoto getMediumImage];
        __weak PhotoViewController *weakSelf = self;
        
        [UIView
         animateWithDuration:0.4
         animations:^{  
             [weakSelf displayImage:photoToDisplay forController:weakSelf];       
             [weakSelf.scrollView flashScrollIndicators];
         }];
        
        [self showTitleBriefly];
    }
    else {
        
        // See why we couldn't get the photo to load.
        if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
            
            if (!self.flkrApiDelegate.userSessionModel.errorMessage) {
                self.flkrApiDelegate.userSessionModel.errorMessage = @"Unable to load photo from Flickr";
            }
        }
        
        [self displayErrorMessage:self.flkrApiDelegate.userSessionModel.errorMessage withTitle:@"Photo Not Available"];        
    }
    
    [self.busyIndicatorView stopAnimating];
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];    
    self.wantsFullScreenLayout = YES;  
    self.scrollView.delegate = self;
}

// Called after view appears.
- (void)viewDidAppear:(BOOL)animated {    
    //NSLog(@"PhotoVC.viewDidAppear photo %@",self.selectedPhoto.title);
    
    self.busyIndicatorView.center = self.view.center;
    [self.busyIndicatorView startAnimating];
    [self.view bringSubviewToFront:self.busyIndicatorView];
    
    // Make sure there is a selected photo to work with.
    
    if (!self.selectedPhoto.mediumImageLoaded) {
        // Pull the photo image down from FLickr in the bg.
        GetDisplayPhoto *getDisplayPhoto = [[GetDisplayPhoto alloc] initWithApiDelegate:self.flkrApiDelegate  andPhoto:self.selectedPhoto onCompleteUpdate:self withSelector:@selector(createPhotoImageView)];    
    
        [self.operationsQueue addOperation:getDisplayPhoto]; 
    }
    else {
        [self createPhotoImageView];
    }
}

// return a view that will be scaled. if delegate returns nil, nothing happens
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {

    return self.photoImageView;
}

- (void)viewDidUnload {
    [self setScrollView:nil];

    [self setBusyIndicatorView:nil];
    self.operationsQueue = nil;
    self.selectedPhoto = nil;
    self.photoImageView = nil;
    self.flkrApiDelegate = nil;
    
    [self setTitleView:nil];
    [self setTitleLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self resizeImageViewAfterRotation];    
}

@end
