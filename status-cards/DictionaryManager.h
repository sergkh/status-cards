//
//  DictionaryManager.h
//  status-cards
//
//  Created by Sergey Khruschak on 9/26/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#ifndef status_cards_DictionaryManager_h
#define status_cards_DictionaryManager_h

#import <Cocoa/Cocoa.h>

#endif

@interface DictionaryManager : NSObject
- (instancetype) initWithManagedObjectContext:(NSManagedObjectContext *)context;
- (NSDictionary*) nextPair;
- (void) importFromURL:(NSURL*)url error:(NSError **)error;
- (BOOL) addPair:(NSString*)word translation:(NSString*)translation error:(NSError **)error;
- (void) removeAll;

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

// - (void) importFromFile:(NSString*)fileName error:(NSError **)error;

@end

