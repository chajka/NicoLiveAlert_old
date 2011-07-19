//
//  SocketConnection.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SocketConnection : NSObject {
@private
		// Buffer
	NSMutableData *dataBuffer;
		// Queue
	NSMutableArray *sendQueue;
	NSMutableArray *recieveQueue;
	BOOL sendIsBusy;
		// Stream
	NSInputStream *iStream;
	NSOutputStream *oStream;
}
- (id) init;
- (id) initWithRecieveQueue:(NSMutableArray *)rcvQueue;
	// public method
- (void) setRecieveQueue:(NSMutableArray *)rcvQueue;
- (void) openServer:(NSString *)server port:(NSInteger)port;
- (void) closeServer;
- (void) sendText:(NSString *)text;
@end
