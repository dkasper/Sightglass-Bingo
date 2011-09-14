//
//  ASIFormDataRequest.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 07/11/2008.
//  Copyright 2008-2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PF_ASIHTTPRequest.h"
#import "PF_ASIHTTPRequestConfig.h"

typedef enum _PF_ASIPostFormat {
    PF_ASIMultipartFormDataPostFormat = 0,
    PF_ASIURLEncodedPostFormat = 1
	
} PF_ASIPostFormat;

@interface PF_ASIFormDataRequest : PF_ASIHTTPRequest <NSCopying> {

	// Parameters that will be POSTed to the url
	NSMutableArray *postData;
	
	// Files that will be POSTed to the url
	NSMutableArray *fileData;
	
	PF_ASIPostFormat postFormat;
	
	NSStringEncoding stringEncoding;
	
#if DEBUG_FORM_DATA_REQUEST
	// Will store a string version of the request body that will be printed to the console when ASIHTTPREQUEST_DEBUG is set in GCC_PREPROCESSOR_DEFINITIONS
	NSString *debugBodyString;
#endif
	
}

#pragma mark utilities 
- (NSString*)encodeURL:(NSString *)string; 
 
#pragma mark setup request

// Add a POST variable to the request
- (void)addPostValue:(id <NSObject>)value forKey:(NSString *)key;

// Set a POST variable for this request, clearing any others with the same key
- (void)setPostValue:(id <NSObject>)value forKey:(NSString *)key;

// Add the contents of a local file to the request
- (void)addFile:(NSString *)filePath forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)addFile:(NSString *)filePath withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;

// Add the contents of a local file to the request, clearing any others with the same key
- (void)setFile:(NSString *)filePath forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)setFile:(NSString *)filePath withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;

// Add the contents of an NSData object to the request
- (void)addData:(NSData *)data forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)addData:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;

// Add the contents of an NSData object to the request, clearing any others with the same key
- (void)setData:(NSData *)data forKey:(NSString *)key;

// Same as above, but you can specify the content-type and file name
- (void)setData:(id)data withFileName:(NSString *)fileName andContentType:(NSString *)contentType forKey:(NSString *)key;


@property (assign) PF_ASIPostFormat postFormat;
@property (assign) NSStringEncoding stringEncoding;
@end
