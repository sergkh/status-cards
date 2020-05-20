//
//  AppDelegate.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Cocoa
import CoreData
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var leftToUpdateSources = 10
    
    let sourcesKey = "sources"
    let notificationsEnabled = "notificationsEnabled"
    let panelEnabled = "panelEnabled"
    let launchAtLoginEnabled = "launchAtLoginEnabled"
    
    var dictionaryManager: DictionaryManager?
    var repeatingTimer: Timer?
    
    let timerTolerance = TimeInterval(60*5) // 5 min
    
    lazy var coreData = CoreDataStack()
    
    var statusItem: NSStatusItem?
    @IBOutlet weak var statusBarMenu: NSMenu?
    @IBOutlet weak var importDictMenuItem: NSMenuItem?
    @IBOutlet weak var settingsMenuItem: NSMenuItem?
    @IBOutlet weak var exitMenuItem: NSMenuItem?
    
    override init() {
        let defaults = [
            notificationsEnabled: false,
            panelEnabled : true,
            launchAtLoginEnabled: false
        ];
        
        UserDefaults.standard.register(defaults: defaults)
    }

    @objc func changePairTimerActivated() {
        let dictionary = self.dictionaryManager
    
        let maybeWord = dictionary?.nextWord()
        
        let prefs = UserDefaults.standard
    
        if let word = maybeWord {
            
            if prefs.bool(forKey: notificationsEnabled) {
                let notification = NSUserNotification()
                notification.title = word.word
                notification.informativeText = word.definition
                // no sound: notification.soundName = NSUserNotificationDefaultSoundName;
                print("Notifications are enabled")
                NSUserNotificationCenter.default.deliver(notification)
            } else {
                print("Notifications are disabled")
            }
    
            if prefs.bool(forKey: panelEnabled) {
                print("Setting status")
                self.statusItem?.button?.title = word.displayText()
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
                //if let url = NSURL(string: path) {
                    //self.dictionaryManager?.importFromURL(url, fromLang: 0, toLang: 0, error:&error);
                //}
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // NSRunningApplication.current().hide()
        
        coreData.load { 
            self.dictionaryManager = DictionaryManager(context: self.coreData.managedObjectContext)
            self.startTimer() // start the timer
            
            if let filepath = Bundle.main.path(forResource: "basic_en", ofType: "txt") {
                do {
                    let fileContents = try? String(contentsOfFile:filepath, encoding: .utf8)
                               
                    if let file = fileContents {
                       let lang = try self.dictionaryManager?.findOrAddLang("en")
                       
                       for word in file.split(separator: ",", omittingEmptySubsequences: true) {
                        
                            let old = try self.dictionaryManager?.addKnownWord(word: String(word), lang: lang!)
                            if (old != nil) {
                                break ;
                            }
                       }
                   }
                } catch {
                    
                }
            }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "📔"
        statusItem?.menu = statusBarMenu
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
        
        openPanel.title = "Choose a dictionary" // TODO: localize me
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
    
    @IBAction func openTextAction(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        
        openPanel.title = "Choose a subtitles file" // TODO: localize me
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["srt"];
        
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            for url in openPanel.urls {
                do {
                    try self.dictionaryManager?.importFromURL(url)
                } catch {
                    print("Error importing file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func appAction(_ sender: AnyObject) {
        
    }

    
    @IBAction func exitAction(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }

}

