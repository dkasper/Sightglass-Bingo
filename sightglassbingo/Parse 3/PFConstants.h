// PFConstants.h
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import <Foundation/Foundation.h>

// *************************************************************
//                       KEY SET UP
// 
// Uncomment these lines and replace the strings with your keys
// from the dashboard:

//#define APPLICATION_ID  @"yourappid"
//#define CLIENT_KEY      @"yourkey"

// *************************************************************

#if !defined(APPLICATION_ID) || !defined(CLIENT_KEY)
#error Please uncomment and fill in APPLICATION_ID and CLIENT_KEY at the top of PFConstants.h
#endif 

// Version
extern NSString *const PARSE_VERSION;
extern NSInteger const PARSE_API_VERSION;

// Server
extern NSString *const PARSE_SERVER;

// Errors

/*! @abstract 1: Internal server error. No information available. */
extern NSInteger const kPFErrorInternalServer;
/*! @abstract 100: The connection to the Parse servers failed. */
extern NSInteger const kPFErrorConnectionFailed;
/*! @abstract 101: Object doesn't exist, or has an incorrect password. */
extern NSInteger const kPFErrorObjectNotFound;
/*! @abstract 102: You tried to find values matching a datatype that doesn't support exact database matching, like an array or a dictionary. */
extern NSInteger const kPFErrorInvalidQuery;
/*! @abstract 103: Missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters. */
extern NSInteger const kPFErrorInvalidClassName;
/*! @abstract 104: Missing object id. */
extern NSInteger const kPFErrorMissingObjectId;
/*! @abstract 105: Invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters. */
extern NSInteger const kPFErrorInvalidKeyName;
/*! @abstract 106: Malformed pointer. Pointers must be arrays of a classname and an object id. */
extern NSInteger const kPFErrorInvalidPointer;
/*! @abstract 107: Malformed json object. A json dictionary is expected. */
extern NSInteger const kPFErrorInvalidJSON;
/*! @abstract 108: Tried to access a feature only available internally. */
extern NSInteger const kPFErrorCommandUnavailable;
/*! @abstract 111: Field set to incorrect type. */
extern NSInteger const kPFErrorIncorrectType;
/*! @abstract 112: Invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter. */
extern NSInteger const kPFErrorInvalidChannelName;
/*! @abstract 114: Invalid device token. */
extern NSInteger const kPFErrorInvalidDeviceToken;
/*! @abstract 115: Push is misconfigured. See details to find out how. */
extern NSInteger const kPFErrorPushMisconfigured;
/*! @abstract 116: The object is too large. */
extern NSInteger const kPFErrorObjectTooLarge;

/*! @abstract 200: Username is missing or empty */
extern NSInteger const kPFErrorUsernameMissingError;
/*! @abstract 201: Password is missing or empty */
extern NSInteger const kPFErrorUserPasswordMissingError;
/*! @abstract 202: Username has already been taken */
extern NSInteger const kPFErrorUsernameTakenError;
/*! @abstract 203: Email has already been taken */
extern NSInteger const kPFErrorUserEmailTakenError;
/*! @abstract 204: The email is missing, and must be specified */
extern NSInteger const kPFErrorUserEmailMissing;
/*! @abstract 205: A user with the specified email was not found */
extern NSInteger const kPFErrorUserWithEmailNotFound;
/*! @abstract 206: A user with the specified email was not found */
extern NSInteger const kPFErrorUserCannotBeAlteredWithoutSession;

#if NS_BLOCKS_AVAILABLE
@class PFObject;
@class PFUser;

typedef void (^PFBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^PFArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^PFObjectResultBlock)(PFObject *object, NSError *error);
typedef void (^PFSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^PFUserResultBlock)(PFUser *user, NSError *error);
#endif