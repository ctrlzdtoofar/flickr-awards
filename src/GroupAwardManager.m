//
//  GroupAwardManager.m
//  Flckr1
//
//  Created by Heather Stevens on 2/3/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "GroupAwardManager.h"

@interface GroupAwardManager()
@property (atomic, retain) NSManagedObjectContext *managedObjectContext;

- (Award *)convertAwardFromAwardEntity:(AwardModelEntity *)awardEntity;
@end

@implementation GroupAwardManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistenceError = _persistenceError;
@synthesize resultsController = _resultsController;

static NSString * const kDataStoreUrl                = @"Documents/flickrUserAwardList.db";
static NSString * const kAwardEntity                 = @"AwardModelEntity";
static NSString * const kNsidEquals                  = @"awardNsid == %@";

// Attempt to initialize the managed object context for this manager.
- (void)createContext {

    // Get the context.
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    if (!self.managedObjectContext) {
        NSLog(@"GroupAwardManager.createContext, failed to create managedObjectContext");
        return;
    }  
    
    // Get the object model.
    NSManagedObjectModel *managedModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    if (!managedModel) {
        NSLog(@"GroupAwardManager.createContext, failed to create managedModel");
        self.managedObjectContext = nil;
        return;
    }  
        
    // Get the URL to our data store.
    NSURL *url = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:kDataStoreUrl]];
    if (!url) {
        NSLog(@"GroupAwardManager.createContext, failed to create datastore url");
        self.managedObjectContext = nil;
        return;
    }      
    
    NSPersistentStoreCoordinator *storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedModel];
    
    if (!storeCoordinator) {
        NSLog(@"GroupAwardManager.createContext, failed to create NSPersistentStoreCoordinator");
        self.managedObjectContext = nil;
        return;
    }    
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:                             
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,                             
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSError *storeCoorError;    
    if (![storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&storeCoorError]) {
        
        NSLog(@"GroupAwardManager, Failed to create persistence context, %@", [storeCoorError localizedFailureReason]);
        self.persistenceError = storeCoorError;
        self.managedObjectContext = nil;
        return;
    }    
    
    [self.managedObjectContext setPersistentStoreCoordinator:storeCoordinator];   
}

// Get the award entity from the db.
- (AwardModelEntity *)getAwardEntityWithGroupNsid:(NSString *) groupNsid {
    
    if (!self.managedObjectContext) {
        return nil;
    }    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:kAwardEntity inManagedObjectContext:self.managedObjectContext]];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:kNsidEquals, groupNsid];
    
    NSError *fetchError;
    NSArray *awardList = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];

    if (fetchError) {
        NSLog(@"GroupAwardManager, Failed to fetch award, %@", [fetchError localizedFailureReason]);
        self.persistenceError = fetchError;
        return nil; 
    }
    else if (!awardList || !awardList.count) {
        self.persistenceError = nil;
        return nil;
    }    
    
    AwardModelEntity *awardEntity = [awardList objectAtIndex:0];
    return awardEntity;
}

// Save group to datastore.
- (BOOL) saveAward:(Award *) award {
    
    //NSLog(@"GroupAwardManager.saveAward, saving award w nsid %@ req %d html %@", award.groupNsid, award.requiredAwards, award.htmlAward);
    if (!self.managedObjectContext) {
        [self createContext];
        
        if (!self.managedObjectContext) { 
            return NO;
        }
    }
    
    AwardModelEntity *awardEntity = [self getAwardEntityWithGroupNsid:award.groupNsid];    
    if (!awardEntity) {
        //NSLog(@"GroupAwardManager.saveAward, inserting new award w nsid %@ req %d", award.groupNsid, award.requiredAwards);
        
        //Insert new group which may have awards
        awardEntity = (AwardModelEntity *)[NSEntityDescription insertNewObjectForEntityForName:kAwardEntity 
                                                                            inManagedObjectContext:self.managedObjectContext];
        awardEntity.created = [NSDate date];
        awardEntity.lastUsed = awardEntity.created;
        awardEntity.awardNsid = award.groupNsid;
        awardEntity.awardType = award.awardType;
    }   
    else {
         //NSLog(@"GroupAwardManager.saveAward, saving changes to award w nsid %@ req %d", award.groupNsid, award.requiredAwards);
        
        awardEntity.lastModified = [NSDate date];
        awardEntity.lastUsed = awardEntity.lastModified;
    }
    
    awardEntity.awardHtml = award.htmlAward;            
    if (award.maxPhotosPerDay) {
        awardEntity.maxPhotosPerDay = [NSNumber numberWithInteger:award.maxPhotosPerDay];
    }            
    if (award.requiredAwards) {
        awardEntity.requiredAwards = [NSNumber numberWithInteger:award.requiredAwards];
    }
            
    awardEntity.rules = award.rules;   
    NSError *addError;    
    if (![self.managedObjectContext save:&addError]) {
        NSLog(@"Failed to save award, %@", [addError localizedFailureReason]);        
        self.persistenceError = addError;
        return NO;        
    }
    
    self.persistenceError = nil;
    return YES;
}

// Get award from datastore.
- (Award *)getAwardWithGroupNsid:(NSString *) groupNsid {
    Award *award = nil;
    
    AwardModelEntity *awardEntity = [self getAwardEntityWithGroupNsid:groupNsid];
    
    if (awardEntity) {        
        award = [self convertAwardFromAwardEntity:awardEntity];
    }
    
    self.persistenceError = nil;
    return award;
}

// Convert entities to poocos
- (Award *)convertAwardFromAwardEntity:(AwardModelEntity *)awardEntity {
    Award *award = nil;
    
    if (awardEntity) {
        award = [[Award alloc] init];
        award.groupNsid = awardEntity.awardNsid;
        award.htmlAward = awardEntity.awardHtml;
        award.awardType = awardEntity.awardType;
        award.created = awardEntity.created;
        award.maxPhotosPerDay = [awardEntity.maxPhotosPerDay integerValue];
        award.requiredAwards = [awardEntity.requiredAwards integerValue];
        award.rules = awardEntity.rules;        
    }
    
    return award; 
}

@end
