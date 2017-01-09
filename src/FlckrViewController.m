//
//  FlckrViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 1/11/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "FlckrViewController.h"
#import "Flickr1NavigationController.h"

@interface FlckrViewController()
@property (weak, nonatomic) IBOutlet UIView *loginView;
@end

@implementation FlckrViewController

@synthesize loginDelegate = _loginDelegate;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize loginView = _loginView;

static NSString * const kHomeSequeId  = @"toHomeSegue";

// Display error message to user on the login screen.
- (void)displayErrorMessage:(NSString *) message withTitle:(NSString *) title {    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];    
}

// Override getter to initialize login delegate.
// Gets the initial network status.
- (LoginDelegate *)loginDelegate {
    if (!_loginDelegate) {        
        _loginDelegate = [[LoginDelegate alloc] init];      
    }
    return _loginDelegate;
}

// Override getter to initialize flckr api delegate.
- (FlkrApiDelegate *)flkrApiDelegate {
    if (!_flkrApiDelegate) {
        _flkrApiDelegate = [[FlkrApiDelegate alloc] init];
    }
    return _flkrApiDelegate;
}

// Start OAuth login process
- (IBAction)startLoginProcess:(id)sender {
    
    if (![self.loginDelegate completeUserAuthorization]) {
        NSLog(@"FlckrVC.startLoginProcess Failed to initiate login process due to: %@", self.loginDelegate.errorMessage);        
        [self displayErrorMessage:self.loginDelegate.userSessionModel.errorMessage withTitle:@"Login Error"];
    }
}

// Called when control returns from the Yahoo Login, on behalf of Flickr.com.
// This is only called when the URL given to yahoo is invoked on the browser.
- (void)continueLoginProcess:(NSString *)queryFromYahoo {     
    if ([self.loginDelegate finishUserAuthorization:queryFromYahoo]) {
                
        NSLog(@"FlckrVC.continueLoginProcess Successfully logged in %@", self.loginDelegate.userName);
        
        // Save the session attributes for later use.
        [self.loginDelegate.userSessionModel syncSessionStore];

        // Set the user session model on the flickr delegate.
        self.flkrApiDelegate.userSessionModel = self.loginDelegate.userSessionModel; 

        [self performSegueWithIdentifier:kHomeSequeId sender:self];
    }
    else {
        NSLog(@"FlckrVC.continueLoginProcess Failed to finish login process due to: %@", self.loginDelegate.errorMessage);
        [self displayErrorMessage:self.loginDelegate.userSessionModel.errorMessage withTitle:@"Login Error"];
    }    
}

// Pass on the delegate for Flickr API comm.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![self.loginDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
        return;
    }
    
    // Give the 
    ((Flickr1NavigationController *)self.parentViewController).userSessionModel = self.loginDelegate.userSessionModel;    
    
    if (self.loginDelegate.userSessionModel.accessToken) {  
        //NSLog(@"FlckrVC.viewDidLoad, found accessToken %@", self.loginDelegate.userSessionModel.accessToken);
        
        self.flkrApiDelegate.userSessionModel = self.loginDelegate.userSessionModel;
        
        if ([self.flkrApiDelegate testLogin]) {
            NSLog(@"FlckrVC.viewDidLoad, test access succeeded, forwarding to HomeVC.");
            [self performSegueWithIdentifier:kHomeSequeId sender:self];
        }
    }
}

// Sync the user session to default user store.
- (void)viewDidUnload {
    [self setLoginView:nil];
    [super viewDidUnload];
    [self.flkrApiDelegate.userSessionModel syncSessionStore];
    self.flkrApiDelegate = nil;
    self.loginDelegate = nil;
}

// Clear out the previous session, if any, ahead of a possible new session.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.flkrApiDelegate.userSessionModel.groupList = nil;
    self.flkrApiDelegate.userSessionModel.groupWithAwardList = nil;
    self.flkrApiDelegate.userSessionModel.photoList = nil;
    [self.flkrApiDelegate.userSessionModel.cachedImages removeAllObjects];
}

// Check connectivity and display an error message upon showing the screen.
- (void)viewDidAppear:(BOOL)animated {
    
    if (![self.loginDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        [self displayErrorMessage:kNoNetworkConnectivity withTitle:@"Login Error"];
    }    
}    

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@FlckrVC.didReceiveMemoryWarning@@@@");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

@end
