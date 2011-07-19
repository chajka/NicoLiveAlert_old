//
//  HTTPConnection.m
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "HTTPConnection.h"


@implementation HTTPConnection

- (id) init
{
	self = [super init];
	if (self != nil)
	{
    cookies = [[NSMutableDictionary alloc] initWithCapacity:512];
	}
	return self;
}// end - (id) init

- (void) dealloc
{
  [cookies release];
	[super dealloc];
}// - (void) dealloc

#pragma mark -
#pragma mark client
  // define sync transfer method
- (NSString *) httpSource:(NSURL *)url
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
  [request setHTTPShouldHandleCookies:NO];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *receivedData = [NSURLConnection sendSynchronousRequest : request
																							 returningResponse : &response error : &error];
	
    // error
	NSString *error_str = [error localizedDescription];
	if (0<[error_str length]) {
		NSLog(@"Error");
		return NULL;
	}
	
    // response
	NSString *data_str = nil;
	NSArray *encodings = [NSArray arrayWithObjects:
												[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding],	
												[NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding],	
												[NSNumber numberWithUnsignedInt:NSJapaneseEUCStringEncoding],
												[NSNumber numberWithUnsignedInt:NSISO2022JPStringEncoding],
												[NSNumber numberWithUnsignedInt:NSUnicodeStringEncoding],
												[NSNumber numberWithUnsignedInt:NSASCIIStringEncoding],
												nil];
	for (NSNumber *enc in encodings)
	{
		data_str = [[[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]] autorelease];
		if (data_str!=nil) {
			break;
		}
	}
	
	return data_str;
}// end - (NSString *) httpSource:(NSURL *)url

- (NSData *) httpData:(NSURL *)url
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
  [request setHTTPShouldHandleCookies:NO];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *receivedData = [NSURLConnection sendSynchronousRequest : request
                                               returningResponse : &response error : &error];
	
    // error
	NSString *error_str = [error localizedDescription];
	if (0<[error_str length]) {
		NSLog(@"Error");
		return NULL;
	}
	
	return receivedData;
}// end - (NSData *) httpData:(NSURL *)url

- (NSURLConnection *) httpDataAsync:(NSURL *)url delegate:(id)target
{
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
  NSURLConnection *connection;
  if (target == nil)
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  else
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:target];
  
  return connection;
}// end - (void) httpDataAsync (NSURL *)url delegate:(id)target

- (NSData *) postMessage:(NSString *)message ToURL:(NSURL *)url
{
	NSMutableURLRequest* urlRequest = [[NSMutableURLRequest alloc]initWithURL:url];
  [urlRequest setHTTPShouldHandleCookies:NO];
	NSData *httpBody = [message dataUsingEncoding:NSUTF8StringEncoding];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:httpBody];
	NSHTTPURLResponse *response;
	NSError* error = nil;
	NSData* result = [NSURLConnection sendSynchronousRequest:urlRequest
																				 returningResponse:&response
																										 error:&error];
	[urlRequest release];
	if (error)
	{
		NSLog(@"error = %@", error);
    NSLog(@"Result = %@", result);
		return NULL;
	}
	else
		return result;
}// end - (BOOL) postMessageToURL:(NSString *)message url:(NSURL *)url

@end