//
//  LaunchOnLoginSupport.h
//  status-cards
//
//  Created by Sergey Khruschak on 12/18/14.
//  Copyright (c) 2014 Sergey Khruschak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LaunchOnLoginSupport : NSObject
- (BOOL)isLaunchAtStartup;
- (void)toggleLaunchAtStartup;
@end
