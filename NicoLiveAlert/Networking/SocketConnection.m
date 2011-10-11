//
//  SocketConnection.m
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "SocketConnection.h"


@interface SocketConnection ()
- (void) openStreams;
- (void) closeStreams;
- (void) handleRecievedString:(NSString *)rcv;
- (void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent;
@end

@implementation SocketConnection
#pragma mark construct / destruct
- (id) init
{
	self = [super init];
	if (self != nil) {
		iStream = nil;
		oStream = nil;
		sendIsBusy = YES;
		sendQueue = [[NSMutableArray alloc] initWithCapacity:16];
		recieveQueue = [[NSMutableArray alloc] initWithCapacity:256];
	}
	return self;
}// end - (id) init

- (id) initWithRecieveQueue:(NSMutableArray *)rcvQueue
{
	self = [super init];
	if (self != nil) {
		iStream = nil;
		oStream = nil;
		sendIsBusy = YES;
		sendQueue = [[NSMutableArray alloc] initWithCapacity:16];
		recieveQueue = [rcvQueue retain];
	}
	return self;
}// end - (id) initWithRecieveQueue:(NSMutableArray *)rcvQueue

- (void) dealloc
{
	[sendQueue release];
	[recieveQueue release];
	[super dealloc];
}// end - (void) dealloc

#pragma mark -
#pragma mark public method
- (void) setRecieveQueue:(NSMutableArray *)rcvQueue
{
  [recieveQueue autorelease];
  recieveQueue = [rcvQueue retain];
}// end - (void) setRecieveQueue:(NSMutableArray *)rcvQueue

- (void) openServer:(NSString *)server port:(NSInteger)port
{
	NSHost *host = [NSHost hostWithName:server];
	[NSStream getStreamsToHost:host port:port inputStream:&iStream outputStream:&oStream];
	[self openStreams];
}// end - (void) openServer:(NSString *)server port:(NSInteger)port

- (void) closeServer
{
  [self closeStreams];
}// end - (void) closeServer

- (void)sendText:(NSString *)text
{
  if (sendIsBusy == YES)
	{
		[sendQueue addObject:text];
	}
	else
	{
		NSData * dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
		NSUInteger remainingToWrite = [dataToSend length];
		void * marker = (void *)[dataToSend bytes];
		while (0 < remainingToWrite) {
			NSUInteger actuallyWritten = 0;
			actuallyWritten = [oStream write:marker maxLength:remainingToWrite];
			remainingToWrite -= actuallyWritten;
			marker += actuallyWritten;
		}// end while textbuffer is not empty
		sendIsBusy = YES;
	}
	
}// end - (void)sendText:(NSString *)text

#pragma mark -
#pragma mark internal
- (void) openStreams
{
	[iStream retain];
	[iStream setDelegate:self];
	[iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[iStream open];
	[oStream retain];
	[oStream setDelegate:self];
	[oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[oStream open];
}// - (void) openStreams

- (void)closeStreams
{
	[iStream close];
	[iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[iStream setDelegate:nil];
	[iStream release];
	iStream = nil;
	[oStream close];
	[oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[oStream setDelegate:nil];
	[oStream release];
	oStream = nil;
}// end - (void)closeStreams

- (void) handleRecievedString:(NSString *)rcv
{
	[recieveQueue addObject:rcv];
}// end - (void)handleRecievedString:(NSString *)rcv

#pragma mark handle event
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
	switch(streamEvent) {
		case NSStreamEventHasBytesAvailable:
			if (aStream == iStream)
			{
				uint8_t oneByte;
				NSUInteger actuallyRead = 0;
				iStream = (NSInputStream *)aStream;
				if (!dataBuffer) {
					dataBuffer = [[NSMutableData alloc] initWithCapacity:2048];
				}
				actuallyRead = [iStream read:&oneByte maxLength:1];
				if (actuallyRead == 1) {
					[dataBuffer appendBytes:&oneByte length:1];
				}
				if (oneByte == '\0') {
            // We've got the carriage return at the end of the echo. Let's set the string.
					NSString * string = [[NSString alloc] initWithData:dataBuffer encoding:NSUTF8StringEncoding] ;
					[recieveQueue addObject:string];
					[string release];
					[dataBuffer release];
					dataBuffer = nil;
				}
			}
			break;
		case NSStreamEventEndEncountered:
        //			NSLog(@"NSStreamEventEndEncountered");
			[self closeStreams];
			break;
		case NSStreamEventHasSpaceAvailable:
        //				NSLog(@"NSStreamEventHasSpaceAvailable, count : %d", [sendQueue count]);
			if ((aStream == oStream) && [sendQueue count] > 0)
			{
				sendIsBusy = NO;
				if ([sendQueue count] > 0)
				{
					NSString *str = [[sendQueue objectAtIndex:0] retain];
					[self sendText:str];
          @try {
            [sendQueue removeObject:str];
          }
          @catch (NSException *exception) {
            NSLog(@"stream:handleEvent cased exception");
            NSLog(@"%@", [exception name]);
            NSLog(@"%@", [exception userInfo]);
          }
					[str release];
				} // end while
			}
			else {
				sendIsBusy = NO;
			}// end if
			break;
		case NSStreamEventErrorOccurred:
        //			NSLog(@"EventErrorOccurred");
			[self closeStreams];
			break;
		case NSStreamEventOpenCompleted:
			break;
		case NSStreamEventNone:
			break;
		default:
			break;
	}// end switch stream event
}// end - (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent

@end
