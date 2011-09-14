//
//  PFRequest.h
//  Parse
//
//  Created by Ilya Sukhar on 6/19/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFConstants.h"
#import "PF_OAuthCore.h"
#import "PF_ASIFormDataRequest.h"
#import "PFCommand.h"
#import "PFInternalUtils.h"

@interface PFRequest : PF_ASIFormDataRequest {    
    PFCommand *command;
}

@property (nonatomic, retain) PFCommand *command;

- (void)buildAndSignPostBody;
+ (PFRequest *)createRequestFromCommand:(PFCommand *)command;

@end

