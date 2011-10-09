//
//  NicoLiveAlertAppDelegate.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NicoLive.h"

@interface NicoLiveAlertAppDelegate : NSObject <NSApplicationDelegate> {
@private
  NSWindow *window;
  	// status bar menu
  IBOutlet NSMenu *menuStatusBar;
    // control panel window
  IBOutlet NSWindow *controlPanel;
  	// Login id & password
  IBOutlet NSTextField *txtboxLoginID;
  IBOutlet NSSecureTextField *txtboxPassword;
  IBOutlet NSTextField *labelLoginStatus;
  IBOutlet NSButton *btnLogin;
    // Community items
  IBOutlet NSArrayController *arrayWatchlist;
  IBOutlet NSTableView *tableWatchList;
  IBOutlet NSTextField *txtboxCommunityNo;
  IBOutlet NSTextField *txtboxNote;
  	//
  IBOutlet NicoLive *nico;
    //
  NSTimer	*cleaner;
}
@property (assign) IBOutlet NSWindow *window;
- (IBAction) loginToNico:(id)sender;
- (IBAction) addItemToWatchlist:(id)sender;
- (IBAction) removeSelectedItem:(id)sender;
- (IBAction) checkClicked:(id)sender;
- (IBAction) openProgram:(id)sender;
@end
