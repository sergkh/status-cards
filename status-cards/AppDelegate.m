//
//  AppDelegate.m
//  status-cards
//
//  Created by Sergey Khruschak on 9/26/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import "AppDelegate.h"

#define kSources @"sources"
#define kNotificationsEnabled @"notificationsEnabled"
#define kPanelEnabled @"panelEnabled"

@interface AppDelegate ()

// @property (weak) IBOutlet NSWindow *window;
//- (IBAction)quitAction:(id)sender;

@end

@implementation AppDelegate

int leftToUpdateSources;

+(void)initialize {
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              @NO, kNotificationsEnabled,
                              @YES, kPanelEnabled,
                              nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    leftToUpdateSources = 10;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setTitle:@"T"]; // T is for translation )
    [self.statusItem setHighlightMode:YES];
    
    NSManagedObjectContext* context = [self managedObjectContext];
    self.dictionaryManager = [[DictionaryManager alloc] initWithManagedObjectContext:context];
    
    [self.repeatingTimer invalidate];
    self.repeatingTimer = nil;
    
    [self updateSources];
    [self changePairTimerActivated:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self.repeatingTimer invalidate];
}



#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "gmd.status_cards" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"gmd.status_cards"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"status_cards" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Core_Data.sqlite"];
        NSLog(@"Storage url: %@", url);
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

- (void)changePairTimerActivated:(NSTimer*)timer {
    id dictionary = [self dictionaryManager];
    
    NSDictionary* pair = [dictionary nextPair];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (pair) {
        if([prefs boolForKey:kNotificationsEnabled]) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = [pair objectForKey:@"word"];
            notification.informativeText = [pair objectForKey:@"translation"];
            // no sound: notification.soundName = NSUserNotificationDefaultSoundName;
        
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        } else {
            NSLog(@"Notifications are disabled");
        }
        
        if ([prefs boolForKey:kPanelEnabled]) {
            [self.statusItem setTitle: [[NSString alloc] initWithFormat:@"%@ – %@", [pair objectForKey:@"word"], [pair objectForKey:@"translation"]]];
        } else {
            NSLog(@"Panel is disabled");
        }
    }
    
    if(leftToUpdateSources-- == 0) {
        leftToUpdateSources = 10;
        [self updateSources];
    }
    
    [self.repeatingTimer invalidate];
    self.repeatingTimer = nil;
    self.repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:[self nextTimerInterval]
                                     target:self selector:@selector(changePairTimerActivated:)
                                     userInfo:[self dictionaryManager]
                                     repeats:NO];
}


- (void)updateSources {
    // TODO: update all registered sources
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSArray *sources = [prefs stringArrayForKey:kSources];
    
    NSLog(@"Updating sources %ld", [sources count]);
    
    for (NSString* path in sources) {
        NSLog(@"Processing source: %@", path);
        NSError* error = nil;
        [self.dictionaryManager importFromURL:[NSURL URLWithString:path] error:&error];
    }
}

- (void)addSource:(NSURL*)url {
    NSError* error = nil;
    [self.dictionaryManager importFromURL:url error:&error];
    
    // add source to settings if not added already
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSArray *sources = [prefs stringArrayForKey:kSources];
    
    NSString *newPath = [url absoluteString];
    
    for (NSString* path in sources) {
        if ([path isEqualToString:newPath]) return ;
    }
    
    NSArray* updatedSetting = sources ? [sources arrayByAddingObject:newPath] : [[NSArray alloc] initWithObjects:newPath, nil];
    
    [prefs setObject:updatedSetting forKey:kSources];
    [prefs synchronize];
    
    NSLog(@"Added new source %@", url);
}

- (NSTimeInterval)nextTimerInterval {
    NSTimeInterval interval = 60 + arc4random() % (60*1);
    
    // Logging:
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSLog(@"Next show up at: %@ +(%f)", [dateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceNow:interval]], interval);
    
    return interval;
}

- (IBAction)importAction:(id)sender {
    // Uncomment to clean up dictionay before import:
    //[self.dictionaryManager removeAll];
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    openPanel.title = @"Choose a file";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    //openPanel.allowedFileTypes = @[@"txt"];

    if([openPanel runModal] == NSFileHandlingPanelOKButton) {
        NSURL *selection = openPanel.URLs[0];
        [self addSource:selection];
    };
}

- (IBAction)manageAccountsAction:(id)sender {
    // [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

#pragma mark - Core Data Saving and Undo support

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
