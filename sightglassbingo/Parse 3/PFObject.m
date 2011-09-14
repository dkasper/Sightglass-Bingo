// PFObject.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import "PFObject.h"
#import "PFObjectPrivate.h"
#import "PFQuery.h"

#define PARSE_DATA_DIRECTORY @"Parse/"

@implementation PFObject (Private)

// Validations that are done on delete. For now, there is nothing.
- (void)checkDeleteParams {
    return;
}

// Validations that are done on save. For now, there is nothing.
- (void)checkSaveParams {
    return;
}

- (void)mergeFromResult:(NSDictionary *)result {
    objectId = [[result objectForKey:@"id"] copy];
    updatedAt = [[PFInternalUtils dateFromString:[result objectForKey:@"updated_at"]] retain]; 
    createdAt = [[PFInternalUtils dateFromString:[result objectForKey:@"created_at"]] retain];       
    
    data = [[NSMutableDictionary alloc] initWithDictionary:[result objectForKey:@"data"] copyItems:YES];
    pointers = [[NSMutableDictionary alloc] init];
    
    NSDictionary *newPointers = [result objectForKey:@"pointers"];
    for (NSString *key in newPointers) {
        [data removeObjectForKey:key];
        
        NSArray *serializedPFPointer = [newPointers objectForKey:key];
        
        PFPointer *pointer = [[PFPointer alloc] initWithClassName:[serializedPFPointer objectAtIndex:0] objectId:[serializedPFPointer objectAtIndex:1]];
        
        [pointers setObject:pointer forKey:key];
        [pointer release];
    }
}

// Validates a class name.

+ (void)validateClassName:(NSString *)aClassName {
    if ([aClassName hasPrefix:@"_"]) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid class name. Class names cannot start with an underscore."];
    }
}

// The data file that we save data to

+ (NSString *)dataFilePath:(NSString *)filename {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    // Create the Parse directory if needed
    NSString *parseDirPath = [documentsDirectory stringByAppendingPathComponent:PARSE_DATA_DIRECTORY];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:parseDirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parseDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
	return [documentsDirectory stringByAppendingPathComponent:[PARSE_DATA_DIRECTORY stringByAppendingString:filename]];
}

// Serializes the object to the data file

- (void)serializeToDataFile:(NSString *)filename {
    NSMutableDictionary *serialized = [self serialize];
    NSString *serializedJson = [PFInternalUtils serializeToJSON:serialized];
    //NSMutableDictionary *serializedDataToSave = [[[NSMutableDictionary alloc] init] autorelease];
    
    //[serializedDataToSave setObject:serializedJson forKey:key];
    
	//[serializedDataToSave writeToFile:[PFObject dataFilePath:@"parse_data"] atomically:YES];
    [serializedJson writeToFile:[[self class] dataFilePath:filename] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Deletes a data file

+ (void)deleteDataFile:(NSString *)filename {
    [[NSFileManager defaultManager] removeItemAtPath:[self dataFilePath:filename] error:nil];
}

// Initializes a PFObject from a data file

- (id)initFromDataFile:(NSString *)filename {
    //NSMutableDictionary *fileData = [[NSMutableDictionary alloc] initWithContentsOfFile:[PFObject dataFilePath:@"parse_data"]];
    //if (!fileData) { return nil; }
    
    NSString *jsonData = [NSString stringWithContentsOfFile:[[self class] dataFilePath:filename] encoding:NSUTF8StringEncoding error:nil];
    
    if (jsonData) { 
        NSMutableDictionary *result = [PFInternalUtils deserializeFromJSON:jsonData];
        self = [self initWithClassName:[result objectForKey:@"classname"] result:result];
        return self;
    } else {
        return nil;
    }
}

// Serializes the object to a NSDictionary, suitable to be turned into JSON or saved to a file
// NOTE: do not call this on a PFObject that hasn't already had all children saved. This assumes all
// child pointers already have a pointer that can be resolved.
//
// This is fundamental method we use to serialize to disk, or send as JSON.

- (NSMutableDictionary *)serialize {
	NSMutableDictionary *dataToSerialize = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *pointersToSerialize = [[[NSMutableDictionary alloc] initWithDictionary:pointers copyItems:YES] autorelease];
	NSMutableDictionary *serialized = [[[NSMutableDictionary alloc] init] autorelease];
	
    // Serialize all the data keys
	for (NSString *key in data) {
        id object = [data objectForKey:key];
        if ([object isKindOfClass:[PFObject class]]) {
            if (![(PFObject *)object address]) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Cannot serialize an object which has unsaved child objects."]; 
            }
            [pointersToSerialize setObject:[(PFObject *)object address]
                                    forKey:key];
        } else {
            NSDictionary *serializedDictionary = [PFInternalUtils encodeObjectIntoDictionary:object];
            
            if (serializedDictionary) {
                [dataToSerialize setObject:serializedDictionary forKey:key];
            } else {
                [dataToSerialize setObject:object forKey:key];
            }
        }
    }
    
    // Serialize the timestamps.
    if (createdAt) {
        [serialized setObject:[PFInternalUtils stringFromDate:createdAt] forKey:@"created_at"];
    }
    
    if (updatedAt) {
        [serialized setObject:[PFInternalUtils stringFromDate:updatedAt] forKey:@"updated_at"];
    }
	
	[serialized setObject:className            forKey:@"classname"];
    [serialized setObject:dataToSerialize      forKey:@"data"];
    [serialized setObject:pointersToSerialize  forKey:@"pointers"];
	
    if (self.objectId) {
        [serialized setObject:self.objectId forKey:@"id"];
    }
	
	return serialized;
}

- (PFCommand *)constructSaveCommand {
    NSString *operation;
	
	NSMutableDictionary *params = [self serialize];
    
    if ([deletedKeys count] > 0) {
        [params setObject:[PFInternalUtils serializeToJSON:[deletedKeys allObjects]] forKey:@"deleted"];
    }
    
    // Never send timestamp data, which can never be updated via the client
    [params removeObjectForKey:@"created_at"];
    [params removeObjectForKey:@"updated_at"];
    
    // JSON-ify the data and pointer fields
    [params setObject:[PFInternalUtils serializeToJSON:[params objectForKey:@"data"]] forKey:@"data"];
    [params setObject:[PFInternalUtils serializeToJSON:[params objectForKey:@"pointers"]] forKey:@"pointers"];
    
    if ([params objectForKey:@"id"]) {
        operation = @"update";
    } else {
        operation = @"create";
    }
    
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(handleSaveResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleSaveResultForCommand:result:error:)];

    PFCommand *command = [PFCommand createCommandWithOperation:operation params:params];
    [command setInternalCallback:internalCallback andRetain:self];
    
    return command;
}

- (PFCommand *)constructRefreshCommand {
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    
    [params setObject:className forKey:@"classname"];
    [params setObject:objectId forKey:@"id"];
    
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(handleRefreshResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleRefreshResultForCommand:result:error:)];
    
    PFCommand *command = [PFCommand createCommandWithOperation:@"get" params:params];
    [command setInternalCallback:internalCallback andRetain:self];
    
    return command;
}

- (PFCommand *)constructDeleteCommand {
    if (!self.objectId) { return nil; }
    
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    
    [params setObject:self.objectId    forKey:@"id"];
    [params setObject:className        forKey:@"classname"];
    
    NSMethodSignature *handlerSignature = [[self class]
                                           instanceMethodSignatureForSelector:@selector(handleDeleteResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleDeleteResultForCommand:result:error:)];
    
    PFCommand *deleteCommand = [PFCommand createCommandWithOperation:@"delete" params:params];
    [deleteCommand setInternalCallback:internalCallback andRetain:self];

    return deleteCommand;
}

- (void)runCommandAndSaveChildrenInBackgroundWithTarget:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector {
    if (!dirty) {
        [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:[NSNumber numberWithBool:YES] error:nil];
        return;
    }
    
    if ([self countChildren] > 0) {
        NSMethodSignature *saveChildrenSignature = [[self class]
                                                    instanceMethodSignatureForSelector:@selector(saveChildrenInBackground:selector:commandSelector:)];
        NSInvocation *saveChildren = [NSInvocation invocationWithMethodSignature:saveChildrenSignature];
        [saveChildren setTarget:self];
        [saveChildren setSelector:@selector(saveChildrenInBackground:selector:commandSelector:)];
        
        [saveChildren setArgument:&target atIndex:2];
        [saveChildren setArgument:&selector atIndex:3];
        [saveChildren setArgument:&commandSelector atIndex:4];
        
        [saveChildren performSelectorInBackground:@selector(invoke) withObject:nil];
    } else {
        [self doneSavingChildrenInBackground:target selector:selector commandSelector:commandSelector];
    }
}

- (id)handleSaveResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"] || ![result objectForKey:@"result"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return [NSNumber numberWithBool:NO];
    }
    
    NSDictionary *actualResult = [result objectForKey:@"result"];

    if (([saveCommand.operation isEqualToString:@"create"]) || ([saveCommand.operation isEqualToString:@"user_signup"])) {
        objectId = [[actualResult objectForKey:@"id"] copy];
        updatedAt = [[PFInternalUtils dateFromString:[actualResult objectForKey:@"updated_at"]] retain]; 
        createdAt = [[PFInternalUtils dateFromString:[actualResult objectForKey:@"created_at"]] retain]; 
    } else {
        [updatedAt release];
        updatedAt = [[PFInternalUtils dateFromString:[actualResult objectForKey:@"updated_at"]] retain];
    }
    
    [deletedKeys release];
    deletedKeys = [[NSMutableSet alloc] init];
    
    dirty = NO;
    return [NSNumber numberWithBool:YES];
}

- (id)handleRefreshResultForCommand:(PFCommand *)refreshCommand result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return nil;
    } else {
        NSDictionary *resultObject = [result objectForKey:@"result"];

        [objectId release];
        [updatedAt release];
        [createdAt release];
        [pointers release];
        [data release];
        [deletedKeys removeAllObjects];

        [self mergeFromResult:resultObject];
        return self;
    }
}

- (int)countChildren {
    int i = 0;
    
    for (NSString *key in data) {
        id object = [data objectForKey:key];
        if ([object isKindOfClass:[PFObject class]]) {
            i += 1;
        }
    }
    
    return i;
}



- (BOOL)hasDirtyChildren {
    for (NSString *key in data) {
        id object = [data objectForKey:key];
        if ([object isKindOfClass:[PFObject class]] && [object isDirty]) {
            return YES;
        }
    }
    
    return NO;
}

// TODO(ilya): Convert this to a more elegant solution when we switch over to using blocks.
- (BOOL)saveChildren:(NSError **)error {
    for (NSString *key in data) {
        id object = [data objectForKey:key];
        if ([object isKindOfClass:[PFObject class]]) {
            NSError *childError;
            
            BOOL saveSuccess = [(PFObject *)object save:&childError];
            
            if (!saveSuccess) {
                if (error) { *error = childError; }
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)saveChildrenInBackground:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    
    BOOL saveSuccess = [self saveChildren:&error];
    
    if (!saveSuccess) {
        if (target && [target respondsToSelector:selector]) {  
            NSNumber *fakeNumber = nil;    
            [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:fakeNumber error:error];
        }
    } else {
        NSMethodSignature *saveSignature = [[self class]
                                            instanceMethodSignatureForSelector:@selector(doneSavingChildrenInBackground:selector:commandSelector:)];
        NSInvocation *save = [NSInvocation invocationWithMethodSignature:saveSignature];
        [save setTarget:self];
        [save setSelector:@selector(doneSavingChildrenInBackground:selector:commandSelector:)];
        
        [save setArgument:&target atIndex:2];
        [save setArgument:&selector atIndex:3];
        [save setArgument:&commandSelector atIndex:4];
        
        [save performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)doneSavingChildrenInBackground:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector {
    PFCommand *command = [self performSelector:commandSelector];
    command.resultSelector = selector;
    command.resultTarget = target;

    [[self class] sendAsyncRequestForCommand:command];
}

- (id)handleDeleteResultForCommand:(PFCommand *)deleteCommand result:(NSDictionary *)result error:(NSError **)error {
    dirty = YES;
    
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return [NSNumber numberWithBool:NO];
    }
    
    return [NSNumber numberWithBool:YES];
}

+ (void)sendAsyncRequestForCommand:(PFCommand *)command {
    PFRequest *request = [PFRequest createRequestFromCommand:command];
    [request startAsynchronous];
}

- (BOOL)sendSyncRequestForCommand:(PFCommand *)command withError:(NSError **)error {
    PFRequest *request = [PFRequest createRequestFromCommand:command];
    [request startSynchronous];
    
    NSError *newError = [command error];
    
    if (newError) {
        if (error) { *error = newError; }        
        return NO;
    } else {
        return YES;
    }    
}

#if NS_BLOCKS_AVAILABLE
- (void)doneSavingChildrenInBackgroundWithBlock:(PFBooleanResultBlock)block commandSelector:(SEL)commandSelector {
    PFCommand *command = [self performSelector:commandSelector];
    command.booleanResultBlock = block;
    
    [[self class] sendAsyncRequestForCommand:command];
}

- (void)runCommandAndSaveChildrenInBackgroundWithBlock:(PFBooleanResultBlock)block commandSelector:(SEL)commandSelector {
    if (!dirty) {
        [PFInternalUtils callBooleanResultBlockOnMainThread:block withResult:YES error:nil];
        return;
    }
    
    if ([self countChildren] > 0) {
        NSMethodSignature *saveChildrenSignature = [[self class]
                                                    instanceMethodSignatureForSelector:@selector(saveChildrenInBackgroundWithBlock:commandSelector:)];
        NSInvocation *saveChildren = [NSInvocation invocationWithMethodSignature:saveChildrenSignature];
        [saveChildren setTarget:self];
        [saveChildren setSelector:@selector(saveChildrenInBackgroundWithBlock:commandSelector:)];
        
        [saveChildren setArgument:&block atIndex:2];
        [saveChildren setArgument:&commandSelector atIndex:3];
        
        [saveChildren performSelectorInBackground:@selector(invoke) withObject:nil];
    } else {
        [self doneSavingChildrenInBackgroundWithBlock:block commandSelector:commandSelector];
    }
}
#endif

- (NSString *)displayObjectId {
    return objectId ? objectId : @"new";
}

- (NSString *)displayClassName {
    return className;
}

@end

@implementation PFObject
@synthesize objectId;
@synthesize updatedAt;
@synthesize createdAt;

- (id) initWithClassName:(NSString *)newClassName {
    [[self class] validateClassName:newClassName];
    
    self = [super init];
    if (self != nil) {
        pointers = [[NSMutableDictionary alloc] init];
        data = [[NSMutableDictionary alloc] init];
        deletedKeys = [[NSMutableSet alloc] init];
        className = [newClassName retain];
        objectId = nil;
        updatedAt = nil;
        createdAt = nil;
        dirty = YES;
    }
    return self;
}

- (id)initWithClassName:(NSString *)newClassName
              result:(NSDictionary *)result {
    [[self class] validateClassName:newClassName];
    
    self = [super init];
    if (self != nil) {
        className = [newClassName copy];
        deletedKeys = [[NSMutableSet alloc] init];
        [self mergeFromResult:result];
        dirty = NO;
    }
    return self;
}

- (PFPointer *)address {
    if (self.objectId) {
        return [[[PFPointer alloc] initWithClassName:className objectId:self.objectId] autorelease];
    }
        
    return nil;
}

- (BOOL)delete {
    return [self delete:nil];
}

- (BOOL)delete:(NSError **)error {
    [self checkDeleteParams];
    PFCommand *deleteCommand = [self constructDeleteCommand];
    if (!deleteCommand) { return YES; }
    return [self sendSyncRequestForCommand:deleteCommand withError:error];
}

- (void)deleteInBackground {
    [self deleteInBackgroundWithTarget:nil selector:nil];
}

- (void)deleteInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self checkDeleteParams];
    PFCommand *deleteCommand = [self constructDeleteCommand];
    
    if (!deleteCommand) {
        [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:[NSNumber numberWithBool:YES] error:nil];
        return;
    }
    
    deleteCommand.resultTarget = target;
    deleteCommand.resultSelector = selector;
    
    [[self class] sendAsyncRequestForCommand:deleteCommand];
}

- (BOOL)save {
    return [self save:nil];
}

- (BOOL)save:(NSError **)error {
    [self checkSaveParams];
    if (!dirty) { return YES; }    
    if (![self saveChildren:error]) { return NO; }
    
    return [self sendSyncRequestForCommand:[self constructSaveCommand] withError:error];
}

- (void)saveInBackground {
    [self saveInBackgroundWithTarget:nil selector:nil];    
}

- (void)saveInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self checkSaveParams];
    [self runCommandAndSaveChildrenInBackgroundWithTarget:target selector:selector commandSelector:@selector(constructSaveCommand)];
}

- (void)refresh {
    [self refresh:nil];
}

- (void)refresh:(NSError **)error {
    if (objectId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Can't refresh an object that hasn't been saved to the server."];
    }
    [self sendSyncRequestForCommand:[self constructRefreshCommand] withError:error];
}

- (void)refreshInBackgroundWithTarget:(id)target selector:(SEL)selector {
    if (objectId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Can't refresh an object that hasn't been saved to the server."];
    }
    
    PFCommand *refreshCommand = [self constructRefreshCommand];
    
    refreshCommand.resultTarget = target;
    refreshCommand.resultSelector = selector;
    
    [[self class] sendAsyncRequestForCommand:refreshCommand];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    if (object == nil || key == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Can't use nil for keys or values on PFObject. Use NSNull for values."];
    }
    
    [PFInternalUtils assertValidClassForValue:object];

    if ([deletedKeys containsObject:key]) {
        [deletedKeys removeObject:key];
    }
    
    [data setObject:object forKey:key];
    [pointers removeObjectForKey:key];    
    dirty = YES;    
}

- (id)objectForKey:(NSString *)key {
    id object = [data objectForKey:key];
    if (object) { return object; }
    
    PFPointer *pointer = [pointers objectForKey:key];
    if (!pointer) { return nil; }
    
    object = [PFQuery getObjectOfClass:[pointer className] objectId:[pointer objectId]];
    if (object) {
        [pointers removeObjectForKey:key];
        [data setObject:object forKey:key];
    }
    
    return object;
}

- (void)removeObjectForKey:(NSString *)key {
    id object = [data objectForKey:key];
    
    if (object) {
        [deletedKeys addObject:key];
        [data removeObjectForKey:key];
        dirty = YES;
        return;
    }
    
    PFPointer *pointer = [pointers objectForKey:key];
    if (pointer) {
        [deletedKeys addObject:key];
        [pointers removeObjectForKey:key];
        dirty = YES;
    }
}

- (BOOL)isDirty {
    return dirty || [self hasDirtyChildren];
}

+ (BOOL)saveAll:(NSArray *)objects {    
    return [PFObject saveAll:objects error:nil];
}

+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error {    
    NSMutableArray *commands = [[[NSMutableArray alloc] init] autorelease];
    
    for (PFObject *object in objects) {
        if ([object hasDirtyChildren]) {
            [NSException raise:NSInternalInconsistencyException format:@"Can't call saveAll with objects that have dirty children.", nil];
        }
        
        [object checkSaveParams];
        
        [commands addObject:[object constructSaveCommand]];
    }
    
    PFMultiRequest *request = [PFMultiRequest createRequestFromCommands:commands];
    
    [request startSynchronous];
    
    NSError *newError = nil;
    
    for (PFCommand *command in commands) {
        if ([command error]) {
            newError = [command error];
            break;
        }
    }
        
    if (newError) {
        if (error) { *error = newError; }        
        return NO;
    } else {
        return YES;
    }
}


+ (void)saveAllInBackground:(NSArray *)objects {
    [PFObject saveAllInBackground:objects withTarget:nil selector:nil];
}

+ (void)saveAllInBackground:(NSArray *)objects withTarget:(id)target selector:(SEL)selector {
    NSMutableArray *commands = [[[NSMutableArray alloc] init] autorelease];
    
    for (PFObject *object in objects) {
        if ([object hasDirtyChildren]) {
            [NSException raise:NSInternalInconsistencyException format:@"Can't call saveAll with objects that have dirty children.", nil];
        }
        
        [commands addObject:[object constructSaveCommand]];
    }
    
    PFMultiRequest *request = [PFMultiRequest createRequestFromCommands:commands];
    request.resultTarget = target;
    request.resultSelector = selector;
    [request startAsynchronous];
}

#if NS_BLOCKS_AVAILABLE


- (void)saveChildrenInBackgroundWithBlock:(PFBooleanResultBlock)block commandSelector:(SEL)commandSelector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSError *error = nil;
    
    BOOL saveSuccess = [self saveChildren:&error];
    
    if (!saveSuccess) {
        [PFInternalUtils callBooleanResultBlockOnMainThread:block withResult:NO error:error];
    } else {
        NSMethodSignature *saveSignature = [[self class]
                                            instanceMethodSignatureForSelector:@selector(doneSavingChildrenInBackgroundWithBlock:commandSelector:)];
        NSInvocation *save = [NSInvocation invocationWithMethodSignature:saveSignature];
        [save setTarget:self];
        [save setSelector:@selector(doneSavingChildrenInBackgroundWithBlock:commandSelector:)];
        
        [save setArgument:&block atIndex:2];
        [save setArgument:&commandSelector atIndex:3];
        
        [save performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
    
    [pool release];
}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self checkSaveParams];
    [self runCommandAndSaveChildrenInBackgroundWithBlock:block commandSelector:@selector(constructSaveCommand)];
}

- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self checkDeleteParams];
    PFCommand *deleteCommand = [self constructDeleteCommand];
    
    if (!deleteCommand) {
        [PFInternalUtils callBooleanResultBlockOnMainThread:block withResult:YES error:nil];
        return;
    }
    
    deleteCommand.booleanResultBlock = block;
    
    [[self class] sendAsyncRequestForCommand:deleteCommand];
}

- (void)refreshInBackgroundWithBlock:(PFObjectResultBlock)block {
    if (objectId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Can't refresh an object that hasn't been saved to the server."];
    }

    PFCommand *refreshCommand = [self constructRefreshCommand];
    
    refreshCommand.objectResultBlock = block;
    [[self class] sendAsyncRequestForCommand:refreshCommand];
}
#endif



- (NSString *)description {
    NSMutableDictionary *descriptionDict = [[[NSMutableDictionary alloc] initWithDictionary:data] autorelease];
    
    for (NSString *key in descriptionDict) {
        id value = [descriptionDict objectForKey:key];
        
        if ([value isKindOfClass:[PFObject class]]) {
            [descriptionDict setObject:[NSString stringWithFormat:@"<%@:%@>", 
                                        [value displayClassName], 
                                        [value displayObjectId],
                                        nil]
                                forKey:key];
        }
    }
    
    return [NSString stringWithFormat:@"<%@:%@> %@",
            [self displayClassName],
            [self displayObjectId],
            [descriptionDict description]];
}

- (void)dealloc {
    [objectId release];
    [updatedAt release];
    [createdAt release];
    [className release];
    [pointers release];
    [data release];
    [deletedKeys release];
    [super dealloc];
}

@end
