//
//  WordsPair.h
//  status-cards
//
//  Created by Sergey Khruschak on 10/22/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordsPair : NSObject
    @property (nonatomic, copy) NSString* word;
    @property (nonatomic, copy) NSString* translation;

    -(id)initWithWord:(NSString *)word translation:(NSString *)translation;

@end
