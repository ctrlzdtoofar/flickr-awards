//
//  GroupWebPageViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 2/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GroupWebPageViewController.h"
#import "SyncGroupHtml.h"

@interface GroupWebPageViewController() <UIScrollViewDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicatorView;
@property (weak, nonatomic) IBOutlet UIWebView *groupWebPageView;
@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@end

@implementation GroupWebPageViewController
@synthesize busyIndicatorView = _busyIndicatorView;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize groupWebPageView = _groupWebPageView;
@synthesize selectedGroup = _selectedGroup;
@synthesize operationsQueue = _operationsQueue;

// getter for the operations queue.
- (NSOperationQueue *)operationsQueue {
    
    if (!_operationsQueue) {
        _operationsQueue = [[NSOperationQueue alloc] init];
    }
    
    return _operationsQueue;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Get any awards for this group from the db.
- (void)loadGroupHtml {
    
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        SyncGroupHtml *syncGroupHtml = [[SyncGroupHtml alloc] initWithGroup:self.selectedGroup  onCompleteUpdate:self];        
        [self.operationsQueue addOperation:syncGroupHtml];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Group Site Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show]; 
        [self.busyIndicatorView stopAnimating];
    }
}

// Update the view based on the award sync operation.
- (void) htmlSyncComplete:(NSString *) htmlContent {
    
    
    if (htmlContent) {        
        [self.groupWebPageView loadHTMLString:htmlContent baseURL:nil];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Group Site Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show]; 
    }    

}

#pragma mark - UIWebViewDelegate methods

// called when html loads
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.busyIndicatorView stopAnimating];
    [self.view setNeedsDisplay];
}

// problems...
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self.busyIndicatorView stopAnimating];
    [self.view setNeedsDisplay];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Group Site Unavailable" message:@"Unable to load groups web page." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show]; 
}

//Get award html from pasteboard and replace the award text with it.
//Pop this controller when done.
- (void)grabAwardPopController:(id)sender {
    
    //Call the built in copy menu command
    [self.groupWebPageView copy:[UIApplication sharedApplication]];
    
    // Gain access to the general/shared pasteboard.
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    NSString *theText = [[NSString alloc] initWithData:[pasteboard dataForPasteboardType:@"public.text"] encoding:NSUTF8StringEncoding];
    
    NSLog(@"GroupWebPageVC.grabAwardPopController theText %@",theText);
    
    if (!self.selectedGroup.award) {
        self.selectedGroup.award = [[Award alloc] init];
    }
    self.selectedGroup.award.htmlAward = theText;
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuVisible = NO;
    
    __weak GroupWebPageViewController *weakSelf = self;
    
    [UIView transitionWithView:self.navigationController.view duration:0.75
                       options:UIViewAnimationOptionTransitionCrossDissolve     
                    animations:^{                       
                        [weakSelf.navigationController popViewControllerAnimated:NO];                        
                        [weakSelf.navigationController.topViewController.view setNeedsDisplay];
                    }    
                    completion:NULL];    
}

#pragma mark - View lifecycle

// Called upon first loa hding the controller's page.
- (void)loadView {
    [super loadView];
    //[self becomeFirstResponder];
    
    self.groupWebPageView.delegate = self;
    
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Grab Award" action:@selector(grabAwardPopController:)];
    NSArray *menuItemList = [[NSArray alloc] initWithObjects:menuItem, nil];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = menuItemList; 
    
    self.busyIndicatorView.center = self.view.center;
}

// return a view that will be scaled. if delegate returns nil, nothing happens
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.groupWebPageView;
}

// Called after the view displays on screen.
- (void)viewDidAppear:(BOOL)animated {
    self.busyIndicatorView.center = self.view.center;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self loadGroupHtml];
    
    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    gr.numberOfTapsRequired = 2;
    [self.groupWebPageView addGestureRecognizer:gr];
    self.groupWebPageView.scrollView.minimumZoomScale = .25;
    self.groupWebPageView.scrollView.maximumZoomScale = 1.5; 
    
}

- (void)viewDidUnload {
    [self setGroupWebPageView:nil];
    [self setBusyIndicatorView:nil];
    self.flkrApiDelegate = nil;
    self.selectedGroup = nil;
    self.operationsQueue = nil;   
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"GroupWebPageViewController.didReceiveMemoryWarning@@@@");
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.busyIndicatorView.center = self.view.center;    
}

@end
