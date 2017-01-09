//
//  PickPhotoTableViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 1/21/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "PickPhotoTableViewController.h"
#import "PickGroupTableViewController.h"
#import "PhotoViewController.h"
#import "PhotoXmlParser.h"
#import "SyncPhoto.h"
#import "GetDisplayPhoto.h"

// Private interface.
@interface PickPhotoTableViewController() <UITableViewDelegate> {
    BOOL loading;
}

@property (weak, nonatomic) IBOutlet UITableView *photoTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicator;

@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@end

@implementation PickPhotoTableViewController

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize photoTable = _photoTable;
@synthesize busyIndicator = _busyIndicator;
@synthesize operationsQueue = _operationsQueue;

// getter for the operations queue.
- (NSOperationQueue *)operationsQueue {
    
    if (!_operationsQueue) {
        _operationsQueue = [[NSOperationQueue alloc] init];
    }
    
    return _operationsQueue;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Pass on the delegate for Flickr API comm. Get models ready to display flckr content.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Make sure the api delegate is set.
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    
    // Pass in the selected photo.
    [segue.destinationViewController setSelectedPhoto:[self.flkrApiDelegate.userSessionModel.photoList objectAtIndex:self.tableView.indexPathForSelectedRow.row]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@@PickPhotoTableViewController.didReceiveMemoryWarning@@@@");
}

// Called by other view ctrls to let this ctrl know that the photos are being loaded.
- (void)setPhotoListLoading {
    loading = YES;
}

// Reload the table to show new data.
- (void)reloadPhotoTable {
    [self.photoTable reloadData];
    [self.busyIndicator stopAnimating];
    loading = NO;    
}

#pragma mark - View lifecycle
#define ROW_HEIGHT 60.0

// Called after the view first displays.
- (void)viewDidAppear:(BOOL)animated {
    
    self.busyIndicator.center = self.view.center;
   
    // There are no photos loaded and there is no network, complain.
    if (self.flkrApiDelegate.userSessionModel.photoList.count == 0 && ![self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
            
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Photos Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];  
        [self.busyIndicator stopAnimating];
        loading = NO;
    }
    else if (self.flkrApiDelegate.userSessionModel.photoList.count > 0) {
        [self.busyIndicator stopAnimating];
        loading = NO;
    }
}

// Alter the table's row height to be taller.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = ROW_HEIGHT;
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.busyIndicator.center = self.view.center;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

//There is only one section.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

// Determine the number of rows for the table.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int count = self.flkrApiDelegate.userSessionModel.photoList.count;
    
    if (count) {
        self.photoTable.userInteractionEnabled = YES;
        
    }
    else {
        count = 1; // use the first row to show msg
        self.photoTable.userInteractionEnabled = NO;
    }    
    
    // Return the number of rows in the section.
    return count;
} 

// Setup cells as required.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Photo Picker Cell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];    
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Make sure we HAVE a row for this cell.
    if (indexPath.row < self.flkrApiDelegate.userSessionModel.photoList.count) {
    
        Photo *photo = [self.flkrApiDelegate.userSessionModel.photoList objectAtIndex:indexPath.row];   
        cell.textLabel.text = photo.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ views", photo.views];
        
        if ([photo smallImageLoaded] || (self.tableView.dragging == NO && self.tableView.decelerating == NO)) {
            cell.imageView.image =  [photo getSmallImage]; 
        }
        else {
            SyncPhoto *syncPhoto = [[SyncPhoto alloc] initWithPhoto:photo onCompleteCell:cell];        
             [self.operationsQueue addOperation:syncPhoto];
        }     
    
    }
    else if (self.flkrApiDelegate.userSessionModel.photoList.count == 0 && indexPath.row == 0) {
        
        if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
            
            if (loading) {
                cell.textLabel.text = @"  Loading Photos...";
            }
            else {
                cell.textLabel.text = @"  No Photos Found";
            }
        }
        else {
            cell.textLabel.text = @"  Photos Unavailable";
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate


// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Start loading the photo now to save time.
    Photo *photo = [self.flkrApiDelegate.userSessionModel.photoList objectAtIndex:indexPath.row];
    if (!photo.mediumImageLoaded) {
        
        if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
            
            // Pull the photo image down from FLickr in the bg.
            GetDisplayPhoto *getDisplayPhoto = [[GetDisplayPhoto alloc] initWithApiDelegate:self.flkrApiDelegate andPhoto:photo onCompleteUpdate:nil withSelector:nil];        
            [self.operationsQueue addOperation:getDisplayPhoto]; 
        }
    }
    
    [self performSegueWithIdentifier:@"Display Photo" sender:self];
}

- (void)viewDidUnload {
    [self setPhotoTable:nil];
    self.operationsQueue = nil;
    self.flkrApiDelegate = nil;
    [self setBusyIndicator:nil];
    [super viewDidUnload];
}
@end
