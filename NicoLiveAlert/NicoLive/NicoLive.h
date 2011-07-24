//
//  NicoLive.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
#import "SocketConnection.h"
#import	"NicoLiveProgram.h"
#import "Growl.h"


@interface NicoLive : NSObject <GrowlApplicationBridgeDelegate> {
@private
  	// my joined communities storage
  NSMutableDictionary *communities;
  	// program alive checker
  NSMutableDictionary	*activePrograms;
  	// socket pushed data storage
  NSMutableArray *recieveQueue;
  	// message server information
  NSString *serverAddr;
  NSInteger serverPort;
  NSString *serverThread;
  	// httpConnection class
  HTTPConnection *http;
  SocketConnection *sock;
  	// Current All RSS Feed
  NSXMLDocument *rss;
  	// status bar
  NSStatusItem *statusIcon;
  NSMenu *statusMenu;
	NSMenu *programMenu;
  NSTimer *statusIconTimer;
  BOOL iconTimerStatus;
  	// for asyncronus rss retrieve
  BOOL firstTime;
  NSInteger pageCount;
  NSInteger currentPage;
  NSMutableData *rssData;
  NSURLConnection *connection;
  NSMutableArray *AllRSSs;
  NSString *lastTopCache;
  NSString *currentTopCache;
}
@property (assign, readwrite) NSStatusItem *statusIcon;
@property (assign, readwrite) NSMenu *programMenu;
	// constructer
- (id) init;
  // public method
- (BOOL) login:(NSString *)loginID password:(NSString *)password;
- (void) startMonitorProgram;
- (void) monitorProgramEnd;
- (void) addSingleWatchList:(NSString *)watch;
- (void) removeSingleWatchList:(NSString *)watch;
- (void) addManualWatchList:(NSArray *)programs;
- (void) changeAutoOpenStatus:(NSString *)community with:(NSNumber *)isAutoOpen;
- (void) rejectEndedProgram;
  // async url connection for rss search
- (void) startMakeAllRSSAsync;
	// Growling
- (void) newLive:(NSString *)title description:(NSString *)desc withImage:(NSImage *)image url:(NSString *)url;
- (void) loginResult:(NSString *)title message:(NSString *)message withImage:(NSImage *)image;
@end
