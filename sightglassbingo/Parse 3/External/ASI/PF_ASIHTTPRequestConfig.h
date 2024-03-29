//
//  ASIHTTPRequestConfig.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 14/12/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//


// ======
// Debug output configuration options
// ======

// When set to 1 ASIHTTPRequests will print information about what a request is doing
#ifndef PF_DEBUG_REQUEST_STATUS
	#define PF_DEBUG_REQUEST_STATUS 0
#endif

// When set to 1, ASIFormDataRequests will print information about the request body to the console
#ifndef PF_DEBUG_FORM_DATA_REQUEST
	#define PF_DEBUG_FORM_DATA_REQUEST 0
#endif

// When set to 1, ASIHTTPRequests will print information about bandwidth throttling to the console
#ifndef PF_DEBUG_THROTTLING
	#define PF_DEBUG_THROTTLING 0
#endif

// When set to 1, ASIHTTPRequests will print information about persistent connections to the console
#ifndef PF_DEBUG_PERSISTENT_CONNECTIONS
	#define PF_DEBUG_PERSISTENT_CONNECTIONS 0
#endif

// When set to 1, ASIHTTPRequests will print information about HTTP authentication (Basic, Digest or NTLM) to the console
#ifndef PF_DEBUG_HTTP_AUTHENTICATION
#define PF_DEBUG_HTTP_AUTHENTICATION 0
#endif
