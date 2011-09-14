// PFQuery.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "PFObject.h"
#import "PFRequest.h"
#import "PFUser.h"
#import "PFInternalUtils.h"

/*!
 @class PFQuery
 @abstract A class that defines a query that is used to query for PFObjects.
 */
@interface PFQuery : NSObject {
    NSString *className;
    NSMutableDictionary *where;
    NSNumber *limit;
    NSString *order;
}

/*!
 @abstract The class name to query for
 */
@property (nonatomic, retain) NSString *className;

/*!
 @abstract A limit on the number of objects to return.
 */
@property (nonatomic, retain) NSNumber *limit;

/*!
 @abstract A string representing an ordering for the objects returned.
 @deprecated Use orderByAscending: and orderByDescending: instead.
 */
@property (nonatomic, retain) NSString *order;

/*!
 @abstract Initializes the query with a class name.
 @param newClassName The class name.
 */
- (id)initWithClassName:(NSString *)newClassName;

/*!
 @abstract Sort the results in ascending order with the given key.
 @param key The key to order by.
 */
- (void)orderByAscending:(NSString *)key;

/*!
 @abstract Sort the results in descending order with the given key.
 @param key The key to order by.
 */
- (void)orderByDescending:(NSString *)key;

/*!
 @abstract Add a where condition to the query.
 @param key The key to search on
 @param object The value to search on.
 @deprecated Use whereKey:equalTo: instead.
 */
- (void)whereObject:(id)object forKey:(NSString *)key __attribute__ ((deprecated));

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key equalTo:(id)object;

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be less than the provided object.
 @param key The key to be constrained.
 @param object The object that provides an upper bound.
 */
- (void)whereKey:(NSString *)key lessThan:(id)object;

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be less than or equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key lessThanOrEqualTo:(id)object;

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be greater than the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key greaterThan:(id)object;

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be greater than or equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object;

/*!
 @abstract Add a constraint to the query that requires a particular key's object to be not equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must not be equalled.
 */
- (void)whereKey:(NSString *)key notEqualTo:(id)object;

/*!
 @abstract Finds objects based on the constructed query.
 @result Returns an array of PFObjects that were found.
 */
- (NSArray *)findObjects;

/*!
 @abstract Finds objects based on the constructed query and sets an error if there was one.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns an array of PFObjects that were found.
 */
- (NSArray *)findObjects:(NSError **)error;

/*!
 @abstract Finds objects asynchronously and calls the given callback with the results.
 @param target The object to call the selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSArray *)result error:(NSError *)error. result will be nil if error is set and vice versa.
 */
- (void)findObjectsInBackgroundWithTarget:(id)target selector:(SEL)selector;

/*!
 @abstract Returns a PFObject with the given id.
 @param objectId The id of the object that is being requested.
 @result The PFObject if found. Returns nil if the object isn't found, or if there was an error.
 */
- (PFObject *)getObjectWithId:(NSString *)objectId;

/*!
 @abstract Returns a PFObject with the given id and sets an error if necessary.
 @param error Pointer to an NSError that will be set if necessary.
 @result The PFObject if found. Returns nil if the object isn't found, or if there was an error.
 */
- (PFObject *)getObjectWithId:(NSString *)objectId error:(NSError **)error;

/*!
 @abstract Gets a PFObject asynchronously.
 @param objectId The id of the object being requested.
 @param target The target for the callback selector.
 @param selector The selector for the callback. It should have the following signature: (void)callbackWithResult:(PFObject *)result error:(NSError *)error. result will be nil if error is set and vice versa.
 */
- (void)getObjectInBackgroundWithId:(NSString *)objectId target:(id)target selector:(SEL)selector;

/*!
 @abstract Returns a PFObject with a given class and id.
 @param objectClass The class name for the object that is being requested.
 @param objectId The id of the object that is being requested.
 @result The PFObject if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (PFObject *)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId;

/*!
 @abstract Returns a PFObject with a given class and id and sets an error if necessary.
 @param error Pointer to an NSError that will be set if necessary.
 @result The PFObject if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (PFObject *)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId error:(NSError **)error;

/*!
 @abstract Returns a PFQuery for a given class.
 @param className The class to query on.
 @return A PFQuery object.
 */
+ (PFQuery *)queryWithClassName:(NSString *)className;

/*!
 @abstract Returns a PFUser with a given id.
 @param objectId The id of the object that is being requested.
 @result The PFUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (PFUser *)getUserObjectWithId:(NSString *)objectId;

/*!
 @abstract Returns a PFUser with a given class and id and sets an error if necessary.
 @param error Pointer to an NSError that will be set if necessary.
 @result The PFUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (PFUser *)getUserObjectWithId:(NSString *)objectId error:(NSError **)error;

/*!
 @abstract Returns a PFQuery for a PFUser.
 @return A PFQuery object.
 */
+ (PFQuery *)queryForUser;

#if NS_BLOCKS_AVAILABLE
/*!
 @abstract Finds objects asynchronously and calls the given block with the results.
 @param block The block to execute. The block should have the following argument signature: (NSArray *objects, NSError *error) 
 */
- (void)findObjectsInBackgroundWithBlock:(PFArrayResultBlock)block;

/*!
 @abstract Gets a PFObject asynchronously and calls the given block with the result. 
 @param block The block to execute. The block should have the following argument signature: (NSArray *object, NSError *error) 
 */
- (void)getObjectInBackgroundWithId:(NSString *)objectId block:(PFObjectResultBlock)block;
#endif


@end
