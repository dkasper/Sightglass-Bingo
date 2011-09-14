// PFObjectPrivate.h
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import <Foundation/Foundation.h>

#define USER_CLASS_NAME @"_User"

@interface PFObject (Private)

// Internal commands
- (PFCommand *)constructSaveCommand;
- (PFCommand *)constructDeleteCommand;
- (PFCommand *)constructRefreshCommand;

// Helpers
- (NSString *)displayClassName;
- (NSString *)displayObjectId;
- (int)countChildren;
- (BOOL)hasDirtyChildren;
- (void)runCommandAndSaveChildrenInBackgroundWithTarget:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector;
#if NS_BLOCKS_AVAILABLE
- (void)runCommandAndSaveChildrenInBackgroundWithBlock:(PFBooleanResultBlock)block commandSelector:(SEL)commandSelector;
#endif
- (BOOL)saveChildren:(NSError **)error;
- (void)saveChildrenInBackground:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector;
- (void)doneSavingChildrenInBackground:(id)target selector:(SEL)selector commandSelector:(SEL)commandSelector;
+ (void)validateClassName:(NSString *)aClassName;

// Validations
- (void)checkDeleteParams;
- (void)checkSaveParams;

// Serialization
+ (NSString *)dataFilePath:(NSString *)filename;
- (NSMutableDictionary *)serialize;
- (void)serializeToDataFile:(NSString *)filename;
- (id)initFromDataFile:(NSString *)filename;
+ (void)deleteDataFile:(NSString *)filename;
- (void)mergeFromResult:(NSDictionary *)result;

// Command handlers
- (id)handleSaveResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error;
- (id)handleDeleteResultForCommand:(PFCommand *)deleteCommand result:(NSDictionary *)result error:(NSError **)error;
- (id)handleRefreshResultForCommand:(PFCommand *)refreshCommand result:(NSDictionary *)result error:(NSError **)error;

// Requests
+ (void)sendAsyncRequestForCommand:(PFCommand *)command;
- (BOOL)sendSyncRequestForCommand:(PFCommand *)command withError:(NSError **)error;

@end
