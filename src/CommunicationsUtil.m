//
//  CommunicationsUtil.m
//
//  Flckr1, Used to facilitate Flickr.com api communications. Contains low level resuable methods.
//
//  Created by Heather Stevens on 1/12/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "CommunicationsUtil.h"

@implementation CommunicationsUtil

// Create random number for oauth nonce
+ (NSString *)createNonce {
    
    u_int32_t rndNum = arc4random()%RND_MOD_NUM;    
    return [NSString stringWithFormat:@"%u", rndNum];
}

// Get the number of secs between now and 1/1/1970
+ (NSString *)getSecondsSince1970 {
    
    NSDate *sinceNow = [[NSDate alloc] init];    
    double secsSince1970 = [sinceNow timeIntervalSince1970];    
    return [NSString stringWithFormat:@"%10.0f", secsSince1970];    
}

// Check for html escape codes, they are used to display html on an html page.
+ (BOOL)lineHasHtmlEscapeSequences:(NSString *)currentLine {
    
    BOOL foundCodes = NO;
    
    NSArray *escapeCodeList = [CommunicationsUtil getHtmlEscapedCodeShortList];
    for (NSString *escapeCode in escapeCodeList) {
        NSRange escapeRange = [currentLine rangeOfString:escapeCode options:NSCaseInsensitiveSearch];
        if (escapeRange.length > 0) {
            foundCodes = YES;
            break;
        }
        
    }
    
    return foundCodes;
}


// Check for keywords/tags that may be found in or leading up to an award.
+ (int)checkTags:(NSString *) tagListString withOutTags: (NSString *) withOutTags forCurrentLine:(NSString *)currentLine usingPoints:(int)points {
    
    int matches = 0;
    NSArray *tagList = [withOutTags componentsSeparatedByString:@","];
    for (NSString *tag in tagList) {
        
        NSRange tagRange = [currentLine rangeOfString:tag options:NSCaseInsensitiveSearch];
        if (tagRange.length != 0) {
            return 0;
        }
    }    
    
    matches = 0;
    tagList = [tagListString componentsSeparatedByString:@","];
    for (NSString *tag in tagList) {
        
        NSRange tagRange = [currentLine rangeOfString:tag options:NSCaseInsensitiveSearch];
        if (tagRange.length != 0) {
            matches += points;
        }
    }
    
    return matches;
}

// Determine if any of the words passed in are in the text, if so return the first word found.
+ (NSRange)findFirstWord:(NSString *) wordCommaDelimitedList inText:(NSString *)text {
    
    NSRange wordRange = NSMakeRange(0, 0);
    NSArray *wordList = [wordCommaDelimitedList componentsSeparatedByString:@","];
    for (NSString *word in wordList) {
        
        if (word.length < text.length) {
            wordRange = [text rangeOfString:word options:NSCaseInsensitiveSearch];
            if (wordRange.length != 0) {            
                break;
            }
        }
    }
    
    return wordRange;
}

// Check for keywords/tags that may be found in or leading up to an award.
+ (int)checkTags:(NSString *) tagListString forCurrentLine:(NSString *)currentLine usingPoints:(int)points {
    
    int matches = 0;
    NSArray *tagList = [tagListString componentsSeparatedByString:@","];
    for (NSString *tag in tagList) {
        
        NSRange tagRange = [currentLine rangeOfString:tag options:NSCaseInsensitiveSearch];
        if (tagRange.length != 0) {
            matches += points;
        }
    }
    
    return matches;
}

// Detect repeating chars
#define REPEATING_CHARS_TEST_TEXT_CHARS 12
#define REPEATS_REQUIRED 5

// Look for line with repeating chars on the first few chars of the line.
+ (BOOL)lineHasRepeatingChars:(NSString *)currentLine {
        
    if (currentLine.length > REPEATING_CHARS_TEST_TEXT_CHARS) {
        int matchCount = 0;
        
        const char *lineCharList = [currentLine UTF8String];
        
        char startChar = lineCharList[0];
        int index;        
        
        for (int start = 1; start+REPEATS_REQUIRED < currentLine.length;start+=REPEATING_CHARS_TEST_TEXT_CHARS) {
            
            for (index = start; index < start+REPEATING_CHARS_TEST_TEXT_CHARS && index < currentLine.length; index++) {
            
                if (startChar == lineCharList[index] && ' ' != startChar && '\t' != startChar) {
                    matchCount++;
                }
                else {
                    startChar = lineCharList[index];
                    matchCount = 0;
                }    
            
                if (matchCount >= REPEATS_REQUIRED) {
                    return YES;
                }
            }            
        }        

        NSMutableSet *lineChars = [[NSMutableSet alloc] init];
        for (int index = 0; index < REPEATING_CHARS_TEST_TEXT_CHARS; index++) {
                
            NSString *charToAdd = [currentLine substringWithRange:NSMakeRange(index, 1)];
                
            [lineChars addObject: charToAdd];
        }
            
        if (REPEATING_CHARS_TEST_TEXT_CHARS/lineChars.count >= 4) {
                
            return YES;
        }        
    }
    
    return NO;
}

// Removes non alpha chars from a string.
+ (NSString *)removeNonAlphaCharactersFrom: (NSString *) sourceText {

    NSMutableString *workStr = [[NSMutableString alloc] init];
    const char *lineCharList = [sourceText UTF8String];
    
    for (int index = 0; index < sourceText.length; index++) {
        char tempChar = lineCharList[index];
        
        if ((tempChar >= 'A' && tempChar <= 'Z') || (tempChar >= 'a' && tempChar <= 'b')) {
            [workStr appendFormat:@"%c", tempChar];
        }
    }
    return workStr;    
}

// Look for a section of text with repeating chars.
+ (BOOL)textHasRepeatingChars:(NSString *)sourceText {
    
    BOOL isRepeatingChars = NO;
    
    if (sourceText.length > REPEATING_CHARS_TEST_TEXT_CHARS) {
        int matchCount = 0;
        
        
        const char *lineCharList = [sourceText UTF8String];
        
        for (int offset = 0; offset <= sourceText.length;offset += REPEATING_CHARS_TEST_TEXT_CHARS) {
            
            char startChar = lineCharList[offset];
            for (int index = offset; index < offset+REPEATING_CHARS_TEST_TEXT_CHARS && index < sourceText.length; index++) {
                
                if (startChar == lineCharList[index] && ' ' != startChar && '\t' != startChar) {
                    matchCount++;
                }
                else {
                    startChar = lineCharList[index];
                    matchCount = 0;
                }    
                
                if (matchCount >= REPEATS_REQUIRED*3) {
                    isRepeatingChars = YES;
                    break;
                }
            }
        }
    }
    
    return isRepeatingChars;
}

static NSString * const kLessThan            = @"<";
static NSString * const kGreaterThan         = @">";
+ (NSString *)removeErrantEmbeddedTags:(NSString *)sourceText {
    
    if (!sourceText || sourceText.length == 0) {
        return sourceText;
    }
    
    NSMutableString *workText = [[NSMutableString alloc] initWithCapacity:sourceText.length];
    NSArray *ltArray = [sourceText componentsSeparatedByString:kLessThan];
    
    int embeddedTagCount = 0;
    BOOL hasLessThanInFront = NO;
    if ([sourceText hasPrefix:kLessThan]) {
        hasLessThanInFront = YES; //means the first loop should be checked
        //NSLog(@"CommunicationsUtil, Starts w <");
    }
    
    for (NSString *seq in ltArray) {        
        
        //NSLog(@"embeddedTagCount=%d, seq to process  %@", embeddedTagCount, seq);
        
        if (!seq || seq.length == 0) {
            continue;
        }
        
        NSRange range = [seq rangeOfString:kGreaterThan];
        
        // See if no gtr than char was found and if we are after at least one less than char
        if (range.location == NSNotFound && hasLessThanInFront) {
            // This means the next string sequence starts with an embedded tag (or this is a dbl embedded seq).
            embeddedTagCount++;
            
            // This seq is in front of an errant embedded tag.
            if (embeddedTagCount == 1) {
                [workText appendString:kLessThan];
                [workText appendString:seq]; 
                //NSLog(@"CommunicationsUtil, in front of embedded tag, workText=%@", workText.description);
            }
        }
        // An dbl+ embedded sequence was previously detected and this > ends it.
        else if (embeddedTagCount > 1) {            
            embeddedTagCount--;  
            //NSLog(@"dbl embedded seq!!");
        } 
        // Embedded tag(s) ended, add text after the errant tag
        else if (embeddedTagCount == 1) {
            embeddedTagCount--;           
            [workText appendString:@" "];
            [workText appendString:[seq substringFromIndex:range.location+1]];
            
            //NSLog(@"CommunicationsUtil, embedded tag ended, adding good portion of seq, workText=%@", workText.description); 
        }
        else if (hasLessThanInFront) {
            [workText appendString:kLessThan];
            [workText appendString:seq];
            //NSLog(@"CommunicationsUtil, seq is fine & put less than back, workText=%@", workText.description);
        } 
        else {
            [workText appendString:seq];
            //NSLog(@"CommunicationsUtil, seq is fine, workText=%@", workText.description);
        }
        
        // If we loop it will be after at least one less than or more.
        hasLessThanInFront = YES;
    }
    
    // See if the 1st '<' should be removed.
    if (![sourceText hasPrefix:@"<"]) {
        
        //NSLog(@"CommunicationsUtil, Removing 1st <");
        [workText replaceCharactersInRange:NSMakeRange(1,0) withString:@""];
        
    }    
    
    //NSLog(@"CommunicationsUtil.removeErrantEmbeddedTags, done, workText=%@", workText.description);
    return workText.description;
}

static NSString * const kHref = @"href=\"";
static NSString * const kImg = @"src=\"";
static NSString * const kHrefNoQuot = @"href=http";
static NSString * const kImgNoQuot = @"src=http";
static NSString * const kHrefWithQuot = @"href=\"http";
static NSString * const kImgWithQuot = @"src=\"http";
static NSString * const kDblQuote = @"\"";
static NSString * const kJpgEndWithSlash = @".jpg/";
static NSString * const kGifEndWithSlash = @".gif/";
static NSString * const kJpgEndWithoutSlash = @".jpg";
static NSString * const kGifEndWithoutSlash = @".gif";
static NSString * const kHrefWithoutGtrThen = @">a href";
static NSString * const kHrefWithGtrThen = @"><a href";
static NSString * const kImgWithoutGtrThen = @">img ";
static NSString * const kImgWithGtrThen = @"><img ";
static unichar const kSpace = ' ';
static unichar const kDblQuoteChar = '"';
static unichar const kGreaterThanChar = '>';

// Find tags with missing quotes at the end that need to be fixed.
+ (NSString *)fixBrokenTag:(NSString *) tag inHtml:(NSString *)awardText {
    
    NSMutableString *workText = [[NSMutableString alloc] initWithString:awardText];
    
    // Look for tags to check for errors.

    NSRange tagRange;
    NSRange searchRange = NSMakeRange(0, workText.length);
    //NSLog(@"CommunicationsUtil.fixBrokenTag first  search range %@", NSStringFromRange(searchRange));
    // Loop thru each instance of the tag to check
    do {
        tagRange = [workText rangeOfString:tag options:NSCaseInsensitiveSearch range:searchRange];
        //NSLog(@"CommunicationsUtil.fixBrokenTag tagRange %@", NSStringFromRange(tagRange));
        
        if (tagRange.length != 0) {
            int index;
            for (index = tagRange.location+tagRange.length+1;index <workText.length;index++) {
            
                if ([workText characterAtIndex:index] == kDblQuoteChar) {
                    // This is good;
                    break;
                }
                else if ([workText characterAtIndex:index] == kSpace || [workText characterAtIndex:index] == kGreaterThanChar) {
                    // Found end of tag before quote, needs to be fixed.
                    [workText insertString:kDblQuote atIndex:index];                
                    //NSLog(@"CommunicationsUtil.fixBrokenTag added dbl quote at %d, new len %d, text: %@", index, workText.length,workText);
                    break;
                }
            }
            
            searchRange = NSMakeRange(index, workText.length-index);            
            //NSLog(@"CommunicationsUtil.fixBrokenTag next search range %@", NSStringFromRange(searchRange));
        }
        
    } while (tagRange.length != 0);
    
    //NSLog(@"CommunicationsUtil.fixBrokenTag returning %@", workText);
    return workText.description;
}

// Look for broken links and tags found in some of the group awards.
+ (NSString *)fixBoundariesOfHtmlTags:(NSString *)sourceText {    
    
    NSString *fixedText = [sourceText stringByReplacingOccurrencesOfString:kHrefNoQuot withString:kHrefWithQuot];
    fixedText = [fixedText stringByReplacingOccurrencesOfString:kImgNoQuot withString:kImgWithQuot];
    fixedText = [fixedText stringByReplacingOccurrencesOfString:kHrefWithoutGtrThen withString:kHrefWithGtrThen];
    fixedText = [fixedText stringByReplacingOccurrencesOfString:kImgWithoutGtrThen withString:kImgWithGtrThen];
    fixedText = [CommunicationsUtil fixBrokenTag:kHref inHtml:fixedText];
    fixedText = [CommunicationsUtil fixBrokenTag:kImg inHtml:fixedText];  
    
    return fixedText;
}

// Removes slash from end of jpg or gif image links if one is found.
+ (NSString *)fixImageTags:(NSString *)sourceText {
    
    NSString *fixedText = [sourceText stringByReplacingOccurrencesOfString:kJpgEndWithSlash withString:kJpgEndWithoutSlash];
    fixedText = [fixedText stringByReplacingOccurrencesOfString:kGifEndWithSlash withString:kGifEndWithoutSlash];
    
    return fixedText;
}

static char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// encode to BASE64
+ (NSString*) encodeBase64:(const uint8_t*) valueToEncode length:(NSInteger) length {
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & valueToEncode[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    encodingTable[(value >> 18) & 0x3F];
        output[index + 1] =                    encodingTable[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? encodingTable[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? encodingTable[(value >> 0)  & 0x3F] : '=';

    }
    
    return [[NSString alloc] initWithData:data
                                 encoding:NSASCIIStringEncoding];
}

// Create hash signature using HMAC-SHA1
+ (NSString *)createSignature:(NSString *) dataToSign usingKey:(NSString *) hashkey {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    char *keyCharPtr = strdup([hashkey UTF8String]);
    char *dataCharPtr = strdup([dataToSign UTF8String]);
    
    CCHmacContext hctx;
    CCHmacInit(&hctx, kCCHmacAlgSHA1, keyCharPtr, strlen(keyCharPtr));
    CCHmacUpdate(&hctx, dataCharPtr, strlen(dataCharPtr));
    CCHmacFinal(&hctx, digest);
 
    NSString *base64Digest = [CommunicationsUtil encodeBase64:digest length:CC_SHA1_DIGEST_LENGTH];
    
    free(keyCharPtr);
    free(dataCharPtr);
    
    return [CommunicationsUtil urlEncodeRFC3986:base64Digest];
    
    // h ttp://www.flickr.com/services/oauth/request_token?oauth_callback=flckr1%3A%2F%2Foauthlogin&oauth_consumer_key=5ba9a0182068c1193f16d5826570b5fa&oauth_nonce=2449473536&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1326473440&oauth_version=1.0&oauth_signature=kSt1WH4seEo2H80NX4S8B58p5Ns=
    
    // flickr  h ttp://www.flickr.com/services/oauth/request_token?oauth_nonce=95613465&oauth_timestamp=1305586162&oauth_consumer_key=653e7a6ecc1d528c516cc8f92cf98611&oauth_signature_method=HMAC-SHA1&oauth_version=1.0&oauth_signature=7w18YS2bONDPL%2FzgyzP5XTr5af4%3D&oauth_callback=http%3A%2F%2Fwww.example.com
}

// Create hash signature using HMAC-SHA1
+ (NSString *)createSignatureUTF8:(NSString *) dataToSign usingKey:(NSString *) hashkey {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    char *keyCharPtr = strdup([hashkey UTF8String]);
    char *dataCharPtr = strdup([dataToSign UTF8String]);
    
    CCHmacContext hctx;
    CCHmacInit(&hctx, kCCHmacAlgSHA1, keyCharPtr, strlen(keyCharPtr));
    CCHmacUpdate(&hctx, dataCharPtr, strlen(dataCharPtr));
    CCHmacFinal(&hctx, digest);
    
    
    NSString *base64Digest = [CommunicationsUtil encodeBase64:digest length:CC_SHA1_DIGEST_LENGTH];
    
    free(keyCharPtr);
    free(dataCharPtr);
    
    return base64Digest;
    
    //NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH]; 
    //return [[NSString alloc] initWithData:digestData
      //                           encoding:NSASCIIStringEncoding]; 
}

// Determine if a string has characters with a higher value then number passed in.
+ (BOOL)hasCharacters:(NSString *)charactersSet greaterThan:(NSString *)charStr {

    if (charStr && charStr.length == 1) {
            
        for (int indx = 0; indx < charactersSet.length; indx++) {
            
            if ([charactersSet characterAtIndex:indx] > [charStr characterAtIndex:0]) {
                return YES;
            }
        }        
    }
    
    return NO;
    
}

//RFC 3986
//http ://tools.ietf.org/html/rfc3986
+ (NSString *) urlEncodeRFC3986: (NSString *) url {
    
    CFStringRef escapeChars = NULL;
    
    if (![CommunicationsUtil hasCharacters:url greaterThan:@"ÿ"]) {
        
        escapeChars = (CFStringRef)@" \"\n%;/?¿:@&=$+,[]#!'()*<>¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ";
    }
    else {
        
        NSLog(@"CommunicationsUtil.urlEncodeRFC3986 Using large escape charset!");
        
    escapeChars = (CFStringRef)@" \"\n%;/?¿:@&=$+,[]#!'()*<>¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſſƀƁƂƃƄƅƆƇƈƉƊƋƌƍƎƏƐƑƒƓƔƕƖƗƘƙƚƛƜƝƞƟƠơƢƣƤƥƦƧƨƩƪƫƬƭƮƯưƱƲƳƴƵƶƷƸƹƺƻƼƽƾƿǀǁǂǃǄǅǆǇǈǉǊǋǌǍǎǏǐǑǒǓǔǕǖǗǘǙǚǛǜǝǞǟǠǡǢǣǤǥǦǧǨǩǪǫǬǭǮǯǰǱǲǳǴǵǶǷǸǹǺǻǼǽǾǿȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȜȝȞȟȠȡȢȣȤȥȦȧȨȩȪȫȬȭȮȯȰȱȲȳȴȵȶȷȸȹȺȻȼȽȾȿɀɁɂɃɄɅɆɇɈɉɊɋɌɍɎɏɐɑɒɓɔɕɖɗɘəɚɛɜɝɞɟɠɡɢɣɤɥɦɧɨɩɪɫɬɭɮɯɰɱɲɳɴɵɶɷɸɹɺɻɼɽɾɿʀʁʂʃʄʅʆʇʈʉʊʋʌʍʎʏʐʑʒʓʔʕʖʗʘʙʚʛʜʝʞʟʠʡʢʣʤʥʦʧʨʩʪʫʬʭʮʯʰʱʲʳʴʵʶʷʸʹʺʻʼʽʾʿˀˁ˂˃˄˅ˆˇˈˉˊˋˌˍˎˏːˑ˒˓˔˕˖˗˘˙˚˛˜˝˞˟ˠˡˢˣˤ΄΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϏϐϑϒϓϔϕϖϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯϰϱϲϳϴϵ϶ϷϸϹϺϻϼϽϾϿЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂ ҃ ҄ ҅ ҆ ҇ ҈ ҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӝӞӟӠӡӢӣӤӥӦӧӨөӪӫӬӭӮӯӰӱӲӳӴӵӶӷӸӹӺӻӼӽӾӿԀԁԂԃԄԅԆԇԈԉԊԋԌԍԎԏԐԑԒԓԔԕԖԗԘԙԚԛԜԝԞԟԠԡԢԣԤԥԦԧԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖՙ՚՛՜՝՞աբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆև׃‎ׅׄ‎׆‎ׇ‎‎ב‎ג‎ד‎ה‎ו‎ז‎ח‎ט‎י‎ך‎כ‎ל‎ם‎מ‎ן‎נ‎ס‎ע‎ף‎פ‎ץ‎צ‎ק‎ר‎ש‎ת‎‎װ‎ױ‎ײ‎׳‎״‎؇‎؈‎؉‎؊‎؋‎،؍‎؎؏ؐؑؒؓؔؕؖ‎ؗ‎ؘ‎ؙ‎ؚ‎؛‎؞‎؟‎ء‎آ‎أ‎ؤ‎إ‎ئ‎ا‎ب‎ة‎ت‎ث‎ج‎ح‎خ‎د‎ذ‎ر‎ز‎س‎ش‎ص‎ض‎ط‎ظ‎ع‎غ‎ػ‎ؼ‎ؽ‎ؾ‎ؿ‎ـ‎ف‎ق‎ك‎ل‎م‎ن‎ه‎و‎ى‎ي‎ًٌٍَُِّْٕٖٓٔٗ٘ٙ‎ٚ‎ٛ‎ٜ‎ٝ‎ٞ‎ٟ‎٠١٢٣٤٥٦٧٨٩٪٫٬٭‎ٮ‎ٯ‎ٰٱ‎ٲ‎ٳ‎ٴ‎ٵ‎ٶ‎ٷ‎ٸ‎ٹ‎ٺ‎ٻ‎ټ‎ٽ‎پ‎ٿ‎ڀ‎ځ‎ڂ‎ڃ‎ڄ‎څ‎چ‎ڇ‎ڈ‎ډ‎ڊ‎ڋ‎ڌ‎ڍ‎ڎ‎ڏ‎ڐ‎ڑ‎ڒ‎ړ‎ڔ‎ڕ‎ږ‎ڗ‎ژ‎ڙ‎ښ‎ڛ‎ڜ‎ڝ‎ڞ‎ڟ‎ڠ‎ڡ‎ڢ‎ڣ‎ڤ‎ڥ‎ڦ‎ڧ‎ڨ‎ک‎ڪ‎ګ‎ڬ‎ڭ‎ڮ‎گ‎ڰ‎ڱ‎ڲ‎ڳ‎ڴ‎ڵ‎ڶ‎ڷ‎ڸ‎ڹ‎ں‎ڻ‎ڼ‎ڽ‎ھ‎ڿ‎ۀ‎ہ‎ۂ‎ۃ‎ۄ‎ۅ‎ۆ‎ۇ‎ۈ‎ۉ‎ۊ‎ۋ‎ی‎ۍ‎ێ‎ۏ‎ې‎ۑ‎ے‎ۓ‎۔‎ە‎ۖۗۘۙۚۛۜ‎۞ۣ۟۠ۡۢۤۥ‎ۦ‎ۧۨ۩۪ۭ۫۬ۮ‎ۯ‎۰۱۲۳۴۵۶۷۸۹ۺ‎ۻ‎ۼ‎۽‎۾‎ۿݐ‎ݑ‎ݒ‎ݓ‎ݔ‎ݕ‎ݖ‎ݗ‎ݘ‎ݙ‎ݚ‎ݛ‎ݜ‎ݝ‎ݞ‎ݟ‎ݠ‎ݡ‎ݢ‎ݣ‎ݤ‎ݥ‎ݦ‎ݧ‎ݨ‎ݩ‎ݪ‎ݫ‎ݬ‎ݭ‎ݮ‎ݯ‎ݰ‎ݱ‎ݲ‎ݳ‎ݴ‎ݵ‎ݶ‎ݷ‎ݸ‎ݹ‎ݺ‎ݻ‎ݼ‎ݽ‎ݾ‎ݿ‎ऄअआइईउऊऋऌऍऎएऐऑऒओऔकखगघङचछजझञटठडढणतथदधनऩपफबभमयरऱलळऴवशषसሀሁሂሃሄህሆሇለሉሊላሌልሎሏሐሑሒሓሔሕሖሗመሙሚማሜምሞሠሡሢሣሤሥሦሧረሩሪራሬርሮሯሰሱሲሳሴስሶሷሸሹሺሻሼሽሾሿቀቁቂቃቄቅቆቇቈ቉ቊቋቌቍ቎቏ቐቑቒቓቔቕቖ቗ቘ቙ቚቛቜቝ቞቟በቡቢባቤብቦቧቨቩቪቫቬቭቮቯተቱቲታቴትቶቷቸቹቺቻቼችቾቿኀኁኂኃኄኅኆኇኈ኉ኊኋኌኍ኎኏ነኑኒናኔንኖኗኘኙኚኛኜኝኞኟአኡኢኣኤእኦኧከኩኪካኬክኮኯኰ኱ኲኳኴኵ኶኷ኸኹኺኻኼኽኾ኿ዀ዁ዂዃዄዅ዆዇ወዉዊዋዌውዎዏዐዑዒዓዔዕዖ዗ዘዙዚዛዜዝዞዟዠዡዢዣዤዥዦዧየዩዪያዬይዮዯደዱዲዳዴድዶዷዸዹዺዻዼዽዾዿጀጁጂጃጄጅጆጇገጉጊጋጌግጎጏጐ጑ጒጓጔጕ጖጗ጘጙጚጛጜጝጞጟጠጡጢጣጤጥጦጧጨጩጪጫጬጭጮጯጰጱጲጳጴጵጶጷጸጹጺጻጼጽጾጿፀፁፂፃፄፅፆፇፈፉፊፋፌፍፎፏፐፑፒፓፔፕፖፗፘፙፚ፛፜፝፞፟፠፡።፣፤፥፦፧፨፩፪፫፬፭፮፯፰፱፲፳፴፵፶፷፸፹፺፻፼፽፾፿ᎀᎁᎂᎃᎄᎅᎆᎇᎈᎉᎊᎋᎌᎍᎎᎏ᎐᎑᎒᎓᎔᎕᎖᎗᎘᎙᎚᎛᎜᎝᎞᎟ᎠᎡᎢᎣᎤᎥᎦᎧᎨᎩᎪᎫᎬᎭᎮᎯᎰᎱᎲᎳᎴᎵᎶᎷᎸᎹᎺᎻᎼᎽᎾᎿᏀᏁᏂᏃᏄᏅᏆᏇᏈᏉᏊᏋᏌᏍᏎᏏᏐᏑᏒᏓᏔᏕᏖᏗᏘᏙᏚᏛᏜᏝᏞᏟᏠᏡᏢᏣᏤᏥᏦᏧᏨᏩᏪᏫᏬᏭᏮᏯᏰᏱᏲᏳᏴᏵ᏶᏷ᏸᏹᏺᏻᏼᏽ᏾᏿᐀ᐁᐂᐃᐄᐅᐆᐇᐈᐉᐊᐋᐌᐍᐎᐏᐐᐑᐒᐓᐔᐕᐖᐗᐘᐙᐚᐛᐜᐝᐞᐟᐠᐡᐢᐣᐤᐥᐦᐧᐨᐩᐪᐫᐬᐭᐮᐯᐰᐱᐲᐳᐴᐵᐶᐷᐸᐹᐺᐻᐼᐽᐾᐿᑀᑁᑂᑃᑄᑅᑆᑇᑈᑉᑊᑋᑌᑍᑎᑏᑐᑑᑒᑓᑔᑕᑖᑗᑘᑙᑚᑛᑜᑝᑞᑟᑠᑡᑢᑣᑤᑥᑦᑧᑨᑩᑪᑫᑬᑭᑮᑯᑰᑱᑲᑳᑴᑵᑶᑷᑸᑹᑺᑻᑼᑽᑾᑿᒀᒁᒂᒃᒄᒅᒆᒇᒈᒉᒊᒋᒌᒍᒎᒏᒐᒑᒒᒓᒔᒕᒖᒗᒘᒙᒚᒛᒜᒝᒞᒟᒠᒡᒢᒣᒤᒥᒦᒧᒨᒩᒪᒫᒬᒭᒮᒯᒰᒱᒲᒳᒴᒵᒶᒷᒸᒹᒺᒻᒼᒽᒾᒿᓀᓁᓂᓃᓄᓅᓆᓇᓈᓉᓊᓋᓌᓍᓎᓏᓐᓑᓒᓓᓔᓕᓖᓗᓘᓙᓚᓛᓜᓝᓞᓟᓠᓡᓢᓣᓤᓥᓦᓧᓨᓩᓪᓫᓬᓭᓮᓯᓰᓱᓲᓳᓴᓵᓶᓷᓸᓹᓺᓻᓼᓽᓾᓿᔀᔁᔂᔃᔄᔅᔆᔇᔈᔉᔊᔋᔌᔍᔎᔏᔐᔑᔒᔓᔔᔕᔖᔗᔘᔙᔚᔛᔜᔝᔞᔟᔠᔡᔢᔣᔤᔥᔦᔧᔨᔩᔪᔫᔬᔭᔮᔯᔰᔱᔲᔳᔴᔵᔶᔷᔸᔹᔺᔻᔼᔽᔾᔿᕀᕁᕂᕃᕄᕅᕆᕇᕈᕉᕊᕋᕌᕍᕎᕏᕐᕑᕒᕓᕔᕕᕖᕗᕘᕙᕚᕛᕜᕝᕞᕟᕠᕡᕢᕣᕤᕥᕦᕧᕨᕩᕪᕫᕬᕭᕮᕯᕰᕱᕲᕳᕴᕵᕶᕷᕸᕹᕺᕻᕼᕽᕾᕿᖀᖁᖂᖃᖄᖅᖆᖇᖈᖉᖊᖋᖌᖍᖎᖏᖐᖑᖒᖓᖔᖕᖖᖗᖘᖙᖚᖛᖜᖝᖞᖟᖠᖡᖢᖣᖤᖥᖦᖧᖨᖩᖪᖫᖬᖭᖮᖯᖰᖱᖲᖳᖴᖵᖶᖷᖸᖹᖺᖻᖼᖽᖾᖿᗀᗁᗂᗃᗄᗅᗆᗇᗈᗉᗊᗋᗌᗍᗎᗏᗐᗑᗒᗓᗔᗕᗖᗗᗘᗙᗚᗛᗜᗝᗞᗟᗠᗡᗢᗣᗤᗥᗦᗧᗨᗩᗪᗫᗬᗭᗮᗯᗰᗱᗲᗳᗴᗵᗶᗷᗸᗹᗺᗻᗼᗽᗾᗿᘀᘁᘂᘃᘄᘅᘆᘇᘈᘉᘊᘋᘌᘍᘎᘏᘐᘑᘒᘓᘔᘕᘖᘗᘘᘙᘚᘛᘜᘝᘞᘟᘠᘡᘢᘣᘤᘥᘦᘧᘨᘩᘪᘫᘬᘭᘮᘯᘰᘱᘲᘳᘴᘵᘶᘷᘸᘹᘺᘻᘼᘽᘾᘿᙀᙁᙂᙃᙄᙅᙆᙇᙈᙉᙊᙋᙌᙍᙎᙏᙐᙑᙒᙓᙔᙕᙖᙗᙘᙙᙚᙛᙜᙝᙞᙟᙠᙡᙢᙣᙤᙥᙦᙧᙨᙩᙪᙫᙬ᙭᙮ᙯᙰᙱᙲᙳᙴᙵᙶកខគឃងចឆជឈញដឋឌឍណតថទធនបផពភមយរលវឝឞសហឡᴀᴁᴂᴃᴄᴅᴆᴇᴈᴉᴊᴋᴌᴍᴎᴏᴐᴑᴒᴓᴔᴕᴖᴗᴘᴙᴚᴛᴜᴝᴞᴟᴠᴡᴢᴣᴤᴥᴦᴧᴨᴩᴪᴫᴬᴭᴮᴯᴰᴱᴲᴳᴴᴵᴶᴷᴸᴹᴺᴻᴼᴽᴾᴿᵀᵁᵂᵃᵄᵅᵆᵇᵈᵉᵊᵋᵌᵍᵎᵏᵐᵑᵒᵓᵔᵕᵖᵗᵘᵙᵚᵛᵜᵝᵞᵟᵠᵡᵢᵣᵤᵥᵦᵧᵨᵩᵪᵫᵬᵭᵮᵯᵰᵱᵲᵳᵴᵵᵶᵷᵸᵹᵺᵻᵼᵽᵾᵿᶀᶁᶂᶃᶄᶅᶆᶇᶈᶉᶊᶋᶌᶍᶎᶏᶐᶑᶒᶓᶔᶕᶖᶗᶘᶙᶚᶛᶜᶝᶞᶟᶠᶡᶢᶣᶤᶥᶦᶧᶨᶩᶪᶫᶬᶭᶮᶯᶰᶱᶲᶳᶴᶵᶶᶷᶸᶹᶺᶻᶼᶽᶾḀḁḂḃḄḅḆḇḈḉḊḋḌḍḎḏḐḑḒḓḔḕḖḗḘḙḚḛḜḝḞḟḠḡḢḣḤḥḦḧḨḩḪḫḬḭḮḯḰḱḲḳḴḵḶḷḸḹḺḻḼḽḾḿṀṁṂṃṄṅṆṇṈṉṊṋṌṍṎṏṐṑṒṓṔṕṖṗṘṙṚṛṜṝṞṟṠṡṢṣṤṥṦṧṨṩṪṫṬṭṮṯṰṱṲṳṴṵṶṷṸṹṺṻṼṽṾṿẀẁẂẃẄẅẆẇẈẉẊẋẌẍẎẏẐẑẒẓẔẕẖẗẘẙẚẛẜẝẞẟẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹỺỻỼỽỾỿἀἁἂἃἄἅἆἇἈἉἊἋἌἍἎἏἐἑἒἓἔἕ἖἗ἘἙἚἛἜἝ἞἟ἠἡἢἣἤἥἦἧἨἩἪἫἬἭἮἯἰἱἲἳἴἵἶἷἸἹἺἻἼἽἾἿὀὁὂὃὄὅ὆὇ὈὉὊὋὌὍ὎὏ὐὑὒὓὔὕὖὗ὘Ὑ὚Ὓ὜Ὕ὞ὟὠὡὢὣὤὥὦὧὨὩὪὫὬὭὮὯὰάὲέὴήὶίὸόὺύὼώ὾὿ᾀᾁᾂᾃᾄᾅᾆᾇᾈᾉᾊᾋᾌᾍᾎᾏᾐᾑᾒᾓᾔᾕᾖᾗᾘᾙᾚᾛᾜᾝᾞᾟᾠᾡᾢᾣᾤᾥᾦᾧᾨᾩᾪᾫᾬᾭᾮᾯᾰᾱᾲᾳᾴ᾵ᾶᾷᾸᾹᾺΆᾼ᾽ι᾿῀῁ῂῃῄ῅ῆῇῈΈῊΉῌ῍῎῏ῐῑῒΐ῔῕ῖῗῘῙῚΊ῜῝῞῟ῠῡῢΰῤῥῦῧῨῩῪΎῬ    ⁰ⁱ⁲⁳⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎₏ₐₑₒₓₔₕₖₗₘₙₚₛₜ₝₞₟₠₡₢₣₤₥₦₧₨₩₪₫€₭₮₯₰₱₲₳₴₵₶₷₸₹₺₻₼₽₾₿⃀⃁⃂⃃⃄⃅⃆⃇⃈⃉⃊⃋⃌⃍⃎℀℁ℂ℃℄℅℆ℇ℈℉ℊℋℌℍℎℏℐℑℒℓ℔ℕ№℗℘ℙℚℛℜℝ℞℟℠℡™℣ℤ℥Ω℧ℨ℩KÅℬℭ℮ℯℰℱℲℳℴℵℷℸ℺℻ℼℽℾℿ⅀⅁⅂⅃⅄ⅅⅆⅇⅈⅉ⅊⅋⅌⅍ⅎ⅏⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞⅟ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫⅬⅭⅮⅯⅰⅱⅲⅳⅴⅵⅶⅷⅸⅹⅺⅻⅼⅽⅾⅿↀↁↂↃↄↅↆ⧼⧽⧾⧿⨀⨁⨂⨃⨄⨅⨆⨇⨈⨉⨊⨋⨌⨍⨎⨏⨐⨑⨒⨓⨔⨕⨖⨗⨘⨙⨚⨛⨜⨝⨞⨟⨠⨡⨢⨣⨤⨥⨦⨧⨨⨩⨪⨫⨬⨭⨮⨯⨰⨱⨲⨳⨴⨵⨶⨷⨸⨹⨺⨻⨼⨽⨾⨿⩀⩁⩂⩃⩄⩅⩆⩇⩈⩉⩊⩋⩌⩍⩎⩏⩐⩑⩒⩓⩔⩕⩖⩗⩘⩙⩚⩛⩜⩝⩞⩟⩠⩡⩢⩣⩤⩥⩦⩧⩨⩩⩪⩫⩬⩭⩮⩯⩰⩱⩲⩳⩴⩵⩶⩷⩸⩹⩺⩻⩼⩽⩾⩿⪀⪁⪂⪃⪄⪅⪆⪇⪈⪉⪊⪋⪌⪍⪎⪏⪐⪑⪒⪓⪔⪕⪖⪗⪘⪙⪚⪛⪜⪝⪞⪟⪠⪡⪢⪣⪤⪥⪦⪧⪨⪩⪪⪫⪬⪭⪮⪯⪰⪱⪲⪳⪴⪵⪶⪷⪸⪹⪺⪻⪼⪽⪾⪿⫀⫁⫂⫃⫄⫅⫆⫇⫈⫉⫊⫋⫌⫍⫎⫏⫐⫑⫒⫓⫔⫕⫖⫗⫘⫙⫚⫛⫝̸⫝⫞⫟⫠⫡⫢⫣⫤⫥⫦⫧⫨⫩⫪⫫⫬⫭⫮⫯⫰⫱⫲⫳⫴⫵⫶⫷⫸⫹⫺⫻⫼⫽⫾⫿⬀⬁⬂⬃⬄⬅⬆⬇⬈⬉⬊⬋⬌⬍ぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔゕゖ";
    }
    
    NSString *encodedString = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge_retained CFStringRef) url, NULL, escapeChars, kCFStringEncodingUTF8);
    
    return encodedString;
    
    //return out;
}

// Decode strings in RFC3986 format to human readible form.
+ (NSString *)decodeRFC3986:(NSString *)valueToDecode {
    
    return [valueToDecode stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

}

+(NSArray *)getHtmlEscapedCodeShortList {
    
    return [NSArray arrayWithObjects:
            @"&lt;", @"&gt;", @"&quot;", nil];
}

+(NSArray *)getHtmlEscapedCodeSequences {
    
    return [NSArray arrayWithObjects:
            @"&lt;", @"&gt;", @"&amp;", @"&ouml;", @"&ograve;", 
            @"&ntilde;", @"&quot;", @"&sp;", @"&blank", @"&num;" ,
            @"&dollar;", @"&percnt;", @"&apos;", @"&lpar;", @"&rpar;", 
            @"&ast;", @"&plus;", @"&comma;", @"&period;",  @"&colon;",
            @"&semi;", @"&equals;", @"&quest;", @"&commat;",  @"&lsqb;",
            @"&bsol;", @"&rsqb;", @"&circ;", @"&caret;",  @"&lowbar;",
            @"&lcub;", @"&verbar;", @"&rcub;", @"&tilde;",  @"&nbsp;",
            @"&hyphen;", @" &minus;", @"&dash;", @"&sol;",  nil];
}

// Decode html escapes code sequences back into regular html.
+(NSString *)decodeHtmlEscapes:(NSString *)valueToDecode {
    NSArray *htmlChars = [NSArray arrayWithObjects:
                            @"<",  @">" , @"&" , @"ö" ,  @"ò" ,
                            @"ñ" , @"\"" , @" " , @" " , @"#" , 
                            @"$" , @"%" , @"'",  @"(",   @")", 
                            @"*",  @"+",  @",",  @".",   @":",
                            @";",  @"=",  @"?",  @"@",   @"[",
                            @"\\",  @"]",  @"^",  @"^",   @"_",
                            @"{",  @"|",  @"}",  @"~",   @" ",
                            @"-",  @"-",  @"-",  @"/",   nil];
    
    NSArray *escapedCodeSequences = [CommunicationsUtil getHtmlEscapedCodeSequences ];
                                     
        
    int len = [htmlChars count];
    
    NSMutableString *temp = [valueToDecode mutableCopy];
    
    int index;
    for(index = 0; index < len; index++) {
        
        [temp replaceOccurrencesOfString: [escapedCodeSequences objectAtIndex:index]
                              withString:[htmlChars objectAtIndex:index]
                                 options:NSCaseInsensitiveSearch
                                   range:NSMakeRange(0, [temp length])];
    }
    
    NSString *out = [NSString stringWithString: temp];
    
    return out;

    /*
     &amp; = & 
     &lt; = < 
     &gt; = > 
     &ouml; = ö 
     &ograve; = ò 
     &ntilde; = ñ 
    */
}

// Used to build displayable html on ios web view.
+ (NSString *)swapCRLFforHtmlBreak:(NSString *) sourceHtmlText {
    
    if (!sourceHtmlText || sourceHtmlText.length == 0) {
        return sourceHtmlText;
    }
    
    NSMutableString *targetHtmlText = [sourceHtmlText mutableCopy];    
    [targetHtmlText replaceOccurrencesOfString:@"\n" withString:@"<br/>" options:NSLiteralSearch range:NSMakeRange(0, targetHtmlText.length)];
     
    return targetHtmlText;
}

// Sets html background to Black
+ (NSString *)addBlackBackgroundToHTML:(NSString *) sourceHtmlText {
    
    if (!sourceHtmlText) {
        return sourceHtmlText;
    }
    
    NSMutableString *targetHtmlText = [sourceHtmlText mutableCopy];
    [targetHtmlText insertString:@"<div style=\"background-color:black;\">" atIndex:0];
    [targetHtmlText appendString:@"</div>"];
    
    return targetHtmlText;
}

// Used to build comment html to send display in an ios text view.
+ (NSString *)swapHtmlBreakforCRLF:(NSString *) sourceHtmlText {
    
    if (!sourceHtmlText || sourceHtmlText.length < 5) {
        return sourceHtmlText;
    }
    
    NSMutableString *targetHtmlText = [sourceHtmlText mutableCopy];
    [targetHtmlText replaceOccurrencesOfString:@"<br/>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, targetHtmlText.length)];
    [targetHtmlText replaceOccurrencesOfString:@"<br />" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, targetHtmlText.length)];
    
    return targetHtmlText;
}

// Create md5 check sum string.
+ (NSString *) md5:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]]; 
}

// Send request token to Flckr and get response
+ (ApiResponse *)sendHttpRequestWithUrl:(NSURL *)httpUrlQuery {    
    //NSLog(@"CommunicationsUtil.sendHttpRequestWithUrl, at beginning, httpUrlQuery %@", httpUrlQuery);
    
    ApiResponse *apiResponse = [[ApiResponse alloc] init];        
    NSError *error = nil;  
    NSStringEncoding encodingUsed;
    
    apiResponse.response = [NSString stringWithContentsOfURL:httpUrlQuery usedEncoding:&encodingUsed error:&error];
    
    if (error || !apiResponse.response) {
        apiResponse.errorMessage = @"Failed to Reach Flickr";
        NSLog(@"CommunicationsUtil.sendHttpRequestWithUrl, Failed to send request. %@", [error localizedDescription]); 
        NSLog(@"CommunicationsUtil.sendHttpRequestWithUrl, httpUrlQuery %@", httpUrlQuery); 
        
        if (apiResponse.response) {
            NSLog(@"Errant response data %@", apiResponse.response);
        }
    }   
    
    return apiResponse;
}

/*
 
 
 Char  Dec  Oct  Hex | Char  Dec  Oct  Hex | Char  Dec  Oct  Hex | Char Dec  Oct   Hex
 -------------------------------------------------------------------------------------
 (nul)   0 0000 0x00 | (sp)   32 0040 0x20 | @      64 0100 0x40 | `      96 0140 0x60
 (soh)   1 0001 0x01 | !      33 0041 0x21 | A      65 0101 0x41 | a      97 0141 0x61
 (stx)   2 0002 0x02 | "      34 0042 0x22 | B      66 0102 0x42 | b      98 0142 0x62
 (etx)   3 0003 0x03 | #      35 0043 0x23 | C      67 0103 0x43 | c      99 0143 0x63
 (eot)   4 0004 0x04 | $      36 0044 0x24 | D      68 0104 0x44 | d     100 0144 0x64
 (enq)   5 0005 0x05 | %      37 0045 0x25 | E      69 0105 0x45 | e     101 0145 0x65
 (ack)   6 0006 0x06 | &      38 0046 0x26 | F      70 0106 0x46 | f     102 0146 0x66
 (bel)   7 0007 0x07 | '      39 0047 0x27 | G      71 0107 0x47 | g     103 0147 0x67
 (bs)    8 0010 0x08 | (      40 0050 0x28 | H      72 0110 0x48 | h     104 0150 0x68
 (ht)    9 0011 0x09 | )      41 0051 0x29 | I      73 0111 0x49 | i     105 0151 0x69
 (nl)   10 0012 0x0a | *      42 0052 0x2a | J      74 0112 0x4a | j     106 0152 0x6a
 (vt)   11 0013 0x0b | +      43 0053 0x2b | K      75 0113 0x4b | k     107 0153 0x6b
 (np)   12 0014 0x0c | ,      44 0054 0x2c | L      76 0114 0x4c | l     108 0154 0x6c
 (cr)   13 0015 0x0d | -      45 0055 0x2d | M      77 0115 0x4d | m     109 0155 0x6d
 (so)   14 0016 0x0e | .      46 0056 0x2e | N      78 0116 0x4e | n     110 0156 0x6e
 (si)   15 0017 0x0f | /      47 0057 0x2f | O      79 0117 0x4f | o     111 0157 0x6f
 (dle)  16 0020 0x10 | 0      48 0060 0x30 | P      80 0120 0x50 | p     112 0160 0x70
 (dc1)  17 0021 0x11 | 1      49 0061 0x31 | Q      81 0121 0x51 | q     113 0161 0x71
 (dc2)  18 0022 0x12 | 2      50 0062 0x32 | R      82 0122 0x52 | r     114 0162 0x72
 (dc3)  19 0023 0x13 | 3      51 0063 0x33 | S      83 0123 0x53 | s     115 0163 0x73
 (dc4)  20 0024 0x14 | 4      52 0064 0x34 | T      84 0124 0x54 | t     116 0164 0x74
 (nak)  21 0025 0x15 | 5      53 0065 0x35 | U      85 0125 0x55 | u     117 0165 0x75
 (syn)  22 0026 0x16 | 6      54 0066 0x36 | V      86 0126 0x56 | v     118 0166 0x76
 (etb)  23 0027 0x17 | 7      55 0067 0x37 | W      87 0127 0x57 | w     119 0167 0x77
 (can)  24 0030 0x18 | 8      56 0070 0x38 | X      88 0130 0x58 | x     120 0170 0x78
 (em)   25 0031 0x19 | 9      57 0071 0x39 | Y      89 0131 0x59 | y     121 0171 0x79
 (sub)  26 0032 0x1a | :      58 0072 0x3a | Z      90 0132 0x5a | z     122 0172 0x7a
 (esc)  27 0033 0x1b | ;      59 0073 0x3b | [      91 0133 0x5b | {     123 0173 0x7b
 (fs)   28 0034 0x1c | <      60 0074 0x3c | \      92 0134 0x5c | |     124 0174 0x7c
 (gs)   29 0035 0x1d | =      61 0075 0x3d | ]      93 0135 0x5d | }     125 0175 0x7d
 (rs)   30 0036 0x1e | >      62 0076 0x3e | ^      94 0136 0x5e | ~     126 0176 0x7e
 (us)   31 0037 0x1f | ?      63 0077 0x3f | _      95 0137 0x5f | (del) 127 0177 0x7f
 
 What is UTF-8?
 
 UCS and Unicode are first of all just code tables that assign integer numbers to characters. There exist several alternatives for how a sequence of such characters or their respective integer values can be represented as a sequence of bytes. The two most obvious encodings store Unicode text as sequences of either 2 or 4 bytes sequences. The official terms for these encodings are UCS-2 and UCS-4, respectively. Unless otherwise specified, the most significant byte comes first in these (Bigendian convention). An ASCII or Latin-1 file can be transformed into a UCS-2 file by simply inserting a 0x00 byte in front of every ASCII byte. If we want to have a UCS-4 file, we have to insert three 0x00 bytes instead before every ASCII byte.
 
 Using UCS-2 (or UCS-4) under Unix would lead to very severe problems. Strings with these encodings can contain as parts of many wide characters bytes like “\0” or “/” which have a special meaning in filenames and other C library function parameters. In addition, the majority of UNIX tools expects ASCII files and cannot read 16-bit words as characters without major modifications. For these reasons, UCS-2 is not a suitable external encoding of Unicode in filenames, text files, environment variables, etc.
 
 The UTF-8 encoding defined in ISO 10646-1:2000 Annex D and also described in RFC 3629 as well as section 3.9 of the Unicode 4.0 standard does not have these problems. It is clearly the way to go for using Unicode under Unix-style operating systems.
 
 UTF-8 has the following properties:
 
 UCS characters U+0000 to U+007F (ASCII) are encoded simply as bytes 0x00 to 0x7F (ASCII compatibility). This means that files and strings which contain only 7-bit ASCII characters have the same encoding under both ASCII and UTF-8.
 All UCS characters >U+007F are encoded as a sequence of several bytes, each of which has the most significant bit set. Therefore, no ASCII byte (0x00-0x7F) can appear as part of any other character.
 The first byte of a multibyte sequence that represents a non-ASCII character is always in the range 0xC0 to 0xFD and it indicates how many bytes follow for this character. All further bytes in a multibyte sequence are in the range 0x80 to 0xBF. This allows easy resynchronization and makes the encoding stateless and robust against missing bytes.
 All possible 231 UCS codes can be encoded.
 UTF-8 encoded characters may theoretically be up to six bytes long, however 16-bit BMP characters are only up to three bytes long.
 The sorting order of Bigendian UCS-4 byte strings is preserved.
 The bytes 0xFE and 0xFF are never used in the UTF-8 encoding.
 The following byte sequences are used to represent a character. The sequence to be used depends on the Unicode number of the character:
 
 U-00000000 – U-0000007F:	0xxxxxxx
 U-00000080 – U-000007FF:	110xxxxx 10xxxxxx
 U-00000800 – U-0000FFFF:	1110xxxx 10xxxxxx 10xxxxxx
 U-00010000 – U-001FFFFF:	11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 U-00200000 – U-03FFFFFF:	111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
 U-04000000 – U-7FFFFFFF:	1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
 The xxx bit positions are filled with the bits of the character code number in binary representation. The rightmost x bit is the least-significant bit. Only the shortest possible multibyte sequence which can represent the code number of the character can be used. Note that in multibyte sequences, the number of leading 1 bits in the first byte is identical to the number of bytes in the entire sequence.
 
 Examples: The Unicode character U+00A9 = 1010 1001 (copyright sign) is encoded in UTF-8 as
 
 11000010 10101001 = 0xC2 0xA9
 and character U+2260 = 0010 0010 0110 0000 (not equal to) is encoded as:
 
 11100010 10001001 10100000 = 0xE2 0x89 0xA0
 The official name and spelling of this encoding is UTF-8, where UTF stands for UCS Transformation Format. Please do not write UTF-8 in any documentation text in other ways (such as utf8 or UTF_8), unless of course you refer to a variable name and not the encoding itself.
 
 An important note for developers of UTF-8 decoding routines: For security reasons, a UTF-8 decoder must not accept UTF-8 sequences that are longer than necessary to encode a character. For example, the character U+000A (line feed) must be accepted from a UTF-8 stream only in the form 0x0A, but not in any of the following five possible overlong forms:
 
 0xC0 0x8A
 0xE0 0x80 0x8A
 0xF0 0x80 0x80 0x8A
 0xF8 0x80 0x80 0x80 0x8A
 0xFC 0x80 0x80 0x80 0x80 0x8A
 Any overlong UTF-8 sequence could be abused to bypass UTF-8 substring tests that look only for the shortest possible encoding. All overlong UTF-8 sequences start with one of the following byte patterns:
 
 1100000x (10xxxxxx)
 11100000 100xxxxx (10xxxxxx)
 11110000 1000xxxx (10xxxxxx 10xxxxxx)
 11111000 10000xxx (10xxxxxx 10xxxxxx 10xxxxxx)
 11111100 100000xx (10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx)
 Also note that the code positions U+D800 to U+DFFF (UTF-16 surrogates) as well as U+FFFE and U+FFFF must not occur in normal UTF-8 or UCS-4 data. UTF-8 decoders should treat them like malformed or overlong sequences for safety reasons.
 
 Markus Kuhn’s UTF-8 decoder stress test file contains a systematic collection of malformed and overlong UTF-8 sequences and will help you to verify the robustness of your decoder.
 

 
 
 */

@end
