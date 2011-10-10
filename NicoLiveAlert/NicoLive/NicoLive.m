//
//  NicoLive.m
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "NicoLive.h"
#import "NicoLiveAlertDefinitions.h"

@interface NicoLive ()
  //
- (void) updateStatusIcon;
- (void) openURL:(NSURL *)url;
- (void) notifyNewProgram:(NicoLiveProgram *)live;
- (void) foundNewLiveInSocket:(NSXMLNode *)node;
- (void) foundNewLiveInRSS:(NSXMLNode *)node;
  // notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)program change:(NSDictionary *)change context:(void *)context;
  // Other application collaboration
- (void) startFMLE:(NSString *)live;
- (void) stopFMLE;
  // Async URL Connection Delegate
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)con;
- (void) abort;
  // Growling
- (void) growlNotificationWasClicked:(id)clickContext;
@end

@implementation NicoLive
@synthesize isPremium;
@synthesize statusIcon, programMenu;
#pragma mark construct / destruct
- (id) init
{
  self = [super init];
  if (self)
  {
      // myStatus
    myUserID = nil;
    isPremium = NO;
    	// my joined communities storage
    communities = [[NSMutableDictionary alloc] initWithCapacity:16];
      // program alive checker
    activePrograms = [[NSMutableDictionary alloc] initWithCapacity:16];
      // socket pushed data storage
    recieveQueue = [[NSMutableArray alloc] initWithCapacity:8];
      // message server information
    serverAddr = nil;
    serverPort = -1;
    serverThread = nil;
      // httpConnection class
    http = [[HTTPConnection alloc] init];
    sock = [[SocketConnection alloc] initWithRecieveQueue:recieveQueue];
      // Current All RSS Feed
    rss = nil;
      // collaboration control
    broadcasting = NO;
      // for asyncronus rss retrieve
    pageCount = 0;
    currentPage = 0;
    firstTime = YES;
    rssData = nil;
    AllRSSs = nil;
    lastTopCache = nil;
    [GrowlApplicationBridge setGrowlDelegate:self];
  }

  return self;
}// end - (id) init

- (void) dealloc
{
  [communities release];
  [activePrograms release];
  [recieveQueue release];
  [serverAddr release];
  [serverThread release];
  [rss release];
  [http release];
  [sock release];
  [super dealloc];
}// end - (void) dealloc


#pragma mark -
#pragma mark public
- (BOOL) login:(NSString *)loginID password:(NSString *)password
{		// login & get loginticket
  NSString *postdata = [NSString stringWithFormat:@"mail=%@&password=%@", loginID, password];
  NSURL *url = [NSURL URLWithString:LoginAPIServerURL];
  NSData *result = [http postMessage:postdata ToURL:url];
  NSError *err;
  NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:result options:NSXMLDocumentTidyXML error:&err];
  NSXMLElement *root = [xml rootElement];
  	// check success
  if ((root == nil) || ([[[root attributeForName:@"status"] stringValue] isEqualToString:@"ok"] == NO))
    return NO;
  
    // ok continue
    // get login ticket
  NSXMLNode *resultNode;
  resultNode = [[root nodesForXPath:LoginTicketXPath error:&err] objectAtIndex:0];
  NSString *loginTicket = [resultNode stringValue];
  [xml release];
  
		// correct my communities & channels
  url = [NSURL URLWithString:[NSString stringWithFormat:AlertStatusAPIURL, loginTicket]];
	result = [[http httpData:url] autorelease];
  xml = [[NSXMLDocument alloc] initWithData:result options:NSXMLDocumentTidyXML error:&err];
  root = [xml rootElement];
    // check success
  if ((root == nil) || ([[[root attributeForName:@"status"] stringValue] isEqualToString:@"ok"] == NO))
    return NO;
  
    // ok continue
    // get myUid
  resultNode = [[root nodesForXPath:MyUserIDXPath error:&err] objectAtIndex:0];
  myUserID = [[resultNode stringValue] copy];
    // cheki I'm premium ?
  resultNode = [[root nodesForXPath:IsPremiumXPath error:&err] objectAtIndex:0];
	[self setIsPremium:[[resultNode stringValue] boolValue]];
    // add community & channel to dictionary
  NSArray *channels;
  channels = [root nodesForXPath:MyCommunityXPath error:&err];
  NSString *comch;
  NSNumber *defaultno = [NSNumber numberWithBool:NO];
  for (NSXMLNode *node in channels)
  {
    comch = [node stringValue];
    [communities setValue:defaultno forKey:comch];
  }// end foreach channels
    // correct message server
    // get server
  resultNode = [[root nodesForXPath:ProgramServerXPath error:&err] objectAtIndex:0];
  serverAddr = [resultNode stringValue];
    // get port
  resultNode = [[root nodesForXPath:ProgramPortXPath error:&err] objectAtIndex:0];
  serverPort = [[resultNode stringValue] integerValue];
    // get thread
  resultNode = [[root nodesForXPath:ProgramThreadXPath error:&err] objectAtIndex:0];
  serverThread = [resultNode stringValue];
  	// all data corrected release object & return result
  [xml release];
  
  return YES;
    //  NSString *logdata = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    //  NSLog(@"alert result\n%@", logdata);
}// end - (BOOL) login:(NSString *)loginID password:(NSString *)password

- (void) startMonitorProgram
{
  NSString *ticket = [NSString stringWithFormat:ProgramThreadQuery, serverThread];
  [sock openServer:serverAddr port:serverPort];
  [sock sendText:ticket];
	NSThread *programThread = [[NSThread alloc] initWithTarget:self selector:@selector(processProgramInThread) object:nil];
  [programThread start];
}// end - (void) startMonitorProgram

- (void) monitorProgramEnd
{
  [sock closeServer];
}// end - (void) monitorProgramEnd

- (void) addSingleWatchList:(NSString *)watch
{
  [communities setValue:[NSNumber numberWithBool:NO] forKey:watch];
}// end - (void) addSingleWatchList:(NSString *)watch

- (void) removeSingleWatchList:(NSString *)watch
{
  [communities removeObjectForKey:watch];
}// end - (void) removeSingleWatchList:(NSString *)watch

- (void) addManualWatchList:(NSArray *)programs
{
  for (NSDictionary *dict in programs)
  {
		NSNumber *isAutoOpen = [dict objectForKey:KeyAutoOpen];
    NSString *watchItem = [dict objectForKey:KeyCommunity];
    [communities setValue:isAutoOpen forKey:watchItem];
  }// end foreach wlist
}// end - (void) addManualWatchList:(NSDictionary *)wlist

- (void) changeAutoOpenStatus:(NSString *)community with:(NSNumber *)isAutoOpen
{
  [communities setValue:isAutoOpen forKey:community];
}// end - (void) changeAutoOpenStatus:(NSString *)community with:(NSNumber *)autoOpen

- (void) rejectEndedProgram
{
  for (NicoLiveProgram *program in [activePrograms allValues])
  {
    if ([program liveAlive] == NO)
    {
      NSMenuItem *item = [program menuItem];
      [programMenu removeItem:item];
      [activePrograms removeObjectForKey:[program liveNo]];
      [self updateStatusIcon];
    }
  }// end foreach live no.
}// end - (void) rejectEndedProgram

- (void) startMakeAllRSSAsync
{
  currentPage = 1;
  lastTopCache = currentTopCache;
  currentTopCache	= nil;
	NSURL *rssURL = [NSURL URLWithString:[NSString stringWithFormat:RSSInforURL, @"", currentPage]];
  [rssData release];
  rssData = [[NSMutableData alloc] initWithCapacity:4096];
  [rssData setData:[http httpData:rssURL]];
  NSError *err;
  NSXMLDocument *xml;
  @try {
    xml = [[[NSXMLDocument alloc] initWithData:rssData options:NSXMLDocumentTidyXML error:&err] autorelease];
    NSXMLElement *root = [xml rootElement];
    if ([[root name] isEqualToString:@"rss"] == NO)
      return;
    NSInteger count = [[[[root nodesForXPath:RSSTotalCountXPath error:&err] objectAtIndex:0] stringValue] integerValue];
    pageCount = ceilf(count / 18);
#ifdef DEBUG
    NSLog(@"checklist count is : %ld", [[communities allKeys] count]);
    for (NSString *chk in [communities allKeys])
    {
      NSLog(@"check : `%@`", chk);
    }
    NSLog(@"pageCount : %ld", pageCount);
#endif
    iconTimerStatus = NO;
      // cleanup previous status icon EyeCandy
    if ([statusIconTimer isValid] == YES)
      [statusIconTimer invalidate];
      // start icon EyeCandy
    statusIconTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerIconUpdate) userInfo:nil repeats:YES];
    [statusIconTimer fire];
    [self connectionDidFinishLoading:nil];
  }
  @catch (NSException *exception) {
    NSLog(@"startMakeAllRSSAsync - NicoLive.m cause exception");
    NSLog(@"%@", [exception name]);
    NSLog(@"%@", [exception userInfo]);
  }
}// end - (void) startMakeAllRSSAsync

#pragma mark -
#pragma mark Async URL Connection Delegate
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [rssData release];
  rssData = [[NSMutableData alloc] initWithCapacity:4096];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [rssData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [self abort];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
  NSError *err;
  NSXMLDocument *xml;
  @try {
    xml = [[[NSXMLDocument alloc] initWithData:rssData options:NSXMLDocumentTidyXML error:&err] autorelease];
    NSXMLElement *root = [xml rootElement];
    NSArray *nodes = [root nodesForXPath:RSSLiveIDXPath error:&err];
    NSNumber *autoOpen = nil;
    NSXMLNode *parent;
    NSArray *commus;
    for (NSXMLNode *node in nodes)
    {
        // check first lv#
      if (currentTopCache == nil)
        currentTopCache = [node stringValue];
        // check reach last lv#
      if ([lastTopCache isEqualToString:[node stringValue]] == YES)
      {
        [statusIconTimer invalidate];
        [self updateStatusIcon];
        [self rejectEndedProgram];
        return;
      }
        // check already opend
      NSString *liveNo = [node stringValue];
      if ([activePrograms objectForKey:liveNo] != nil)
      {// yes alredy open skip this RSS
        continue;
      }
        // check lv#
#ifdef DEBUG
      NSLog(@"checking %@", [node stringValue]);
#endif
      autoOpen = [communities objectForKey:liveNo];
      if (autoOpen != nil)
      {// notify program
        [self foundNewLiveInRSS:[node parent]];
        if ([autoOpen boolValue] == YES)
        {
          NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:ProgramURL, [node stringValue]]];
          [self openURL:url];
        }// end if autoOpen
      }// endif found live (by lv#)
      
        // check co#
      parent = [node parent];
      commus = [parent nodesForXPath:ItemCommuXPath error:&err];
#ifdef DEBUG
      NSLog(@"checking %@", [[commus objectAtIndex:0] stringValue]);
#endif
      if ([commus count] == 1)
      {
        autoOpen = [communities objectForKey:[[commus objectAtIndex:0] stringValue]];
        if (autoOpen != nil)
        {// notify program
#ifdef DEBUG
          NSLog(@"%@", [parent stringValue]);
#endif
          [self foundNewLiveInRSS:parent];
          if ([autoOpen boolValue] == YES)
          {
            NSArray *lives = [parent nodesForXPath:ItemLvIDXPath error:&err];
            NSURL *url;
            if ([lives count] >= 1)	// open by live no
              url = [NSURL URLWithString:[NSString stringWithFormat:ProgramURL, [[lives objectAtIndex:0] stringValue]]];
            else	// open by community no
              url = [NSURL URLWithString:[NSString stringWithFormat:ProgramURL, [[commus objectAtIndex:0] stringValue]]];
            [self openURL:url];
          }
        }// end if found live (by co#)
      }
    }// end foreach current RSS nodes
      // check next rss page
    if (currentPage++ < pageCount)
    {
#ifdef DEBUG
      NSLog(@"Goto Next RSS Page %ld", currentPage);
#endif
      NSURL *rssURL = [NSURL URLWithString:[NSString stringWithFormat:RSSInforURL, @"", currentPage]];
      connection = [http httpDataAsync:rssURL delegate:self];
    }
    else
    {
#ifdef DEBUG
      NSLog(@"All check Done");
#endif
      [statusIconTimer invalidate];
      [self updateStatusIcon];
      [self rejectEndedProgram];
    }
  }
  @catch (NSException *exception) {
    NSLog(@"connectionDidFinishLoading: - NicoLive.m cause exception");
    NSLog(@"%@", [exception name]);
    NSLog(@"%@", [exception userInfo]);
  }
}// end - (void)connectionDidFinishLoading:(NSURLConnection *)con


- (void) abort
{
	if(connection != nil)
  {
    [connection cancel];
    [connection release];
    connection = nil;
  }
  
  if(rssData != nil)
  {
    [rssData release];
    rssData = nil;
  }
}// end - (void) abort

#pragma mark -
#pragma mark internal
- (void) updateStatusIcon
{
  if ([[activePrograms allKeys] count] > 0)
  {
    NSImage *active = [NSImage imageNamed:@"SBIconHaveProg"];
    [statusIcon setImage:active];
    [statusIcon setTitle:[NSString stringWithFormat:@"%ld", [[activePrograms allKeys] count]]];
  }
  else
  {
    NSImage *active = [NSImage imageNamed:@"SBIconNoProg"];
    [statusIcon setImage:active];
    [statusIcon setTitle:@""];
  }// end if
}// end - (void) updateStatusIcon

- (void) openURL:(NSURL *)url
{
  if ((broadcasting == NO) || ((isPremium == YES) && ([[NSUserDefaults standardUserDefaults] boolForKey:DoNotOpenWhenBroadcasting] == NO)))
  {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws openURL:url];
  }// end if
}// end - (void) openURL:(NSURL *)url

- (void) foundNewLive:(NSXMLNode *)node
{
  NicoLiveProgram *newLive = [[[NicoLiveProgram alloc] initWithStreaminfo:node] autorelease];
  if ([activePrograms valueForKey:[newLive liveNo]] == nil)
  {		// guard for double notify
    [activePrograms setValue:newLive forKey:[newLive liveNo]];
    [self notifyNewProgram:newLive];
    [self updateStatusIcon];
  }// end if
}// end - (void) foundNewLive:(NSXMLNode *)node

- (void) foundNewLiveRSS:(NSXMLNode *)node
{
  NicoLiveProgram *newLive = [[[NicoLiveProgram alloc] initWithRSS:node] autorelease];
  if ([activePrograms valueForKey:[newLive liveNo]] == nil)
  {		// guard for double notify
    [activePrograms setValue:newLive forKey:[newLive liveNo]];
    [self notifyNewProgram:newLive];
    [self updateStatusIcon];
  }
}// end - (void) foundNewLive:(NSXMLNode *)node

- (void) notifyNewProgram:(NicoLiveProgram *)live
{
    // growling
  [self newLive:[live title] description:[live description] withImage:[live thumbnail] url:[[live liveURL] absoluteString]];
  
		// make menu item
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(openProgram:) keyEquivalent:@""];
	[item setRepresentedObject:[live liveURL]];
  [live setMenuItem:item]; 
  [item setImage:[live menuImage]];
  [programMenu addItem:item];
}// end - (void) notifyNewProgram:(NicoLiveProgram *)live

- (void) foundNewLiveInSocket:(NSXMLNode *)node
{
  NicoLiveProgram *newLive = [[[NicoLiveProgram alloc] initWithStreaminfo:node] autorelease];
  if ([activePrograms valueForKey:[newLive liveNo]] == nil)
  {		// guard for double notify
    [activePrograms setValue:newLive forKey:[newLive liveNo]];
    [self notifyNewProgram:newLive];
    [self updateStatusIcon];
  }
}// end - (void) foundNewLive:(NSXMLNode *)node

- (void) foundNewLiveInRSS:(NSXMLNode *)node
{
  NicoLiveProgram *newLive = [[[NicoLiveProgram alloc] initWithRSS:node] autorelease];
  if ([activePrograms valueForKey:[newLive liveNo]] == nil)
  {		// guard for double notify
    [activePrograms setValue:newLive forKey:[newLive liveNo]];
    [self notifyNewProgram:newLive];
    [self updateStatusIcon];
  }
}// end - (void) foundNewLive:(NSXMLNode *)node

#pragma mark notification
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)program 
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqual:@"liveAlive"])
  {
    [self stopFMLE];
    broadcasting = NO;
    [program removeObserver:self forKeyPath:@"liveAlive"];
  }// end if
}// end - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)program change:(NSDictionary *)change context:(void *)context

#pragma mark Other application collaboration
- (void) startFMLE:(NSString *)live
{
  NSDistantObject *fmle = [NSConnection rootProxyForConnectionWithRegisteredName:FMELauncher host:@""];
  [fmle startFMLE:live];
}// end - (void) startFMLE:(NSString *)live

- (void) stopFMLE
{
  NSDistantObject *fmle = [NSConnection rootProxyForConnectionWithRegisteredName:FMELauncher host:@""];
  [fmle stopFMLE];
}// end - (void) stopFMLE

#pragma mark -
#pragma mark timer
- (void) timerIconUpdate
{
  NSImage *icon;
  if (iconTimerStatus == YES)
  {
    icon = [NSImage imageNamed:@"SBIconRot1"];
    [statusIcon setImage:icon];
    iconTimerStatus = NO;
  }
  else
  {
    icon = [NSImage imageNamed:@"SBIconRot2"];
    [statusIcon setImage:icon];
    iconTimerStatus = YES;
  }
}// end - (void) timerIconUpdate

- (BOOL) checkStreamInfo:(NSString *)live
{
  NSError *err;
  NSString *urlStr = [NSString stringWithFormat:StreamInforAPIURL, live];
  NSData *xmlData = [[http httpData:[NSURL URLWithString:urlStr]] autorelease];
  NSXMLDocument *xml = [[[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&err] autorelease];
  NSXMLElement *root = [xml rootElement];
  NSXMLNode *status = [root attributeForName:@"status"];
  [xml release];
  
  if ([[status stringValue] isEqualToString:@"ok"] == YES)
    return YES;
  else
    return NO;
}// - (BOOL) checkStreamInfo:(NSString *)live

#pragma mark -
#pragma mark threading
- (void) processProgramInThread
{
	NSAutoreleasePool* pool;
	pool = [[NSAutoreleasePool alloc] init];
  NSString *line;
  NSData *dataline;
	NSXMLParser *parser;
	NSError *err;
	BOOL success;
  
  while (YES) {
    [NSThread sleepForTimeInterval:0.5];
		if ([recieveQueue count] == 0)
			continue;
    
		do	// recieveQueue is not empty let us do
		{		// get one line from comment queue
      line = [recieveQueue objectAtIndex:0];
      
      dataline = [line dataUsingEncoding:NSUTF8StringEncoding];
      parser = [[[NSXMLParser alloc] initWithData:dataline] autorelease];
      [parser setDelegate:self];
      [parser setShouldProcessNamespaces:NO];
      [parser setShouldReportNamespacePrefixes:NO];
      [parser setShouldResolveExternalEntities:NO];
      success = [parser parse];
      if (success != YES)
        err = [parser parserError];
      if (success || ([err code] == NSXMLParserPrematureDocumentEndError))
      {
          // raise something;
      }
      [recieveQueue removeObject:line];
    } while ([recieveQueue count] > 0);
  }// end while YES
  
	[pool drain];
	[NSThread exit];
}// end - (void) processProgramInThread

#pragma mark -
#pragma mark XMLParsing
- (void) parserDidStartDocument:(NSXMLParser *) parser
{
    //	NSLog(@"parserDidStartDocument : NicoLiveDocumentParser.m");
}// end - (void) parserDidStartDocument:(NSXMLParser *) parser

- (void) parserDidEndDocument:(NSXMLParser *) parser
{
    //	NSLog(@"parserDidEndDocument : NicoLiveDocumentParser.m");
}// end - (void) parserDidEndDocument:(NSXMLParser *) parser

- (void)parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI
 qualifiedName:(NSString *) qualifiedName
		attributes:(NSDictionary *) attributeDict
{
}// end - (void)parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *) attributeDict

- (void)parser:(NSXMLParser *) parser foundCharacters:(NSString *) string
{
  NSString *progInfo = [NSString stringWithFormat:@"lv%@", string];
  NSArray *program = [[progInfo componentsSeparatedByString:@","] autorelease];
  if ([program count] == 3)
  {		// check program need notify
    NSNumber *isAutoOpen;
    BOOL needNotify = NO;
    BOOL autoOpen = NO;
    for (NSString *info in program)
    {		// check to much in my list
      isAutoOpen = [communities objectForKey:info];
      if (isAutoOpen != nil)
      {
        autoOpen |= [isAutoOpen boolValue];
      	needNotify = YES;	// need growling
      }
    }// end forach program
    if (needNotify == YES)
    {
      NSError *err;
      NSString *live = [program objectAtIndex:OffsetLiveNo];
      NSString *streamURLStr = [NSString stringWithFormat:StreamInforAPIURL, live];
      NSURL *streamURL = [NSURL URLWithString:streamURLStr];
      NSData *streamData = [[http httpData:streamURL] autorelease];
      @try {
        NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:streamData options:NSXMLDocumentTidyXML error:&err];
        NSXMLElement *root = [xml rootElement];
        [self performSelector:@selector(foundNewLive:) onThread:[NSThread mainThread] withObject:root waitUntilDone:YES];
        [xml release];
          // check start FMLE
        if (([[program objectAtIndex:OffsetUserID] isEqualToString:myUserID] == YES) && ([[NSUserDefaults standardUserDefaults] boolForKey:CollaborateWithFMELauncher] == YES))
        {
          broadcasting = YES;
          [self startFMLE:live];
          NicoLiveProgram *program = [activePrograms objectForKey:live];
          [program addObserver:self forKeyPath:@"liveAlive" options:NSKeyValueObservingOptionNew context:nil];
        }// end if CollaborateWithFMELauncher
        if (autoOpen == YES)
        {
          NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
          if ([ud boolForKey:AutoOpen] == YES)
          {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:ProgramURL, live]];
            [self openURL:url];
          }// if Auto open == YES
        }// end if check auto open
      }
      @catch (NSException *exception) {
        NSLog(@"Notify caused exception");
        NSLog(@"%@", [exception name]);
        NSLog(@"%@", [exception userInfo]);
      }
    }// end if Need Notify
  }// end if string is program information
  [program release];
}// end - (void)parser:(NSXMLParser *) parser foundCharacters:(NSString *) string

- (void)parser:(NSXMLParser *) parser didEndElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI
 qualifiedName:(NSString *) qName
{
}// end - (void)parser:(NSXMLParser *) parser didEndElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName

#pragma mark -
#pragma mark growling
- (void) newLive:(NSString *)title description:(NSString *)desc withImage:(NSImage *)image url:(NSString *)url
{	//	TimeExtendNotification
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
	NSNumber *priority = [NSNumber numberWithInt:2];
  NSNumber *isStickey = [NSNumber numberWithBool:NO];
	[dict setObject:@"Found Live Program" forKey:GROWL_NOTIFICATION_NAME];
	[dict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	[dict setObject:desc forKey:GROWL_NOTIFICATION_DESCRIPTION];
	[dict setObject:image forKey:GROWL_NOTIFICATION_ICON];
	[dict setObject:priority forKey:GROWL_NOTIFICATION_PRIORITY];
  [dict setObject:isStickey forKey:GROWL_NOTIFICATION_STICKY];
  [dict setObject:url forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	
	[GrowlApplicationBridge notifyWithDictionary:dict];
}// end - (void) newLive:(NSString *)title description:(NSString *)desc withImage:(NSImage *)image url:(NSURL *)url

- (void) loginResult:(NSString *)title message:(NSString *)message withImage:(NSImage *)image
{	//	TimeExtendNotification
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
	NSNumber *priority = [NSNumber numberWithInt:2];
  NSNumber *isStickey = [NSNumber numberWithBool:NO];
	[dict setObject:@"Login Result" forKey:GROWL_NOTIFICATION_NAME];
	[dict setObject:message forKey:GROWL_NOTIFICATION_TITLE];
	[dict setObject:title forKey:GROWL_NOTIFICATION_DESCRIPTION];
	[dict setObject:image forKey:GROWL_NOTIFICATION_ICON];
	[dict setObject:priority forKey:GROWL_NOTIFICATION_PRIORITY];
  [dict setObject:isStickey forKey:GROWL_NOTIFICATION_STICKY];
	
	[GrowlApplicationBridge notifyWithDictionary:dict];
}// end - (void) loginResult:(NSString *)title message:(NSString *)message withImage:(NSImage *)image

- (void) growlNotificationWasClicked:(id)clickContext
{
  NSURL *url = [NSURL URLWithString:clickContext];
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  [ws openURL:url];
}// end - (void) growlNotificationWasClicked:(id)clickContext
@end
