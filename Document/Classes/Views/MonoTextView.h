//
//  MonoTextView.h
//  Document
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MonoTextViewDelegate;

@interface MonoTextView : NSTextView
@property (nonatomic, assign) id<NSTextViewDelegate, MonoTextViewDelegate> delegate;
@end

@protocol MonoTextViewDelegate <NSObject>

- (void)monoTextViewDidUpdate:(MonoTextView *)textView;

@end