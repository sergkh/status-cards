//
//  AppDelegate.h
//  status-cards
//
//  Created by Sergey Khruschak on 9/26/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DictionaryManager.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) NSTimer *repeatingTimer;
@property DictionaryManager *dictionaryManager;

- (void)changePairTimerActivated:(NSTimer*)timer;
- (void)updateSources;
- (NSTimeInterval)nextTimerInterval;
- (IBAction)importAction:(id)sender;
- (IBAction)manageAccountsAction:(id)sender;

- (void)addSource:(NSURL*)url;
@end

