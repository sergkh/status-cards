//
//  LaunchOnLoginSupport.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Foundation

// Loaded from: http://stackoverflow.com/questions/26475008/swift-getting-a-mac-app-to-launch-on-startup


// TODO: update it with https://stackoverflow.com/questions/35339277/make-swift-cocoa-app-launch-on-startup-on-os-x-10-11
class LaunchOnLoginSupport {
    
    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList?
        
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl : CFURL = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL? {
                    LSSharedFileListInsertItemURL(loginItemsRef, itemReferences.lastReference, nil, nil, appUrl, nil, nil)
                    print("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    print("Application was removed from login items")
                }
            }
        }
    }
    
    fileprivate func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
        let itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.allocate(capacity: 1)
        
        if let appUrl : URL = URL(fileURLWithPath: Bundle.main.bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList?
            
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                let lastItemRef: LSSharedFileListItem = loginItems.lastObject as! LSSharedFileListItem
                
                for i in 0 ..< loginItems.count + 1 {
                    let currentItemRef: LSSharedFileListItem = loginItems.object(at: i) as! LSSharedFileListItem
                    
                    if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                        if let urlRef: URL =  itemUrl.pointee?.takeRetainedValue() as URL? {
                        
                            if urlRef == appUrl {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    }
                }
                //The application was not found in the startup list
                return (nil, lastItemRef)
            }
        }
        
        return (nil, nil)
    }
}
