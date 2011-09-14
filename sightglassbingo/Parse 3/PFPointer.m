// PFPointer.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import "PFPointer.h"


@implementation PFPointer
@synthesize objectId;
@synthesize className;

- (id) initWithClassName:(NSString *)newClassName objectId:(NSString *)newObjectId {
    self = [super init];
    if (self != nil) {
        self.objectId = newObjectId;
        self.className = newClassName;
    }
    return self;
}

- (id)proxyForJson {
    return [NSArray arrayWithObjects:self.className, self.objectId, nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%@>", className, objectId];
}

- (void)dealloc {
    self.objectId = nil;
    self.className = nil;
    [super dealloc];
}

@end