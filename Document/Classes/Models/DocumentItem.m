//
//  DocumentItem.m
//  Menter
//
//  Created by Simon Andersson on 3/31/13.
//  Copyright (c) 2013 hiddencode.me. All rights reserved.
//

#import "DocumentItem.h"

@implementation DocumentItem

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
    
	if (self)
	{
		self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
	}
    
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.fileName forKey:@"fileName"];
}

@end
