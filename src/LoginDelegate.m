//
//  LoginDelegate.m
//  Flckr1
//
//  Created by Heather Stevens on 1/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

/*
 
 Signing Requests
 
 You must sign all requests to the Flickr API. Currently, Flickr only supports HMAC-SHA1 signature encryption.
 
 First, you must create a base string from your request. The base string is constructed by concatenating the HTTP verb, the request URL, and all request parameters sorted by name, using lexicograhpical byte value ordering, separated by an '&'.
 
 Use the base string as the text and the key is the concatenated values of the Consumer Secret and Token Secret, separated by an '&'.
 
 For example, using the following URL:
 http://www.flickr.com/services/oauth/request_token
 &oauth_callback%3Dflckr1%253A%252F%252Foauthlogin%26
 oauth_consumer_key%3D5ba9a0182068c1193f16d5826570b5fa%26
 oauth_nonce%3D2315255808%26
 oauth_signature_method%3DHMAC-SHA1%26
 oauth_timestamp%3D1326435027
 */

#import "LoginDelegate.h"
#import <CommonCrypto/CommonHMAC.h>
#import "NetworkAvailability.h"
#import "MessageXmlParser.h"
#import "XmlParser.h"

@implementation LoginDelegate

@synthesize userSessionModel = _userSessionModel;

// Override the synthesize getter
- (UserSessionModel *)userSessionModel {
    if (!_userSessionModel) {
        _userSessionModel = [[UserSessionModel alloc] init];
    }
    return _userSessionModel;
}

// Return error message, may be nil.
- (NSString *)errorMessage {
    return self.userSessionModel.errorMessage;
}


// Return username, will have value only after login.
- (NSString *)userName {
    return self.userSessionModel.userName;
}

static NSString * const kGet                = @"GET&";
static NSString * const kRequestTokenURL    = @"http://www.flickr.com/services/oauth/request_token";
static NSString * const kFirstParamDelim    = @"?";
static NSString * const kParamDelim         = @"&";
static NSString * const kCallBack           = @"oauth_callback=FlickrAwards%3A%2F%2Foauthlogin";
static NSString * const kConsumerKey        = @"oauth_consumer_key=****************************";
static NSString * const kNonceLabel         = @"&oauth_nonce=";
static NSString * const kTimeStampLabel     = @"&oauth_timestamp=";
static NSString * const kVersion            = @"&oauth_version=1.0";
static NSString * const kSignature          = @"&oauth_signature=";
static NSString * const kSigMethod          = @"&oauth_signature_method=HMAC-SHA1";
static NSString * const kFlckrSecretKey     = @"*********************&";

static NSString * const kConfirmedTrue          = @"oauth_callback_confirmed=true";
static NSString * const kOauthTokenLabel        = @"oauth_token";
static NSString * const kOauthTokenSecretLabel  = @"oauth_token_secret";

static NSString * const kUserAuthURL        = @"http://www.flickr.com/services/oauth/authorize?oauth_token=";

static NSString * const kOauthTokenAT     = @"&oauth_token=";
static NSString * const kVerifierAT       = @"&oauth_verifier=";
static NSString * const kFullNameText     = @"fullname=";

static NSString * const kAccessTokenURL   = @"http://www.flickr.com/services/oauth/access_token";

// Create a Flickr Request Token
- (NSString *) createRequestToken {
    
    NSMutableString *requestParameters = [[NSMutableString alloc] initWithCapacity:300];      
    [requestParameters appendString:kCallBack];
    
    [requestParameters appendString:kParamDelim];
    [requestParameters appendString:kConsumerKey];
    
    [requestParameters appendString:kNonceLabel];
    [requestParameters appendString:[CommunicationsUtil createNonce]];
    
    [requestParameters appendString:kSigMethod];
    
    [requestParameters appendString:kTimeStampLabel];
    [requestParameters appendString:[CommunicationsUtil getSecondsSince1970]];
   
    [requestParameters appendString:kVersion];
    
    NSMutableString *requestUrlToSend = [[NSMutableString alloc] initWithCapacity:400]; 
    [requestUrlToSend appendString:kRequestTokenURL];
    [requestUrlToSend appendString:kFirstParamDelim];
    [requestUrlToSend appendString:requestParameters];    
    
    NSMutableString *requestUrlToSign = [[NSMutableString alloc] initWithCapacity:400]; 
    [requestUrlToSign appendString:kGet];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:kRequestTokenURL]]; 
    [requestUrlToSign appendString:kParamDelim];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:requestParameters]];
    //NSLog(@"LoginDelegate.createRequestToken, url to sign %@", requestUrlToSign);    
    
    [requestUrlToSend appendString:kSignature];
    [requestUrlToSend appendString:[CommunicationsUtil createSignature:requestUrlToSign usingKey:kFlckrSecretKey]];    
    //NSLog(@"LoginDelegate.createRequestToken, url to send %@", requestUrlToSend);
    
    return requestUrlToSend;
}

// Parses the Flickr response to get the error message so it can be displayed to the user.
- (NSString *)getFlickrMessageFromResponse:(NSString *) response {
    
    if (response) {
        XmlParser *xmlParser = [[XmlParser alloc] init];
        MessageXmlParser *messageXmlParser = [[MessageXmlParser alloc] init];
    
        if ([xmlParser parseXmlDocument:response withMapper:messageXmlParser]) { 
            return messageXmlParser.message;
        }        
    }
    
    return nil;
}

// Determine what error message to display for the user
- (void)determineErrorMessageToDisplay:(ApiResponse *) apiResponse {
    
    self.userSessionModel.errorMessage = nil;
    if (apiResponse.response) {
        self.userSessionModel.errorMessage = [self getFlickrMessageFromResponse:apiResponse.response];
    }
        
    if (!self.userSessionModel.errorMessage) {
    
        // There's been a problem, see if it is a network issue.
        if ([self.userSessionModel haveInternetBeOptimistic:NO]) {
            // See if we can get the error message from the response.
            self.userSessionModel.errorMessage = [apiResponse.errorMessage copy];            
        }       
    }
}

// Parse response to get oauth token
- (void)getTokenFromResponse:(NSString *) response {
    
    //NSLog(@"LoginDelegate.getTokenFromResponse response %@", response);
    
    NSArray *responseComponents = [response componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&="]];
    
    if ([kOauthTokenLabel isEqualToString:[responseComponents objectAtIndex:2]]) {
        
        self.userSessionModel.oauthToken = [responseComponents objectAtIndex:3];       
       // NSLog(@"LoginDelegate.getTokenFromResponse, found oauth token %@", self.userSessionModel.oauthToken);
    }
    else {
        NSLog(@"Unable to find oauth token, %@", response);
        self.userSessionModel.errorMessage = @"Flickr Authorization Problem";
    }    
   
    if ([kOauthTokenSecretLabel isEqualToString:[responseComponents objectAtIndex:4]]) {
        
        self.userSessionModel.oauthTokenSecret = [responseComponents objectAtIndex:5];       
       // NSLog(@"LoginDelegate.getTokenFromResponse, found oauth secret token %@", self.userSessionModel.oauthTokenSecret);
    }
    
}

// Parse the response to the request token.
- (BOOL)parseRequestTokenResponse:(NSString *)sResponse {   
    
    if ([sResponse hasPrefix:kConfirmedTrue]) {
        
        // Get Token and Token Secret
        [self getTokenFromResponse:sResponse];        
    }
    else {
        NSLog(@"Failed to confirm token request %@", sResponse);      
        
        self.userSessionModel.errorMessage = (@"Flickr Login Failed");
        return NO;
    }
    
    return YES;
}

// Send control to the browser so user can authorize this application to access thier content.
- (void)askFlickrForUserAuthorizationBySendingControlToYahoo {
    
    NSMutableString *requestUrlToSend = [[NSMutableString alloc] initWithCapacity:300]; 
    [requestUrlToSend appendString:kUserAuthURL];
    [requestUrlToSend appendString:self.userSessionModel.oauthToken];
    
    // Give control to Yahoo.
    NSURL *safariURL = [NSURL URLWithString:requestUrlToSend];
    
    //NSLog(@"LoginDelegate.askFlickrForUserAuthorizationBySendingControlToYahoo, request auth for app from user: %@",safariURL);
    
    [[UIApplication sharedApplication] openURL:safariURL];
}

// Carries out the first half of the login and authorization process.
- (BOOL)completeUserAuthorization {
    
    if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
         return NO;
    }

    NSString *tokenRequest = [self createRequestToken];    
    
    //NSLog(@"LoginDelegate.completeUserAuthorization, createRequestToken created %@",tokenRequest);    
    ApiResponse *apiResponse = [CommunicationsUtil sendHttpRequestWithUrl: [[NSURL alloc] initWithString:tokenRequest ]];
    
    if (apiResponse.errorMessage || !apiResponse.response) {
            
        if (apiResponse.response) {
            self.userSessionModel.errorMessage = [self getFlickrMessageFromResponse:apiResponse.response];
        }
            
        if (!self.userSessionModel.errorMessage) {
            self.userSessionModel.errorMessage = [apiResponse.errorMessage copy];
        }
    }
    else if ([self parseRequestTokenResponse:apiResponse.response]) {
        
        if (self.userSessionModel.oauthToken && self.userSessionModel.oauthTokenSecret) {
            //NSLog(@"user session established, token:%@ secret:%@", self.userSessionModel.oauthToken, self.userSessionModel.oauthTokenSecret);     
            self.userSessionModel.errorMessage = nil;
            [self askFlickrForUserAuthorizationBySendingControlToYahoo];
            return YES;
        }        
    }
    
    return NO;
}

/*
 Process response from Yahoo login, oauth_token=72157628859617357-6e538cfec5d43c3f&oauth_verifier=48a7b6d4c936c7b2
*/
- (BOOL)parseYahooUrlQuery:(NSString *)queryFromYahoo {
    
    if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
        return NO;
    }
     
    NSArray *queryComponents = [queryFromYahoo componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&="]];

    if ([self.userSessionModel.oauthToken isEqualToString:[queryComponents objectAtIndex:1]]) {
        
        self.userSessionModel.oauthVerifier = [queryComponents objectAtIndex:3]; 
        return YES;
    }
    else {
        NSLog(@"LoginDelegater.parseYahooUrlQuery,  Auth Token Mismatch, Ours:%@, from Yahoo:%@", self.userSessionModel.oauthToken, [queryComponents objectAtIndex:1]);
        self.userSessionModel.errorMessage = @"Authorization Error.";
    }
    
    // Errors...
    return NO;
}

/*
 Exa http request: http ://www.flickr.com/services/oauth/access_token?&oauth_consumer_key=5ba9a0182068c1193f16d5826570b5fa&oauth_nonce=3705667584&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1326524237&oauth_token=72157628861412911-d80471947fa375dd&oauth_verifier=8f02ecd513b991f5&oauth_version=1.0&oauth_signature=VZlF4kq1zXtvWUlDoYyZOaSJImA%3D
 
 Exa String to sign: GET&http%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Faccess_token&oauth_consumer_key%3D5ba9a0182068c1193f16d5826570b5fa%26oauth_nonce%3D3539992576%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1326555913%26oauth_token%3D72157628865781183-db53e14a95ac2642%26oauth_verifier%3D896f62a0c41f05e6%26oauth_version%3D1.0
 */
// Use the oauth token to get the access token.
- (NSString *)createAccessTokenRequest {
    
    NSMutableString *accessTokenRequestParameters = [[NSMutableString alloc] initWithCapacity:300];      
    
    [accessTokenRequestParameters appendString:kConsumerKey];
    
    [accessTokenRequestParameters appendString:kNonceLabel];
    [accessTokenRequestParameters appendString:[CommunicationsUtil createNonce]];
    
    [accessTokenRequestParameters appendString:kSigMethod];
    
    [accessTokenRequestParameters appendString:kTimeStampLabel];
    [accessTokenRequestParameters appendString:[CommunicationsUtil getSecondsSince1970]];
    
    [accessTokenRequestParameters appendString:kOauthTokenAT];
    [accessTokenRequestParameters appendString:self.userSessionModel.oauthToken];    
    
    [accessTokenRequestParameters appendString:kVerifierAT];
    [accessTokenRequestParameters appendString:self.userSessionModel.oauthVerifier];  
    
    [accessTokenRequestParameters appendString:kVersion];
    
    NSMutableString *requestUrlToSend = [[NSMutableString alloc] initWithCapacity:300]; 
    [requestUrlToSend appendString:kAccessTokenURL];
    [requestUrlToSend appendString:kFirstParamDelim];
    [requestUrlToSend appendString:accessTokenRequestParameters];    
    
    NSMutableString *requestUrlToSign = [[NSMutableString alloc] initWithCapacity:300]; 
    [requestUrlToSign appendString:kGet];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:kAccessTokenURL]]; 
    [requestUrlToSign appendString:kParamDelim];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:accessTokenRequestParameters]];
    //NSLog(@"LoginDelegate.createAccessTokenRequest urlToSign %@", requestUrlToSign);
    
    NSMutableString *keyForSigningRequest = [[NSMutableString alloc] initWithCapacity:100];
    [keyForSigningRequest appendString:kFlckrSecretKey];
    [keyForSigningRequest appendString:self.userSessionModel.oauthTokenSecret];
    
    [requestUrlToSend appendString:kSignature];
    [requestUrlToSend appendString:[CommunicationsUtil createSignature:requestUrlToSign usingKey:keyForSigningRequest]];    
    
    //NSLog(@"LoginDelegate.createAccessTokenRequest request %@", requestUrlToSend);
    return requestUrlToSend;

}

/*
fullname=Heather%20Stevens&oauth_token=72157628865866341-fbc415f68c67449a&oauth_token_secret=133da1e1276c0265&user_nsid=59195110%40N02&username=Heather92115
 */
// Parse the response to the request token.
- (BOOL)parseAccessTokenResponse:(NSString *)sResponse {   
        
    //NSLog(@"LoginDelegate.parseAccessTokenResponse response %@", sResponse);
    
    if ([sResponse hasPrefix:kFullNameText]) {
        NSArray *responseComponents = [sResponse componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&="]];
        
        if ([responseComponents count] >= 10) {
        
            self.userSessionModel.fullName = [responseComponents objectAtIndex:1];
        
            if ([kOauthTokenLabel isEqualToString:[responseComponents objectAtIndex:2]]) {
            
                
                self.userSessionModel.accessToken = [responseComponents objectAtIndex:3];                
                self.userSessionModel.accessTokenSecret = [responseComponents objectAtIndex:5];
                
                // Decode the UserNsid for later use.
                //self.userSessionModel.userNsid = [CommunicationsUtil decodeRFC3986:[responseComponents objectAtIndex:7]];
                self.userSessionModel.userNsid = [responseComponents objectAtIndex:7];
                
                self.userSessionModel.userName = [responseComponents objectAtIndex:9];
                
                if (self.userSessionModel.accessToken && 
                    self.userSessionModel.accessTokenSecret &&
                    self.userSessionModel.userNsid &&
                    self.userSessionModel.userName) {
                    
                    return YES;
                }
                
            }
            else {
                NSLog(@"Unable to find oauth token");
                self.userSessionModel.errorMessage = @"Unable to establish communications with Flickr";
            }  
        }
        else {
            NSLog(@"Not enough parameters found, %d", [responseComponents count]);
            self.userSessionModel.errorMessage = @"Unable to establish communications with Flickr";    
        }
    }
    else {
        NSLog(@"Failed to confirm access request %@", sResponse);
        self.userSessionModel.errorMessage = (@"Failed to complete login with Flickr");        
    }
    
    return NO;
}

// Called after Yahoo login completes. Second half of login process.
- (BOOL)finishUserAuthorization:(NSString *)queryFromYahoo {

    if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
        return NO;
    }
        
    if ([self parseYahooUrlQuery:queryFromYahoo]) {
        
        // Create the access token request        
        NSString *accessRequest = [self createAccessTokenRequest];       
        
        // Loop up to three times because of Flickr API bug.
        for (int index=0; index <= 3; index++) {        
            ApiResponse *apiResponse = [CommunicationsUtil sendHttpRequestWithUrl: [[NSURL alloc] initWithString:accessRequest]];        
        
            if (apiResponse.errorMessage || !apiResponse.response) {                    
                [self determineErrorMessageToDisplay:apiResponse];
                
                if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
                    return NO;
                }
            }
            else if (apiResponse.response) {
                if ([self parseAccessTokenResponse:apiResponse.response]) {
                    self.userSessionModel.errorMessage = nil;
                    return YES;
                }
            }
            
            // Sleep for one second to see if Flickr will become happy.
            [NSThread sleepForTimeInterval:1.0];
        }
    }
    
    return NO;
}

@end
