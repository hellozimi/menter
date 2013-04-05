//
//  Document.m
//  Menter
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "Document.h"
#import "INAppStoreWindow.h"
#import "GHMarkdownParser.h"
#import "DataObject.h"
#import "SeparatorView.h"
#import "MonoTextView.h"
#import "DocumentItem.h"
#import "AppDelegate.h"
#import "MonoWebView.h"

@interface NSString (CountString)
- (NSUInteger)countOccurencesOfString:(NSString*)searchString;
@end

@implementation NSString (CountString)
- (NSUInteger)countOccurencesOfString:(NSString*)searchString {
    unsigned long strCount = [self length] - [[self stringByReplacingOccurrencesOfString:searchString withString:@""] length];
    return strCount / [searchString length];
}
@end

@interface Document () <NSTextViewDelegate, MonoTextViewDelegate, NSWindowDelegate>
@property (nonatomic, strong) IBOutlet MonoTextView *inputTextField;
@property (weak) IBOutlet MonoWebView *previewWebView;
@property (weak) IBOutlet SeparatorView *separatorView;
@property (weak) IBOutlet NSScrollView *textFieldScrollView;
@property (weak) IBOutlet NSScrollView *webScrollView;
@property (nonatomic, strong) NSMutableDictionary *dataTypesDictionary;
@property (nonatomic, strong) NSString *markdown;
@property (nonatomic, strong) INAppStoreWindow *keyedWindow;
@property (nonatomic, strong) NSFileWrapper *documentFileWrapper;
@end

@implementation Document

//static NSString * const kObjectCreationRegEx = @"(@([A-Za-z0-9_]*)(\\s*)=(\\s*)(\\{([^}]+)\\});)";

// (({((\s*?.*?)*?)\});)
//static NSString * const kObjectCreationRegEx = @"(@([A-Za-z0-9_]*)\\s*=\\s*(\\{((\\s\\*?.*?)*?)\\});)";
static NSString * const kObjectCreationRegEx = @"(@[A-Za-z0-9_]*\\s*=\\s*\\{(\\s\\*?.*?)*?\\};)";
static NSString * const kObjectCreationNameRegEx = @"^@([A-Za-z0-9_]*)";
static NSString * const kObjectCreationObjectRegEx = @"(\\{((\\s\\*?.*?)*?)\\});";

static NSString * const kObjectIncludanceRegEx = @"((@include\\s)([A-Za-z0-9_-]+)\\s*\\((.*)\\))";
static NSString * const kObjectContentRegEx = @"((@content\\s)([A-Za-z0-9_-]+)\\s*\\((.*)\\))";

- (id)init
{
    self = [super init];
    if (self) {
        self.documentFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    aController.shouldCascadeWindows = YES;
    
    INAppStoreWindow *aWindow = (INAppStoreWindow*)[aController window];
    aWindow.titleBarHeight = 48.0;
    aWindow.showsTitle = YES;
    
    self.keyedWindow = aWindow;
    
    self.separatorView.backgroundColor = [NSColor colorWithCalibratedHue:0.000 saturation:0.000 brightness:0.796 alpha:1];
    self.inputTextField.delegate = self;
    aWindow.backgroundColor = [NSColor whiteColor];
    aWindow.delegate = self;
    self.dataTypesDictionary = [NSMutableDictionary dictionary];
    self.inputTextField.font = [NSFont fontWithName:@"Monaco" size:13];
    [self.inputTextField setTextContainerInset:NSMakeSize(10, 10)];
    [self layoutWindow:aWindow];
    
    if (self.markdown) {
        [self.inputTextField setString:self.markdown];
        [self monoTextViewDidUpdate:self.inputTextField];
    }
    
    [self.previewWebView.mainFrame.frameView setAllowsScrolling:NO];
    
    __weak Document *weakSelf = self;
    self.previewWebView.pageDidLoadBlock = ^{
        [self layoutWindow:self.keyedWindow];
        /*
        NSScrollView* scrollView = [[[[weakSelf.previewWebView mainFrame] frameView] documentView] enclosingScrollView];
        [[scrollView verticalScroller] setControlSize: NSSmallControlSize];
        [[scrollView horizontalScroller] setControlSize: NSSmallControlSize];
        */
        return;
        //NSScrollView *mainScrollView = weakSelf.previewWebView.mainFrame.frameView.documentView.enclosingScrollView;
        NSRect rect = weakSelf.previewWebView.bounds;
        rect.size.width = weakSelf.keyedWindow.frame.size.width/2;
        rect.size.height = weakSelf.previewWebView.mainFrame.DOMDocument.body.boundingBox.size.height;
        
        rect.origin.y = -rect.size.height;
        weakSelf.previewWebView.frame = rect;
        [[weakSelf.webScrollView documentView] setFrame:NSMakeRect(0, 0, weakSelf.keyedWindow.frame.size.width/2, rect.size.height)];
    };
}

- (void)exportHTML:(NSNotification *)notification {
    
    NSString *rawText = self.inputTextField.string;
    
    rawText = [self handleObjects:rawText];
    rawText = [self handleIncludance:rawText];
    rawText = [self handleContents:rawText];
    
    NSString *html = [self generateHTMLMarkdownForString:rawText];
    
    NSSavePanel *savePanel = [[NSSavePanel alloc] init];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowedFileTypes:@[@"html"]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setTitle:@"Export as HTML"];
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == 1) {
            NSURL *url = [savePanel URL];
            NSError *error = nil;
            [html writeToFile:[url path] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Couldn't save file to: %@", [url absoluteString]];
                [alert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
            }
        }
    }];
}

- (void)exportMarkdown:(NSNotification *)notification {
    
    NSString *rawText = self.inputTextField.string;
    
    rawText = [self handleObjects:rawText];
    rawText = [self handleIncludance:rawText];
    rawText = [self handleContents:rawText];
    
    NSString *markdown = rawText;
    
    NSSavePanel *savePanel = [[NSSavePanel alloc] init];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowedFileTypes:@[@"md"]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setTitle:@"Export as Markdown"];
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == 1) {
            NSURL *url = [savePanel URL];
            NSError *error = nil;
            [markdown writeToFile:[url path] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Couldn't save file to: %@", [url absoluteString]];
                [alert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
            }
        }
    }];
}
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return [NSKeyedArchiver archivedDataWithRootObject:self.markdown];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
    NSString *string = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.markdown = string;
    [self.inputTextField insertText:string];
    
    return YES;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    [savePanel setAllowedFileTypes:@[@"mmd", @"txt"]];
    [savePanel setExtensionHidden:YES];
    [savePanel setAllowsOtherFileTypes:NO];
    
    return YES;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

+ (BOOL)preservesVersions {
    return NO;
}

+ (BOOL)autosavesDrafts {
    return NO;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError {
	// encode the index
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.markdown];
    
	// create a new fileWrapper for the bundle
	NSFileWrapper *newWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
	return newWrapper;
}

#pragma mark - Implementation

- (void)windowDidResize:(NSNotification *)notification {
    //self.inputTextField.frame = NSMakeRect(kPadding, kPadding, (self.window.frame.size.width/2)-kPadding, self.window.frame.size.height - (kPadding*2)-46);
    
    
    NSWindow *window = [notification object];
    [self layoutWindow:window];
    
}

- (void)layoutWindow:(NSWindow *)window {
    
    NSRect rect = [window contentRectForFrameRect:window.frame];
    self.inputTextField.frame = NSMakeRect(0, 0, (rect.size.width/2), rect.size.height);
    self.separatorView.frame = NSMakeRect((rect.size.width/2), 0, 1, rect.size.height);
    {
        self.webScrollView.frame = NSMakeRect(rect.size.width/2, 0, rect.size.width/2, rect.size.height);
        self.webScrollView.backgroundColor = [NSColor greenColor];
        
    }
    
    {
        float height = [self.previewWebView mainFrame].DOMDocument.body.boundingBox.size.height;
        NSRect frame = self.previewWebView.frame;
        frame.size.height = height < rect.size.height ? rect.size.height : height;
        frame.origin.y = 0;
        self.previewWebView.frame = frame;
        
        [[self.webScrollView documentView] setFrame:NSMakeRect(0, 0, rect.size.width/2, self.previewWebView.frame.size.height)];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self layoutWindow:[notification object]];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }
    else if (commandSelector == @selector(insertTab:)) {
        [textView insertTabIgnoringFieldEditor:self];
        result = YES;
    }
    return result;
}

- (void)monoTextViewDidUpdate:(MonoTextView *)textView {
    if (textView == self.inputTextField) {
        
        NSString *rawText = self.inputTextField.string;
        self.markdown = [rawText mutableCopy];
        
        rawText = [self handleObjects:rawText];
        rawText = [self handleIncludance:rawText];
        rawText = [self handleContents:rawText];
        rawText = [self stringByReplaceTabsInString:rawText withString:@"    "];
        NSString *html = [self generateHTMLMarkdownForString:rawText];
        /*
        float offsetY = [self.previewWebView.mainFrame.frameView.documentView.enclosingScrollView documentVisibleRect].origin.y;

        self.previewWebView.lastScrollY = offsetY;
        */
        [[self.previewWebView mainFrame] loadHTMLString:html baseURL:nil];
        
    }
}

- (NSString *)stringByReplaceTabsInString:(NSString *)string withString:(NSString *)replaceString {
    return [string stringByReplacingOccurrencesOfString:@"\t" withString:replaceString];
}

- (NSString *)generateHTMLMarkdownForString:(NSString *)text {
    
    /*
    NSString *css = @"body{font-family:Georgia, Palatino, serif;color:#444;line-height:1;max-width:960px;margin:0 auto;padding:10px 10px;}h1,h2,h3,h4{color:#111;font-weight:400;}h1,h2,h3,h4,h5,p{margin-bottom:24px;padding:0;}h1{font-size:48px;}h2{font-size:36px;margin:24px 0 6px;}h3{font-size:24px;}h4{font-size:21px;}h5{font-size:18px;}a{color:#09f;vertical-align:baseline;margin:0;padding:0;}a:hover{text-decoration:none;color:#f60;}a:visited{color:purple;}ul,ol{margin:0;padding:0;}li{line-height:24px;}li ul,li ul{margin-left:24px;}p,ul,ol{font-size:16px;line-height:24px;max-width:540px;}code,pre{font-family:Monaco, Andale Mono, Courier New, monospace;}code{background-color:#fee9cc;color:rgba(0,0,0,0.75);font-size:12px;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px;padding:1px 3px;}pre{display:block;line-height:16px;font-size:13px;border:1px solid #d9d9d9;white-space:pre-wrap;word-wrap:break-word;margin:0 0 18px;padding:14px;}pre code{background-color:#fff;color:#737373;font-size:13px;padding:0;}aside{display:block;float:right;width:390px;}blockquote{border-left:.5em solid #eee;margin-left:0;max-width:476px;padding:0 2em;}blockquote cite{font-size:14px;line-height:20px;color:#bfbfbf;}blockquote cite:before{content:'\\2014 \\00A0';}blockquote p{color:#666;max-width:460px;}hr{width:540px;text-align:left;color:#999;margin:0 auto 0 0;}button,input,select,textarea{font-size:100%;vertical-align:middle;margin:0;}button,input{line-height:normal;overflow:visible;}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0;}button,input[type=button],input[type=reset],input[type=submit]{cursor:pointer;-webkit-appearance:button;}input[type=checkbox],input[type=radio]{cursor:pointer;margin-bottom:0;}input:not([type=image]),textarea{-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;}input[type=search]{-webkit-appearance:textfield;-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;}input[type=search]::-webkit-search-decoration{-webkit-appearance:none;}label,input,select,textarea{font-family:\"Helvetica Neue\", Helvetica, Arial, sans-serif;font-size:13px;font-weight:400;line-height:normal;margin-bottom:18px;}input[type=text],input[type=password],textarea,select{display:inline-block;width:210px;font-size:13px;font-weight:400;line-height:18px;height:18px;color:gray;border:1px solid #ccc;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px;padding:4px;}select,input[type=file]{height:27px;line-height:27px;}textarea{height:auto;}input[type=text],input[type=password],select,textarea{-webkit-transition:border linear .2s box-shadow linear .2s;-moz-transition:border linear .2s box-shadow linear .2s;transition:border linear .2s box-shadow linear .2s;-webkit-box-shadow:inset 0 1px 3px rgba(0,0,0,0.1);-moz-box-shadow:inset 0 1px 3px rgba(0,0,0,0.1);box-shadow:inset 0 1px 3px rgba(0,0,0,0.1);}input[type=text]:focus,input[type=password]:focus,textarea:focus{outline:none;-webkit-box-shadow:inset 0 1px 3px rgba(0,0,0,0.1), 0 0 8px rgba(82,168,236,0.6);-moz-box-shadow:inset 0 1px 3px rgba(0,0,0,0.1), 0 0 8px rgba(82,168,236,0.6);box-shadow:inset 0 1px 3px rgba(0,0,0,0.1), 0 0 8px rgba(82,168,236,0.6);border-color:rgba(82,168,236,0.8);}button{display:inline-block;font-family:\"Helvetica Neue\", Helvetica, Arial, sans-serif;font-size:13px;line-height:18px;-webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;-webkit-box-shadow:inset 0 1px 0 rgba(255,255,255,0.2), 0 1px 2px rgba(0,0,0,0.05);-moz-box-shadow:inset 0 1px 0 rgba(255,255,255,0.2), 0 1px 2px rgba(0,0,0,0.05);box-shadow:inset 0 1px 0 rgba(255,255,255,0.2), 0 1px 2px rgba(0,0,0,0.05);background-color:#0064cd;background-repeat:repeat-x;background-image:linear-gradient(top,#049cdb,#0064cd);color:#fff;text-shadow:0 -1px 0 rgba(0,0,0,0.25);border:1px solid #004b9a;-webkit-transition:.1s linear all;-moz-transition:.1s linear all;transition:.1s linear all;border-color:rgba(0,0,0,0.1) rgba(0,0,0,0.1) rgba(0,0,0,0.25);padding:4px 14px;}button:hover{color:#fff;background-position:0 -15px;text-decoration:none;}button:active{-webkit-box-shadow:inset 0 3px 7px rgba(0,0,0,0.15), 0 1px 2px rgba(0,0,0,0.05);-moz-box-shadow:inset 0 3px 7px rgba(0,0,0,0.15), 0 1px 2px rgba(0,0,0,0.05);box-shadow:inset 0 3px 7px rgba(0,0,0,0.15), 0 1px 2px rgba(0,0,0,0.05);}button::-moz-focus-inner{border:0;padding:0;}:-moz-placeholder,::-webkit-input-placeholder{color:#bfbfbf;}";
    */
    NSString *css = @"html{font-size:100%;overflow-y:scroll;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}body{color:#444;font-family:'Helvetica Neue', Helvetica, Arial;font-size:14px;line-height:1.5em;max-width:100%;background:#fefefe;margin:auto;padding:1em;}a{color:#0645ad;text-decoration:none;}a:visited{color:#0b0080;}a:hover{color:#06e;}a:active{color:#faa700;}a:focus{outline:thin dotted;}a:hover,a:active{outline:0;}p{margin:1em 0;}img{max-width:100%;border:0;-ms-interpolation-mode:bicubic;vertical-align:middle;}h1,h2,h3,h4,h5,h6{font-weight:800;color:#111;line-height:1em;}h1{font-size:2.5em;}h2{font-size:2em;}h3{font-size:1.5em;}h4{font-size:1.2em;}h5{font-size:1em;}h6{font-size:.9em;}blockquote{color:#666;padding-left:3em;border-left:.5em #EEE solid;margin:0;}hr{display:block;height:2px;border:0;border-top:1px solid #aaa;border-bottom:1px solid #eee;margin:1em 0;padding:0;}dfn{font-style:italic;}ins{background:#ff9;color:#000;text-decoration:none;}mark{background:#ff0;color:#000;font-style:italic;font-weight:700;}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline;}sup{top:-.5em;}sub{bottom:-.25em;}ul,ol{margin:1em 0;padding:0 0 0 2em;}li p:last-child{margin:0;}dd{margin:0 0 0 2em;}table{border-collapse:collapse;border-spacing:0;}td{vertical-align:top;}::-moz-selection,::selection{background:rgba(255,255,0,0.3);color:#000;}a::-moz-selection,a::selection{background:rgba(255,255,0,0.3);color:#0645ad;}h4,h5,h6,b,strong{font-weight:700;}@media only screen and min-width 480px{body{font-size:14px;}}@media only screen and min-width 768px{body{font-size:16px;}}@media print{*{background:transparent!important;color:#000!important;filter:none!important;-ms-filter:none!important;}body{font-size:12pt;max-width:100%;}a,a:visited{text-decoration:underline;}hr{height:1px;border:0;border-bottom:1px solid #000;}a[href]:after{content:\" (\" attr(href) \")\";}abbr[title]:after{content:\" (\" attr(title) \")\";}.ir a:after,a[href^=javascript:]:after,a[href^=#]:after{content:"";}pre,blockquote{border:1px solid #999;padding-right:1em;page-break-inside:avoid;}tr,img{page-break-inside:avoid;}img{max-width:100%!important;}p,h2,h3{orphans:3;widows:3;}h2,h3{page-break-after:avoid;}}code,pre{font-family:Monaco, Andale Mono, Courier New, monospace;}code{background-color:#fee9cc;color:rgba(0,0,0,0.75);font-size:12px;-webkit-border-radius:3px;-moz-border-radius:3px;border-radius:3px;padding:1px 3px;}pre{display:block;line-height:16px;font-size:13px;border:1px solid #d9d9d9;white-space:pre-wrap;word-wrap:break-word;margin:0 0 18px;padding:14px;}pre code{background-color:#fff;color:#737373;font-size:13px;padding:0;}";
    
    return [NSString stringWithFormat:@"<style>%@</style><body>%@</body>", css, text.flavoredHTMLStringFromMarkdown];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    
    return YES;
}

- (IBAction)redo:(id)sender {
    [[self undoManager] redo];
}

- (NSString *)handleObjects:(NSString *)rawText {
    
    NSError *error = nil;
    
    // Check for includes
    // { } - creation
    {
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:kObjectCreationRegEx options:NSRegularExpressionCaseInsensitive error:&error];
        
        if (!error) {
            //NSMatchingOptions
            NSArray *matches = [regexp matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
            if (matches.count > 0) {
                
                NSMutableArray *objects = [NSMutableArray array];
                
                int i = (int)matches.count;
                while (i) {
                    i--;
                    
                    NSTextCheckingResult *match = matches[i];
                    NSRange fullRange = [match rangeAtIndex:1];
                    /*
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
                    */
                    
                    NSString *fullObject = [rawText substringWithRange:fullRange];
                    
                    // Fetch name
                    NSRegularExpression *nameRegEx = [NSRegularExpression regularExpressionWithPattern:kObjectCreationNameRegEx options:NSRegularExpressionCaseInsensitive error:&error];
                    NSString *name = nil;
                    if (!error) {
                        NSArray *nameMatches = [nameRegEx matchesInString:fullObject options:0 range:NSMakeRange(0, fullObject.length)];
                        if (nameMatches.count > 0) {
                            
                            NSTextCheckingResult *nameMatch = nameMatches[0];
                            NSRange nameRange = [nameMatch rangeAtIndex:1];
                            name = [fullObject substringWithRange:nameRange];
                        }
                        else {
                            return rawText;
                        }
                    }
                    
                    error = nil;
                    NSRegularExpression *bodyRegEx = [NSRegularExpression regularExpressionWithPattern:kObjectCreationObjectRegEx options:NSRegularExpressionCaseInsensitive error:&error];
                    NSString *body = nil;
                    
                    if (!error) {
                        NSArray *bodyMatches = [bodyRegEx matchesInString:fullObject options:0 range:NSMakeRange(0, fullRange.length)];
                        if (bodyMatches.count > 0) {
                            
                            NSTextCheckingResult *bodyMatch = bodyMatches[0];
                            NSRange bodyRange = [bodyMatch rangeAtIndex:1];
                            body = [fullObject substringWithRange:bodyRange];
                            
                            body = [self handleIncludance:body];
                        }
                        else {
                            return rawText;
                        }
                    }
                    
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
                        [self.dataTypesDictionary removeObjectForKey:key];
                    }
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

- (NSString *)handleContents:(NSString *)rawText {
    NSError *error = nil;
    
    // Check for includes
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:kObjectContentRegEx options:NSRegularExpressionCaseInsensitive error:&error];
    if (!error) {
        NSArray *matches = [regexp matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
        
        int i = (int)matches.count;
        while (i) {
            i--;
            
            NSTextCheckingResult *match = matches[i];
            NSRange fullRange = [match rangeAtIndex:0];
            NSRange methodRange = [match rangeAtIndex:3];
            
            NSString *method = [rawText substringWithRange:methodRange];
            
            if (method && [self.dataTypesDictionary objectForKey:method]) {
                
                DataObject *dataObject = [self.dataTypesDictionary objectForKey:method];
                NSString *body = dataObject.body;
                
                NSRange firstCurlyBrace = [body rangeOfString:@"{"];
                if (firstCurlyBrace.location != NSNotFound) {
                    body = [body stringByReplacingCharactersInRange:firstCurlyBrace withString:@""];
                }
                
                NSRange lastCurlyBrace = [body rangeOfString:@"}" options:NSBackwardsSearch];
                if (lastCurlyBrace.location != NSNotFound) {
                    body = [body stringByReplacingCharactersInRange:lastCurlyBrace withString:@""];
                }
                
                body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                rawText = [rawText stringByReplacingCharactersInRange:fullRange withString:body];
            }
        }
    }
    
    return rawText;
}


@end
