//
//  NicoLiveAlertAppDelegate.m
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "NicoLiveAlertAppDelegate.h"
#import "NicoLiveAlertDefinitions.h"
#import "SFKeychain.h"

@interface NicoLiveAlertAppDelegate ()
- (void) installToolBarMenu;
- (void) periodicalCleanup;
@end

@implementation NicoLiveAlertAppDelegate
@synthesize window;

- (id) init
{
  self = [super init];
  if (self != nil)
  {
    nico = [[NicoLive alloc] init];
    NSString *udPath;
    NSDictionary *udDict;
    udPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    udDict = [NSDictionary dictionaryWithContentsOfFile:udPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:udDict];
  }// end if

  return self;
}// end - (id) init

- (void) dealloc
{
  [nico release];
  [super dealloc];
}// end - (void) dealloc

#pragma mark -
#pragma mark delegate
- (void) awakeFromNib
{
  [self installToolBarMenu];
  [nico setProgramMenu:[[menuStatusBar itemWithTag:MenuProgram] submenu]];
}// end - (void) awakeFromNib

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
  	// ControlPanel to be Floating Window
  [controlPanel setLevel:NSFloatType];
    // load watchlist from preference
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSData *data = [ud objectForKey:WatchList];
  NSArray *ary = [NSUnarchiver unarchiveObjectWithData:data];
  [arrayWatchlist addObjects:ary];
  	// read password from KeyChain if exists
  NSString *loginID = [txtboxLoginID stringValue];
  BOOL havePassword;
  NSString *loginPW;
  havePassword = [SFKeychain checkForExistanceOfKeychainItem:ItemName withItemKind:ItemKind forUsername:loginID];
  if (havePassword)
  {
		loginPW = [SFKeychain getPasswordFromKeychainItem:ItemName withItemKind:ItemKind forUsername:loginID];
    [txtboxPassword setStringValue:loginPW];
  }
  else
  {
    [txtboxPassword setStringValue:@""];
  }// end if
  [self loginToNico:self];
  cleaner = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(periodicalCleanup) userInfo:nil repeats:YES];
  [cleaner fire];
}// end - (void) applicationDidFinishLaunching:(NSNotification *)aNotification

- (void) applicationWillTerminate:(NSNotification *)notification
{
  [cleaner invalidate];
  [nico monitorProgramEnd];
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSArray *ary = [arrayWatchlist arrangedObjects];
  NSData *data = [NSArchiver archivedDataWithRootObject:ary];
  [ud setValue:data forKey:WatchList];
}// end - (void) applicationWillTerminate:(NSNotification *)notification

#pragma mark -
#pragma mark action
- (IBAction) loginToNico:(id)sender
{
    // notify Trying login
  [labelLoginStatus setStringValue:LoginProgress];
  	// check loginable & login
  NSString *loginID = [txtboxLoginID stringValue];
  NSString *loginPW = [txtboxPassword stringValue];
  BOOL success;
  if (([loginID isEqualToString:@""] == NO) && ([loginPW isEqualToString:@""] == NO))
    success = [nico login:loginID password:loginPW];
  if (success == YES)
  {		// update keychain
    if ([SFKeychain checkForExistanceOfKeychainItem:ItemName withItemKind:ItemKind forUsername:loginID])
      [SFKeychain modifyKeychainItem:ItemName withItemKind:ItemKind forUsername:loginID withNewPassword:loginPW];
    else
      [SFKeychain addKeychainItem:ItemName withItemKind:ItemKind forUsername:loginID withPassword:loginPW];
      // notify login success
    [labelLoginStatus setStringValue:LoginDone];
    NSImage *img = [NSImage imageNamed:@"NicoLiveAlert"];
    [nico loginResult:@"NicoLiveAlert" message:LoginDone withImage:img];
    [[menuStatusBar itemWithTag:MenuLogin] setTitle:TitleLoginDone];
  }
  else
  {		// notify fail to user
    NSImage *img = [NSImage imageNamed:@"NicoLiveAlert"];
    [nico loginResult:@"NicoLiveAlert" message:LoginFail withImage:img];
    [labelLoginStatus setStringValue:LoginFail];
    [[menuStatusBar itemWithTag:MenuLogin] setTitle:TitleUnLogin];
  }
    // append manual watch list
  [nico addManualWatchList:[arrayWatchlist arrangedObjects]];
    // start fetch program
  [nico startMonitorProgram];
}// end - (IBAction) loginToNico:(id)sender

- (IBAction) addItemToWatchlist:(id)sender
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
  [dict setObject:[txtboxCommunityNo stringValue] forKey:KeyCommunity];
  [dict setObject:[NSNumber numberWithBool:NO] forKey:KeyAutoOpen];
  [dict setObject:[txtboxNote stringValue] forKey:KeyComment];
  [arrayWatchlist addObject:dict];
  [tableWatchList reloadData];
  [nico addSingleWatchList:[txtboxCommunityNo stringValue]];
}// end - (IBAction) addItemToWatchlist:(id)sender

- (IBAction) removeSelectedItem:(id)sender
{
  NSInteger row = [tableWatchList selectedRow];
  if (row == -1)
    return;
  
  NSDictionary *watchDict = [[arrayWatchlist arrangedObjects] objectAtIndex:row];
  NSString *watch = [watchDict objectForKey:KeyCommunity];
  [nico removeSingleWatchList:watch];
  [arrayWatchlist removeObjectAtArrangedObjectIndex:row];
}// end - (IBAction) removeSelectedItem:(id)sender

- (IBAction) checkClicked:(id)sender
{
}// end - (IBAction) checkClicked:(id)sender

- (IBAction) openProgram:(id)sender
{
  NSURL *url = [sender representedObject];
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  [ws openURL:url];
}// end - (IBAction) openProgram:(id)sender

#pragma mark -
#pragma mark internal
- (void) installToolBarMenu
{
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	NSStatusItem *sbItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	[sbItem retain];
  [nico setStatusIcon:sbItem];
  
	NSImage *nicoLiveIcon = [NSImage imageNamed:@"SBIconNoProg"];
  NSImage *nicoLiveAlt = [NSImage imageNamed:@"SBIconProgAlt"];
	[sbItem setTitle:@""];
	[sbItem setImage:nicoLiveIcon];
  [sbItem setAlternateImage:nicoLiveAlt];
	[sbItem setToolTip:@"NicoLiveAlert"];
	[sbItem setHighlightMode:YES];
		// localize
  [[menuStatusBar itemWithTag:MenuProgram] setTitle:TitleProgram];
  [[menuStatusBar itemWithTag:MenuLogin] setTitle:TitleLoginDone];
  [[menuStatusBar itemWithTag:MenuPreference] setTitle:TitlePreference];
  [[menuStatusBar	itemWithTag:MenuQuit] setTitle:TitleQuit];
  [[menuStatusBar itemWithTag:MenuAbout] setTitle:TitleAbout];
  
	[sbItem setMenu:menuStatusBar];
}// end - (void) installToolBarMenu

- (void) periodicalCleanup
{
  [nico rejectEndedProgram];
  [nico startMakeAllRSSAsync];
}
@end
