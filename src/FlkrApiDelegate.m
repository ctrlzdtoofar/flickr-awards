//
//  FlkrApiDelegate.m
//  Flckr1
//
//  Created by Heather Stevens on 1/15/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "FlkrApiDelegate.h"
#import "MessageXmlParser.h"
#import "XmlParser.h"
#import "GeneralUtil.h"

@implementation FlkrApiDelegate

@synthesize userSessionModel = _userSessionModel;

static NSString * const kGet                = @"GET&";
static NSString * const kHttpRequest        = @"http://api.flickr.com/services/rest";

static NSString * const kCommentId          = @"comment_id=";
static NSString * const kCommentText        = @"comment_text=";
static NSString * const kContentType        = @"content_type=1&";
static NSString * const kExtras             = @"&extras=";
static NSString * const kExtrasViews        = @"extras=views&";
static NSString * const kUrl_S              = @"url_s";
static NSString * const kFormat             = @"format=rest";
static NSString * const kGroupNsid          = @"&group_id=";
static NSString * const kMethod             = @"&method=";

static NSString * const kOauthConsumerKey   = @"&oauth_consumer_key=5ba9a0182068c1193f16d5826570b5fa";
static NSString * const kOauthNonce         = @"&oauth_nonce=";
static NSString * const kOauthTimeStamp     = @"&oauth_timestamp=";
static NSString * const kOauthToken         = @"&oauth_token=";
static NSString * const kOauthSigMethod     = @"&oauth_signature_method=HMAC-SHA1";
static NSString * const kOauthVersion       = @"&oauth_version=1.0";
static NSString * const kPerPage            = @"&per_page=500"; // for user's photos
static NSString * const kPhotoId            = @"&photo_id=";
static NSString * const kPrivacyFilter      = @"&privacy_filter=1";
static NSString * const kSafeSearch         = @"&safe_search=2"; // moderate

static NSString * const kUserNsid           = @"&user_id=";

static NSString * const kOauthSignature     = @"&oauth_signature="; // The signature parameter
static NSString * const kFirstParamDelim    = @"?";
static NSString * const kParamDelim         = @"&";
static NSString * const kEquals             = @"=";

static NSString * const kFlckrSecretKey     = @"b25999f1bde04dd4&"; // For signing

// Initialize the login delegate with the current internet connectivity and register to 
// to receive connectivity updates.
- (id) init {
    self = [super init];
    if (self) {
    }
    
    return self;
}

// Create a Flickr API request.
// All parameters must be in alphabetical order.
- (NSURL *)createRequest:(NSString *)method forUser:(NSString *)userNsid forGroup:(NSString *)groupNsid forPhoto:(NSString *)photoId withComent:(NSString *)commentText {
    
    NSMutableString *requestParameters = [[NSMutableString alloc] initWithCapacity:2000];      

    if (commentText) {
        
        if ([method isEqualToString:@"flickr.photos.comments.deleteComment"]) {
            [requestParameters appendString:kCommentId];        }
        else {
            [requestParameters appendString:kCommentText];
        }
        
        // Dbl encode comment text/id
        NSString *dblEncodedComment = [CommunicationsUtil urlEncodeRFC3986:commentText];
        //NSLog(@"encode comment %@", dblEncodedComment);
        [requestParameters appendString:dblEncodedComment];
        [requestParameters appendString:kParamDelim];        
    }
    
    if ([method isEqualToString:@"flickr.people.getPhotos"]) {
        [requestParameters appendString:kContentType];
    }
    
    // Ask for extra content, views
    if ([method isEqualToString:@"flickr.people.getPhotos"] ||
        [method isEqualToString:@"flickr.groups.pools.getPhotos"]) {
         [requestParameters appendString:kExtrasViews];        
    }
    
    [requestParameters appendString:kFormat];
        
    if (groupNsid) {
        [requestParameters appendString:kGroupNsid];
        
        // The group nsid has to be double encoded, so here's the first time. The whole signed request is encoded again later.
        NSString *encodedGroupNsid = [CommunicationsUtil urlEncodeRFC3986:groupNsid];  
        
        
        [requestParameters appendString:encodedGroupNsid];
    }
    
    [requestParameters appendString:kMethod];
    [requestParameters appendString:method];

    [requestParameters appendString:kOauthConsumerKey];
    
    [requestParameters appendString:kOauthNonce];
    [requestParameters appendString:[CommunicationsUtil createNonce]];
    
    [requestParameters appendString:kOauthSigMethod];
    
    [requestParameters appendString:kOauthTimeStamp];
    [requestParameters appendString:[CommunicationsUtil getSecondsSince1970]];
    
    [requestParameters appendString:kOauthToken];
    [requestParameters appendString:self.userSessionModel.accessToken];    
    
    [requestParameters appendString:kOauthVersion];
    
    if ([method isEqualToString:@"flickr.people.getPhotos"]) {
        [requestParameters appendString:kPerPage];
    }
    
    if (photoId) {
        [requestParameters appendString:kPhotoId];
        [requestParameters appendString:photoId];
    }
    
    if ([method isEqualToString:@"flickr.people.getPhotos"]) {
        [requestParameters appendString:kPrivacyFilter];
        [requestParameters appendString:kSafeSearch];        
    }
    
    if (userNsid) {
        [requestParameters appendString:kUserNsid];
        [requestParameters appendString:userNsid];
    }
    
    NSMutableString *requestUrlToSend = [[NSMutableString alloc] initWithCapacity:2000]; 
    [requestUrlToSend appendString:kHttpRequest];
    [requestUrlToSend appendString:kFirstParamDelim];
    [requestUrlToSend appendString:requestParameters];

    
    NSMutableString *requestUrlToSign = [[NSMutableString alloc] initWithCapacity:2000]; 
    [requestUrlToSign appendString:kGet];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:kHttpRequest]]; 
    [requestUrlToSign appendString:kParamDelim];
    
    NSString *encodedRequestParameters = [CommunicationsUtil urlEncodeRFC3986:requestParameters];
    [requestUrlToSign appendString:encodedRequestParameters];
    
    //NSLog(@"FlkrApiDelegate.createRequest urlToSign %@", requestUrlToSign);
    
    NSMutableString *keyForSigningRequest = [[NSMutableString alloc] initWithCapacity:500];
    [keyForSigningRequest appendString:kFlckrSecretKey];
    [keyForSigningRequest appendString:self.userSessionModel.accessTokenSecret];
    
    [requestUrlToSend appendString:kOauthSignature];
    [requestUrlToSend appendString:[CommunicationsUtil createSignature:requestUrlToSign usingKey:keyForSigningRequest]];    
    
    //NSLog(@"FlkrApiDelegate.createRequest request %@", requestUrlToSend);
    return [[NSURL alloc] initWithString:requestUrlToSend];    
}

// Adds required parameters, sorts parameters alphabetically, then appends all params into a string.
- (NSString *)getRequiredStaticApiParamters:(NSMutableArray *)apiRequestParameters {
    
    NSMutableString *tempParam = [[NSMutableString alloc] initWithCapacity:40];
    
    [apiRequestParameters addObject:kOauthConsumerKey];
    
    [tempParam appendString:kOauthNonce];
    [tempParam appendString:[CommunicationsUtil createNonce]];
    [apiRequestParameters addObject:tempParam];
    
    [apiRequestParameters addObject:kOauthSigMethod];
    
    [tempParam setString: @""];
    [tempParam appendString:kOauthTimeStamp];
    [tempParam appendString:[CommunicationsUtil getSecondsSince1970]];
    [apiRequestParameters addObject:tempParam];
    
    [tempParam setString: @""];
    [tempParam appendString:kOauthToken];
    [tempParam appendString:self.userSessionModel.accessToken];
    [apiRequestParameters addObject:tempParam];
    
    [apiRequestParameters addObject:kOauthVersion];

     NSArray *groupList = [apiRequestParameters sortedArrayUsingSelector:@selector(compare:)];
     NSMutableString *requestParameters = [[NSMutableString alloc] initWithCapacity:2000];
    
    for (NSMutableString *param in groupList) {
        [requestParameters appendString:param];
    }
    
     return requestParameters;
}

- (NSURL *)getFlickrApiUrl:(NSMutableArray *)apiRequestParameters {

    NSString *requestParameters = [self getRequiredStaticApiParamters:apiRequestParameters];
    
    NSMutableString *requestUrlToSend = [[NSMutableString alloc] initWithCapacity:2000];
    [requestUrlToSend appendString:kHttpRequest];
    [requestUrlToSend appendString:kFirstParamDelim];
    [requestUrlToSend appendString:requestParameters];
    
    
    NSMutableString *requestUrlToSign = [[NSMutableString alloc] initWithCapacity:2000];
    [requestUrlToSign appendString:kGet];
    [requestUrlToSign appendString:[CommunicationsUtil urlEncodeRFC3986:kHttpRequest]];
    [requestUrlToSign appendString:kParamDelim];
    
    NSString *encodedRequestParameters = [CommunicationsUtil urlEncodeRFC3986:requestParameters];
    [requestUrlToSign appendString:encodedRequestParameters];
    
    //NSLog(@"FlkrApiDelegate.createRequest urlToSign %@", requestUrlToSign);
    
    NSMutableString *keyForSigningRequest = [[NSMutableString alloc] initWithCapacity:500];
    [keyForSigningRequest appendString:kFlckrSecretKey];
    [keyForSigningRequest appendString:self.userSessionModel.accessTokenSecret];
    
    [requestUrlToSend appendString:kOauthSignature];
    [requestUrlToSend appendString:[CommunicationsUtil createSignature:requestUrlToSign usingKey:keyForSigningRequest]];
    
    //NSLog(@"FlkrApiDelegate.createRequest request %@", requestUrlToSend);
    return [[NSURL alloc] initWithString:requestUrlToSend];
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
    if (apiResponse.response) {
        self.userSessionModel.errorMessage = [self getFlickrMessageFromResponse:apiResponse.response];
    }
    
    if (!self.userSessionModel.errorMessage) {
        
        NetworkAvailability *networkAvailability = [[NetworkAvailability alloc] init];
        self.userSessionModel.networkStatus = [networkAvailability getNetworkStatus];  	
        
        if (!self.userSessionModel.networkStatus == wiFiConnection && !self.userSessionModel.networkStatus == cellularConnection) {
            self.userSessionModel.errorMessage = kNoNetworkConnectivity;
        }
        else {
            self.userSessionModel.errorMessage = [apiResponse.errorMessage copy];
        }
    }
}

// Create an api request, send it to Flickr and get response.
// Refactored version.
- (ApiResponse *)makeRequest:(NSMutableArray *)paramList {
    
    // Check for network availability
    if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
        ApiResponse *response = [[ApiResponse alloc] init];
        response.errorMessage = kNoNetworkConnectivity;
        return response;
    }
    
    NSURL *userPhotosRequest = [self getFlickrApiUrl:paramList];
    
    NSLog(@"FlkrApiDelegate.makeRequest url: %@", userPhotosRequest.absoluteString);
    
    // Monitoring purposes.
    NSDate *startTime = [NSDate date];
    
    ApiResponse *apiResponse = [CommunicationsUtil sendHttpRequestWithUrl:userPhotosRequest];
    
    if (apiResponse.errorMessage) {
        self.userSessionModel.errorMessage = apiResponse.errorMessage;
        NSLog(@"FlkrApiDelegate.makeRequest failed url: %@", userPhotosRequest.debugDescription);
        NSLog(@"FlkrApiDelegate.makeRequest failed response: %@", apiResponse.response);
    }
    else {
        self.userSessionModel.errorMessage = nil;
    }
    
    NSTimeInterval secsApart = abs([startTime timeIntervalSinceDate:[NSDate date]]);
    if (secsApart >= 1.0) {
        NSLog(@"!!!FlkrApiDelegate.makeRequest slow response for url %@, sec %f", userPhotosRequest.debugDescription, secsApart);
    }
    
    NSLog(@"FlkrApiDelegate.makeRequest finished request url %@ with response %@",
          userPhotosRequest.debugDescription, apiResponse.response);
    
    return apiResponse;
}

// Create an api request, send it to Flickr and get response.
- (ApiResponse *)makeRequest:(NSString *)method  forUser:(NSString *)userNsid forGroup:(NSString *)groupNsid forPhoto:(NSString *)photoId withComment:(NSString *)commentText {
    
    // Check for network availability
    if (![self.userSessionModel haveInternetBeOptimistic:YES]) {
        ApiResponse *response = [[ApiResponse alloc] init];
        response.errorMessage = kNoNetworkConnectivity;
        return response;
    }
    
    NSURL *userPhotosRequest = [self createRequest:method forUser:userNsid forGroup:groupNsid forPhoto:photoId withComent:commentText];    
    //NSLog(@"FlkrApiDelegate.makeRequest url: %@", userPhotosRequest.absoluteString);
    
    // Monitoring purposes.
    NSDate *startTime = [NSDate date];  
    
    ApiResponse *apiResponse = [CommunicationsUtil sendHttpRequestWithUrl:userPhotosRequest];

    if (apiResponse.errorMessage) {
        self.userSessionModel.errorMessage = apiResponse.errorMessage;        
        NSLog(@"FlkrApiDelegate.makeRequest failed url: %@", userPhotosRequest.debugDescription);
        NSLog(@"FlkrApiDelegate.makeRequest failed response: %@", apiResponse.response);
    }
    else {
        self.userSessionModel.errorMessage = nil;
    }
    
    NSTimeInterval secsApart = abs([startTime timeIntervalSinceDate:[NSDate date]]);
    if (secsApart >= 1.0) {
        NSLog(@"!!!FlkrApiDelegate.makeRequest slow response for url %@, sec %f", userPhotosRequest.debugDescription, secsApart);
    }    
    
    return apiResponse;    
}   

// Create an api request, send it to Flickr and get response.
- (ApiResponse *)makeRequest:(NSString *)method  forUser:(NSString *)userNsid forGroup:(NSString *)groupNsid forPhoto:(NSString *)photoId {
    
    return [self makeRequest:method forUser:userNsid forGroup:groupNsid forPhoto:photoId withComment:nil];
}

// See if we can issue an actual api command. If so, the login is good.
- (BOOL)testLogin {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.test.login" forUser:nil forGroup:nil forPhoto:nil];
    NSLog(@"FlkrApiDelegate.testLogin response: %@", apiResponse.response);
    
    if (apiResponse.errorMessage) {
        // Don't display this error, it may be that the user's login expired or isn't valid.
        return NO;
    }    
    
    return YES;
}

// Get list of user's photos, 1st 100.
- (NSString *)peopleGetPhotos {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.people.getPhotos" forUser:self.userSessionModel.userNsid forGroup:nil forPhoto:nil];

    if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];
        return nil;
    }
    
    return apiResponse.response;
}

// Get user's groups
- (NSString *)getUserGroups {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.groups.pools.getGroups" forUser:nil forGroup:nil forPhoto:nil];
    
    if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];
        return nil;
    }
    
    return apiResponse.response;
}

// Parse the response from Flickr to make sure the photo was added sin error.
- (BOOL)verifyResponse:(ApiResponse *) apiResponse {
    
    XmlParser *xmlParser = [[XmlParser alloc] init];
    MessageXmlParser *messageXmlParser = [[MessageXmlParser alloc] init];
    [xmlParser parseXmlDocument:apiResponse.response withMapper:messageXmlParser];
 
    if (!messageXmlParser.successfulApiInvocation) {
        [self determineErrorMessageToDisplay:apiResponse];
        return NO;
    }
    
    return YES;
}

// Add photo to group.
- (BOOL)addPhotoToGroup:(NSString *)groupNsid forPhoto:(NSString *)photoId {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.groups.pools.add" forUser:nil forGroup:groupNsid forPhoto:photoId];
    
     if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];
        return NO;
    }
    else if (![self verifyResponse:apiResponse]) {
        return NO;
    }
    
    return YES;
}

// Get list of photos for group
- (NSString *)getPhotoPoolFromGroup:(NSString *)groupNsid {

    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.groups.pools.getPhotos" forUser:nil forGroup:groupNsid forPhoto:nil];
        
    if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];
        return nil;
    }
    
    return apiResponse.response;
}



// Determine what error message to display for the user
- (NSString *)getCommentIdFromResponse:(ApiResponse *) apiResponse {
    
    if (apiResponse.response) {
        XmlParser *xmlParser = [[XmlParser alloc] init];
        MessageXmlParser *messageXmlParser = [[MessageXmlParser alloc] init];
        
        if ([xmlParser parseXmlDocument:apiResponse.response withMapper:messageXmlParser]) { 
            return messageXmlParser.commentId;
        }        
    }
    
    return nil;
}

// Add award (comment) to photo.
- (BOOL)addAward:(NSString *) awardHtml toPhoto:(Photo **)photo {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.photos.comments.addComment" forUser:nil forGroup:nil forPhoto:[*photo photoId] withComment:awardHtml];
    
    NSLog(@"FlickrAwards.addPhotoToGroup addAward: %@ error: %@", apiResponse.response, apiResponse.errorMessage); 
    
    if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];  
        return NO;
    }
    else if (![self verifyResponse:apiResponse]) {
        return NO;
    }
    
    [*photo setCommentId:[ self getCommentIdFromResponse:apiResponse]];
    
    return YES;
}

// Remove award (comment) from photo using the comment id.
- (BOOL)removeAward:(NSString *) commentId {
    
    ApiResponse *apiResponse = [self makeRequest:@"flickr.photos.comments.deleteComment" forUser:nil forGroup:nil forPhoto:nil withComment:commentId];
    
     if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];  
        return NO;
    }
    else if (![self verifyResponse:apiResponse]) {
        return NO;
    }
     
    return YES;
}

// Get specifed user's photo from specifed group
- (NSString *)getUsersPhotosFromGroup:(NSString *)groupNsid {
    
    NSMutableArray *methodParamList = [[NSMutableArray alloc] init];

    [methodParamList addObject:[GeneralUtil concatenateStrings:kMethod with:@"flickr.groups.pools.getPhotos"]];
    [methodParamList addObject:[GeneralUtil concatenateStrings:kUserNsid with:self.userSessionModel.userNsid]];
    [methodParamList addObject:[GeneralUtil concatenateStrings:kGroupNsid with:[CommunicationsUtil urlEncodeRFC3986:groupNsid]]];
 
    ApiResponse *apiResponse = [self makeRequest:methodParamList];
    
    if (apiResponse.errorMessage) {
        [self determineErrorMessageToDisplay:apiResponse];
        return nil;
    }
    
    return apiResponse.response;
}

@end
