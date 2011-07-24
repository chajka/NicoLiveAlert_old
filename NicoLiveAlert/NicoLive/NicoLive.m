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
  // Async URL Connection Delegate
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)con;
- (void) abort;
@end

@implementation NicoLive
@synthesize statusIcon, programMenu;
- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


#pragma mark -
#pragma mark public
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
      // check lv#
#ifdef DEBUG
    NSLog(@"checking %@", [node stringValue]);
#endif
    autoOpen = [communities objectForKey:[node stringValue]];
    if (autoOpen != nil)
    {// notify program
      [self foundNewLiveRSS:[node parent]];
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
        [self foundNewLiveRSS:parent];
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
}
@end
