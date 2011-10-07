//
//  NicoLiveProgram.m
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "NicoLiveProgram.h"
#import "HTTPConnection.h"
#import "NicoLiveAlertDefinitions.h"
#import "RegexKitLite.h"

@interface NicoLiveProgram ()
- (void) parseRSSNode:(NSXMLNode *)rssNode;
- (void) parseStreamInfo:(NSXMLNode *)streamNode;
- (void) makeMenuImage;
- (void) checkLiveAlive;
@end

@implementation NicoLiveProgram
@synthesize liveAlive;
@synthesize title;
@synthesize description;
@synthesize liveNo;
@synthesize menuItem;
@synthesize thumbnail;
@synthesize menuImage;

- (id) init
{
  self = [super init];
  if (self)
  {
      // Initialization code here.
  }
  
  return self;
}// end init

- (id) initWithStreaminfo:(NSXMLNode *)node
{
  self = [super init];
  if (self)
  {
    liveAlive = YES;
    menuItem = nil;
  	[self parseStreamInfo:node];
    [self makeMenuImage];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFireMethod) userInfo:nil repeats:YES];
    [timer fire];
  }
  
  return self;
}// end initWithStreaminfo:(NSXMLNode *)node

- (id) initWithRSS:(NSXMLNode *)node
{
  self = [super init];
  if (self)
  {
    liveAlive = YES;
    menuItem = nil;
    [self parseRSSNode:node];
    [self makeMenuImage];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFireMethod) userInfo:nil repeats:YES];
    [timer fire];
  }
  
  return self;
}// end initWithRSS:(NSXMLNode *)node

- (void)dealloc
{
  [timer invalidate];
  [liveNo release];
  [title release];
  [description release];
  [buffer release];
  [thumbnail release];
  [menuImage release];
  [startTime release];
  [super dealloc];
}// end - (void)dealloc

#pragma -
#pragma accessor

- (NSString *) liveURL
{
  NSString *urlstr = [NSString stringWithFormat:LiveURLFormat, liveNo];
  return [NSURL URLWithString:urlstr];
}// end - (NSString *) liveURL

#pragma -
#pragma internal
- (void) parseRSSNode:(NSXMLNode *)rssNode
{
  NSError *err;
  NSArray *nodes;
  
  	// get time
  nodes = [rssNode nodesForXPath:@"pubDate" error:&err];
  if ([nodes count] == 1)
  {
    startTime = [[NSDate	dateWithNaturalLanguageString:[[nodes objectAtIndex:0] stringValue]] retain];
      //    startTime = [[NSDate alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
  }
    // get liveNo
  nodes = [rssNode nodesForXPath:@"guid" error:&err];
  if ([nodes count] == 1)
    liveNo = [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
  	// get live title
  nodes = [rssNode nodesForXPath:@"title" error:&err];
  if ([nodes count] == 1)
    title = [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
  	// get live description
  nodes = [rssNode nodesForXPath:@"description" error:&err];
  if ([nodes count] == 1)
    description = [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
    // get community thumbnail
  NSString *thumbURLStr;
	nodes = [rssNode nodesForXPath:@"media:thumbnail" error:&err];
  if ([nodes count] == 0)
    nodes = [rssNode nodesForXPath:@"thumbnail" error:&err];
  if ([nodes count] == 1)
  {
    HTTPConnection *http = [[[HTTPConnection alloc] init] autorelease];
    thumbURLStr = [[[nodes objectAtIndex:0] attributeForName:@"url"] stringValue];
    NSURL *thumbURL = [NSURL URLWithString:thumbURLStr];
    NSData *thumbData = [http httpData:thumbURL];
    thumbnail = [[NSImage alloc] initWithData:thumbData];
      // make menuIcon;
		menuImage = [[NSImage alloc] initWithData:thumbData];
    [menuImage setSize:NSMakeSize(MenuIconSize, MenuIconSize)];
  }
}// end - (void) parseRSSNode:(NSXMLNode *)rssNode

#pragma mark -
#pragma mark internal
- (void) parseStreamInfo:(NSXMLNode *)streamNode
{
  NSError *err;
  NSArray *nodes;
  
  startTime = [[NSDate alloc] init];
  	// get liveNo;
  nodes = [streamNode nodesForXPath:@"/getstreaminfo/request_id" error:&err];
  if ([nodes count] == 1)
    liveNo = [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
  	// get live title
  nodes = [streamNode nodesForXPath:@"/getstreaminfo/streaminfo/title" error:&err];
  if ([nodes count] == 1)
    title = [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
    // get live description
  nodes = [streamNode nodesForXPath:@"/getstreaminfo/streaminfo/description" error:&err];
  if ([nodes count] == 1)
    description	= [[NSString alloc] initWithString:[[nodes objectAtIndex:0] stringValue]];
  	// get community thumbnail
  nodes	= [streamNode nodesForXPath:@"/getstreaminfo/communityinfo/thumbnail" error:&err];
  NSString *thumbURLStr;
  if ([nodes count] == 1)
  {
    HTTPConnection *http = [[[HTTPConnection alloc] init] autorelease];
    thumbURLStr = [[nodes objectAtIndex:0] stringValue];
    NSURL *thumbURL = [NSURL URLWithString:thumbURLStr];
    NSData *thumbData = [http httpData:thumbURL];
    thumbnail = [[NSImage alloc] initWithData:thumbData];
    menuImage	 = [[NSImage alloc] initWithData:thumbData];
    [menuImage setSize:NSMakeSize(MenuIconSize, MenuIconSize)];
  }
}// end - (void) parseStreamInfo:(NSXMLNode *)streamNode

- (void) makeMenuImage
{
  buffer = [[NSImage alloc] initWithSize:NSMakeSize(256.0, 64.0)];
	[buffer lockFocusFlipped:NO];
  [thumbnail drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:NSMakeRect(0.0, 0.0, 64.0, 64.0) operation:NSCompositeSourceOver fraction:1.0];
  NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"HiraKakuStd-W8" size:10], NSFontAttributeName, nil];
  [title drawAtPoint:NSMakePoint(66, 50) withAttributes:attrDict];
	[buffer unlockFocus];
  [buffer lockFocusFlipped:YES];
  [[NSFont messageFontOfSize:10] set];
  NSTextStorage *txtStorage;
  NSTextContainer *txtContainer;
  NSLayoutManager *layoutManager;
  NSFont *font = [NSFont fontWithName:@"HiraKakuProN-W3" size:10.0];
  NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
  [paragraph setLineSpacing:-3.0];
  attrDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraph, NSParagraphStyleAttributeName, nil];
  txtStorage = [[NSTextStorage alloc] initWithString:description attributes:attrDict];
  NSSize viewSize = NSMakeSize(192.0, 49.0);
  txtContainer = [[NSTextContainer alloc] initWithContainerSize:viewSize];
  layoutManager = [[NSLayoutManager alloc] init];
  [txtStorage addLayoutManager:layoutManager];
  [layoutManager addTextContainer:txtContainer];
	NSRange range = [layoutManager glyphRangeForTextContainer:txtContainer];
  NSPoint point = NSMakePoint(64.0, 15.0);
  [layoutManager drawGlyphsForGlyphRange:range atPoint:point];
  [buffer unlockFocus];
	[txtStorage release];
  [txtContainer release];
  [layoutManager release];
  [menuImage release];
  menuImage = [buffer copy];
}// end - (void) makeMenuImage

- (void) checkLiveAlive
{
  NSError *err;
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:EmbedURL, liveNo]];
  HTTPConnection *http = [[[HTTPConnection alloc] init] autorelease];
  NSString *urlString = [http httpSource:url];
  NSString *mutch = [urlString stringByMatching:OnAirString options:RKLMultiline inRange:NSMakeRange(0, [urlString length]) capture:0L error:&err];
  if (mutch == nil)
    [self setLiveAlive:NO];
  else
    liveAlive = YES;
}// end - (void) checkLiveAlive

- (void) timerFireMethod
{
  NSString *leftTimeStr;
  NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:9], NSFontAttributeName, nil];
  NSInteger fullsec = 1800 + [startTime timeIntervalSinceNow];
  if (liveAlive == YES)
  {
    while (fullsec < 0)
      fullsec += 1800;
    NSInteger	sec = fullsec % 60;
    NSInteger minute = (fullsec / 60) % 30;
    NSString *sTimeStr = [startTime descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
    leftTimeStr = [NSString stringWithFormat:@"%@~ / @%02d:%02d",sTimeStr , minute, sec];
    [menuImage release];
    menuImage = [buffer copy];
    [menuImage lockFocusFlipped:NO];
    [leftTimeStr drawAtPoint:NSMakePoint(145.0, 1.0) withAttributes:attrDict];
  }
  else
  {
    leftTimeStr = [NSString stringWithFormat:StatusDone];
    [menuImage release];
    menuImage = [buffer copy];
    [menuImage lockFocusFlipped:NO];
    [leftTimeStr drawAtPoint:NSMakePoint(220.0, 1.0) withAttributes:attrDict];
  }
  [menuImage unlockFocus];
  [menuItem setImage:menuImage];
  if (((fullsec % 180) == 0) && (liveAlive == YES))
    [self checkLiveAlive];
}// end - (void) timerFireMethod

@end
