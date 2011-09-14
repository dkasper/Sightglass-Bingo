// PFUser.m
// Copyright 2011 Ping Labs, Inc. All rights reserved.

#import "PFUser.h"
#import "PFObjectPrivate.h"

#define CURRENT_USER_FILE @"currentUser"

@interface PFUser (Private)

// Internal commands
+ (void)validateClassName:(NSString *)aClassName;
- (PFCommand *)constructSignUpCommand;
+ (PFCommand *)constructRequestPasswordReset:(NSString *)email;
- (PFCommand *)constructSaveCommand;
+ (PFCommand *)constructLoginCommandWithUsername:username andPassword:password;
- (void)checkSignUpParams;
+ (id)handleLoginResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error;
+ (id)sendSyncRequestForCommand:(PFCommand *)command withError:(NSError **)error;
+ (void)saveCurrentUser:(PFUser *)user;

@end

// Private Properties
@interface PFUser ()

    // This earmarks the user as being an "identity" user. This will make saves write through
    // to the currentUser singleton and disk object
    @property (nonatomic, assign) BOOL isCurrentUser;

@end

@implementation PFUser (Private)

static PFUser *currentUser;

// Check security on delete
- (void)checkDeleteParams {
    if (![self isAuthenticated]) {
        [NSException raise:NSInternalInconsistencyException format:@"User cannot be deleted unless they have been authenticated via logIn or signUp", nil];
    }
    
    [super checkDeleteParams];
}

- (NSString *)displayClassName {
    return @"PFUser";
}

// Validates a class name. We override this to only allow the user class name.

+ (void)validateClassName:(NSString *)aClassName {
    if (![aClassName isEqualToString:USER_CLASS_NAME]) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot initialize a PFUser with a custom class name."];
    }
}

// Checks the properties on the object before saving.

- (void)checkSaveParams {
    if (!self.objectId) {
        [NSException raise:NSInternalInconsistencyException format:@"User cannot be saved unless they are already signed up. Call signUp first.", nil];
    }
    
    if (![self isAuthenticated] && dirty) {
        [NSException raise:NSInternalInconsistencyException format:@"User cannot be saved unless they have been authenticated via logIn or signUp", nil];
    }
}

// Checks the properties on the object before signUp.

- (void)checkSignUpParams {
    if (username == nil) {
		[NSException raise:NSInternalInconsistencyException format:@"Cannot sign up without a username."];
	}
	
	if (password == nil) {
		[NSException raise:NSInternalInconsistencyException format:@"Cannot sign up without a password."];
	}
	
	if (!dirty || self.objectId) {
		[NSException raise:NSInternalInconsistencyException format:@"Cannot sign up an existing user."];
	}
}

// Overrides the serialize method to add the session token (which should be serialized to disk)

- (NSMutableDictionary *)serialize {
    NSMutableDictionary *serialized = [super serialize];
    
    if (sessionToken) {
        [serialized setObject:sessionToken forKey:@"session_token"];
    }
    
    return serialized;
}

// Overrides the save command so that we send the password to the server (used for signUp)

- (PFCommand *)constructSaveCommand {
    PFCommand *command = [super constructSaveCommand];
    NSMutableDictionary *params = command.params;
    
    // Send the user's password if it exists
    if (password) {
        [params setObject:password forKey:@"user_password"];
    }
    
    return command;
}

// Overrides the delete command to send the sessionToken

- (PFCommand *)constructDeleteCommand {
    PFCommand *command = [super constructDeleteCommand];
    NSMutableDictionary *params = command.params;
    
    if (sessionToken) {
        [params setObject:sessionToken forKey:@"session_token"];
    }
    
    return command;
}

// The signUp command is a thin shell around the save command (just with a different operation)

- (PFCommand *)constructSignUpCommand {
	PFCommand *command = [self constructSaveCommand];
	
	command.operation = @"user_signup";

	return command;
}

// Constructs a request password reset command.

+ (PFCommand *)constructRequestPasswordReset:(NSString *)email {
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:email forKey:@"email"];
        
    PFCommand *command = [PFCommand createCommandWithOperation:@"user_request_password_reset" params:params];
    [command useGenericBooleanCallback];
	
	[params release];
    
    return command;
}

// Constructs the login command. We send the username and password properties.

+ (PFCommand *)constructLoginCommandWithUsername:username andPassword:password {
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:username forKey:@"username"];
    [params setObject:password forKey:@"user_password"];
    
    NSMethodSignature *handlerSignature = [PFUser methodSignatureForSelector:@selector(handleLoginResultForCommand:result:error:)];
    NSInvocation *internalCallback = [NSInvocation invocationWithMethodSignature:handlerSignature];
    [internalCallback setTarget:self];
    [internalCallback setSelector:@selector(handleLoginResultForCommand:result:error:)];
    
    PFCommand *command = [PFCommand createCommandWithOperation:@"user_login" params:params];
    [command setInternalCallback:internalCallback andRetain:self];
	
	[params release];
    
    return command;
}

// Handles the response from user login. 

+ (id)handleLoginResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error {
    if ([result objectForKey:@"error"] || ![result objectForKey:@"result"]) {
        NSError *newError = [PFInternalUtils handleError:result];
        if (error) { *error = newError; }
        return nil;
    }
    
    NSDictionary *actualResult = [result objectForKey:@"result"];
    
    // We test for a null object, if it isn't, we can use the response to create a PFUser
    if (![actualResult isKindOfClass:[NSNull class]]) {
        PFUser *loggedInUser = [[[PFUser alloc] initWithClassName:USER_CLASS_NAME result:actualResult] autorelease];
        
        // Serialize the object to disk so we can later access it via currentUser
        [PFUser saveCurrentUser:loggedInUser];
        
        return loggedInUser;
    } else {
        return nil;
    }
}

// Generic sync request method.

+ (id)sendSyncRequestForCommand:(PFCommand *)command withError:(NSError **)error {
    PFRequest *request = [PFRequest createRequestFromCommand:command];
    [request startSynchronous];
    
    NSError *newError = [command error];
    
    if (newError) {
        if (error) { *error = newError; }        
        return nil;
    } else {
        return [command returnedValue];
    }
}

// Override the save result handling. We need to set the session_token.

- (id)handleSaveResultForCommand:(PFCommand *)saveCommand result:(NSDictionary *)result error:(NSError **)error {
	NSNumber *saveResult = [super handleSaveResultForCommand:saveCommand result:result error:error];
	
	if ([saveResult boolValue] && [saveCommand.operation isEqualToString:@"user_signup"]) {
		// Save the session information
		NSDictionary *actualResult = [result objectForKey:@"result"];
		sessionToken = [[actualResult objectForKey:@"session_token"] copy];
    }
    
    // Serialize the object to disk so we can later access it via currentUser, only if
    // the operation is a signup, or if the user is the currentUser
    if (isCurrentUser || [saveCommand.operation isEqualToString:@"user_signup"]) {
        [PFUser saveCurrentUser:self];
	}
    
    return saveResult;
}

+ (void)saveCurrentUser:(PFUser *)user {
    [user serializeToDataFile:CURRENT_USER_FILE];
    user.isCurrentUser = YES;
    
    // If the user is already the currentUser, we do nothing.
    if (currentUser == user) {
        return;
    }
    
    if (currentUser) {
        [currentUser release];
    }
    
    currentUser = user;
    [currentUser retain];
}

- (void)mergeFromResult:(NSDictionary *)result {
    [super mergeFromResult:result];
    
    // save the session token
    sessionToken   = [[result objectForKey:@"session_token"] copy];
    
    // Need to set various fields from the data.
    self.username  = [data objectForKey:@"username"];
    self.email     = [data objectForKey:@"email"];
}

@end


@implementation PFUser

@synthesize sessionToken;
@synthesize isCurrentUser;

+ (id)currentUser {
    @synchronized(self) {
        if (currentUser == nil) {
            currentUser = [[PFUser alloc] initFromDataFile:CURRENT_USER_FILE];
            currentUser.isCurrentUser = YES;
        }
    }
    
    return currentUser;
}

+ (PFUser *)logInWithUsername:(NSString *)username password:(NSString *)password {
    return [self logInWithUsername:username password:password error:nil];
}

+ (PFUser *)logInWithUsername:(NSString *)username password:(NSString *)password error:(NSError **)error {
    PFCommand *loginCommand = [self constructLoginCommandWithUsername:username andPassword:password];
    return [self sendSyncRequestForCommand:loginCommand withError:error];
}

+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password {
    [self logInWithUsernameInBackground:username password:password target:nil selector:nil];
}

+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password target:(id)target selector:(SEL)selector {
    PFCommand *loginCommand = [self constructLoginCommandWithUsername:username andPassword:password];
    
    loginCommand.resultTarget = target;
    loginCommand.resultSelector = selector;
    
    [self sendAsyncRequestForCommand:loginCommand];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email {
    return [self requestPasswordResetForEmail:email error:nil];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email error:(NSError **)error {
    PFCommand *resetCommand = [self constructRequestPasswordReset:email];
    return [[self sendSyncRequestForCommand:resetCommand withError:error] boolValue];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email {
    [self requestPasswordResetForEmailInBackground:email withTarget:nil selector:nil];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email withTarget:(id)target selector:(SEL)selector {
    PFCommand *resetCommand = [self constructRequestPasswordReset:email];
    
    resetCommand.resultTarget = target;
    resetCommand.resultSelector = selector;
    
    [self sendAsyncRequestForCommand:resetCommand];
}

+ (void)logOut {
    [self deleteDataFile:CURRENT_USER_FILE];
    
    if (currentUser != nil) {
        [currentUser release];
    }
    
    currentUser = nil;
}

- (id)init {
	self = [super initWithClassName:USER_CLASS_NAME];
    
    if (self != nil) {
        username = nil;
        email = nil;
        password = nil;
        sessionToken = nil;
        isCurrentUser = NO;
    }
	return self;
}

- (void)setObject:(id)object forKey:(NSString *)key {
    if ([key isEqualToString:@"username"]) {
        [NSException raise:NSInvalidArgumentException format:@"Can't set the username field. Use the setter instead."];
    }
    if ([key isEqualToString:@"email"]) {
        [NSException raise:NSInvalidArgumentException format:@"Can't set the email field. Use the setter instead."];
    }
    [super setObject:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    if ([key isEqualToString:@"username"]) {
        [NSException raise:NSInvalidArgumentException format:@"Can't remove the username field for a PFUser."];
    }
    [super removeObjectForKey:key];
}

- (void)setUsername:(NSString *)newUsername {
    dirty = YES;
	[newUsername retain];
	[username release];
    username = newUsername;
    if (username) {
        [data setObject:username forKey:@"username"];
    }
}
	 
- (NSString *)username {
	return username;
}

- (void)setEmail:(NSString *)newEmail {
    dirty = YES;
	[newEmail retain];
	[email release];
    email = newEmail;
    if (email) {
        [data setObject:email forKey:@"email"];
    }
}

- (NSString *)email {
	return email;
}
	 
- (void)setPassword:(NSString *)newPassword {
	dirty = YES;
	[newPassword retain];
	[password release];
	password = newPassword;
}

- (NSString *)password {
	return password;
}

- (BOOL)signUp {
	return [self signUp:nil];
}

- (BOOL)signUp:(NSError **)error {
	[self checkSignUpParams];
	
    if (![self saveChildren:error]) { return NO; }
    
    return [self sendSyncRequestForCommand:[self constructSignUpCommand] withError:error];
}

- (void)signUpInBackground {
    [self signUpInBackgroundWithTarget:nil selector:nil];    
}

- (void)signUpInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self checkSignUpParams];
    [self runCommandAndSaveChildrenInBackgroundWithTarget:target selector:selector commandSelector:@selector(constructSignUpCommand)];
}

- (BOOL)isAuthenticated {
    return sessionToken != nil;
}

- (void)dealloc {
    [username release];
    [email release];
	[password release];
    [sessionToken release];
    [super dealloc];
}

#if NS_BLOCKS_AVAILABLE
+ (void)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password block:(PFUserResultBlock)block {
    PFCommand *loginCommand = [self constructLoginCommandWithUsername:username andPassword:password];
    loginCommand.userResultBlock = block;    
    [self sendAsyncRequestForCommand:loginCommand];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email block:(PFBooleanResultBlock)block {
    PFCommand *resetCommand = [self constructRequestPasswordReset:email];
    resetCommand.booleanResultBlock = block;
    [self sendAsyncRequestForCommand:resetCommand];
}

- (void)signUpInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self checkSignUpParams];
    [self runCommandAndSaveChildrenInBackgroundWithBlock:block commandSelector:@selector(constructSignUpCommand)];
}
#endif

@end
