//
//  AppDelegate.h
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UIKitAppDelegate;
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) UIKitAppDelegate *appDelegate;
@property (weak) IBOutlet NSMenuItem *exportHTMLButton;
@property (weak) IBOutlet NSMenuItem *exportMarkdownButton;

@end
