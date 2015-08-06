//
//  AppDelegate.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var leftToUpdateSources = 10
    
    let sourcesKey = "sources"
    let notificationsEnabled = "notificationsEnabled"
    let panelEnabled = "panelEnabled"
    let launchAtLoginEnabled = "launchAtLoginEnabled"
    
    var statusItem: NSStatusItem
    var dictionaryManager: DictionaryManager?
    var repeatingTimer: NSTimer?
    
    let timerTolerance = NSTimeInterval(60*5) // 5 min
    
    override init() {
        let defaults = [
            notificationsEnabled: false,
            panelEnabled : true,
            launchAtLoginEnabled: false
        ];
        
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        let length: CGFloat = -1
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(length)
    }

    func changePairTimerActivated() {
        
        println("Timer action started")
        
        let dictionary = self.dictionaryManager
    
        let maybeWord = dictionary?.nextPair()

        println("Maybe word: \(maybeWord)")
        
        let prefs = NSUserDefaults.standardUserDefaults()
    
        if let word = maybeWord {
            
            if prefs.boolForKey(notificationsEnabled) {
                let notification = NSUserNotification()
                notification.title = word.word
                notification.informativeText = word.translationText()
                // no sound: notification.soundName = NSUserNotificationDefaultSoundName;
                println("Notifications are enabled")
                NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
            } else {
                println("Notifications are disabled")
            }
    
            if prefs.boolForKey(panelEnabled) {
                println("Setting status")
                self.statusItem.title = String(format: "%@ – %@", word.word, word.translationText())
            } else {
                println("Panel is disabled");
            }
        } else {
            println("Word is not obtained")
        }
    
        if(leftToUpdateSources-- == 0) {
            leftToUpdateSources = 10;
            self.updateSources()
        }
        
        //let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5000 * Double(NSEC_PER_SEC)))

        //dispatch_after(delayTime, dispatch_get_main_queue()) {
        //    self.changePairTimerActivated()
        //}
        
        self.repeatingTimer?.invalidate()
        self.repeatingTimer = nil;

        self.repeatingTimer = NSTimer.scheduledTimerWithTimeInterval(nextTimerInterval(),
                                                                     target: self,
                                                                     selector: "changePairTimerActivated",
                                                                     userInfo: nil,
                                                                     repeats: true)
        self.repeatingTimer?.tolerance = timerTolerance
    }
    
    func addSource(url: NSURL) {
        var error: NSError? = nil
        
        self.dictionaryManager?.importFromURL(url, error: &error)
    
        // add source to settings if not added already
        let prefs = NSUserDefaults.standardUserDefaults()
        let sourcesOpt = prefs.stringArrayForKey(sourcesKey) as? [String]
        var sources = sourcesOpt ?? [String]()
        let newSource = url.absoluteString!
    
        for path in sources {
            if (path == newSource) {
                return ;
            }
        }
    
        sources.append(newSource)
    
        prefs.setObject(sources, forKey: sourcesKey)

        prefs.synchronize()
    
        println("Added new source \(url)")
    }
    
    func updateSources() {
        let prefs = NSUserDefaults.standardUserDefaults()
        let sources = prefs.stringArrayForKey(sourcesKey) as! Array<String>
        
        println("Updating sources, count: \(sources.count)")
        
        for path in sources {
            println("Processing source: \(path)")
            var error: NSError? = nil
            if let url = NSURL(string: path) {
                //self.dictionaryManager?.importFromURL(url, fromLang: 0, toLang: 0, error:&error);
            }
        }
    }
    
    func nextTimerInterval() -> NSTimeInterval {
        let interval = NSTimeInterval(60 + arc4random() % (60*5))
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        println("Next show up at: \(formatter.stringFromDate(NSDate(timeIntervalSinceNow: interval))) +\(interval)")
        
        return interval
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let context = self.managedObjectContext!
        dictionaryManager = DictionaryManager(context: context)
        
        // Check autostart
        let autostart = LaunchOnLoginSupport()
        let autostartEnabled = NSUserDefaults.standardUserDefaults().boolForKey(launchAtLoginEnabled)
        
        if(autostartEnabled != autostart.applicationIsInStartUpItems()) {
            autostart.toggleLaunchAtStartup()
            println("Toggled autostart status to: \(autostart.applicationIsInStartUpItems())")
        }
        
        let languages: NSArray? = NSLocale.ISOLanguageCodes()
        let locale = NSLocale.autoupdatingCurrentLocale()
        
        for code in languages! {
            println("\(code) – \(locale.displayNameForKey(NSLocaleIdentifier, value: code))")
        }
        
        statusItem.title = "test"
        
        self.changePairTimerActivated() // start the timer
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        self.repeatingTimer?.invalidate();
        self.repeatingTimer = nil
    }
    
    // UI handlers
    
    @IBAction func openAction(sender: AnyObject) {
        // Uncomment to clean up dictionay before import:
        //[self.dictionaryManager removeAll];
        
        let openPanel = NSOpenPanel()
        
        openPanel.title = "Choose a file" // localize me
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        //openPanel.allowedFileTypes = ["txt"];
        
        if (openPanel.runModal() == NSFileHandlingPanelOKButton) {
            let selection = openPanel.URLs[0] as! NSURL
            self.addSource(selection) // TODO: add languages here
        }        
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.sergkh.status_cards" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as! NSURL
        return appSupportURL.URLByAppendingPathComponent("org.sergkh.status_cards")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("status_cards", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("status_cards.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

}

