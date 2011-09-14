//
//  PFPush.h
//  Parse
//
//  Created by Ilya Sukhar on 7/4/11.
//  Copyright 2011 Ping Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFRequest.h"
#import <AudioToolbox/AudioToolbox.h>

/*!
 @class PFPush
 @abstract A class with convenience methods for push notifications.
 */
@interface PFPush : NSObject { }

/*!
 @abstract Subscribes the device to a channel of push notifications.
 @param channel The channel to subscribe to.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the subscribe succeeded.
 */
+ (BOOL)subscribeToChannel:(NSString *)channel withError:(NSError **)error;

/*!
 @abstract Asynchronously subscribes the device to a channel of push notifications.
 @param channel The channel to subscribe to.
 */
+ (void)subscribeToChannelInBackground:(NSString *)channel;

/*!
 @abstract Asynchronously subscribes the device to a channel of push notifications and calls the given callback.
 @param channel The channel to subscribe to.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
+ (void)subscribeToChannelInBackground:(NSString *)channel withTarget:(id)target selector:(SEL)selector;

/*!
 @abstract Unsubscribes the device to a channel of push notifications.
 @param channel The channel to unsubscribe from.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the unsubscribe succeeded.
 */
+ (BOOL)unsubscribeFromChannel:(NSString *)channel withError:(NSError **)error;

/*!
 @abstract Asynchronously unsubscribes the device from a channel of push notifications.
 @param channel The channel to unsubscribe from.
 @param deviceToken The device token. Either as an NSData straight from didRegisterForRemoteNotificationsWithDeviceToken or as an NSString if you converted it yourself.
 */
+ (void)unsubscribeFromChannelInBackground:(NSString *)channel;

/*!
 @abstract Asynchronously unsubscribes the device from a channel of push notifications and calls the given callback.
 @param channel The channel to unsubscribe from.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
+ (void)unsubscribeFromChannelInBackground:(NSString *)channel withTarget:(id)target selector:(SEL)selector;

/*!
 @abstract A default handler for push notifications while the app is active to mimic the behavior of iOS push notifications while the app is backgrounded or not running. Call this from didReceiveRemoteNotification.
 @param userInfo The userInfo dictionary you get in didReceiveRemoteNotification.
 */
+ (void)handlePush:(NSDictionary *)userInfo;

/*!
 @abstract Send a push message to a channel.
 @param channel The channel to send to.
 @param message The message to send.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the send succeeded.
 */
+ (BOOL)sendPushMessageToChannel:(NSString *)channel withMessage:(NSString *)message error:(NSError **)error;

/*!
 @abstract Asynchronously send a push message to a channel.
 @param channel The channel to send to.
 @param message The message to send.
 */
+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message;

/*!
 @abstract Asynchronously send a push message to a channel.
 @param channel The channel to send to.
 @param message The message to send.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message target:(id)target selector:(SEL)selector;

/*!
 @abstract Send a push message with arbitrary data to a channel. See the guide for information about the dictionary structure.
 @param channel The channel to send to.
 @param data The data to send.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the send succeeded.
 */
+ (BOOL)sendPushDataToChannel:(NSString *)channel withData:(NSDictionary *)data error:(NSError **)error;

/*!
 @abstract Asynchronously send a push message with arbitrary data to a channel. See the guide for information about the dictionary structure.
 @param channel The channel to send to.
 @param data The data to send.
 */
+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data;

/*!
 @abstract Asynchronously send a push message with arbitrary data to a channel. See the guide for information about the dictionary structure.
 @param channel The channel to send to.
 @param data The data to send.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSNumber *)result error:(NSError *)error. error will be nil on success and set if there was an error. [result boolValue] will tell you whether the call succeeded or not.
 */
+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data target:(id)target selector:(SEL)selector;

/*!
 @abstract Store the device token locally for push notifications. Usually called from you main app delegate's didRegisterForRemoteNotificationsWithDeviceToken.
 @param deviceToken Either as an NSData straight from didRegisterForRemoteNotificationsWithDeviceToken or as an NSString if you converted it yourself.
 */
+ (void)storeDeviceToken:(id)deviceToken;

/*!
 @absract Get all the channels that this device is subscribed to.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns an NSSet containing all the channel names this device is subscribed to.
 */
+ (NSSet *)getSubscribedChannels:(NSError **)error;

/*!
 @absract Asynchronously get all the channels that this device is subscribed to.
 @param target The object to call selector on.
 @param selector The selector to call. It should have the following signature: (void)callbackWithResult:(NSSet *)result error:(NSError *)error. error will be nil on success and set if there was an error.
 @result Returns an NSSet containing all the channel names this device is subscribed to.
 */
+ (void)getSubscribedChannelsInBackgroundWithTarget:(id)target selector:(SEL)selector;

#if NS_BLOCKS_AVAILABLE
/*!
 @abstract Asynchronously subscribes the device to a channel of push notifications and calls the given block.
 @param channel The channel to subscribe to.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)subscribeToChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block;

/*!
 @abstract Asynchronously unsubscribes the device from a channel of push notifications and calls the given block.
 @param channel The channel to unsubscribe from.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)unsubscribeFromChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block;

/*!
 @abstract Asynchronously sends a push message to a channel and calls the given block.
 @param channel The channel to send to.
 @param message The message to send.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message block:(PFBooleanResultBlock)block;

/*!
 @abstract Asynchronously sends a push message with arbitrary data to a channel and calls the given block. See the guide for information about the dictionary structure.
 @param channel The channel to send to.
 @param data The data to send.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error) 
 */
+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data block:(PFBooleanResultBlock)block;

/*!
 @absract Get all the channels that this device is subscribed to.
 @param block The block to execute. The block should have the following argument signature: (NSSet *channels, NSError *error) 
 */
+ (void)getSubscribedChannelsInBackgroundWithBlock:(PFSetResultBlock)block;
#endif

@end
