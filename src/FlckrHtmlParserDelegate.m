//
//  FlckrHtmlParserDelegate.m
//  FlickerAwards
//  
//  Parses group's html from its home page to find the group's award if possible.
//
//  Created by Heather Stevens on 2/5/12.
//  Copyright (c) 2012 Heather S. Stevens. All rights reserved.
//

#import "FlckrHtmlParserDelegate.h"

@interface FlckrHtmlParserDelegate() <NSURLConnectionDelegate>

@property (nonatomic, retain) Group *selectedGroup;

@end

@implementation FlckrHtmlParserDelegate

static NSString * const kGroupBaseUrl        = @"http://www.flickr.com/groups/";
static NSString * const kUrlLastChar         = @"/";

@synthesize awardList = _awardList;

@synthesize selectedGroup = _selectedGroup;
@synthesize apiResponse = _apiResponse;

// Constructor, requires selected group.
- (id)initWithSelectedGroup:(Group *)selectedGroup {
    
    self = [super init];
    if (self) {
        self.selectedGroup = selectedGroup;
        self.awardList = [[NSMutableArray alloc] initWithCapacity:10];
        
    }
    
    return self;
}

// Create the url for the group's web page.
- (NSURL *)getUrlForWebPage {
    
    NSMutableString *urlStr = [[NSMutableString alloc] initWithCapacity:64];
    
    [urlStr appendString:kGroupBaseUrl];
    [urlStr appendString:self.selectedGroup.nsid];
    [urlStr appendString:kUrlLastChar];
    
    return [[NSURL alloc] initWithString:urlStr];
}

// Get the HTML for this group's web site.
- (NSString *)getGroupWebPageHtmlContent {
    self.apiResponse = [CommunicationsUtil sendHttpRequestWithUrl:[self getUrlForWebPage]];
    
    if (self.apiResponse.errorMessage) {
        NSLog(@"FlckrHtmlParserDelegate, Failed to retrieve the group's page, %@", self.apiResponse.errorMessage);
        return nil;
    }   

    return self.apiResponse.response;
}

// Break text into chunks of possible words using spaces and then find how many of them have junk in them that this app won't look for
- (int)findNumberOfNoopWords:(NSString *)line {
    int noopsFound = 0;
    
    NSArray *wordList = [line componentsSeparatedByString:@" "];
    for (NSString *possibleWord in wordList) {
        
        if (possibleWord.length < 2) {
            noopsFound++;
        }
        else {
            NSMutableString *possible = [NSMutableString stringWithString:possibleWord];
            [possible replaceOccurrencesOfString:@"\t" withString:@"" options:NSASCIIStringEncoding range:NSMakeRange(0, possible.length)];
            
            if (possible.length == 0) {
                noopsFound++;
            }
        }
    }

    return noopsFound;
}

// Try to find the text leading up to the award. This will be the best case we will find so it is rated high.
static NSString * const kPreAwardPhrases_50  = @"comment code,award code,trailr.info,to award,to comment,copy under,copy between,between the lines,between these lines,following code,following text for comments,copy the,past the,member-code,following award,from below,for comment,copy below,thank you for sharing,award\" code,copy &amp;,comment /award,comment/award,copy from,comment on photos,Please use (copy paste)";

#define APPROX_TEXT_BEFORE_AWARD 12000
#define APPROX_TEXT_AFTER_AWARD 24000
#define BACKUP_FROM_COMMENT 800

- (FindAwardHolder *)findGeneralAreaofAward:(NSString *)htmlContent {
    
    int startLocation = APPROX_TEXT_BEFORE_AWARD;
    int closestTagLocation = htmlContent.length;
    
    FindAwardHolder *findAward = [[FindAwardHolder alloc] init];
    
    NSArray *preAwardTagList = [kPreAwardPhrases_50 componentsSeparatedByString:@","];
    for (NSString *preAwardTag in preAwardTagList) {
        
        NSRange awardCodeRange =[htmlContent rangeOfString:preAwardTag options:NSCaseInsensitiveSearch range:NSMakeRange(APPROX_TEXT_BEFORE_AWARD, htmlContent.length - APPROX_TEXT_AFTER_AWARD)];          

        if (awardCodeRange.length != 0) {
            
            if (awardCodeRange.location < closestTagLocation) {
                
                // NSLog(@"FlckrHtmlParserDelegate.findGeneralAreaofAward tag: '%@' found at %d", preAwardTag, awardCodeRange.location);
                closestTagLocation = startLocation = awardCodeRange.location;                 
            }
        }
    }    
    
    if (startLocation > APPROX_TEXT_BEFORE_AWARD) {
        findAward.awardPoints = 200;
        findAward.parseState = PRE_AWARD_TAGS_FOUND;
    }
    
    // if nothing else, jump to the html body.
    if (startLocation < APPROX_TEXT_BEFORE_AWARD) {
        startLocation = APPROX_TEXT_BEFORE_AWARD;
    }
    
    //NSLog(@"FlckrHtmlParserDelegate.findGeneralAreaofAward  startlocation %d", startLocation);
    
    findAward.startLocation = startLocation-BACKUP_FROM_COMMENT;
    return findAward;    
}

// Find the first digit and return it in numerical form.
- (NSInteger)findAwardsRequired:(NSString *)text {
    NSInteger numReq = 0; 
    
    if (text.length > 0) {

        for (int indx=2;indx < text.length;indx++) {

            unichar c = [text characterAtIndex:indx]; 
            if (c > 0x30 && c < 0x3a) {  // 1-9
                numReq = c-0x30;
                
                if (![text rangeOfString:@"invite" options:NSCaseInsensitiveSearch].length) {
                    break;  
                }                
            }
        }
    }   
    
    return numReq;
}

// Parse the html of the award to see if the number of required awards is discernible.
static NSString * const kPostIndicatorCharsWords = @"post 1,post1,p 1,p1,add 1,add1,p-1,sube 1,sube1,p/1";
- (NSInteger)determineNumberOfRequiredAwards:(NSString *)awardHtml {
    
    __block NSInteger reqAwards = 0;
    __weak FlckrHtmlParserDelegate *weakDelegate = self; 
    
    // Parse each line and respond accordingly.
    [awardHtml enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {    
        
        NSRange postRange = [CommunicationsUtil findFirstWord:kPostIndicatorCharsWords inText:line];
        
        if (postRange.length > 0 && (postRange.location+postRange.length) < line.length-2) {
            NSString *awardReqStrSection = [line substringFromIndex:postRange.location+postRange.length];
            
            reqAwards = [weakDelegate findAwardsRequired:awardReqStrSection];
            if (reqAwards > 0) {
                *stop = YES;
            }
        }
    }];
    
    //NSLog(@"FlckrHtmlParserDelegate.determineNumberOfRequiredAwards ret %d", numAwards);
    return reqAwards;
}

// Looks thru the list of awards to see which one looks the best.
- (Award *)getBestAwardFromList {
    
    Award *award;
    Award *secondBestAward;
    
    if (self.awardList) {
        
        NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList, num awards total %d", self.awardList.count);
        
        // Find the two highest confidence rated awards.
        for (Award *awardFromList in self.awardList) {
            if (!award) {
                // First one set by default.
                secondBestAward = award = awardFromList;
            }
            else if (awardFromList.confidenceScore > award.confidenceScore) {
                
                // Save off the previous high confidence as the second best now.
                secondBestAward = award;
                
                // Set best confidence rating.
                award = awardFromList;
            }        
            else if (awardFromList.confidenceScore > secondBestAward.confidenceScore) {
                
                // Award from list didn't beat out the highest but did overtake 2nd place.
                secondBestAward = awardFromList;
            }
        }
        
        NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList award confidence %d, second best %d", award.confidenceScore, secondBestAward.confidenceScore);
        
        if (award.confidenceScore != secondBestAward.confidenceScore && award.confidenceScore >= 150 && award.confidenceScore - secondBestAward.confidenceScore < 95) {
            award.confidenceScore = 125;
            NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList award confidence too close!!! lowered to %d", award.confidenceScore);
        }
    
        // Clean up the award some.
        if (award && award.htmlAward && award.htmlAward.length > 0) {           
            
            NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList Start %@", award.htmlAward);
            award.htmlAward = [CommunicationsUtil decodeHtmlEscapes:award.htmlAward];
            //NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList after decodeHtmlEscapes %@", award.htmlAward);
            award.htmlAward = [CommunicationsUtil removeErrantEmbeddedTags:award.htmlAward];
            //NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList after removeErrantEmbeddedTags %@", award.htmlAward);
            award.htmlAward = [CommunicationsUtil swapHtmlBreakforCRLF:award.htmlAward];
            //NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList after swapHtmlBreakforCRLF %@", award.htmlAward);
            award.htmlAward = [CommunicationsUtil fixBoundariesOfHtmlTags:award.htmlAward];            
            //NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList after fixTagEndQuotes %@", award.htmlAward);
            award.htmlAward = [CommunicationsUtil fixImageTags:award.htmlAward];
            
            award.requiredAwards = [self determineNumberOfRequiredAwards:award.htmlAward];
            if (!award.requiredAwards) {
                award.requiredAwards = [self determineNumberOfRequiredAwards:self.selectedGroup.name];
                if (!award.requiredAwards) {
                    award.requiredAwards = 5;
                }
            }
            NSLog(@"FlckrHtmlParserDelegate.getBestAwardFromList %@", award.htmlAward);
         } 
    }
    
    return award;
}



static NSString * const kPosStartAward_200   = @"thank you for sharing,thanks for sharing,awarded the,i like it,this is really,i love your,gracias por,grazie per,prime photo award,awards to request an invitation,remember to post";

static NSString * const kPosAdj          = @"beautiful,great,wins,wow,awesome,excellent,appreciated,excelente,magnificent,wondrous,prime,wonderful,lovely,nice,amazing,fantastic,stunning,sparkles,shines,glows,special,admirable,addictive,alluring,angelic,appealing,beauteous,certified,charming,classy,cool,congratulation,congratulations,cute,dazzling,delicate,delightful,divine,elegant,enticing,exquisite,fascinating,fine,gorgeous,grand,handsome,marvelous,pleasing,pulchritudinous,radiant,ravishing,refined,resplendent,shapely,splendid,statuesque,sublime,superb,accomplished,attractive,champion,choice,choicest,distinctive,distinguished,estimable,exceptional,exemplary,finest,first-class,first-rate,high,meritorious,notable,master,outstanding,select,skillful,sterling,striking,superlative,supreme,top-notch,transcendent,awe-inspiring,breathtaking,impressive,majestic,phenomenal,remarkable,stupendous,best,mejor,mesmeric,adorable,agreeable,captivating,enchanting,engaging,enthralling,glamorous,good-looking,interesting,magnetic,pleasant,tantalizing,winning,winsome,heavenly,blissful,beatific,brilliant,celestial,cherubic,entrancing,ethereal,seraphic,arresting,consuming,engrossing,exciting,intriguing,riveting,spellbinding,good,pretty,addictive,spectacular,astounding,unrivaled,superior,august,glorious,matchless,noble,optimal,optimum,peerless,proud,splendiferous,splendorous,standout,uplifting,attention";

static NSString * const kPosPronoun      = @"this ,you ,your ,lo ,esto ,esta ,su, tua, my, I";
static NSString * const kPosNoun         = @"image,photo,shot,foto,capture,picture,example,it,master,work,fotografía,fotografia,tomó,lanzó,scatto,imagen,immagine,cuadro,quadro,choice";

static NSString * const kPosPreAdverb    = @"truly,really,definitely,certainly,absolutely,beyond any doubt,no doubt,categorically,clearly,decidedly,doubtless,doubtlessly,easily,explicitly,expressly,indubitably,obviously,plainly,positively,undeniably,unequivocally,unmistakably,unquestionably,without doubt,without fail,without question,keep up,very";

static NSString * const kPosSimpleVerb   = @" is , es ,was ,has ";
static NSString * const kPosDesVerb      = @"seen,admired,deserves,viewed,vista,appreciated,awarded,saw,worthy of,found, demands, earns, gains, gets, merits, procures, warrants, wins, won, receives, love,born,vi ,caught";
static NSString * const kPosAfterAdverb  = @" at, en, in, on";
static NSString * const kPosExeclamation = @"!";
static NSString * const kStopProcLine    = @"please ,<a href,<link,+xml,<script,load:function,copy below,join our group,invited to,comments &amp;,copy and paste,copy &amp; paste,must include the words,for comments,paste this,images in this group,to invite,copy the following,copy from this,add this beautiful photo";

static NSString * const kNoop = @" a , an , the , and ,<br />, de , la ";

// An array of arrays with comma delimited words used to look for positive language associated with awards given to user's photos.
- (NSArray *)getWordConstructsToTry {
                                                    // I            saw             the     beautiful   photo       in
                                                    // kPosPronoun  kPosDesVerb     kNoop   kPosAdj     kPosNoun    kPosAfterAdverb
    return [NSArray arrayWithObjects:
                                    [NSArray arrayWithObjects:kPosPronoun,kPosAdj, kPosNoun, kPosSimpleVerb, kPosDesVerb, kPosAfterAdverb, nil], // "your beautiful photo was seen in"
                                    [NSArray arrayWithObjects:kPosPronoun,kPosDesVerb, kPosPronoun, kPosAdj, kPosNoun, kPosAfterAdverb, nil], // "I saw your beautiful photo in"
                                    [NSArray arrayWithObjects:kPosPronoun,kPosDesVerb, kPosAdj, kPosNoun, kPosAfterAdverb, nil], // "I saw the beautiful photo in"

                                    [NSArray arrayWithObjects:kPosPronoun,kPosNoun,kPosSimpleVerb,kPosPreAdverb,kPosAdj, nil], // "your image is truly phenomenal"
                                    [NSArray arrayWithObjects:kPosAdj, kPosNoun, kPosSimpleVerb, kPosDesVerb, kPosAfterAdverb, nil], // "beautiful photo was seen in"
                                    [NSArray arrayWithObjects:kPosPronoun, kPosNoun, kPosSimpleVerb, kPosDesVerb, kPosAfterAdverb, nil], // "your photo was viewed on" 
                                    [NSArray arrayWithObjects:kPosAdj, kPosNoun, kPosDesVerb, kPosAfterAdverb, nil], // "excellent photo viewed on"
                                    [NSArray arrayWithObjects:kPosAdj,kPosNoun,kPosPreAdverb,kPosDesVerb, nil], // "wonderful capture definitely deserves"
                                    [NSArray arrayWithObjects:kPosNoun,kPosSimpleVerb,kPosPreAdverb,kPosAdj, nil], // "image is truly phenomenal"
                                    [NSArray arrayWithObjects:kPosPronoun,kPosNoun,kPosSimpleVerb,kPosAdj, nil], //    "this image is wonderful"
                                    [NSArray arrayWithObjects:kPosPronoun,kPosSimpleVerb, kPosAdj, kPosNoun, nil], // this is a magnificent example
                                    [NSArray arrayWithObjects:kPosSimpleVerb,kPosPronoun, kPosNoun, kPosAfterAdverb, nil], // saw your photo in
                                    [NSArray arrayWithObjects:kPosPronoun,kPosNoun, kPosPreAdverb, nil], // "your photo truly"
                                    [NSArray arrayWithObjects:kPosNoun,kPosPreAdverb,kPosDesVerb, nil], // "photo definitely deserves"
                                    [NSArray arrayWithObjects:kPosNoun,kPosPreAdverb,kPosAdj, nil], //    "image really shines"
                                    [NSArray arrayWithObjects:kPosNoun,kPosSimpleVerb,kPosAdj, nil], //    "image is wonderful"
                                    [NSArray arrayWithObjects:kPosNoun,kPosPreAdverb,kPosAdj, nil], // "photo truly sparkles"
                                    [NSArray arrayWithObjects:kPosPreAdverb,kPosDesVerb,kPosAfterAdverb, nil], // "admired and awarded in"
                                    [NSArray arrayWithObjects:kPosDesVerb,kPosAfterAdverb,kPosNoun, nil], // "no doubt in it, a masterpiece"
                                    [NSArray arrayWithObjects:kPosDesVerb,kPosAfterAdverb, nil], // "seen in"
                                    [NSArray arrayWithObjects:kPosAdj,kPosNoun, nil], // "beautiful photo"
                                    [NSArray arrayWithObjects:kPosSimpleVerb,kPosDesVerb, nil], // "was awarded", "is admired"
                                    [NSArray arrayWithObjects:kPosPreAdverb,kPosDesVerb, nil], // "really deserves"
                                    [NSArray arrayWithObjects:kPosDesVerb,kPosDesVerb, nil], // "admired and awarded"
                                    [NSArray arrayWithObjects:kPosNoun,kPosDesVerb, nil], // "image viewed", "photo wins"                                    
                                    [NSArray arrayWithObjects:kPosNoun, kPosPreAdverb, nil], // "photo truly"                                    
                                    [NSArray arrayWithObjects:kPosAdj, nil], // "awesome!"
                                    nil];
}

// See if the required constructs are present in the line and in the order of the array.
- (BOOL)parseLanguageConstruct:(NSArray *)contructList forLine:(NSString *)line {
    
    NSString *workingText = line;
    
    // Each construct must find one word or this sequence doesn't match.
    int count = 1;
    for (NSString *wordCommaDelimitedList in contructList) {

        NSRange range = [CommunicationsUtil findFirstWord:wordCommaDelimitedList inText:workingText];        
        if (range.length == 0) {
            return NO;
        }
        
        // Get the next search area, but overlap it one char to check for spaces    
        workingText = [workingText substringFromIndex:(range.length+range.location-2)];        
        count++;
    }

    return YES;
}

// Checks for language contruct matches and adds up points on the number of matching words and overall closeness of the match
- (int)checkLanguageOfLine:(NSString *) line  usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {
    // Look for spaces to determine approx words in this line. 
    int wordCount = [[line componentsSeparatedByString:@" "] count];
    
    // Remove filler words to get more accurate match calcs and speed time to process the line.
    wordCount -= [CommunicationsUtil checkTags:kNoop forCurrentLine:line usingPoints:1];
    wordCount -= [weakDelegate findNumberOfNoopWords:line];

    int pointsGained = 0;
    int lineCount = 1;
    for (NSArray *wordConstruct in [weakDelegate getWordConstructsToTry]) {
        
        if (wordCount >= wordConstruct.count) {
            
            //NSLog(@"FlckrHtmlParserDelegate.checkLanguageOfLine enough words to look for a matchwordContruct wordCount=%d, wordConstruct.count=%d, line=%@", wordCount,wordConstruct.count,line);
            
            if ([weakDelegate parseLanguageConstruct:wordConstruct forLine:line]) {
                
                // Calc points agained. The longer the word constructs found compared to the total line word count,
                // the more points gained.
                pointsGained = wordConstruct.count*75*wordConstruct.count/wordCount;
            
                if ([line rangeOfString:kPosExeclamation].length != 0) {
                    pointsGained += 50;
                }
            
                //NSLog(@"FlckrHtmlParserDelegate.checkLanguageOfLine wordContruct num=%d wordCount=%d, pointsGained=%d, line=%@", lineCount,wordCount,pointsGained,line);
                // The first match gives the highest score because of the way the outer array is ordered.
                break;
            }
        }

        lineCount++;
    }
    
    return pointsGained;
}

static NSString * const kPosPreAward_40      = @"award,comment,code,copy,codigo,comentar,comentario,premios,commentaires,prix,commenti,premi,kommentare,auszeichnungen,for comments &amp;,copy &amp paste,this group comment,certified by beautiful";
static NSString * const kIsACommentCode_60   = @" between,lines,copy,under,award code,comment on photos";
static NSString * const kCommentLine1        = @"line,between,below,under,beneath,after,copy & paste,copy and paste, copy &amp paste,copy from this entire,stop,down,Lütfen aşağıdaki kodu kopyalayıp,İçindeki fotolara yapıştırın";// 2 Req to set flag
static NSString * const kCommentLine2        = @"award,comment,code,codigo,comentar"; // 1 Req to set flag NEED TO USE THREE OF THESE TOGETHER
static NSString * const kCommentLineImage    = @"<a href,<img";
static NSString * const kNegAward_450        = @"invitation code:,invitation code :,if you would like to invite";
static NSString * const kNegAward_250        = @"invite,invited,invitation,join ,please add ,please post ,looks like,consider adding,welcome to,einladung,invito,invitacion,invitación,invitada,por favor agregue, is an admin,no people, no nudity,please no ,there is to be, proud member, your profile";
static NSString * const kNegAward_100        = @"flickriver,flick river";
static NSString * const kNegAwardwComma_150  = @"please, add, badge,old member award,old award";
static NSString * const kNegAward_70         = @"</script>,javascript,winners,competition,<div,</div>,<meta,property=";
static NSString * const kNegAward_35         = @"add,<a href,init,ownername,date_posted,remove,</a>";
static NSString * const kEndOfAwardCode      = @"should look, look like,looks like, like this,stop copying,above here,stop with this,how the code looks";
static NSString * const kDelimiterOfAwardTag1= @"<a href,<img";
static NSString * const kCounterNeg          = @"if ,to get ,for your special invitation to,not an invite,invite only,please tag ,request an invitation,join us on, invite 1,when your,post 1,post 2,please, post 1,comment code,get,to request an invitation,remember to award";

// Words or phrases that are not expected within an award.
static NSString * const kUnexpectedInAward  = @"to award,to comment,copy under,copy between,between the lines,between these lines,following code,following text for comments,copy the,for comment,copy below,copy &amp;,copy from,<form,<div,<input,<script,<object";

#define MAX_AWARD_LINE_SIZE 500
#define MIN_AWARD_LINE_SIZE 4
#define MIN_AWARD_POINTS_TO_BE_CONSIDERED 0
#define NO_SCORE_LINES_LIMIT_TO_END_AWARD 5

-(BOOL)doubleCheckAwardLooksGood:(NSString *)awardText {
    
    if ([CommunicationsUtil checkTags:kNegAward_250 withOutTags:kCounterNeg forCurrentLine:awardText usingPoints:1] >= 2) {
        return NO;
    }
    else if ([CommunicationsUtil checkTags:kNegAward_250 withOutTags:kCounterNeg forCurrentLine:awardText usingPoints:1] &&
             [CommunicationsUtil lineHasRepeatingChars:awardText]) {
        return NO;
    }
    return YES;
}

// Create an award and add it to the list.
- (void)addAwardToPossibleList:(FindAwardHolder *)findWard {
    Award *award = [[Award alloc] init];

    award.htmlAward = findWard.awardText;
    award.confidenceScore = findWard.awardPoints;
    award.created = [NSDate date];
    
    [self.awardList addObject:award];    
    
    //NSLog(@"FlckrHtmlParserDelegate.addAwardToPossibleList Found award with points %d and text: %@", award.confidenceScore, award.htmlAward);    
}

// Determine if the parameter line contains an award delimiter.
- (BOOL)isLineAnAwardDelimiter:(NSString *)line {
    
    if ([CommunicationsUtil lineHasRepeatingChars:line] ||
         [CommunicationsUtil checkTags:kDelimiterOfAwardTag1 forCurrentLine:line usingPoints:1]) {
        return YES;
    }
        
    return NO;
}

// Looks for high scoring indicators of an award
// Positive points will trigger the start of an award - *Critical
// If award has already start, then this may add more points to score this award higher against others found.
- (int)checkCommonAwardWordsTallyPoints:(NSString *)line withLastLine:(NSString *) lastLine usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {
    
    // Check for words or text that would exempt this line from starting an award.
    if ([CommunicationsUtil checkTags:kStopProcLine forCurrentLine:line usingPoints:1]) {
        return 0;
    }
    else if ([CommunicationsUtil lineHasRepeatingChars:line]) {
        return 0;
    }
    
    int pointsGained = [weakDelegate checkLanguageOfLine:line usingDelegate:weakDelegate];    
    
    if (pointsGained < 200) {
        // Look for awards with unusual beginnings
        pointsGained += [CommunicationsUtil checkTags:kPosStartAward_200 forCurrentLine:line usingPoints:200];
    }
    
    // If points were made, see if it looks even better.
    if (pointsGained) {
        
        // NSLog(@"FlckrHtmlParserDelegate.checkAwardStartingIndicatorsInLine pointsGained=%d",pointsGained);
        // These points will be added if other positive word sequences are found.        
        
        // Check for html escape sequences
        if ([CommunicationsUtil lineHasHtmlEscapeSequences:line]) {
            pointsGained *=2.5;
        }
        
        // See if the previous line was an award delimiter.
        if ([weakDelegate isLineAnAwardDelimiter:lastLine]) {
             pointsGained *= 2;
        } 

    } 
    // See if there are other indicators such as html escape codes, on some awards, this is the only thing found.
    if (pointsGained < 200 && [CommunicationsUtil lineHasHtmlEscapeSequences:line]) {
        
        pointsGained += 200;
        
        //NSLog(@"HtmlParser, line %@ !!! lastLine %@", line, lastLine);
        
        // If the last line has a award delimiter, then double the scrore.
        if ([weakDelegate isLineAnAwardDelimiter:lastLine]) {
            pointsGained *= 2;
        }
        // NSLog(@"FlckrHtmlParserDelegate.checkAwardStartingIndicatorsInLine lineHasHtmlEscapeSequences pointsGained=%d",pointsGained);
    }
    
    return pointsGained;
}

// Check to see if a line just before an award has been found.
// Depending on the context, this line may not be a start so careful attention is given and fuzzy logic is used to boost the points some.
-(int)checkTheLineBeforeBeginningOfAward:(NSString *)line awardState:(int) awardState {
    int pointsGained = 0;
    
    if ([CommunicationsUtil lineHasRepeatingChars:line]) {   
        
        if (awardState == COMMENT_DELIMITER_REQ) {
            pointsGained = 200;
        }
        else {                
            pointsGained = 100;
        }
    }
    else if (awardState == COMMENT_DELIMITER_REQ && [CommunicationsUtil checkTags:kCommentLineImage forCurrentLine:line usingPoints:1]) {
        
        pointsGained = 100;
    }
    
    return pointsGained;
}

//Check previous line for content not indicative of an award and tally up negative points.
-(int) checkNegativeAwardIndicators:(NSString *) line withLastLine:(NSString *) lastLine {
    
    int pointsLost =
        [CommunicationsUtil checkTags:kNegAward_450 withOutTags:kCounterNeg forCurrentLine:line usingPoints:-450];
    pointsLost +=
    [CommunicationsUtil checkTags:kNegAward_250 withOutTags:kCounterNeg forCurrentLine:line usingPoints:-250];
    pointsLost +=
        [CommunicationsUtil checkTags:kNegAwardwComma_150 withOutTags:kCounterNeg forCurrentLine:line usingPoints:-150];
    
    pointsLost += [CommunicationsUtil checkTags:kNegAward_100 withOutTags:kCounterNeg forCurrentLine:line usingPoints:-100];
    pointsLost += [CommunicationsUtil checkTags:kNegAward_70 withOutTags:kCounterNeg forCurrentLine:line usingPoints:-70];
    pointsLost += [CommunicationsUtil checkTags:kNegAward_35 forCurrentLine:line usingPoints:-35];
  
    
    return pointsLost;
}

// Check the line for a trailr start marker, append any text after the marker, reset the find
// award holder and update the holder with setting for an award that has started.
- (BOOL)checkForTrailrStartMarker:(NSString *) line forAward:(FindAwardHolder *) findAwardHolder usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {

    // Look for left over text that might be part of an award after the trailr marker.
    if ([TrailrUtil hasGeneralTrailrMarker:line]) {
        
        NSString *leftOverAward = [TrailrUtil getAwardTextAfterBeginTrailerForLine:line];
        
        findAwardHolder.parseState = AWARD_WILL_START;
        findAwardHolder.awardPoints = 500;
        findAwardHolder.awardText = [[NSMutableString alloc] init];
        
        if (leftOverAward && leftOverAward.length > 8) {
            [findAwardHolder.awardText appendString:leftOverAward];
           // NSLog(@"FlickrHtmlParserDelegate text after TRAILER %@", leftOverAward);
        }        
        return YES;
    }
    
    return NO;
}

// See if the lines fail the initial checks,due to being too long or too short.
// If the last line ended an award, rest the holder to get ready for the next award candidate.
- (BOOL)initialLineChecks:(NSString *) line forAward:(FindAwardHolder *) findAwardHolder usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {
    
    if (line.length > MAX_AWARD_LINE_SIZE) {
        findAwardHolder.parseState = AWARD_ENDED;

        return NO;
    }
    else if (line.length < MIN_AWARD_LINE_SIZE) {
        return NO;
    }
    // See if we reached the end of an award and then look for more in case this award is not the right one.
    else if (findAwardHolder.parseState == AWARD_ENDED) {
        [findAwardHolder reset]; //Start over beginning with this line.
    }
    
    return YES;
}

// Look for text indicating that an award may start soon. Update the current find award holder.
- (void)checkForPreAward:(NSString *) line forAward:(FindAwardHolder *) findAwardHolder usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {
    
    // check for award pre-tags
    int pointsForPreAwardWords = [CommunicationsUtil checkTags:kPosPreAward_40 forCurrentLine:line usingPoints:40];
    
    if (pointsForPreAwardWords > 0) {
        
        findAwardHolder.awardPoints += pointsForPreAwardWords * pointsForPreAwardWords/40;        
        
        // If points are still neg and two pos pre award tags are matched, then boost the points on a curve.
        if (findAwardHolder.awardPoints < 0 && pointsForPreAwardWords/40 >= 2) {
            findAwardHolder.awardPoints = -100 + pointsForPreAwardWords * pointsForPreAwardWords/40;
        }
        
        findAwardHolder.parseState = PRE_AWARD_TAGS_FOUND;
    }

}

// Look for text indicating the initial boundary of the award has been found. Updates the award holder.
- (void)checkForCommentAwardDelimiter:(NSString *) line withLastLine:(NSString *) lastLine forAward:(FindAwardHolder *) findAwardHolder usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {

    int pointsForCommentWords = [CommunicationsUtil checkTags:kIsACommentCode_60 forCurrentLine:line usingPoints:60];
    if (pointsForCommentWords != 0) {
        findAwardHolder.awardPoints += pointsForCommentWords;
        findAwardHolder.parseState = COMMENT_WILL_BEGIN;
    }
    
    pointsForCommentWords = [CommunicationsUtil checkTags:kCommentLine1 withOutTags:kNegAward_250 forCurrentLine:line usingPoints:1];
    if (pointsForCommentWords >= 2) {
        pointsForCommentWords = [CommunicationsUtil checkTags:kCommentLine2 forCurrentLine:line usingPoints:1];
        if (pointsForCommentWords) {
            
            findAwardHolder.awardPoints += 100;
            findAwardHolder.parseState = COMMENT_DELIMITER_REQ;
            //NSLog(@"FlckrHtmlParserDelegate.findAwardGroupAwards^ COMMENT_DELIMITER_REQ set for line %@",line);
        }
    }

    // See if the AWARD_WILL_START state should be set.
    if (findAwardHolder.parseState <= COMMENT_DELIMITER_REQ) {
        
        // See if this is the line just before an award.
        int lineAheadPoints = [weakDelegate checkTheLineBeforeBeginningOfAward:line awardState:findAwardHolder.parseState];
        if (lineAheadPoints > 0) {
            findAwardHolder.awardPoints += lineAheadPoints;
            findAwardHolder.parseState = AWARD_WILL_START;
        }
    }
    
    // Determine if the award has started, if it has see if we are to add on more points.
    if (findAwardHolder.parseState != COMMENT_DELIMITER_REQ && findAwardHolder.parseState < AWARD_STARTED) {
        int startAwardScore = [weakDelegate checkCommonAwardWordsTallyPoints:line withLastLine:lastLine usingDelegate:weakDelegate];
        
        if (startAwardScore) { // Point to be added later.
            findAwardHolder.parseState = AWARD_STARTED;
            //NSLog(@"FlickrHtmlParserDelegate award start on line %@", line);
        }
    }

}

// Look for text indicating that an award may has ended. Update the current find award holder.
- (void)checkForEndOfAward:(NSString *) line forAward:(FindAwardHolder *) findAwardHolder usingDelegate:(FlckrHtmlParserDelegate *) weakDelegate {
    
    //if ([line rangeOfString:@"amp;gt;Beautiful" options:NSCaseInsensitiveSearch].length != 0) {
    //NSLog(@"FlckrHtmlParserDelegate.findAwardGroupAwards pnts %d, state %d @@   line %@",findAward.awardPoints,findAward.parseState, line);
    //}
    
    if (([CommunicationsUtil lineHasRepeatingChars:line] && ![CommunicationsUtil lineHasHtmlEscapeSequences:line])) {
        
        NSString *alphaOnly = [CommunicationsUtil removeNonAlphaCharactersFrom:line];
        if (![CommunicationsUtil checkTags:kPosAdj forCurrentLine:alphaOnly usingPoints:1]) {
        
            findAwardHolder.parseState = AWARD_ENDED;
        }
    }
    else if ([TrailrUtil hasGeneralTrailrMarker:line]) {
        NSString *awardTextInFrontOfTrailrLink = [TrailrUtil getAwardTextInFrontOfTrailerForLine:line];
        if (awardTextInFrontOfTrailrLink && awardTextInFrontOfTrailrLink.length > 5) {
            [findAwardHolder.awardText appendString:awardTextInFrontOfTrailrLink];
        }
        findAwardHolder.parseState = AWARD_ENDED;
        
        if ([TrailrUtil hasTrailrEndAwardMarker:line]) {
                findAwardHolder.awardPoints += 350;
        }
        else if ([TrailrUtil hasTrailrEndInviteMarker:line]) {
            findAwardHolder.awardPoints = -250;
        }
    }
    else if ([CommunicationsUtil checkTags:kEndOfAwardCode forCurrentLine:line usingPoints:5]) {
        findAwardHolder.parseState = AWARD_ENDED;
    }
    else if ([CommunicationsUtil checkTags:kDelimiterOfAwardTag1 forCurrentLine:line usingPoints:1]) {
        findAwardHolder.parseState = AWARD_ENDED;
    }
    else if ([CommunicationsUtil checkTags:kUnexpectedInAward withOutTags:kCounterNeg forCurrentLine:line usingPoints:1]) {
        
        // Found a new beginning in the middle of what was thought to be an award.
        findAwardHolder.parseState = AWARD_ENDED;
        findAwardHolder.awardPoints = -100;
    }
    else {
        int pointsForCommentWords = [CommunicationsUtil checkTags:kCommentLine1 withOutTags:kNegAward_250 forCurrentLine:line usingPoints:1];
        pointsForCommentWords += [CommunicationsUtil checkTags:kCommentLine2 forCurrentLine:line usingPoints:1];
        if (pointsForCommentWords >= 3) {
            findAwardHolder.parseState = AWARD_ENDED;
        }
    }
}

// Searh text line by line for award candidates. When found, put them into an array for later processing.
- (void)findAwardGroupAwards:(NSString *) htmlContent {
    
    // Start by looking for high ranking phrases or delimiters and jump to that position.
    __block FindAwardHolder *findAwardHolder = [self findGeneralAreaofAward:htmlContent];
    __weak FlckrHtmlParserDelegate *weakDelegate = self;
    __block NSString *lastLine;
    
    // Start at award like phrases or the beginning.  
    NSString *htmlSearchArea = [htmlContent substringFromIndex:findAwardHolder.startLocation]; 
    
    // Parse each line tallying point and finding awards to add to the list.
    [htmlSearchArea enumerateLinesUsingBlock:^(NSString *line, BOOL *stop){    
    
        // Debug code, best to keep it for now.
        //if ([line rangeOfString:@"TO AWARD A FLICKR IDOL" options:NSCaseInsensitiveSearch].length != 0) {

          // NSLog(@" pnts %d, state %d @@ line %@",
            //    findAwardHolder.awardPoints,findAwardHolder.parseState, lastLine);
        // }
        
        // See if the lines fail the initial checks, due to being too long or too short.
        if (![weakDelegate initialLineChecks:line forAward:findAwardHolder usingDelegate:weakDelegate]) {
            lastLine = line;
            return;
        }
        
        if (findAwardHolder.parseState > START) {
            // check for wrong award and pre-tags
            findAwardHolder.awardPoints += [weakDelegate checkNegativeAwardIndicators:line withLastLine:lastLine];
        }
        
        // Look for comment, or award, will begin in the line.
        if (findAwardHolder.parseState <= AWARD_WILL_START) {
            [weakDelegate checkForPreAward:line forAward:findAwardHolder usingDelegate:weakDelegate];
            [weakDelegate checkForCommentAwardDelimiter:line withLastLine:lastLine forAward:findAwardHolder usingDelegate:weakDelegate];
            [weakDelegate checkForTrailrStartMarker:line forAward:findAwardHolder usingDelegate:weakDelegate];
        }
          
        // See if we hit a big sign the award is completed.
        if (findAwardHolder.parseState == AWARD_STARTED) {
            
            findAwardHolder.awardPoints += [weakDelegate checkCommonAwardWordsTallyPoints:line withLastLine:lastLine usingDelegate:weakDelegate];

            [weakDelegate checkForEndOfAward:line forAward:findAwardHolder usingDelegate:weakDelegate];
        }
        
        if (findAwardHolder.parseState == AWARD_STARTED) {
            [findAwardHolder.awardText appendString:line];
        }         
        
        // Check to see if there are a bunch of empty lines.
        if (findAwardHolder.awardPoints == findAwardHolder.pointsForLastLine) {
            findAwardHolder.linesSincePointsIncreased++;
            
            if (findAwardHolder.linesSincePointsIncreased > NO_SCORE_LINES_LIMIT_TO_END_AWARD) {
                
                if (findAwardHolder.parseState < AWARD_STARTED) {
                    findAwardHolder.awardPoints -= 200;
                }
                
                findAwardHolder.parseState = AWARD_ENDED;
            }
        }
        else {
            findAwardHolder.linesSincePointsIncreased = 0;
        }        
        
        // Can this award be added to the list???
        if (findAwardHolder.parseState == AWARD_ENDED && findAwardHolder.awardPoints > MIN_AWARD_POINTS_TO_BE_CONSIDERED) {
            
            // Go ahead and add it, but mark it with very low confidence.
            if (![weakDelegate doubleCheckAwardLooksGood:findAwardHolder.awardText]) {
                findAwardHolder.awardPoints = 60;
            }
            
            // Add this award to the list.
            [weakDelegate addAwardToPossibleList:findAwardHolder];
        }
        // Don't let the award indicators to get too low.
        else if (findAwardHolder.awardPoints < -500) {
            findAwardHolder.parseState = AWARD_ENDED;
        }
        
        findAwardHolder.pointsForLastLine = findAwardHolder.awardPoints;
               
        if (line.length > 10) {
            lastLine = line;
        }
     }]; // End of Block
}

// Get the groups web page and try to find the award html content.
- (void)getAwardAutomaticallyFromWebPage {

    NSString *htmlContent = [self getGroupWebPageHtmlContent];
    
    if (htmlContent) {
        //NSLog(@"got html: %@", htmlContent);        
        [self findAwardGroupAwards:htmlContent];
    }    
}

@end
