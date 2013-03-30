//
//  UIKitAppDelegate.m
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "UIKitAppDelegate.h"
#import "MainViewController.h"

@implementation UIKitAppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    MainViewController *vc = [[MainViewController alloc] init];
    vc.view.frame = self.window.bounds;
    vc.view.autoresizingMask  = self.window.autoresizingMask;
    
    self.window.rootViewController = vc;
    
    [self.window makeKeyAndVisible];
}

@end
