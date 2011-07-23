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
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSArray *ary = [arrayWatchlist arrangedObjects];
  NSData *data = [NSArchiver archivedDataWithRootObject:ary];
  [ud setValue:data forKey:WatchList];
}// end - (void) applicationWillTerminate:(NSNotification *)notification

#pragma mark -
#pragma mark action
- (IBAction) loginToNico:(id)sender
{
}// end - (IBAction) loginToNico:(id)sender

- (IBAction) addItemToWatchlist:(id)sender
{
}// end - (IBAction) addItemToWatchlist:(id)sender

- (IBAction) removeSelectedItem:(id)sender
{
}// end - (IBAction) removeSelectedItem:(id)sender

- (IBAction) checkClicked:(id)sender
{
}// end - (IBAction) checkClicked:(id)sender

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
