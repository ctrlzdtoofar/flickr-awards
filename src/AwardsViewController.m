//
//  AwardsViewController.m
//  Flickr Awards
//
//  Created by Heather Stevens on 1/27/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "AwardsViewController.h"
#import "SaveAwardInDB.h"

// Private interface.
@interface AwardsViewController() <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityInd;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *awardEditButton;
@property (weak, nonatomic) IBOutlet UIWebView *awardWebView;
@property (weak, nonatomic) IBOutlet UILabel *awardsRequiredLabel;

@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@end

@implementation AwardsViewController
@synthesize groupNameLabel = _groupNameLabel;
@synthesize activityInd = _activityInd;
@synthesize awardEditButton = _awardEditButton;
@synthesize awardWebView = _awardWebView;
@synthesize awardsRequiredLabel = _awardsRequiredLabel;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize selectedGroup = _selectedGroup;
@synthesize groupAwardManager = _groupAwardManager;
@synthesize operationsQueue = _operationsQueue;
@synthesize isReturning = _isReturning;

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
       //
    }
    return self;
}

// return a view that will be scrolled. if delegate returns nil, nothing happens
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.awardWebView;
}

// Show the award in a web view.
- (void)displayAward:(Award *)award {
    
    NSString *awardToDisplayOnWebView = [CommunicationsUtil swapCRLFforHtmlBreak:award.htmlAward];
    awardToDisplayOnWebView = [CommunicationsUtil removeErrantEmbeddedTags:awardToDisplayOnWebView];
    [self.awardWebView loadHTMLString:awardToDisplayOnWebView baseURL:nil];
    [self.awardWebView setContentScaleFactor:0.60];
    
    __weak AwardsViewController *weakSelf = self;
    
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{             

        weakSelf.awardWebView.alpha = 1.0;    
        weakSelf.awardEditButton.enabled = YES;     
    } completion:nil];

}

// Get any awards for this group from the db.
- (void)loadAwardsFromDb {
                    
    // Update the group from the db if found.
    Award *award = [self.groupAwardManager getAwardWithGroupNsid:self.selectedGroup.nsid];
    if (award) {
        //NSLog(@"AwardsViewController.loadAwardsFromDb, found award in db, %@", award.groupNsid);  
        self.selectedGroup.award = award;
        [self displayAward:self.selectedGroup.award];               
    }
    else {
        //NSLog(@"AwardsViewController.loadAwardsFromDb, no group found");
        self.awardEditButton.enabled = NO;
    }
}

// Pass on the group and award manager.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {        

    self.isReturning = YES;
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    [segue.destinationViewController setGroupAwardManager:self.groupAwardManager];
    [segue.destinationViewController setSelectedGroup:self.selectedGroup];
    [segue.destinationViewController setSelectedPhoto:self.selectedPhoto];    
}

#pragma mark - View lifecycle

// View appeared, load group html if needed. 
- (void)viewDidAppear:(BOOL)animated {
    
    self.activityInd.center = self.view.center;
    self.awardEditButton.enabled = YES;
    
    // If there is no award setup, then segue to the award edit page.
    if (!self.selectedGroup.award && !self.isReturning) {       
        
        // Check for internet connectivity before going to the edit page.
        if (![self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Internet Connectivity" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        else {    
             //NSLog(@"AwardsViewController.viewDidAppear auto seque to edit");

            [self performSegueWithIdentifier:@"Edit Create Award" sender:self];
        }        
    }
    else if (self.selectedGroup.award.htmlAward) {
        [self displayAward:self.selectedGroup.award];
    }
    
    if (self.awardsRequiredLabel && self.selectedGroup.award && self.selectedGroup.award.requiredAwards > 0) {     
        
        //NSLog(@"AwardsViewController.viewDidAppear setting req lbl %d", self.selectedGroup.award.requiredAwards);
        self.awardsRequiredLabel.text = [NSString stringWithFormat:@"Awards Required to Add Photo: %d", self.selectedGroup.award.requiredAwards];
        [self.view setNeedsDisplay];
    }    
    
   [self.activityInd stopAnimating];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.activityInd startAnimating];
    
    // Get the group manager.
    self.groupAwardManager = [[GroupAwardManager alloc] init];    
    [self.groupAwardManager createContext]; 
    
    // If we don't have the award in mem, try sqlite.
    if (!self.selectedGroup.award.htmlAward) {
        
        // Load award from sqlite.
        [self loadAwardsFromDb];
    }   
    
    self.groupNameLabel.text = [@"Group:" stringByAppendingString:self.selectedGroup.name];
    self.awardWebView.userInteractionEnabled = NO;
    
    self.isReturning = NO;
}

// Cleanup.
- (void)viewDidUnload {
    
    [self setGroupNameLabel:nil];
    [self setActivityInd:nil];
    [self setAwardEditButton:nil];
    [self setAwardWebView:nil];
    [self setAwardsRequiredLabel:nil];
    self.groupAwardManager = nil;
    self.selectedGroup = nil;
    self.selectedPhoto = nil;
    self.flkrApiDelegate = nil;
    self.operationsQueue = nil;
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@AwardsViewController.didReceiveMemoryWarning@@@@");
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.activityInd.center = self.view.center;    
}

// Only supporting portrait orientation for this screen.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    }

    return NO;
}

@end
