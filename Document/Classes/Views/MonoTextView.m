//
//  MonoTextView.m
//  Document
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "MonoTextView.h"

@implementation MonoTextView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [super setBackgroundColor:self.backgroundColor];
    [super setTextColor:self.textColor];
}

- (void)viewWillDraw {
    
    [super viewWillDraw];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    
    if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
        
        if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
            
            if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
                [[self delegate] monoTextViewDidUpdate:self];
            }
            return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
        }
        else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
            
            if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
                [[self delegate] monoTextViewDidUpdate:self];
            }
            return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
        }
        else /*if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
              
              if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
              [[self delegate] monoTextViewDidUpdate:self];
              }
              
              return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
              }
              else */if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
                  
                  if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
                      [[self delegate] monoTextViewDidUpdate:self];
                  }
                  return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
              }
              else if ([[event charactersIgnoringModifiers] isEqualToString:@"b"]) {
                  
                  // Make bold
                  NSRange selectedRange = self.selectedRange;
                  
                  [self handleBoldForRange:selectedRange inString:self.string];
                  
                  if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
                      [[self delegate] monoTextViewDidUpdate:self];
                  }
                  
                  return NO;
                  
                  
              }
              else if ([[event charactersIgnoringModifiers] isEqualToString:@"i"]) {
                  
                  // Make bold
                  NSRange selectedRange = self.selectedRange;
                  
                  [self handleItalicForRange:selectedRange inString:self.string];
                  
                  if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
                      [[self delegate] monoTextViewDidUpdate:self];
                  }
                  
                  return NO;
                  
                  
              }
    }
    return [super performKeyEquivalent:event];
}
/*
 -(void)paste:(id)sender {
 NSPasteboard *pb = [NSPasteboard generalPasteboard];
 NSString *pbItem = [pb readObjectsForClasses: @[[NSString class],[NSAttributedString class]] options:nil].lastObject;
 if ([pbItem isKindOfClass:[NSAttributedString class]])
 pbItem = [(NSAttributedString *)pbItem string];
 
 if ([pbItem isEqualToString:@"foo"]) {
 [self insertText:@"bar"];
 }else{
 [super paste:sender];
 }
 }
 */


- (void)insertText:(id)insertString {
    
    // if the insert string isn't one character in length, it cannot be a brace character
    if ([insertString length] != 1) {
        
        [super insertText:insertString];
        return;
    }
    
    unichar firstCharacter = [insertString characterAtIndex:0];
    /*
    if (firstCharacter == '\t') {
        
        [super insertText:@"    "];
        [self setSelectedRange:NSMakeRange(self.selectedRange.location, 0)];
    }
    else*/ {
        BOOL insertedLastComponent = NO;
        
        if (self.string.length > 1) {
            
            if (self.selectedRange.location == 0) {
                NSLog(@"Hela alltet");
                [super insertText:insertString];
                return;
            }
            
            NSString *lastCharacter = [self.string substringWithRange:NSMakeRange(self.selectedRange.location-1, 1)];
            
            if (lastCharacter.length == 1 && (firstCharacter == ')' ||firstCharacter == '}' ||firstCharacter == ']')) {
                unichar character = [lastCharacter characterAtIndex:0];
                switch (character) {
                    case '(':
                    case '[':
                    case '{':
                        insertedLastComponent = YES;
                        [self setSelectedRange:NSMakeRange(self.selectedRange.location + 1, 0)];
                        break;
                }
            }
            
        }
    
        if (!insertedLastComponent) {
            
            [super insertText:insertString];
            
            switch (firstCharacter) {
                case '(':
                    [super insertText:@")"];
                    break;
                case '[':
                    [super insertText:@"]"];
                    break;
                case '{':
                    [super insertText:@"}"];
                    break;
                default:
                    return;
            }
            [self setSelectedRange:NSMakeRange(self.selectedRange.location - 1, 0)];
        }
    }
    // adjust the selected range since we inserted an extra character
}

- (void)handleBoldForRange:(NSRange)range inString:(NSString *)string {
    
    BOOL isAlreadyBold = NO;
    
    // Check for bold
    if (range.location >= 2 && range.location+range.length+2 <= string.length) {
        NSRange boldRange = NSMakeRange(range.location-2, range.length+4);
        NSString *boldString = [string substringWithRange:boldRange];
        NSString *underlineString = [boldString stringByReplacingCharactersInRange:NSMakeRange(2, range.length) withString:@""];
        
        if ([underlineString isEqualToString:@"____"]) {
            isAlreadyBold = YES;
            
            NSString *replacementString = [boldString stringByReplacingOccurrencesOfString:@"_" withString:@""];
            string = [string stringByReplacingCharactersInRange:boldRange withString:replacementString];
            
            [self insertText:replacementString replacementRange:boldRange];
            
            [self setSelectedRange:NSMakeRange(range.location-2, range.length)];
        }
    }
    
    if (!isAlreadyBold) {
        
        // Make bold
        NSString *boldString = [NSString stringWithFormat:@"__%@__", [string substringWithRange:range]];
        string = [self.string stringByReplacingCharactersInRange:range withString:boldString];
        
        [self insertText:boldString replacementRange:range];
        
        [self setSelectedRange:NSMakeRange(range.location+2, range.length)];
    }
    
}

- (void)handleItalicForRange:(NSRange)range inString:(NSString *)string {
    
    BOOL isAlreadyBold = NO;
    
    // Check for bold
    if (range.location >= 1 && range.location+range.length+1 <= string.length) {
        NSRange boldRange = NSMakeRange(range.location-1, range.length+2);
        NSString *boldString = [string substringWithRange:boldRange];
        NSString *underlineString = [boldString stringByReplacingCharactersInRange:NSMakeRange(2, range.length) withString:@""];
        
        if ([underlineString isEqualToString:@"__"]) {
            isAlreadyBold = YES;
            
            NSString *replacementString = [boldString stringByReplacingOccurrencesOfString:@"_" withString:@""];
            string = [string stringByReplacingCharactersInRange:boldRange withString:replacementString];
            
            [self insertText:replacementString replacementRange:boldRange];
            
            [self setSelectedRange:NSMakeRange(range.location-1, range.length)];
        }
    }
    
    if (!isAlreadyBold) {
        
        // Make bold
        NSString *boldString = [NSString stringWithFormat:@"_%@_", [string substringWithRange:range]];
        string = [self.string stringByReplacingCharactersInRange:range withString:boldString];
        
        [self insertText:boldString replacementRange:range];
        
        [self setSelectedRange:NSMakeRange(range.location+1, range.length)];
    }
    
}

- (void)didChangeText {
    
    if ([[self delegate] respondsToSelector:@selector(monoTextViewDidUpdate:)]) {
        [[self delegate] monoTextViewDidUpdate:self];
    }
}

@end
