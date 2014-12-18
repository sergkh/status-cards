//
//  LaunchOnLoginSupport.m
//  status-cards
//
//  Created by Sergey Khruschak on 12/18/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import "LaunchOnLoginSupport.h"

// Loaded from: http://bdunagan.com/2010/09/25/cocoa-tip-enabling-launch-on-startup/ and http://stackoverflow.com/a/20297681

@implementation LaunchOnLoginSupport

// MIT license
- (BOOL)isLaunchAtStartup {
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];

    BOOL isInList = itemRef != nil;
    
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (void)toggleLaunchAtStartup {
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItemsRef == nil) return;
    
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef res = nil;
    
    // Get the app's URL.
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);

    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemURLRef;

        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            // Again, use toll-free bridging.
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            
            if ([itemURL isEqual:bundleURL]) {
                res = itemRef;
                break;
            }
        }
    }
    
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}

@end
