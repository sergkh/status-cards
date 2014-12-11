//
//  WordsPair.m
//  status-cards
//
//  Created by Sergey Khruschak on 10/22/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import "WordsPair.h"

@implementation WordsPair

-(id)initWithWord:(NSString *)word translation:(NSString *)translation {
    self = [super init];
    
    if (self) {
        self.word = word;
        self.translation = translation;
    }
    
    return self;
}

@end
