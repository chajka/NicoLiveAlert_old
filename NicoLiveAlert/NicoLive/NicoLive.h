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


@interface NicoLive : NSObject {
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
  	// status bar
  NSStatusItem *statusIcon;
  NSMenu *statusMenu;
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
	//
- (id) init;
  //
  //
- (void) startMakeAllRSSAsync;
@end
