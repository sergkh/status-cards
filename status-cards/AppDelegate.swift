//
//  AppDelegate.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
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
        statusItem = NSStatusBar.system().statusItem(withLength: length)
    }

    func changePairTimerActivated() {
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
    
    func startTimer() {
        self.repeatingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(20), // 6*60
                                                   target: self,
                                                   selector: #selector(AppDelegate.changePairTimerActivated),
                                                   userInfo: nil,
                                                   repeats: true)
        
        self.repeatingTimer?.tolerance = timerTolerance

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
    
    func updateSources() {
        let prefs = UserDefaults.standard
        if let sources = prefs.stringArray(forKey: sourcesKey) {
        
            print("Updating sources, count: \(sources.count)")
        
            for path in sources {
                print("Processing source: \(path)")
                if let url = NSURL(string: path) {
                    //self.dictionaryManager?.importFromURL(url, fromLang: 0, toLang: 0, error:&error);
                }
            }
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
        
        let languages: NSArray? = Locale.isoLanguageCodes as NSArray?
        let locale = Locale.autoupdatingCurrent
        
        for code in languages! {
            print("\(code) – \((locale as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: code))")
        }
        
        statusItem.title = "test"
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        self.repeatingTimer?.invalidate();
        self.repeatingTimer = nil
    }
    
    // UI handlers
    
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
        
        if (openPanel.runModal() == NSFileHandlingPanelOKButton) {
            let selection = openPanel.urls[0] 
            self.addSource(selection) // TODO: add languages here
        }        
    }

}

