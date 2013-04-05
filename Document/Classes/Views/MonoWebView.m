//
//  MonoWebView.m
//  Menter
//
//  Created by Simon Andersson on 4/3/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "MonoWebView.h"

@implementation MonoWebView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.frameLoadDelegate = self;
    [self setUIDelegate:self];
    [self setEditingDelegate:self];
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyUpMask handler:^NSEvent *(NSEvent *event) {
        if (event.keyCode == 49) {
            //return nil;
        }
        return event;
    }];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    
    if (self.pageDidLoadBlock) {
        self.pageDidLoadBlock();
    }
    
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element
    defaultMenuItems:(NSArray *)defaultMenuItems
{
    // disable right-click context menu
    return nil;
}

@end
