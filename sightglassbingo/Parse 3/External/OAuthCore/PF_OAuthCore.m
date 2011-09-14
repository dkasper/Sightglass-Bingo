//
//  OAuthCore.m
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import "PF_OAuthCore.h"
#import "PF_OAuth+Additions.h"
#import "PF_Base64.h"
#import <CommonCrypto/CommonHMAC.h>

static NSInteger SortParameter(NSString *key1, NSString *key2, void *context) {
	NSComparisonResult r = [key1 compare:key2];
	if(r == NSOrderedSame) { // compare by value in this case
		NSDictionary *dict = (NSDictionary *)context;
		NSString *value1 = [dict objectForKey:key1];
		NSString *value2 = [dict objectForKey:key2];
		return [value1 compare:value2];
	}
	return r;
}

static NSData *HMAC_SHA1(NSString *data, NSString *key) {
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
	return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

NSString *PF_OAuthorizationHeader(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret, NSString *_oAuthToken, NSString *_oAuthTokenSecret)
{
	NSString *_oAuthNonce = [NSString PF_ab_GUID];
	NSString *_oAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
	NSString *_oAuthSignatureMethod = @"HMAC-SHA1";
	NSString *_oAuthVersion = @"1.0";
	
	NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionary];
	[oAuthAuthorizationParameters setObject:_oAuthNonce forKey:@"oauth_nonce"];
	[oAuthAuthorizationParameters setObject:_oAuthTimestamp forKey:@"oauth_timestamp"];
	[oAuthAuthorizationParameters setObject:_oAuthSignatureMethod forKey:@"oauth_signature_method"];
	[oAuthAuthorizationParameters setObject:_oAuthVersion forKey:@"oauth_version"];
	[oAuthAuthorizationParameters setObject:_oAuthConsumerKey forKey:@"oauth_consumer_key"];
	if(_oAuthToken)
		[oAuthAuthorizationParameters setObject:_oAuthToken forKey:@"oauth_token"];
	
	// get query and body parameters
	NSDictionary *additionalQueryParameters = [NSURL PF_ab_parseURLQueryString:[url query]];
	NSDictionary *additionalBodyParameters = nil;
	if(body) {
		NSString *string = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
		if(string) {
			additionalBodyParameters = [NSURL PF_ab_parseURLQueryString:string];
		}
	}
	
	// combine all parameters
	NSMutableDictionary *parameters = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	if(additionalQueryParameters) [parameters addEntriesFromDictionary:additionalQueryParameters];
	if(additionalBodyParameters) [parameters addEntriesFromDictionary:additionalBodyParameters];
	
	// -> UTF-8 -> RFC3986
	NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
	for(NSString *key in parameters) {
		NSString *value = [parameters objectForKey:key];
		[encodedParameters setObject:[value PF_ab_RFC3986EncodedString] forKey:[key PF_ab_RFC3986EncodedString]];
	}
	
	NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:encodedParameters];
	
	NSMutableArray *parameterArray = [NSMutableArray array];
	for(NSString *key in sortedKeys) {
		[parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, [encodedParameters objectForKey:key]]];
	}
	NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
	
    // NOTE(ilya): This fixes a bug in the original library where the port wasn't serialized into the url string if necessary.
    NSString *normalizedURLString;
    if ([url port]) {
        normalizedURLString = [NSString stringWithFormat:@"%@://%@:%@%@", [url scheme], [url host], [url port], [url path]];
    } else {
        normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
    }
	
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
									 [method PF_ab_RFC3986EncodedString],
									 [normalizedURLString PF_ab_RFC3986EncodedString],
									 [normalizedParameterString PF_ab_RFC3986EncodedString]];
    
    // NOTE(ilya): This fixes a bug in the original library where the key was improperly serialized in the two-legged oauth scenario.
    NSString *key;    
    if (_oAuthTokenSecret) {
        key = [NSString stringWithFormat:@"%@&%@",
               [_oAuthConsumerSecret PF_ab_RFC3986EncodedString],
               [_oAuthTokenSecret PF_ab_RFC3986EncodedString]];
    
    } else {
        key = [NSString stringWithFormat:@"%@&", [_oAuthConsumerSecret PF_ab_RFC3986EncodedString]];
    }
    	
	NSData *signature = HMAC_SHA1(signatureBaseString, key);
	NSString *base64Signature = [signature PF_base64EncodedString];
	
	NSMutableDictionary *authorizationHeaderDictionary = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	[authorizationHeaderDictionary setObject:base64Signature forKey:@"oauth_signature"];
	
	NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
	for(NSString *key in authorizationHeaderDictionary) {
		NSString *value = [authorizationHeaderDictionary objectForKey:key];
		[authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
											 [key PF_ab_RFC3986EncodedString],
											 [value PF_ab_RFC3986EncodedString]]];
	}
	
	NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
	authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];
	
	return authorizationHeaderString;
}
