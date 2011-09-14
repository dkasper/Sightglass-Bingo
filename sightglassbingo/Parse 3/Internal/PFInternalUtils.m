//
//  PFInternalUtils.m
//  Parse
//
//  Created by Ilya Sukhar on 6/19/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import "PFInternalUtils.h"
#import "PFObject.h"

static NSDateFormatter *impreciseDateFormatter;
static NSDateFormatter *preciseDateFormatter;
static NSArray *validClasses;
static NSArray *validClassesForQuery;
static NSArray *validClassesForOrdering;

@implementation PFInternalUtils

+ (void)initialize {
    NSString *impreciseDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSString *preciseDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    
    impreciseDateFormatter = [[NSDateFormatter alloc] init];
    [impreciseDateFormatter setDateFormat:impreciseDateFormat];
    [impreciseDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [impreciseDateFormatter setLocale:locale];
    
    preciseDateFormatter = [[NSDateFormatter alloc] init];
    [preciseDateFormatter setDateFormat:preciseDateFormat];
    [preciseDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [preciseDateFormatter setLocale:locale];
    
    // Classes that can be the value of a PFObject
    validClasses = [[NSArray arrayWithObjects:[NSDictionary class], [NSArray class], 
                     [NSString class], [NSNumber class], [NSNull class], [PFObject class], 
                     [NSDate class], [NSData class], nil] retain];
    
    // Classes that can be the value of a query clause
    validClassesForQuery = [[NSArray arrayWithObjects:[NSString class], [NSNumber class], 
                             [NSNull class], [PFObject class], [NSDate class], nil] retain];
    
    // Classes that can be ordered
    validClassesForOrdering = [[NSArray arrayWithObjects:[NSString class], 
                                [NSNumber class], [NSDate class], nil] retain];
}

+ (NSError *)handleError:(NSDictionary *)result {
    NSInteger errorCode = [[result objectForKey:@"code"] integerValue];
    
#ifdef DEBUG
    NSString *errorExplanation = [result objectForKey:@"error"];
    NSLog(@"Error: %@ (Code: %i, Version: %@)", errorExplanation, errorCode, PARSE_VERSION);
#endif
    
    return [NSError errorWithDomain:@"Parse" code:errorCode userInfo:result];
}

// Rounds to the second.
+ (NSString *)stringFromDate:(NSDate *)date { 
    return [impreciseDateFormatter stringFromDate:date];
}

// Only compatible with the updatedAt / createdAt format.
+ (NSDate *)dateFromString:(NSString *)string {
    return [impreciseDateFormatter dateFromString:string];
}

+ (void)assertValidClassForValue:(id)object {
    for (Class validClass in validClasses) {
        if ([object isKindOfClass:validClass]) {
            return;
        }
    }
    
    [NSException raise:NSInvalidArgumentException
                format:@"PFObject values may not have class: %@", [object class]];
    
    return;
}

+ (void)assertValidClassForQuery:(id)object {
    for (Class validClass in validClassesForQuery) {
        if ([object isKindOfClass:validClass]) {
            return;
        }
    }
    
    [NSException raise:NSInvalidArgumentException
                format:@"Cannot do a comparison query for type: %@", [object class]];
}

+ (void)assertValidClassForOrdering:(id)object {
    for (Class validClass in validClassesForOrdering) {
        if ([object isKindOfClass:validClass]) {
            return;
        }
    }
    
    [NSException raise:NSInvalidArgumentException
                format:@"Cannot do a query that requires ordering for type: %@", [object class]];   
}

+ (id)parseDictionaryIntoObject:(NSDictionary *)dictionary {
    NSString *type = [dictionary objectForKey:@"__type"];
    
    if ([type isEqualToString:@"Date"]) {
        return [preciseDateFormatter dateFromString:[dictionary objectForKey:@"iso"]];
    } else if ([type isEqualToString:@"Bytes"]) {
        return [NSData PF_dataFromBase64String:[dictionary objectForKey:@"base64"]];
    } else {
        return nil;
    }
}

+ (NSDictionary *)encodeObjectIntoDictionary:(id)object {
    if ([object isKindOfClass:[NSData class]]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"Bytes", @"__type", 
                [object PF_base64EncodedString], @"base64", 
                nil];
    } else if ([object isKindOfClass:[NSDate class]]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"Date", @"__type",
                [preciseDateFormatter stringFromDate:object], @"iso",
                nil];
    }
    
    return nil;
}

+ (NSString *)serializeToJSON:(NSObject *)object {
    PF_SBJsonWriter *jsonWriter = [[[PF_SBJsonWriter alloc] init] autorelease];
    NSString *json = [jsonWriter stringWithObject:object];
    if (!json) {
        // This shouldn't ever happen since we typecheck in setObject.
        [NSException raise:NSInvalidArgumentException format:@"PFObject values must be serializable to JSON", nil];
    }
    return json;
}

+ (id)deserializeFromJSON:(NSString *)json {
    PF_SBJsonParser *jsonParser = [PF_SBJsonParser new];
    id object = [jsonParser objectWithString:json];
    if (!object)
        NSLog(@"JSON deserialization failed. Error trace is: %@", [jsonParser errorTrace]);
    [jsonParser release];
    return object;
}

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (id)kSecClassGenericPassword, (id)kSecClass,
            service, (id)kSecAttrService,
            service, (id)kSecAttrAccount,
            (id)kSecAttrAccessibleAfterFirstUnlock, (id)kSecAttrAccessible,
            nil];
}

+ (void)saveToKeychain:(NSString *)service data:(id)data {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(id)kSecValueData];
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

+ (id)loadFromKeychain:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData) CFRelease(keyData);
    return ret;
}

+ (void)deleteFromKeychain:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}

+ (void)callResultSelectorOnMainThread:(SEL)selector forTarget:(id)target withResult:(id)result error:(NSError *)error {
    if (target && [target respondsToSelector:selector]) {
        NSMethodSignature *handlerSignature = [[target class] instanceMethodSignatureForSelector:selector];
        NSInvocation *handler = [NSInvocation invocationWithMethodSignature:handlerSignature];
        
        [handler setTarget:target];
        [handler setSelector:selector];
        
        [handler setArgument:&result atIndex:2];
        [handler setArgument:&error atIndex:3];
        
        [handler performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}

#if NS_BLOCKS_AVAILABLE
+ (void)callBooleanResultBlockOnMainThread:(PFBooleanResultBlock)block withResult:(BOOL)result error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{ block(result, error); });
}

+ (void)callSetResultBlockOnMainThread:(PFSetResultBlock)block withResult:(NSSet *)result error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{ block(result, error); });
}
#endif

@end
