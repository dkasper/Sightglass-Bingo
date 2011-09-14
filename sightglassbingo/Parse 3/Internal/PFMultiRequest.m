//
//  PFMultiRequest.m
//  Parse
//
//  Created by Ilya Sukhar on 6/24/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import "PFMultiRequest.h"


@implementation PFMultiRequest
@synthesize commands;
@synthesize resultTarget, resultSelector;

- (void)requestFinished {
    NSDictionary *topLevelResult = [PFInternalUtils deserializeFromJSON:[self responseString]];
    NSArray *results = [topLevelResult objectForKey:@"result"];
    
    if (!results) {
        [self failWithError:[PFInternalUtils handleError:topLevelResult]];        
        return;
    }
    
    int i = 0;
    for (NSDictionary *result in results) {
        NSDictionary *syntheticResult = [NSMutableDictionary dictionaryWithObjectsAndKeys:result, @"result", nil];
        PFCommand *processCommand = [self.commands objectAtIndex:i];
        [processCommand processResult:syntheticResult];

        if (processCommand.error) {
            [self failWithError:processCommand.error];
            return;
        }
            
        i += 1;
    }
    
    if (self.resultTarget && [self.resultTarget respondsToSelector:self.resultSelector]) {
        [self.resultTarget performSelector:self.resultSelector withObject:nil];
    }
}

- (void)failWithError:(NSError *)newError {
    NSError *connectionError = [NSError errorWithDomain:@"Parse" code:kPFErrorConnectionFailed userInfo:nil];
    
    for (PFCommand *commandToNotify in self.commands) {
        [commandToNotify processError:connectionError];
    }
    
    if (self.resultTarget && [self.resultTarget respondsToSelector:self.resultSelector]) {
        [self.resultTarget performSelector:self.resultSelector withObject:connectionError];
    }
}

- (void)buildAndSignPostBody {
    NSMutableArray *serializedCommands = [[[NSMutableArray alloc] init] autorelease];
    
    for (PFCommand *commandToSerialize in self.commands) {
        NSMutableDictionary *serializedCommand = [[NSMutableDictionary alloc] init];
        [serializedCommand setObject:commandToSerialize.operation forKey:@"op"];
        [serializedCommand setObject:commandToSerialize.params forKey:@"params"];
        [serializedCommands addObject:serializedCommand];
        [serializedCommand release];
    }
    
    [self setPostValue:[PFInternalUtils serializeToJSON:serializedCommands] forKey:@"commands"];
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

- (void)dealloc {
    self.commands = nil;
    [super dealloc];
}

+ (PFMultiRequest *)createRequestFromCommands:(NSArray *)commands {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%i/%@", PARSE_SERVER, PARSE_API_VERSION, @"multi"]];

    PFMultiRequest *request = [PFMultiRequest requestWithURL:url];
    request.commands = commands;
    [request buildAndSignPostBody];
    
    return request;
}

@end
