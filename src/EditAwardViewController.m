//
//  EditAwardViewController.m
//  Flckr1
//
//  Created by Heather Stevens on 2/5/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "EditAwardViewController.h"
#import "SyncGroupAward.h"
#import "SaveAwardInDB.h"

// Private interface.
@interface EditAwardViewController() <UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate> {
    int origAwardsRequired;
    int isReturning;
}

@property (weak, nonatomic) IBOutlet UITextView *editAwardTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicatorView;
@property (weak, nonatomic) IBOutlet UIPickerView *awardsRequiredPickerView;
@property (weak, nonatomic) IBOutlet UILabel *requiredAwardsLabel;
@property (weak, nonatomic) IBOutlet UIButton *groupWebPageButton;
@property (weak, nonatomic) IBOutlet UIButton *autoGrabButton;

@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSOperationQueue *operationsQueue;
@property (nonatomic, retain) NSString *origAwardHtml;
@end

@implementation EditAwardViewController

@synthesize selectedPhoto = _selectedPhoto;
@synthesize selectedGroup = _selectedGroup;
@synthesize flkrApiDelegate = _flkrApiDelegate;
@synthesize groupAwardManager = _groupAwardManager;
@synthesize editAwardTextView = _editAwardTextView;
@synthesize busyIndicatorView = _busyIndicatorView;
@synthesize awardsRequiredPickerView = _awardsRequiredPickerView;
@synthesize requiredAwardsLabel = _requiredAwardsLabel;
@synthesize groupWebPageButton = _groupWebPageButton;
@synthesize autoGrabButton = _autoGrabButton;
@synthesize doneButton = _doneButton;
@synthesize operationsQueue = _operationsQueue;
@synthesize origAwardHtml = _origAwardHtml;

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

// Pass on the group and award manager.
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    isReturning = YES;
    
    if ([segue.identifier isEqualToString:@"Group Web Page"]) { 
        [segue.destinationViewController setFlkrApiDelegate:self.flkrApiDelegate];
        [segue.destinationViewController setSelectedGroup:self.selectedGroup];   
    }
}

// Get any awards for this group from the db.
- (void)loadGroupAwardHtml {
    
    if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:YES]) {
        [self.autoGrabButton setEnabled:NO];
        [self.groupWebPageButton setEnabled:NO];
        [self.doneButton setEnabled:NO];
        
        SyncGroupAward *syncGroupAward = [[SyncGroupAward alloc] initWithGroup:self.selectedGroup onCompleteUpdate:self selector:@selector(awardSyncComplete:)];
        [self.operationsQueue addOperation:syncGroupAward];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Group Site Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show]; 
        [self.busyIndicatorView stopAnimating];
        [self.autoGrabButton setEnabled:YES];
        [self.groupWebPageButton setEnabled:YES];
        [self.doneButton setEnabled:YES];
    }
}

// Reload the award html by parsing html from the groups home page.
- (IBAction)attemptAutoCreate:(id)sender {

    self.editAwardTextView.text = nil;
    self.busyIndicatorView.hidden = NO;
    [self.busyIndicatorView startAnimating];
    [self.view bringSubviewToFront:self.busyIndicatorView];
    [self loadGroupAwardHtml];    
}

// Disable button when it is pressed to stop dbl submits.
- (IBAction)groupWebPageButtonPressed:(id)sender {
    [self.autoGrabButton setEnabled:NO];
    [self.groupWebPageButton setEnabled:NO];
    [self.doneButton setEnabled:NO];
}

// Show the award in a web view.
- (void)displayAwardText:(Award *)award {
    
    self.editAwardTextView.textColor = [UIColor blackColor];
    self.editAwardTextView.text = award.htmlAward;
    [self.awardsRequiredPickerView selectRow:self.selectedGroup.award.requiredAwards-1 inComponent:0 animated:YES];
}

// Save the current group in the db.
- (void)saveGroupAwardInDb {
    
    SaveAwardInDB *saveAward = [[SaveAwardInDB alloc] initWithAward:self.selectedGroup.award addWith:self.groupAwardManager];
    [self.operationsQueue addOperation:saveAward];
}

// Update the view based on the award sync operation.
- (void) awardSyncComplete:(Award *) award {
    
    [self.busyIndicatorView stopAnimating];    
    [self.autoGrabButton setEnabled:YES];
    [self.groupWebPageButton setEnabled:YES];
    [self.doneButton setEnabled:YES];
    
    if (award && award.confidenceScore > 100) { // 50 percent
        award.groupNsid = self.selectedGroup.nsid;
        self.selectedGroup.award = award;
        [self displayAwardText:self.selectedGroup.award];
        
        if (award.confidenceScore < 150) {
            
            int score = ((int)award.confidenceScore/20)*10; //Calc divides by 200, score of 200 being 100% for this message.
            
            NSString *message = [NSString stringWithFormat:@"Auto Grab confidence is less than %d percent, be sure to verify the award is correct before using it.", score];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Award Needs Verification" 
                                                                message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
    }
    else if ([self.flkrApiDelegate.userSessionModel haveInternetBeOptimistic:NO]) {        
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed to Find Award" message:@"Navigate to the group's web page to manually \"Grab\" the award." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }    
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Group Site Unavailable" message:self.flkrApiDelegate.userSessionModel.errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }
}

// Delegate for text view. Get rid of the def text for the user.
- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    if ([textView.text isEqualToString:@"Award html text goes here."]) {
        textView.text = @"";
        self.editAwardTextView.textColor = [UIColor blackColor];
    }    
}

// Add new group to the list, make sure we don't add a duplicate
- (void)addGroupToGroupsWithAwardList:(Group *)groupWithAward {
    
    // Remove group if it is already in the list.
    if (self.flkrApiDelegate.userSessionModel.groupWithAwardList) {    
        
        for (Group *group in self.flkrApiDelegate.userSessionModel.groupWithAwardList) {
            if ([group.nsid isEqualToString:groupWithAward.nsid]) {
                [self.flkrApiDelegate.userSessionModel.groupWithAwardList removeObjectIdenticalTo:group];
                break;
            }
        }    
     }
    else {
        self.flkrApiDelegate.userSessionModel.groupWithAwardList = [[NSMutableArray alloc] initWithCapacity:self.flkrApiDelegate.userSessionModel.groupList.count];
    }
    
    //NSLog(@"EditAwardVC.addPossibleNewGroupToGroupsWithAwardList");
    [self.flkrApiDelegate.userSessionModel.groupWithAwardList addObject:groupWithAward];
    NSArray *tmpArray = [self.flkrApiDelegate.userSessionModel.groupWithAwardList sortedArrayUsingSelector:@selector(compareGroupsByNames:)];
    self.flkrApiDelegate.userSessionModel.groupWithAwardList = [NSMutableArray arrayWithArray:tmpArray];
}

// User is done editing, save any changes and return to display mode.
- (void)doneEditingAward {
    
    if (self.editAwardTextView.text && self.editAwardTextView.text.length >0 && 
        ![self.editAwardTextView.text isEqualToString:@"Award html text goes here."]) {
        
        //NSLog(@"EditAwardVC.doneEditingAward saving changes to award");
        
        self.selectedGroup.award.htmlAward = self.editAwardTextView.text;
        self.selectedGroup.award.groupNsid = self.selectedGroup.nsid;
        [self addGroupToGroupsWithAwardList:self.selectedGroup];        
    }  
    
    [self saveGroupAwardInDb];
    
    __weak EditAwardViewController *weakSelf = self;
    
    [UIView transitionWithView:self.navigationController.view duration:0.75
                       options:UIViewAnimationOptionTransitionCrossDissolve     
                    animations:^{                       
                        [weakSelf.navigationController popViewControllerAnimated:NO];                        
                    }    
                    completion:NULL];    
}

// User cancelled any edits, don't save and return to display mode.
- (void)cancelledEditingAward {

    // Put any changes back.
    self.selectedGroup.award.htmlAward = self.origAwardHtml;
    self.selectedGroup.award.requiredAwards = origAwardsRequired;
    
    [self.operationsQueue cancelAllOperations];
    
    __weak EditAwardViewController *weakSelf = self;
    
    [UIView transitionWithView:self.navigationController.view duration:0.75
                       options:UIViewAnimationOptionTransitionCrossDissolve     
                    animations:^{                       
                        [weakSelf.navigationController popViewControllerAnimated:NO];                        
                    }    
                    completion:NULL];
}

// Switch the buttons to display edit mode feel.
- (void)changeButtons {
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelledEditingAward)];    
    cancelBarButton.enabled = YES;
    
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:cancelBarButton];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneEditingAward)];    
    [self.navigationController.navigationBar.topItem setRightBarButtonItem:self.doneButton];    
}

// Move comps to fit screen
- (void)moveComponentsToMatchOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    __weak EditAwardViewController *weakSelf = self;
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{       
        
     
         weakSelf.busyIndicatorView.center = weakSelf.view.center;    
         if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)  {        
        
             self.groupWebPageButton.center = CGPointMake(94, 252.5);
             self.requiredAwardsLabel.center = CGPointMake(142, 303.5);
             self.awardsRequiredPickerView.center = CGPointMake(255, 304);                     
         
         }   
         else { // horizontal
             
             self.groupWebPageButton.center = CGPointMake(226, 207.5);
             self.requiredAwardsLabel.center = CGPointMake(392, 36.5);
             self.awardsRequiredPickerView.center = CGPointMake(432, 163);            

         }
        
    } completion:nil];   
    
}

#pragma mark - View lifecycle

// View appeared, load group html if needed. 
- (void)viewDidAppear:(BOOL)animated {    
        
    self.busyIndicatorView.center = self.view.center;     
    [self moveComponentsToMatchOrientation:self.interfaceOrientation duration:0.25];  
        
    if (self.selectedGroup.award.requiredAwards == 0) {
        self.selectedGroup.award.requiredAwards = 5;
    }    
    
    [self.awardsRequiredPickerView selectRow:self.selectedGroup.award.requiredAwards-1 inComponent:0 animated:YES];
    origAwardsRequired = self.selectedGroup.award.requiredAwards;
    
    // Try to auto load the award if we don't already have one.
    if (!self.selectedGroup.award.htmlAward && !isReturning) {
        
        self.busyIndicatorView.hidden = NO;
        [self.busyIndicatorView startAnimating];
        [self.view bringSubviewToFront:self.busyIndicatorView];
        
        [self loadGroupAwardHtml];
    }
    else {
        [self displayAwardText:self.selectedGroup.award];
        [self.busyIndicatorView stopAnimating];
        [self.groupWebPageButton setEnabled:YES]; 
        [self.autoGrabButton setEnabled:YES];
        [self.doneButton setEnabled:YES];
    }
    
    if (isReturning) {
        isReturning = NO;
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editAwardTextView.delegate = self;
        
    // Setup pickerview.
    self.awardsRequiredPickerView.delegate = self;
    self.awardsRequiredPickerView.dataSource = self;   
    
    // Change the nav bar buttons for edit mode.
    [self changeButtons];
    
    // Save the current award in case the user cancels.
    self.origAwardHtml = self.selectedGroup.award.htmlAward;

    isReturning = NO;
}

- (void)viewDidUnload
{
    [self setBusyIndicatorView:nil];
    [self setEditAwardTextView:nil];
    [self setAwardsRequiredPickerView:nil];
    [self setRequiredAwardsLabel:nil];
    [self setGroupWebPageButton:nil];
    [self setAutoGrabButton:nil];
    [self setDoneButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Make sure the image view size and location changes to match the orientation well.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [self moveComponentsToMatchOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - UIPickerViewDataSource
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 9;
}

// Set the width to 40 points.
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    //NSLog(@"EditAwardViewController.pickerView:(UIPickerView *)pickerView widthForComponent");
    return 50.0;
}

// Return the content of the row specified
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component; {
    return [NSString stringWithFormat:@"%d", row +1]; 
}

#pragma mark - UIPickerViewDelegate
// Called when a row is selected.
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedGroup.award.requiredAwards = row +1;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.flkrApiDelegate.userSessionModel clearImageCache];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"@EditAwardViewController.didReceiveMemoryWarning@@@@");
}
@end
