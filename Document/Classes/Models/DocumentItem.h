//
//  DocumentItem.h
//  Menter
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Document; 
@interface DocumentItem : NSObject <NSCoding>

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, weak) Document *document;

@end
