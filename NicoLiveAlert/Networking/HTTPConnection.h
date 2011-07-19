//
//  HTTPConnection.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HTTPConnection : NSObject {
@private
  NSMutableDictionary *cookies;
}
- (id) init;
- (NSString *) httpSource:(NSURL *)url;
- (NSData *) httpData:(NSURL *)url;
- (NSURLConnection *) httpDataAsync:(NSURL *)url delegate:(id)target;
- (NSData *) postMessage:(NSString *)message ToURL:(NSURL *)url;
@end
