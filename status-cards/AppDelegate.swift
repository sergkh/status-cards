//
//  AppDelegate.swift
//  status-cards
//
//  Created by Sergey Khruschak on 9/28/17.
//  Copyright © 2017 Sergey Khruschak. All rights reserved.
//

import Cocoa
import CoreData

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var leftToUpdateSources = 10
    
    let sourcesKey = "sources"
    let notificationsEnabled = "notificationsEnabled"
    let panelEnabled = "panelEnabled"
    let launchAtLoginEnabled = "launchAtLoginEnabled"
    
    var statusItem: NSStatusItem
    var dictionaryManager: DictionaryManager?
    var repeatingTimer: Timer?
    
    let timerTolerance = TimeInterval(60*5) // 5 min
    
    lazy var coreData = CoreDataStack()

    override init() {
        let defaults = [
            notificationsEnabled: false,
            panelEnabled : true,
            launchAtLoginEnabled: false
        ];
        
        UserDefaults.standard.register(defaults: defaults)
        let length: CGFloat = -1
        statusItem = NSStatusBar.system.statusItem(withLength: length)
        statusItem.title = "📔"
        // statusItem.menu =
    }
    
    func startTimer() {
        self.repeatingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(20), // 6*60
            target: self,
            selector: #selector(AppDelegate.changePairTimerActivated),
            userInfo: nil,
            repeats: true)
        
        self.repeatingTimer?.tolerance = timerTolerance
        
    }
    
    @objc func changePairTimerActivated() {
        let dictionary = self.dictionaryManager
        
        let maybePair = dictionary?.nextPair()
        
        let prefs = UserDefaults.standard
        
        if let pair = maybePair {
            
            if prefs.bool(forKey: notificationsEnabled) {
                let notification = NSUserNotification()
                notification.title = pair.word1.word
                notification.informativeText = pair.word2.word
                // no sound: notification.soundName = NSUserNotificationDefaultSoundName;
                print("Notifications are enabled")
                NSUserNotificationCenter.default.deliver(notification)
            } else {
                print("Notifications are disabled")
            }
            
            if prefs.bool(forKey: panelEnabled) {
                print("Setting status")
                self.statusItem.title = pair.displayText()
            } else {
                print("Panel is disabled");
            }
        } else {
            print("Word is not obtained")
        }
        
        leftToUpdateSources -= 1
        
        if(leftToUpdateSources == 0) {
            leftToUpdateSources = 10;
            self.updateSources()
        }
    }
    
    func updateSources() {
        let prefs = UserDefaults.standard
        if let sources = prefs.stringArray(forKey: sourcesKey) {
            
            print("Updating sources, count: \(sources.count)")
            
            for path in sources {
                print("Processing source: \(path)")
                //if let url = NSURL(string: path) {
                //self.dictionaryManager?.importFromURL(url, fromLang: 0, toLang: 0, error:&error);
                //}
            }
        }
    }
    
    func addSource(_ url: URL) {
        do {
            try self.dictionaryManager?.importFromURL(url)
            
            // add source to settings if not added already
            let prefs = UserDefaults.standard
            let sourcesOpt = prefs.stringArray(forKey: sourcesKey)
            var sources = sourcesOpt ?? [String]()
            let newSource = url.absoluteString
            
            for path in sources {
                if (path == newSource) {
                    return ;
                }
            }
            
            sources.append(newSource)
            
            prefs.set(sources, forKey: sourcesKey)
            
            prefs.synchronize()
            
            print("Added new source \(url)")
        } catch {
            print("Error adding source: \(error.localizedDescription)")
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // NSRunningApplication.current().hide()
        
        coreData.load {
            self.dictionaryManager = DictionaryManager(context: self.coreData.managedObjectContext)
            self.startTimer() // start the timer
        }
        
        // Check autostart
        let autostart = LaunchOnLoginSupport()
        let autostartEnabled = UserDefaults.standard.bool(forKey: launchAtLoginEnabled)
        
        if(autostartEnabled != autostart.applicationIsInStartUpItems()) {
            autostart.toggleLaunchAtStartup()
            print("Toggled autostart status to: \(autostart.applicationIsInStartUpItems())")
        }
        
        //let languages: NSArray? = Locale.isoLanguageCodes as NSArray?
        //let locale = Locale.autoupdatingCurrent
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.repeatingTimer?.invalidate();
        self.repeatingTimer = nil
    }

    // MARK: - Core Data stack

    // MARK: - Core Data Saving and Undo support
    @IBAction func openAction(_ sender: AnyObject) {
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
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let selection = openPanel.urls[0]
            self.addSource(selection) // TODO: add languages here
        }
    }
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        do {
            try coreData.saveContext()
        } catch {
            fatalError("Unresolved error \(error), \(error.localizedDescription)")
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return coreData.undoManager()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        do {
            try coreData.saveContext()
            return .terminateNow
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

