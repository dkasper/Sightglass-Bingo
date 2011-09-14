//
//  OAuth+Additions.h
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (PF_OAuthAdditions)

+ (NSDictionary *)PF_ab_parseURLQueryString:(NSString *)query;

@end

@interface NSString (PF_OAuthAdditions)

+ (NSString *)PF_ab_GUID;
- (NSString *)PF_ab_RFC3986EncodedString;

@end
