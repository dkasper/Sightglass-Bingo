// PFConstants.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import "PFConstants.h"

NSString *const PARSE_VERSION              = @"0.2.10";
NSInteger const PARSE_API_VERSION          = 1;

NSString *const PARSE_SERVER               = @"https://api.parse.com";

NSInteger const kPFErrorInternalServer           = 1;
NSInteger const kPFErrorConnectionFailed         = 100;
NSInteger const kPFErrorObjectNotFound           = 101;
NSInteger const kPFErrorInvalidQuery             = 102;
NSInteger const kPFErrorInvalidClassName         = 103;
NSInteger const kPFErrorMissingObjectId          = 104;
NSInteger const kPFErrorInvalidKeyName           = 105;
NSInteger const kPFErrorInvalidPointer           = 106;
NSInteger const kPFErrorInvalidJSON              = 107;
NSInteger const kPFErrorCommandUnavailable       = 108;
NSInteger const kPFErrorIncorrectType            = 111;
NSInteger const kPFErrorInvalidChannelName       = 112;
NSInteger const kPFErrorInvalidDeviceToken       = 114;
NSInteger const kPFErrorPushMisconfigured        = 115;
NSInteger const kPFErrorObjectTooLarge           = 116;
NSInteger const kPFErrorUsernameMissingError     = 200;
NSInteger const kPFErrorUserPasswordMissingError = 201;
NSInteger const kPFErrorUsernameTakenError       = 202;
NSInteger const kPFErrorUserEmailTakenError      = 203;
NSInteger const kPFErrorUserEmailMissing         = 204;
NSInteger const kPFErrorUserWithEmailNotFound    = 205;
NSInteger const kPFErrorUserCannotBeAlteredWithoutSession = 206;