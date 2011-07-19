//
//  NicoLiveProgram.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NicoLiveProgram : NSObject {
@private
  BOOL liveAlive;
  NSDate *startTime;
  NSString *liveNo;
  NSString *title;
  NSString *description;
  NSMenuItem *menuItem;
  NSImage *thumbnail;
  NSImage *menuImage;
  NSImage *buffer;
  NSTimer *timer;
}
@property (readonly) BOOL liveAlive;
@property (readonly) NSString *title;
@property (readonly) NSString *description;
@property (readonly) NSString *liveNo;
@property (assign, readwrite) NSMenuItem *menuItem;
@property (readonly) NSImage *thumbnail;
@property (readonly) NSImage *menuImage;

- (id) init;
- (id) initWithStreaminfo:(NSXMLNode *)node;
- (id) initWithRSS:(NSXMLNode *)node;
- (NSURL *) liveURL;
@end
