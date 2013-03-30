//
//  MainViewController.m
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "MainViewController.h"

#include "array.h"
#include "buffer.h"
#include "markdown.h"
#include "renderers.h"

@interface DataObject : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *body;
@end

@implementation DataObject

@end

@interface MainViewController () <UITextViewDelegate>
@property (nonatomic, assign) int numberOfIndentions;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIWebView *previewWebView;
@property (nonatomic, strong) NSMutableDictionary *dataTypesDictionary;
@end

static NSString * const kObjectCreationRegEx = @"(@([A-Za-z0-9_]*)(\\s*)=(\\s*)(\\{([^}]+)\\});?)";
// 
static NSString * const kObjectIncludanceRegEx = @"((@include\\s)([A-Za-z0-9_-]+)\\s*\\((.*)\\))";

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataTypesDictionary = [NSMutableDictionary dictionary];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.textView.delegate = self;
    self.textView.font = [UIFont fontWithName:@"Monaco" size:14];
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.textColor = [UIColor colorWithHue:0.000 saturation:0.000 brightness:0.251 alpha:1];
    self.textView.backgroundColor = [UIColor redColor];
    
    self.previewWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:self.textView];
    [self.view addSubview:self.previewWebView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect rect = CGRectInset(self.view.bounds, 10, 10);
    
    self.textView.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width/2, rect.size.height);
    self.previewWebView.frame = CGRectMake(rect.origin.x + (rect.size.width/2), rect.origin.y, rect.size.width/2, rect.size.height);
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        
        NSString *indentations = @"";
        for (int i = 0; i < self.numberOfIndentions; i++) {
            indentations = [indentations stringByAppendingString:@"\t"];
        }
        
        //NSRange selectionRange = NSMakeRange(textView.selectedRange.location+self.numberOfIndentions, textView.selectedRange.length);
        
        NSMutableString *str = [textView.text mutableCopy];
        [str insertString:indentations atIndex:range.location];
        //textView.text = str;
        
        //textView.selectedRange = selectionRange;
    }
    else if ([text isEqualToString:@"\t"]) {
        self.numberOfIndentions++;
    }
    else if (  [[textView.text substringWithRange:NSMakeRange(range.location, range.length)] isEqualToString:@"\t"]) {
        self.numberOfIndentions--;
    }
    
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    NSString *rawText = self.textView.text;
    
    // Check regex
    rawText = [self handleObjects:rawText];
    rawText = [self handleIncludance:rawText];
    
    NSString *html = [self generateHTMLMarkdownForString:rawText];
    [self.previewWebView loadHTMLString:html baseURL:nil];
}

- (NSString *)generateHTMLMarkdownForString:(NSString *)text {
    NSString *rawMarkdown = text;
    const char * prose = [rawMarkdown UTF8String];
    struct buf *ib, *ob;
    
    unsigned long length = rawMarkdown.length + 1;
    
    ib = bufnew(length);
    bufgrow(ib, length);
    memcpy(ib->data, prose, length);
    ib->size = length;
    
    ob = bufnew(64);
    markdown(ob, ib, &mkd_xhtml);
    
    NSString *shinyNewHTML = [NSString stringWithUTF8String: ob->data];
    
    bufrelease(ib);
    bufrelease(ob);
    
    return shinyNewHTML;
}

- (NSString *)handleObjects:(NSString *)rawText {
    
    NSError *error = nil;
    
    // Check for includes
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:kObjectCreationRegEx options:NSRegularExpressionAllowCommentsAndWhitespace error:&error];
    
    if (!error) {
        NSArray *matches = [regexp matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
        NSLog(@"Number of matches: %lu", (unsigned long)matches.count);
        //[self.dataTypesDictionary removeAllObjects];
        
        if (matches.count > 0) {
            
        NSMutableArray *objects = [NSMutableArray array];
        //for (NSTextCheckingResult *match in matches) {
        int i = (int)matches.count;
        while (i) {
            i--;
            
            NSTextCheckingResult *match = matches[i];
            
            NSRange fullRange = [match rangeAtIndex:0];
            NSRange nameRange = [match rangeAtIndex:2];
            NSRange bodyRange = [match rangeAtIndex:5];
            
            NSString *name = [rawText substringWithRange:nameRange];
            NSString *body = [rawText substringWithRange:bodyRange];
            
            DataObject *dataObject = [self.dataTypesDictionary objectForKey:name];
            
            if (!dataObject) {
                dataObject = [[DataObject alloc] init];
                [self.dataTypesDictionary setObject:dataObject forKey:name];
            }
            
            dataObject.name = name;
            dataObject.body = body;
            
            NSLog(@"%@ %@, %@", name, body, NSStringFromRange(fullRange));
            
            rawText = [rawText stringByReplacingCharactersInRange:fullRange withString:@""];
            
            [objects addObject:name];
            
        }
        
        for (NSString *key in [self.dataTypesDictionary copy]) {
            if (![objects containsObject:key]) {
                //NSLog(@"%@ finns inte", key);
            }
        }
        
            
        }
    }
    
    return rawText;
}

- (NSString *)handleIncludance:(NSString *)rawText {
    NSError *error = nil;
    
    // Check for includes
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:kObjectIncludanceRegEx options:NSRegularExpressionCaseInsensitive error:&error];
    if (!error) {
        NSArray *matches = [regexp matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
        //NSLog(@"%@", matches);
        int i = (int)matches.count;
        while (i) {
            i--;
            
            NSTextCheckingResult *match = matches[i];
            NSRange fullRange = [match rangeAtIndex:0];
            NSRange methodRange = [match rangeAtIndex:3];
            //NSRange argsRange = [match rangeAtIndex:4];
            
            NSString *method = [rawText substringWithRange:methodRange];
            //NSLog(@"%@ %@", method, [self.dataTypesDictionary objectForKey:method]);
            [self.dataTypesDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSLog(@"Key: \"%@\"", key);
            }];
            if (method && [self.dataTypesDictionary objectForKey:method]) {
                DataObject *dataObject = [self.dataTypesDictionary objectForKey:method];
                rawText = [rawText stringByReplacingCharactersInRange:fullRange withString:dataObject.body];
            }
        }
    }
    
    return rawText;
}

@end
