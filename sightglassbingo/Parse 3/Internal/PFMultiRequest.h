//
//  PFMultiRequest.h
//  Parse
//
//  Created by Ilya Sukhar on 6/24/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFRequest.h"
#import "PFInternalUtils.h"

@interface PFMultiRequest : PFRequest {
    NSArray *commands;
    id resultTarget;
    SEL resultSelector;
}

@property (nonatomic, retain) NSArray *commands;

@property (assign) id resultTarget;
@property (assign) SEL resultSelector;

+ (PFMultiRequest *)createRequestFromCommands:(NSArray *)commands;

@end
