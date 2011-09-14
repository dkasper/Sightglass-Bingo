//
//  PFCommand.m
//  Parse
//
//  Created by Ilya Sukhar on 6/24/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import "PFCommand.h"


@implementation PFCommand
@synthesize params, operation, error;
@synthesize resultTarget, resultSelector;

#if NS_BLOCKS_AVAILABLE
@synthesize booleanResultBlock;
@synthesize arrayResultBlock;
@synthesize objectResultBlock;
@synthesize setResultBlock;
@synthesize userResultBlock;
#endif

- (void)processResult:(NSDictionary *)result {
    NSError *callbackError = nil;
    NSError **callbackErrorPointer = &callbackError;
        
    [internalCallback setArgument:&self atIndex:2];
    [internalCallback setArgument:&result atIndex:3];
    [internalCallback setArgument:&callbackErrorPointer atIndex:4];
    [internalCallback invoke];
    
    [internalCallback getReturnValue:&returnVal];
    [returnVal retain];
        
    if (self.resultTarget && [self.resultTarget respondsToSelector:self.resultSelector]) {
        [self.resultTarget performSelector:self.resultSelector withObject:returnVal withObject:callbackError];
    } 
#if NS_BLOCKS_AVAILABLE    
    else if (self.booleanResultBlock) {
        self.booleanResultBlock([returnVal boolValue], callbackError);
    } else if (self.arrayResultBlock) {
        self.arrayResultBlock(returnVal, callbackError);
    } else if (self.objectResultBlock) {
        self.objectResultBlock(returnVal, callbackError);
    } else if (self.setResultBlock) {
        self.setResultBlock(returnVal, callbackError);
    } else if (self.userResultBlock) {
        self.userResultBlock(returnVal, callbackError);
    }
#endif
    
    [objectToRetain release];
    
    if (callbackError) {
        self.error = callbackError;
    }    
}

- (void)processError:(NSError *)newError {
    self.error = newError;
    
    if (self.resultTarget && [self.resultTarget respondsToSelector:self.resultSelector]) {
        [self.resultTarget performSelector:self.resultSelector withObject:nil withObject:newError];
    }
    
    [objectToRetain release];
}

- (void)setInternalCallback:(NSInvocation *)callback andRetain:(id)object {
    if (internalCallback) {
        [internalCallback release];
    }
    
    if (objectToRetain) {
        [objectToRetain release];
    }
    
    internalCallback = callback;
    [internalCallback retain];
    
    objectToRetain = object;
    [objectToRetain retain];
}

- (void)useGenericBooleanCallback {
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(genericBooleanCallbackForCommand:result:error:)];
    NSInvocation *genericCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [genericCallback setTarget:self];
    [genericCallback setSelector:@selector(genericBooleanCallbackForCommand:result:error:)];

    [self setInternalCallback:genericCallback andRetain:nil];
}

- (id)genericBooleanCallbackForCommand:(PFCommand *)command result:(NSDictionary *)result error:(NSError **)passedError {
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (passedError) { *passedError = newError; }
        return [NSNumber numberWithBool:NO];
    }
    
    return [NSNumber numberWithBool:YES];
}

- (id)returnedValue {
    return returnVal;
}

- (void)dealloc {
    self.error = nil;
    self.params = nil;
    self.operation = nil;
    [internalCallback release];
    [returnVal release];
    [super dealloc];
}

+ (PFCommand *)createCommandWithOperation:(NSString *)operation params:(NSMutableDictionary *)params {
    PFCommand *command = [[[PFCommand alloc] init] autorelease];
    command.params = params;
    command.operation = operation;
    return command;
}

@end
