//
//  AppDelegate.m
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "AppDelegate.h"
#import "UIKitAppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    _appDelegate = [[UIKitAppDelegate alloc] init];
    [_UIKitView launchApplicationWithDelegate:_appDelegate afterDelay:0.1];
}

@end
