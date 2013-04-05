//
//  MonoTextView.m
//  Document
//
//  Created by Simon Andersson on 3/30/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "MonoTextViewCell.h"

@implementation MonoTextViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.focusRingType = NSFocusRingTypeNone;
        [self setBezeled:NO];
    }
    return self;
}

- (NSColor *)textColor {
    return [NSColor colorWithDeviceRed:0. green:0. blue:0.251 alpha:1];
}

- (NSFont *)font {
    return [NSFont fontWithName:@"Monaco" size:14];
}



@end
