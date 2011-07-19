//
//  SFKeychain.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SFKeychain : NSObject {
@private
  
}
+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item;
+ (BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;
+ (BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword;
+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;
+ (BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password;
+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;
+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item;
@end
