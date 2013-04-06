//
//  AppDelegate.m
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "AppDelegate.h"
#import "INAppStoreWindow.h"

@interface AppDelegate ()
@property (unsafe_unretained) IBOutlet NSPanel *aboutPanel;

@end

@implementation AppDelegate {
    //NSDocumentController *_documentController;
}

- (IBAction)showAboutPanel:(id)sender {
    [self.aboutPanel makeKeyAndOrderFront:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /*
    self.windowController = [[EditingWindowController alloc] initWithWindowNibName:@"EditingWindowController"];
    
    INAppStoreWindow *aWindow = (INAppStoreWindow*)[[self windowController] window];
    aWindow.titleBarHeight = 48.0;
    
    [self.windowController showWindow:self];
    [self.windowController.window makeKeyAndOrderFront:self];
    */
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"Will quit");
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

@end
