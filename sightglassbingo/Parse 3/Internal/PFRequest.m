//
//  PFRequest.m
//  Parse
//
//  Created by Ilya Sukhar on 6/19/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import "PFRequest.h"

@implementation PFRequest
@synthesize command;

- (void)requestFinished {    
    [self.command processResult:[PFInternalUtils deserializeFromJSON:[self responseString]]];
}

- (void)failWithError:(NSError *)newError {
    [self.command processError:[NSError errorWithDomain:@"Parse" code:kPFErrorConnectionFailed userInfo:nil]];
}

- (id)returnedValue {
    return [self.command returnedValue];
}

- (void)dealloc {
    self.command = nil;
    [super dealloc];
}

- (void)buildAndSignPostBody {
    for (NSString *key in self.command.params) {
        [self setPostValue:[self.command.params objectForKey:key] forKey:key];
    }    
    
    // This also ensures that posts are not empty, which would break various things
    [self setPostValue:[NSString stringWithFormat:@"i%@", PARSE_VERSION] forKey:@"v"];
    
    [self buildPostBody];
    
    NSString *header = PF_OAuthorizationHeader([self url],
                                               [self requestMethod], 
                                               [self postBody], 
                                               APPLICATION_ID, 
                                               CLIENT_KEY, 
                                               nil,
                                               nil);
    
    [self addRequestHeader:@"Authorization" value:header];
}

+ (PFRequest *)createRequestFromCommand:(PFCommand *)command {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%i/%@", PARSE_SERVER, PARSE_API_VERSION, command.operation]];
    
    PFRequest *request = [PFRequest requestWithURL:url];
    [request setRequestMethod:@"POST"];
    [request setShouldAttemptPersistentConnection:YES];
    request.command = command;
    [request buildAndSignPostBody];
    
    return request;
}

@end
