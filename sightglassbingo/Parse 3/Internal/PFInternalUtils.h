//
//  PFInternalUtils.h
//  Parse
//
//  Created by Ilya Sukhar on 6/19/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFConstants.h"
#import "PF_SBJsonWriter.h"
#import "PF_SBJsonParser.h"
#import "PF_Base64.h"

@interface PFInternalUtils : NSObject {
}

+ (void)initialize;
+ (NSError *)handleError:(NSDictionary *)result;

+ (NSString *)stringFromDate:(NSDate *)date;
+ (NSDate *)dateFromString:(NSString *)string;

+ (void)assertValidClassForValue:(id)object;
+ (void)assertValidClassForQuery:(id)object;
+ (void)assertValidClassForOrdering:(id)object;

+ (id)parseDictionaryIntoObject:(NSDictionary *)dictionary;
+ (NSDictionary *)encodeObjectIntoDictionary:(id)object;

+ (NSString *)serializeToJSON:(NSObject *)object;
+ (id)deserializeFromJSON:(NSString *)json;

+ (void)saveToKeychain:(NSString *)service data:(id)data;
+ (id)loadFromKeychain:(NSString *)service;
+ (void)deleteFromKeychain:(NSString *)service;

+ (void)callResultSelectorOnMainThread:(SEL)selector forTarget:(id)target withResult:(id)result error:(NSError *)error;

#if NS_BLOCKS_AVAILABLE
+ (void)callBooleanResultBlockOnMainThread:(PFBooleanResultBlock)block withResult:(BOOL)result error:(NSError *)error;
+ (void)callSetResultBlockOnMainThread:(PFSetResultBlock)block withResult:(NSSet *)result error:(NSError *)error;
#endif

@end
