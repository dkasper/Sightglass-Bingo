//
//  PFPush.m
//  Parse
//
//  Created by Ilya Sukhar on 7/4/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import "PFPush.h"


@implementation PFPush

+ (NSString *)convertDeviceTokenToString:(id)deviceToken {
    NSString *deviceTokenString = nil;
    
    if ([deviceToken isKindOfClass:[NSData class]]) {
        deviceTokenString = [NSString stringWithFormat:@"%@", deviceToken];
    } else {
        deviceTokenString = [[deviceToken copy] autorelease];
    }
    
    deviceTokenString = [deviceTokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return deviceTokenString;
}

+ (void)storeDeviceToken:(id)deviceToken {
    NSString *deviceTokenString = [PFPush convertDeviceTokenToString:deviceToken];
    [PFInternalUtils saveToKeychain:@"ParsePush" data:deviceTokenString];
}

+ (NSString *)getDeviceToken:(NSError **)error {
    NSString *deviceToken = [PFInternalUtils loadFromKeychain:@"ParsePush"];
    
    NSDictionary *result = [NSDictionary dictionaryWithObject:@"There is no device token stored yet." forKey:@"error"];
    
    if (!deviceToken && error) {
        *error = [NSError errorWithDomain:@"Parse" code:kPFErrorPushMisconfigured userInfo:result];
    }
    
    return deviceToken;
}

+ (void)clearDeviceToken {
    [PFInternalUtils deleteFromKeychain:@"ParsePush"];
}

+ (PFCommand *)createSendCommandForPush:(NSString *)channel data:(NSDictionary *)data {
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    [params setObject:[PFInternalUtils serializeToJSON:data] forKey:@"data"];
    [params setObject:channel forKey:@"channel"];
    
    PFCommand *command = [PFCommand createCommandWithOperation:@"client_push" params:params];
    [command useGenericBooleanCallback];
    
    return command;
}

+ (PFCommand *)createSendCommandForPushMessage:(NSString *)channel message:(NSString *)message {
    NSDictionary *data = [NSDictionary dictionaryWithObject:message forKey:@"alert"];
    return [PFPush createSendCommandForPush:channel data:data];
}

+ (BOOL)sendPushMessageToChannel:(NSString *)channel withMessage:(NSString *)message error:(NSError **)error  { 
    PFCommand *sendCommand = [PFPush createSendCommandForPushMessage:channel message:message];
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    
    [sendRequest startSynchronous];
    NSError *newError = [sendCommand error];
    
    if (newError) {
        if (error) { *error = newError; }
        return NO;
    } else {
        return YES;
    }
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message {
    PFCommand *sendCommand = [PFPush createSendCommandForPushMessage:channel message:message];
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message target:(id)target selector:(SEL)selector {
    PFCommand *sendCommand = [PFPush createSendCommandForPushMessage:channel message:message];
    sendCommand.resultTarget = target;
    sendCommand.resultSelector = selector;
    
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (BOOL)sendPushDataToChannel:(NSString *)channel withData:(NSDictionary *)data error:(NSError **)error  { 
    PFCommand *sendCommand = [PFPush createSendCommandForPush:channel data:data];
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    
    [sendRequest startSynchronous];
    NSError *newError = [sendCommand error];
    
    if (newError) {
        if (error) { *error = newError; }
        return NO;
    } else {
        return YES;
    }
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data {
    PFCommand *sendCommand = [PFPush createSendCommandForPush:channel data:data];
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data target:(id)target selector:(SEL)selector {
    PFCommand *sendCommand = [PFPush createSendCommandForPush:channel data:data];
    sendCommand.resultTarget = target;
    sendCommand.resultSelector = selector;
    
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (PFCommand *)createSubscribeOrUnsubscribeCommand:(NSString *)subscribeOrUnsubscribe channel:(NSString *)channel error:(NSError **)error {
    NSString *deviceTokenString = [PFPush getDeviceToken:error];
    
    if (!deviceTokenString) { return nil; }
    
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    [params setObject:@"ios" forKey:@"type"];
    [params setObject:deviceTokenString forKey:@"device_token"];
    [params setObject:channel forKey:@"channel"];
    
    PFCommand *command = [PFCommand createCommandWithOperation:subscribeOrUnsubscribe params:params];
    [command useGenericBooleanCallback];
    
    return command;
}

+ (PFCommand *)createGetChannelsCommand:(NSError **)error {
    NSString *deviceTokenString = [PFPush getDeviceToken:error];
    if (!deviceTokenString) { return nil; }
    
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    [params setObject:@"ios" forKey:@"type"];
    [params setObject:deviceTokenString forKey:@"device_token"];
    
    
    NSMethodSignature *handlerSignature = [PFPush methodSignatureForSelector:@selector(handleGetChannelsResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleGetChannelsResultForCommand:result:error:)];
    
    PFCommand *command = [PFCommand createCommandWithOperation:@"channels" params:params];
    [command setInternalCallback:internalCallback andRetain:nil];

    return command;
}

+ (NSSet *)handleGetChannelsResultForCommand:(PFCommand *)command result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return nil;
    }
    
    return [NSSet setWithArray:[result objectForKey:@"result"]];
}

+ (BOOL)subscribeToChannel:(NSString *)channel withError:(NSError **)error { 
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"subscribe" channel:channel error:error];
    if (!subscribeCommand) { return NO; }
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    
    [subscribeRequest startSynchronous];
    NSError *newError = [subscribeCommand error];
    
    if (newError) {
        if (error) { *error = newError; }        
        return NO;
    } else {
        return YES;
    }    
}

+ (void)subscribeToChannelInBackground:(NSString *)channel {    
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"subscribe" channel:channel error:nil];
    if (!subscribeCommand) { return; }

    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel withTarget:(id)target selector:(SEL)selector {
    NSError *error = nil;
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"subscribe" channel:channel error:&error];
    if (!subscribeCommand) {
        [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:[NSNumber numberWithBool:NO] error:error];
        return;
    }

    subscribeCommand.resultTarget = target;
    subscribeCommand.resultSelector = selector;
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (BOOL)unsubscribeFromChannel:(NSString *)channel withError:(NSError **)error {
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"unsubscribe" channel:channel error:error];
    if (!subscribeCommand) { return NO; }
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    
    [subscribeRequest startSynchronous];
    NSError *newError = [subscribeCommand error];
    
    if (newError) {
        if (error) { *error = newError; }        
        return NO;
    } else {
        return YES;
    }
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel {    
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"unsubscribe" channel:channel error:nil];
    if (!subscribeCommand) { return; }
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel withTarget:(id)target selector:(SEL)selector {    
    NSError *error = nil;
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"unsubscribe" channel:channel error:&error];
    if (!subscribeCommand) {
        [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:[NSNumber numberWithBool:NO] error:error];
        return;
    }
    
    subscribeCommand.resultTarget = target;
    subscribeCommand.resultSelector = selector;
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (NSSet *)getSubscribedChannels:(NSError **)error {
    PFCommand *getChannelsCommand = [PFPush createGetChannelsCommand:error];
    if (!getChannelsCommand) { return nil; }
    
    PFRequest *getChannelsRequest = [PFRequest createRequestFromCommand:getChannelsCommand];
    [getChannelsRequest startSynchronous];
    
    NSError *newError = [getChannelsCommand error];
    
    if (newError) {
        if (error) { *error = newError; }
        return nil;
    } else {
        return [getChannelsCommand returnedValue];
    }
}

+ (void)getSubscribedChannelsInBackgroundWithTarget:(id)target selector:(SEL)selector {
    NSError *error = nil;
    PFCommand *getChannelsCommand = [PFPush createGetChannelsCommand:&error];
    if (!getChannelsCommand) {
        [PFInternalUtils callResultSelectorOnMainThread:selector forTarget:target withResult:nil error:error];
        return;
    }
    
    getChannelsCommand.resultTarget = target;
    getChannelsCommand.resultSelector = selector;
    
    PFRequest *getChannelsRequest = [PFRequest createRequestFromCommand:getChannelsCommand];
    [getChannelsRequest startAsynchronous];
}

+ (void)handlePush:(NSDictionary *)userInfo {    
    UIApplication *application = [UIApplication sharedApplication];
    
    
    if ([application respondsToSelector:@selector(applicationState)] &&
        [application applicationState] != UIApplicationStateActive) {
        return;
    }
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];

    if ([aps objectForKey:@"alert"]) {
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        NSString *message = [aps objectForKey:@"alert"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: appName
                                                        message: message
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    
    if ([aps objectForKey:@"badge"]) {
        NSInteger badgeNumber = [[aps objectForKey:@"badge"] integerValue];
        [application setApplicationIconBadgeNumber:badgeNumber];
    }
    
    if ([aps objectForKey:@"sound"] && 
        ![[aps objectForKey:@"sound"] isEqualToString:@""] &&
        ![[aps objectForKey:@"sound"] isEqualToString:@"default"]) {
        NSString *soundName = [aps objectForKey:@"sound"];
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:[soundName stringByDeletingPathExtension] 
                                                              ofType:[soundName pathExtension]];
        if (soundPath) {        
            SystemSoundID soundId;
            AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:soundPath], &soundId);
            AudioServicesPlaySystemSound(soundId);
            return;
        }
    }
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#if NS_BLOCKS_AVAILABLE
+ (void)subscribeToChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block {
    NSError *error = nil;
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"subscribe" channel:channel error:&error];
    if (!subscribeCommand) {
        [PFInternalUtils callBooleanResultBlockOnMainThread:block withResult:NO error:error];
        return;
    }
    
    subscribeCommand.booleanResultBlock = block;
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block {
    NSError *error = nil;
    PFCommand *subscribeCommand = [PFPush createSubscribeOrUnsubscribeCommand:@"unsubscribe" channel:channel error:&error];
    if (!subscribeCommand) {
        [PFInternalUtils callBooleanResultBlockOnMainThread:block withResult:NO error:error];
        return;
    }
    
    subscribeCommand.booleanResultBlock = block;
    
    PFRequest *subscribeRequest = [PFRequest createRequestFromCommand:subscribeCommand];
    [subscribeRequest startAsynchronous];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message block:(PFBooleanResultBlock)block {
    PFCommand *sendCommand = [PFPush createSendCommandForPushMessage:channel message:message];
    sendCommand.booleanResultBlock = block;
    
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data block:(PFBooleanResultBlock)block {
    PFCommand *sendCommand = [PFPush createSendCommandForPush:channel data:data];
    sendCommand.booleanResultBlock = block;
    
    PFRequest *sendRequest = [PFRequest createRequestFromCommand:sendCommand];
    [sendRequest startAsynchronous];
}

+ (void)getSubscribedChannelsInBackgroundWithBlock:(PFSetResultBlock)block {
    NSError *error = nil;
    PFCommand *getChannelsCommand = [PFPush createGetChannelsCommand:&error];
    if (!getChannelsCommand) {
        [PFInternalUtils callSetResultBlockOnMainThread:block withResult:nil error:error];
        return;
    }
    
    getChannelsCommand.setResultBlock = block;
    
    PFRequest *getChannelsRequest = [PFRequest createRequestFromCommand:getChannelsCommand];
    [getChannelsRequest startAsynchronous];
}

#endif

@end
