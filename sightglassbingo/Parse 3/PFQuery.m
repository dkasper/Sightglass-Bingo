// PFQuery.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import "PFQuery.h"
#import "PFObject.h"
#import "PFUser.h"
#import "PFObjectPrivate.h"

@implementation PFQuery

@synthesize className;
@synthesize limit;
@synthesize order; // Deprecated

- (id) initWithClassName:(NSString *)newClassName {
    self = [super init];
    if (self != nil) {
        where = [[NSMutableDictionary alloc] init];
        self.className = newClassName;
    }
    return self;
}

- (void)sendAsyncRequestForCommand:(PFCommand *)command {
    PFRequest *request = [PFRequest createRequestFromCommand:command];
    [request startAsynchronous];    
}

- (id)sendSyncRequestForCommand:(PFCommand *)command withError:(NSError **)error {
    PFRequest *request = [PFRequest createRequestFromCommand:command];
    [request startSynchronous];
    
    NSError *newError = [command error];
    
    if (newError) {
        if (error) { *error = newError; }        
        return nil;
    } else {
        return [command returnedValue];
    }
}

- (void)orderByAscending:(NSString *)key {
    [key retain];
    [order release];
    order = key;
}

- (void) orderByDescending:(NSString *)key {
    [order release];
    order = [[NSString stringWithFormat:@"-%@", key] retain];
}

// Deprecated
- (void)whereObject:(id)object forKey:(NSString *)key {
    [self whereKey:key equalTo:object];
}

// Helper for condition queries.
- (void)whereKey:(NSString *)key condition:(NSString *)condition object:(id)object {
    NSMutableDictionary *whereValue = nil;
    
    // Check if we already have some sort of condition
    id existingCondition = [where objectForKey:key];
    if ([existingCondition isKindOfClass:[NSMutableDictionary class]]) {
        whereValue = existingCondition;
    }
    if (whereValue == nil) {
        whereValue = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [whereValue setObject:object forKey:condition];
    [where setObject:whereValue forKey:key];
}

- (void)whereKey:(NSString *)key equalTo:(id)object {
    [PFInternalUtils assertValidClassForQuery:object];    
    [where setObject:object forKey:key];
}

- (void)whereKey:(NSString *)key greaterThan:(id)object {
    [PFInternalUtils assertValidClassForOrdering:object];
    [self whereKey:key condition:@"$gt" object:object];
}

- (void)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object {
    [PFInternalUtils assertValidClassForOrdering:object];
    [self whereKey:key condition:@"$gte" object:object];
}

- (void)whereKey:(NSString *)key lessThan:(id)object {
    [PFInternalUtils assertValidClassForOrdering:object];
    [self whereKey:key condition:@"$lt" object:object];
}

- (void)whereKey:(NSString *)key lessThanOrEqualTo:(id)object {
    [PFInternalUtils assertValidClassForOrdering:object];
    [self whereKey:key condition:@"$lte" object:object];
}

- (void)whereKey:(NSString *)key notEqualTo:(id)object {
    [PFInternalUtils assertValidClassForQuery:object];
    [self whereKey:key condition:@"$ne" object:object];
}

- (PFCommand *)constructGetCommandWithId:(NSString *)objectId {
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    
    [params setObject:self.className    forKey:@"classname"];
    [params setObject:objectId          forKey:@"id"];
    
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(handleGetResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleGetResultForCommand:result:error:)];
    
    PFCommand *getCommand = [PFCommand createCommandWithOperation:@"get" params:params];
    [getCommand setInternalCallback:internalCallback andRetain:self];
    
    return getCommand;
}

- (PFCommand *)constructFindCommand {
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    
    if (self.order) {
        [params setObject:self.order forKey:@"order"];
    }
    
    if (self.limit) {
        [params setObject:[self.limit stringValue] forKey:@"limit"];
    }
    
    if ([where count] > 0) {
        NSMutableDictionary *whereData = [[[NSMutableDictionary alloc] init] autorelease];
        NSMutableDictionary *wherePointers = [[[NSMutableDictionary alloc] init] autorelease];
        
        for (NSString *key in where) {
            id object = [where objectForKey:key];
            
            if ([object isKindOfClass:[PFObject class]]) {
                PFObject *pfObject = (PFObject *)object;
                
                if ([pfObject address]) {
                    [wherePointers setObject:[pfObject address] forKey:key];
                }
            } else {
                [whereData setObject:object forKey:key];
            }
        }
        
        [params setObject:[PFInternalUtils serializeToJSON:wherePointers]   forKey:@"pointers"];
        [params setObject:[PFInternalUtils serializeToJSON:whereData]       forKey:@"data"];
    }
    
    [params setObject:self.className forKey:@"classname"];
    
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(handleFindResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleFindResultForCommand:result:error:)];
    
    PFCommand *findCommand = [PFCommand createCommandWithOperation:@"find" params:params];
    [findCommand setInternalCallback:internalCallback andRetain:self];
    
    return findCommand;
}

- (NSArray *)handleFindResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        
        return nil;
    } else {
        NSArray *resultObjects = [result objectForKey:@"result"];
        NSMutableArray *returnObjects = [[[NSMutableArray alloc] init] autorelease];
        
        for (NSDictionary *resultObject in resultObjects) {
            id object;
            if ([self.className isEqualToString:USER_CLASS_NAME]) {
                object = [[PFUser alloc] initWithClassName:self.className result:resultObject];
            } else {
                object = [[PFObject alloc] initWithClassName:self.className result:resultObject];
            }
            [returnObjects addObject:object];
            [object release];
        }
        
        return returnObjects;
    }
}

- (PFObject *)handleGetResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return nil;
    } else {
        id object;
        if ([self.className isEqualToString:USER_CLASS_NAME]) {
            object = [PFUser alloc];
        } else {
            object = [PFObject alloc];
        }
        return [[object initWithClassName:self.className
                                          result:[result objectForKey:@"result"]] autorelease];
    }
}


- (NSArray *)findObjects {
    return [self findObjects:nil];
}

- (NSArray *)findObjects:(NSError **)error {
    return [self sendSyncRequestForCommand:[self constructFindCommand] withError:error];
}

- (void)findObjectsInBackgroundWithTarget:(id)target selector:(SEL)selector {
    PFCommand *findCommand = [self constructFindCommand];
    findCommand.resultTarget = target;
    findCommand.resultSelector = selector;
    [self sendAsyncRequestForCommand:findCommand];
}

- (PFObject *)getObjectWithId:(NSString *)objectId {
    return [self getObjectWithId:objectId error:nil];
}

- (PFObject *)getObjectWithId:(NSString *)objectId error:(NSError **)error {
    if (!objectId) { return nil; }    
    return [self sendSyncRequestForCommand:[self constructGetCommandWithId:objectId] withError:error];
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId target:(id)target selector:(SEL)selector {
    PFCommand *getCommand = [self constructGetCommandWithId:objectId];
    getCommand.resultTarget = target;
    getCommand.resultSelector = selector;
    [self sendAsyncRequestForCommand:getCommand];
}

+ (PFObject *)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId {
    return [PFQuery getObjectOfClass:objectClass objectId:objectId error:nil];
}

+ (PFObject *)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId error:(NSError **)error {
    PFQuery *query = [[[PFQuery alloc] initWithClassName:objectClass] autorelease];
    PFObject *object = [query getObjectWithId:objectId error:error];
    
    return object;
}

+ (PFQuery *)queryWithClassName:(NSString *)className {
    return [[[PFQuery alloc] initWithClassName:className] autorelease];
}

+ (PFUser *)getUserObjectWithId:(NSString *)objectId {
    return [PFQuery getUserObjectWithId:objectId error:nil];
}

+ (PFUser *)getUserObjectWithId:(NSString *)objectId error:(NSError **)error {
    PFQuery *query = [[[PFQuery alloc] initWithClassName:USER_CLASS_NAME] autorelease];
    PFUser *object = (PFUser *)[query getObjectWithId:objectId error:error];
    
    return object;
}

+ (PFQuery *)queryForUser {
    return [[[PFQuery alloc] initWithClassName:USER_CLASS_NAME] autorelease];
}

#if NS_BLOCKS_AVAILABLE
- (void)findObjectsInBackgroundWithBlock:(PFArrayResultBlock)block {
    PFCommand *findCommand = [self constructFindCommand];
    findCommand.arrayResultBlock = block;
    [self sendAsyncRequestForCommand:findCommand];
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId block:(PFObjectResultBlock)block {
    PFCommand *getCommand = [self constructGetCommandWithId:objectId];
    getCommand.objectResultBlock = block;
    [self sendAsyncRequestForCommand:getCommand];
}
#endif

- (void)dealloc {
    self.className = nil;
    self.limit = nil;
    [order release];
    [where release];
    [super dealloc];
}

@end
