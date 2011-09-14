//
//  PFCommand.h
//  Parse
//
//  Created by Ilya Sukhar on 6/24/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFInternalUtils.h"


@interface PFCommand : NSObject {
    NSString *operation;
    NSMutableDictionary *params;
    NSError *error;
    
    NSInvocation *internalCallback;
    id resultTarget;
    SEL resultSelector;
    
    
    id objectToRetain;
    id returnVal;

#if NS_BLOCKS_AVAILABLE
    PFBooleanResultBlock booleanResultBlock;
    PFArrayResultBlock arrayResultBlock;
    PFObjectResultBlock objectResultBlock;
    PFSetResultBlock setResultBlock;
    PFUserResultBlock userResultBlock;
#endif
}

@property (nonatomic, retain) NSString *operation;
@property (nonatomic, retain) NSMutableDictionary *params;
@property (nonatomic, retain) NSError *error;

@property (assign) SEL resultSelector;
@property (assign) id resultTarget;

#if NS_BLOCKS_AVAILABLE
@property (nonatomic, copy) PFBooleanResultBlock booleanResultBlock;
@property (nonatomic, copy) PFArrayResultBlock arrayResultBlock;
@property (nonatomic, copy) PFObjectResultBlock objectResultBlock;
@property (nonatomic, copy) PFSetResultBlock setResultBlock;
@property (nonatomic, copy) PFUserResultBlock userResultBlock;
#endif

- (id)returnedValue;
- (void)processResult:(NSDictionary *)result;
- (void)processError:(NSError *)error;
- (void)setInternalCallback:(NSInvocation *)callback andRetain:(id)object;
- (void)useGenericBooleanCallback;
+ (PFCommand *)createCommandWithOperation:(NSString *)operation params:(NSMutableDictionary *)params;

@end
