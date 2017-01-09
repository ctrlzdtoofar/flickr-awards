//
//  CommunicationUtil.h
//  Flckr1
//
//  Created by Heather Stevens on 1/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import "ApiResponse.h"

@interface CommunicationsUtil : NSObject

#define RND_MOD_NUM 314550078

+ (NSString *) createNonce;

+ (NSString *) getSecondsSince1970;

+ (BOOL)lineHasHtmlEscapeSequences:(NSString *)currentLine; 

+ (int)checkTags:(NSString *) tagListString withOutTags: (NSString *) withOutTags forCurrentLine:(NSString *)currentLine usingPoints:(int)points;

+ (NSRange)findFirstWord:(NSString *) wordCommaDelimitedList inText:(NSString *)text;

+ (int)checkTags:(NSString *) tagListString forCurrentLine:(NSString *)currentLine usingPoints:(int)points;

+ (BOOL)textHasRepeatingChars:(NSString *)sourceText;

+ (BOOL)lineHasRepeatingChars:(NSString *)currentLine;

+ (NSString *)removeNonAlphaCharactersFrom: (NSString *) sourceText;

+ (NSString *)removeErrantEmbeddedTags:(NSString *)sourceText;

+ (NSString *)fixBrokenTag:(NSString *) tag inHtml:(NSString *)awardText;

+ (NSString *)fixBoundariesOfHtmlTags:(NSString *)sourceText;

+ (NSString *)fixImageTags:(NSString *)sourceText;

+ (NSString *) createSignature:(NSString *) dataToSign usingKey:(NSString *) key;

+ (NSString *) createSignatureUTF8:(NSString *) dataToSign usingKey:(NSString *) hashkey;

+ (NSString *) encodeBase64:(const uint8_t*) valueToEncode length:(NSInteger) length;

+ (NSString *) urlEncodeRFC3986: (NSString *) url;

+ (NSString *) decodeRFC3986:(NSString *)valueToDecode;

+ (NSArray *) getHtmlEscapedCodeShortList;

+ (NSArray *) getHtmlEscapedCodeSequences;

+ (NSString *) decodeHtmlEscapes:(NSString *)valueToDecode;

+ (NSString *) swapCRLFforHtmlBreak:(NSString *) sourceHtmlText;

+ (NSString *) swapHtmlBreakforCRLF:(NSString *) sourceHtmlText;

+ (NSString *)addBlackBackgroundToHTML:(NSString *) sourceHtmlText;

+ (NSString *) md5:(NSString *)str;

+ (ApiResponse *) sendHttpRequestWithUrl:(NSURL *)httpUrlQuery;

@end
