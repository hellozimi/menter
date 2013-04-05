//
//  Document.h
//  Menter
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface Document : NSDocument
- (IBAction)exportHTML:(id)sender;
- (IBAction)exportMarkdown:(id)sender;
@end
