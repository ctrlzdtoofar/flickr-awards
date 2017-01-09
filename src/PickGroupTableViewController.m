//
//  PickGroupTableViewController.m
//  Flckr1
//
//  Displays table of groups for user to pick from. Supports both edit mode and award mode.
//
//  Created by Heather Stevens on 1/25/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//
#import "PickGroupTableViewController.h"
#import "AwardsViewController.h"
//#import "DelayOperation.h"
  
@interface PickGroupTableViewController() {
    BOOL editMode;
    BOOL loading;
}
@property (weak, nonatomic) IBOutlet UITableView *selectGroupTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicator;
//@property (nonatomic, retain) DelayOperation *delayOperation;
@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@end

@implementation PickGroupTableViewController
@synthesize selectGroupTable = _selectGroupTable;
@synthesize busyIndicator = _busyIndicator;

@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize selectedPhoto = _selectedPhoto;
//@synthesize delayOperation = _delayOperation;
@synthesize operationsQueue = _operationsQueue;

// Switch edit mode on.
- (void)groupEditMode {
    editMode = YES;
}

// Switch edit mode off.
- (void)groupAwardMode {
    editMode = NO;
}

// Called by other view ctrls to let this ctrl know that the photos are being loaded.
- (void)setGroupListLoading {
    loading = YES;   
    [self.busyIndicator startAnimating];
    [self.view bringSubviewToFront:self.busyIndicator];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Reload the table to show new data.
- (void)reloadGroupTable {
    loading = NO;
    [self.selectGroupTable reloadData];
    [self.busyIndicator stopAnimating];
}

// Pass on the delegate for Flickr API comm. Get models ready to display flckr content.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Make sure the api delegate is set.
    [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
    [segue.destinationViewController setSelectedPhoto:self.selectedPhoto];
    
    Group *group = nil;
    if (editMode) {
        group = [self.flkrApiDelegate.userSessionModel.groupList objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    }
    else {
        group = [self.flkrApiDelegate.userSessionModel.groupWithAwardList objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    }    
    
    [segue.destinationViewController setSelectedGroup:group];
}

#pragma mark - View lifecycle
// Set the BG to display the selected photo over white bg
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self.selectedPhoto) {
    
        UIView *bgView = [[UIView alloc] initWithFrame:self.tableView.frame];
        bgView.backgroundColor = UIColor.whiteColor;
        bgView.contentMode = UIViewContentModeScaleToFill;
        bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIImageView *tableBackgroundImageView = [[UIImageView alloc] initWithFrame:self.tableView.frame];   
        
        // Don't bother with the session cache here, because it has most likely already been loaded earlier.
        tableBackgroundImageView.image = [self.selectedPhoto getMediumImage];    
        tableBackgroundImageView.alpha = 0.4;
        tableBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        tableBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [bgView addSubview:tableBackgroundImageView];
        self.tableView.backgroundView = bgView;
    } 
}

// Called after the view first displays.
- (void)viewDidAppear:(BOOL)animated {
    
    self.busyIndicator.center = self.view.center;
    
    // There are no photos loaded and there is no network, complain.
    if (self.flkrApiDelegate.userSessionModel.photoList.count == 0 && ![self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Groups Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show]; 
        
        [self.busyIndicator stopAnimating]; 
        loading = NO;
    }    
    else if (editMode && self.flkrApiDelegate.userSessionModel.groupList.count > 0) {
        [self.busyIndicator stopAnimating];
        loading = NO;
    }
    else if (!editMode && self.flkrApiDelegate.userSessionModel.groupWithAwardList.count > 0) {
        [self.busyIndicator stopAnimating];
        loading = NO;
    }
    else if (loading) {
        [self.busyIndicator startAnimating];
        [self.view bringSubviewToFront:self.busyIndicator];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@PickGroupTableViewController.didReceiveMemoryWarning@@@@");
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.busyIndicator.center = self.view.center;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source
// This table has only one section.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

// The number of rows for this table only section.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    int count = 0;
    
    if (editMode) {
        count = self.flkrApiDelegate.userSessionModel.groupList.count;
    }
    else {        
        count = self.flkrApiDelegate.userSessionModel.groupWithAwardList.count;
    }    
    
    if (count) {
        self.selectGroupTable.userInteractionEnabled = YES;

    }
    else {
        count = 1; // use the first row to show msg
        self.selectGroupTable.userInteractionEnabled = NO;
    }    
       
   
    [self.busyIndicator stopAnimating]; 
    return count;
}

// Build/Reuse cells for table view.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Group Picker Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (editMode && self.flkrApiDelegate.userSessionModel.groupList.count > 0) {
        // Edit mode can see the full user's group membership.
        Group *group = [self.flkrApiDelegate.userSessionModel.groupList objectAtIndex:indexPath.row];
        cell.textLabel.text = group.name;
    }
    else if (!editMode && self.flkrApiDelegate.userSessionModel.groupWithAwardList.count > 0) {
        // Award 
        Group *group = [self.flkrApiDelegate.userSessionModel.groupWithAwardList objectAtIndex:indexPath.row];
        cell.textLabel.text = group.name;       
    }   
    // No groups in the list to display and it's the 1st row.
    else if (indexPath.row == 0) {   
        
        if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {            
                
            if (loading) {
                cell.textLabel.text = @"  Loading Groups...";
            }
            else if (editMode) {
                cell.textLabel.text = @"  No Groups Found";
            }
            else {
                cell.textLabel.text = @"  No Groups w Awards Setup";
            }            
        }
        // Network connectivity issue.
        else {
            cell.textLabel.text = @"  Groups Unavailable";
        }
    }

    return cell;
}

- (void)viewDidUnload {
    [self setSelectGroupTable:nil];
    self.flkrApiDelegate = nil;
    self.selectedPhoto = nil;
    [self setBusyIndicator:nil];
    [super viewDidUnload];
}
@end
