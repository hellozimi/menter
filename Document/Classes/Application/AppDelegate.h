//
//  AppDelegate.h
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UIKit/UIKitView.h>

@class UIKitAppDelegate;
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet UIKitView *UIKitView;
@property (nonatomic, strong) UIKitAppDelegate *appDelegate;

@end
