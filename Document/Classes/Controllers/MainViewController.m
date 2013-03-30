//
//  MainViewController.m
//  Document
//
//  Created by Simon Andersson on 3/27/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "MainViewController.h"
#import "GHMarkdownParser.h"



@interface NSString (CountString)
- (NSUInteger)countOccurencesOfString:(NSString*)searchString;
@end

@implementation NSString (CountString)
- (NSUInteger)countOccurencesOfString:(NSString*)searchString {
    unsigned long strCount = [self length] - [[self stringByReplacingOccurrencesOfString:searchString withString:@""] length];
    return strCount / [searchString length];
}
@end

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
        
        //NSMutableString *str = [textView.text mutableCopy];
        //[str insertString:indentations atIndex:range.location];
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
    
    rawText = [self indentText:rawText];
    
    NSString *html = [self generateHTMLMarkdownForString:rawText];
    
    //NSLog(@"%@",html);
    [self.previewWebView loadHTMLString:html baseURL:nil];
}

- (NSString *)indentText:(NSString *)text {
    
    __block int indentaitons = 0;
    [text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSString *spaces = @"";
        for (int j = 0; j < indentaitons ; j++) {
            spaces = [spaces stringByAppendingFormat:@" "];
        }
        
        for (int i = 0; i < line.length; i++) {
            unichar c = [line characterAtIndex:i];
            if (c == '{') {
                indentaitons++;
            }
            else if (c == '}') {
                indentaitons--;
            }
        }
    }];
    
    return text;
}

- (NSString *)generateHTMLMarkdownForString:(NSString *)text {
    
    NSString *css = @"h1,h2,h3,h4,h5,h6,p,blockquote{margin:0;padding:0;}body{font-family:\"Helvetica Neue\", Helvetica, \"Hiragino Sans GB\", Arial, sans-serif;font-size:13px;line-height:18px;color:#737373;background-color:#FFF;margin:10px 13px;}table{border-collapse:collapse;margin:10px 0 15px;}td,th{border:1px solid #ddd;padding:3px 10px;}th{padding:5px 10px;}a{color:#0069d6;}a:hover{color:#0050a3;text-decoration:none;}a img{border:none;}p{margin-bottom:9px;}h1,h2,h3,h4,h5,h6{color:#404040;line-height:36px;}h1{margin-bottom:18px;font-size:30px;}h2{font-size:24px;}h3{font-size:18px;}h4{font-size:16px;}h5{font-size:14px;}h6{font-size:13px;}hr{border:0;border-bottom:1px solid #ccc;margin:0 0 19px;}blockquote{margin-bottom:18px;font-family:georgia,serif;font-style:italic;padding:13px 13px 21px 15px;}blockquote:before{content:\"\\201C\";font-size:40px;margin-left:-10px;font-family:georgia,serif;color:#eee;}blockquote p{font-size:14px;font-weight:300;line-height:18px;margin-bottom:0;font-style:italic;}code,pre{font-family:Monaco, Andale Mono, Courier New, monospace;}code{background-color:#fee9cc;color:rgba(0,0,0,0.75);font-size:12px;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px;padding:1px 3px;}pre{display:block;line-height:16px;font-size:11px;border:1px solid #d9d9d9;white-space:pre-wrap;word-wrap:break-word;margin:0 0 18px;padding:14px;}pre code{background-color:#fff;color:#737373;font-size:11px;padding:0;}sup{font-size:.83em;vertical-align:super;line-height:0;}*{-webkit-print-color-adjust:exact;}@media screen and min-width 914px{body{width:854px;margin:10px auto;}}@media print{body,code,pre code,h1,h2,h3,h4,h5,h6{color:#000;}table,pre{page-break-inside:avoid;}}";
    return [NSString stringWithFormat:@"<style>%@</style><body>%@</body>", css, text.flavoredHTMLStringFromMarkdown];
}

- (NSString *)handleObjects:(NSString *)rawText {
    
    NSError *error = nil;
    
    // Check for includes
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:kObjectCreationRegEx options:NSRegularExpressionAllowCommentsAndWhitespace error:&error];
    
    if (!error) {
        NSArray *matches = [regexp matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
        // NSLog(@"Number of matches: %lu", (unsigned long)matches.count);
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
            
            NSString *method = [rawText substringWithRange:methodRange];
            
            if (method && [self.dataTypesDictionary objectForKey:method]) {
                
                __block NSUInteger numberOfTabs = 0;
                [rawText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    if ([line rangeOfString:[NSString stringWithFormat:@"@include %@()", method]].location != NSNotFound) {
                        numberOfTabs = [line countOccurencesOfString:@"\t"];
                    }
                }];
                
                DataObject *dataObject = [self.dataTypesDictionary objectForKey:method];
                NSString *body = dataObject.body;
                __block NSString *tabbedBody = @"";
                NSString *tabs = [@"" stringByPaddingToLength:numberOfTabs withString:@"\t" startingAtIndex:0];
                
                __block int i = 0;
                [body enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    
                    if (i > 0) {
                        tabbedBody = [tabbedBody stringByAppendingFormat:@"\n%@%@", tabs, line];
                    }
                    else {
                        tabbedBody = [tabbedBody stringByAppendingString:line];
                    }
                    i++;
                }];
                
                rawText = [rawText stringByReplacingCharactersInRange:fullRange withString:tabbedBody];
            }
        }
    }
    
    return rawText;
}

@end
