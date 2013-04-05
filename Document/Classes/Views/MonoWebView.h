//
//  MonoWebView.h
//  Menter
//
//  Created by Simon Andersson on 4/3/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <WebKit/WebKit.h>
typedef void(^PageDidLoad)(void);
@interface MonoWebView : WebView
@property (nonatomic, assign) float lastScrollY;
@property (nonatomic, copy) PageDidLoad pageDidLoadBlock;
@end
