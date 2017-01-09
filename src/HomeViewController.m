//
//  HomeViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 1/14/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "HomeViewController.h"
#import "PhotoViewController.h"
#import "PickPhotoTableViewController.h"
#import "PickGroupTableViewController.h"
#import "PhotoXmlParser.h"
#import "GroupXmlParser.h"
#import "NetworkAvailability.h"


// Private interface.
@interface HomeViewController() {
    BOOL loadingGroupList;
    BOOL loadingPhotoList;
}
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIButton *quickPicksButton;
@property (weak, nonatomic) IBOutlet UIButton *groupSetupButton;

@property (nonatomic, retain) NSOperationQueue *operationsQueue;

@end


@implementation HomeViewController

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize welcomeLabel = _welcomeLabel;
@synthesize quickPicksButton = _quickPicksButton;
@synthesize groupSetupButton = _groupSetupButton;
@synthesize operationsQueue = _operationsQueue;
@synthesize syncGroupList = _syncGroupList;

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
    }
    return self;
}

// Display error message to user on the login screen.
- (void)displayErrorMessage:(NSString *) message withTitle:(NSString *) title {    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];    
}

// Pass on the delegate for Flickr API comm. Get models ready to display flckr content.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Make sure the api delegate is set.
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    
    if ([segue.identifier isEqualToString:@"Quick Pics"]) {
        
        if (!loadingPhotoList && [self.flkrApiDelegate.userSessionModel shouldLoadNewPhotos]) {
            [self startGetPhotoJob];
        }
        else if (loadingPhotoList) {
            [segue.destinationViewController setPhotoListLoading];
        }
    }
    else if ([segue.identifier isEqualToString:@"Group Award Setup"]) {
        
        // In edit mode.
        [segue.destinationViewController groupEditMode];
        
        if (!loadingGroupList && [self.flkrApiDelegate.userSessionModel shouldLoadNewGroups]) {           
            [self startGroupsJob];
        }
        else if (loadingGroupList) {
            [segue.destinationViewController setGroupListLoading];
        }
    }    
}

// Put uses's 1st photo into the bg, play sound effects and shake phone.
- (void)loadFirstPhotoIntoBackgroundandPlayCameraSounds {
    if (self.flkrApiDelegate.userSessionModel.photoList.count > 0) {
        
        Photo *photo = [self.flkrApiDelegate.userSessionModel.photoList objectAtIndex:0];
        if (photo) {
        
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];   
        
            backgroundImageView.image = [photo getMediumImage];    
            backgroundImageView.alpha = 0.25;
            backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
            backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
            __weak HomeViewController *weakSelf = self;
            __weak UIImageView *weakImageView = backgroundImageView;
           
            [UIView
             animateWithDuration:0.3
             delay:0
             options:UIViewAnimationOptionCurveEaseInOut
             animations:^{                 
                 [weakSelf.view addSubview:weakImageView];
                 [weakSelf.view bringSubviewToFront:weakSelf.welcomeLabel];
                 [weakSelf.view bringSubviewToFront:weakSelf.quickPicksButton];
                 [weakSelf.view bringSubviewToFront:weakSelf.groupSetupButton];
             }
             completion:nil];            
        }
    }
}

// Get the photo select view controller.
- (void) invokeSelectorOnPhotoSelectViewCtrl:(SEL)ctrlSelector {
    
    NSArray * navChildViewControllers = self.navigationController.childViewControllers;
    for (UIViewController *viewCtrl in navChildViewControllers) {
        
        if (viewCtrl.title && [viewCtrl.title isEqualToString:@"Select Photo"] && viewCtrl.isViewLoaded) {
            
            [(PickPhotoTableViewController *)viewCtrl performSelectorOnMainThread:ctrlSelector
                                               withObject:nil
                                            waitUntilDone:YES];            
            break;
        }
    }
}

// Load photos in bg queue.
- (void)startGetPhotoJob {
    
    // If we need to load the photo list from Flickr, use bg queue.
    if (!loadingPhotoList && [self.flkrApiDelegate.userSessionModel shouldLoadNewPhotos]) {
        // Load list of user's photos.
        SyncPhotoList *syncPhotoList = [[SyncPhotoList alloc] initWithApiDelegate:self.flkrApiDelegate onCompleteUpdate:self];        
        [self.operationsQueue addOperation:syncPhotoList];  
        
        // Set the ctrl using the photo list to show that we are working on getting the photo list.
        [self invokeSelectorOnPhotoSelectViewCtrl:@selector(setPhotoListLoading)];
        loadingPhotoList = YES;
    }
    else {
        loadingPhotoList = NO;
    }
}

// Called operation to update
- (void) photoListSyncComplete:(NSArray *) photoList {
    
    self.flkrApiDelegate.userSessionModel.photoList = photoList;    
    [self invokeSelectorOnPhotoSelectViewCtrl:@selector(reloadPhotoTable)];
    loadingPhotoList = NO;
    
    if (photoList && photoList.count > 0) {
        // Cache some of the small photos in memory.
        SyncPhoto *syncPhoto = [[SyncPhoto alloc] initWithPhotoList:photoList haveWifi:self.flkrApiDelegate.userSessionModel.networkStatus == wiFiConnection];
        [self.operationsQueue addOperation:syncPhoto];        
        [self loadFirstPhotoIntoBackgroundandPlayCameraSounds];
    }          
}

// Invoke method the group select view controller.
- (void) invokeSelectorOnGroupSelectViewCtrl:(SEL)ctrlSelector {
    
    NSArray * navChildViewControllers = self.navigationController.childViewControllers;
    for (UIViewController *viewCtrl in navChildViewControllers) {
        
        if (viewCtrl.title && [viewCtrl.title isEqualToString:@"Select Group"] && viewCtrl.isViewLoaded) {
            
            [(PickGroupTableViewController *)viewCtrl performSelectorOnMainThread:ctrlSelector
                                                                       withObject:nil
                                                                    waitUntilDone:YES];            
        }
    }
}

// Called operation to update view once group list has been loaded into mem.
- (void) groupListSyncComplete {

    [self invokeSelectorOnGroupSelectViewCtrl:@selector(reloadGroupTable)];
     loadingGroupList = NO;
}

// Load photos in bg queue.
- (void)startGroupsJob {
    
    if (!loadingGroupList && [self.flkrApiDelegate.userSessionModel shouldLoadNewGroups]) {
        self.syncGroupList = [[SyncGroupList alloc] initWithApiDelegate:self.flkrApiDelegate onCompleteUpdate:self];        
        [self.operationsQueue addOperation:self.syncGroupList];        
        [self invokeSelectorOnGroupSelectViewCtrl:@selector(setGroupListLoading)];
        loadingGroupList = YES;
    }
    else {
        loadingGroupList = NO;
    }
}

#pragma mark - View lifecycle

// Called after view appears.
- (void)viewDidAppear:(BOOL)animated {
    
    if (![self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
       
        [self displayErrorMessage:kNoNetworkConnectivity withTitle:@"Connectivity Error"];
        [self.operationsQueue cancelAllOperations];  
    }
    else {        
        [self startGetPhotoJob];
        [self startGroupsJob];
    }
}

// Setup label just before the view displays.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UILabel *welcomeLabel = (UILabel *)[self.view viewWithTag:20];    
    if (welcomeLabel) {        
        NSMutableString *welcome = [[NSMutableString alloc] init];
        [welcome appendString:@"Welcome "];
        [welcome appendString:self.flkrApiDelegate.userSessionModel.userName];
        welcomeLabel.text = welcome;
    } 
}

// When the view first loads, setup the sounds to be played.
- (void)viewDidLoad {
    
    loadingPhotoList = NO;
    loadingGroupList = NO;
}

// Sync the session store to default user settings.
- (void)viewDidUnload {
    
    [self.flkrApiDelegate.userSessionModel syncSessionStore];
    
    self.flkrApiDelegate = nil;    
    self.syncGroupList = nil;
    self.operationsQueue = nil;
    [self setWelcomeLabel:nil];
    [self setQuickPicksButton:nil];
    [self setGroupSetupButton:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@@HomeViewController.didReceiveMemoryWarning@@@@");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
