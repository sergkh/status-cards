//
//  DictionaryManager.m
//  status-cards
//
//  Created by Sergey Khruschak on 9/26/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import "DictionaryManager.h"

@implementation DictionaryManager

@synthesize managedObjectContext;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if ( self = [super init] ) {
        self.managedObjectContext = context;
        // [[NSUserDefaults standardUserDefaults] objectForKey:kLingualeoUser];
        return self;
    } else {
        return nil;
    }
}

- (NSDictionary*) nextPair {
    
    // TODO: fetch
    
     // Fetching
     NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WordsPair"];
    
     NSSortDescriptor *sortByViewDate = [NSSortDescriptor sortDescriptorWithKey:@"lastShown" ascending:YES];
     NSSortDescriptor *sortByViews = [NSSortDescriptor sortDescriptorWithKey:@"shownTimes" ascending:YES];

    [request setSortDescriptors:@[sortByViewDate, sortByViews]];
    [request setFetchLimit:1];
     
     // Execute Fetch Request
     NSError *fetchError = nil;
    
     NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&fetchError];
     
     if (!fetchError) {
         if( [result count] > 0) {
             NSManagedObject *managedPair = result[0];
             NSDate *oldDate = [managedPair valueForKey:@"lastShown"];
             
             NSString *word = [managedPair valueForKey:@"word"];
             NSString *translation = [managedPair valueForKey:@"translation"];
             NSNumber *originalShownTimes = [managedPair valueForKey:@"shownTimes"];
             int shown = [originalShownTimes intValue] + 1;

             [managedPair setValue:[NSDate date] forKey:@"lastShown"];
             [managedPair setValue:[NSNumber numberWithInteger:shown] forKey:@"shownTimes"];
             
             NSError *saveError = nil;
             
             if(![managedPair.managedObjectContext save:&saveError]) {
                 NSLog(@"Unable to update managed object context %@, %@", saveError, saveError.localizedDescription);
             }
             
             NSLog(@"Got pair: %@ - %@, shown %d, lat on %@", word, translation, shown, oldDate);
             
             return [[NSDictionary alloc] initWithObjectsAndKeys:
                        word, @"word",
                        translation, @"translation",
                        nil];
         } else {
             NSLog(@"No records are found");
             return nil;
         }
     
     } else {
         NSLog(@"Error fetching data.");
         NSLog(@"%@, %@", fetchError, fetchError.localizedDescription);
         return nil;
     }
    
    // TODO: update
    /*NSManagedObject *person = (NSManagedObject *)[result objectAtIndex:0];
    
    [person setValue:@30 forKey:@"age"];
    
    NSError *saveError = nil;
    
    if (![person.managedObjectContext save:&saveError]) {
        NSLog(@"Unable to save managed object context.");
        NSLog(@"%@, %@", saveError, saveError.localizedDescription);
    } */
    
    return nil; //[[WordsPair alloc] initWithWord:@"Test" translation:@"Translation"];
}

- (void) importFromURL:(NSURL*)url error:(NSError **)error {
    if([url.scheme isEqualToString:@"file"]) {
        [self importFromFile:url.path error:error];
    } else {
        NSLog(@"URL is not supported Yet %@", url);
    }
}

//- (void) importFromLingualeo:(NSString*)login password:(NSString*)password {
//    NSLog(@"Importing from Lingua Leo account: %@", login);
//}

- (void) importFromFile:(NSString*)fileName error:(NSError **)error {
    NSLog(@"Importing file: %@", fileName);
    
    NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:error];
    
    if (*error) {
        NSLog(@"Error reading file: %@ : %@", (*error), (*error).localizedDescription);
        return ;
    }
    
    NSArray *fileLines = [fileContents componentsSeparatedByString:@"\n"];
    
    NSLog(@"Got %ld lines in file.", [fileLines count]);
    
    NSCharacterSet* allowedDelimeters = [NSCharacterSet characterSetWithCharactersInString:@":–=—"];
    
    int importedCount = 0;
    
    for (NSString *line in fileLines) {
        NSArray* pairsArray = [line componentsSeparatedByCharactersInSet:allowedDelimeters];
        
        if([pairsArray count] == 2) {
            if([self addPair:pairsArray[0] translation:pairsArray[1] error:error]) {
                importedCount++;
            }
        } else {
            // skipe empty lines
            if([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0) {
                NSLog(@"Ignored line: %@ with pairs: %ld", line, [pairsArray count]);
            }
        }
    }
    
    NSLog(@"Imported %d lines of %ld from %@", importedCount, [fileLines count], fileName);
}

- (BOOL) addPair:(NSString*)wordRaw translation:(NSString*)translationRaw error:(NSError **)error {
    
    NSCharacterSet* spaces = [NSCharacterSet whitespaceCharacterSet];
    
    // trim spaces
    NSString* word = [[wordRaw stringByTrimmingCharactersInSet:spaces] lowercaseString];
    NSString* translation = [translationRaw stringByTrimmingCharactersInSet:spaces];
    
    // Check is pair already exists
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext* context = [self managedObjectContext];
    [request setEntity:[NSEntityDescription entityForName:@"WordsPair" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"word=%@", word]] ;
    
    NSArray *results = [context executeFetchRequest:request error:nil];

    if ([results count] == 0) {
        // No previous entry found 
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"WordsPair" inManagedObjectContext:self.managedObjectContext];
        NSManagedObject *managedPair = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
        
        [managedPair setValue:word forKey:@"word"];
        [managedPair setValue:translation forKey:@"translation"];
        
        if(![managedPair.managedObjectContext save:error]) {
            NSLog(@"Unable to save context %@, %@", (*error), (*error).localizedDescription);
        } else {
            return true;
        }
    } else {
        // silence, please NSLog(@"Words pair already exists in base: %@, %@", word, translation);
    }
    
    return false;
}

- (void) removeAll {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allPairs = [[NSFetchRequest alloc] init];
    [allPairs setEntity:[NSEntityDescription entityForName:@"WordsPair" inManagedObjectContext:context]];
    [allPairs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *pairs = [[self managedObjectContext] executeFetchRequest:allPairs error:&error];
    
    for (NSManagedObject *p in pairs) {
        [context deleteObject:p];
    }
    
    [context save:&error];
}

@end
