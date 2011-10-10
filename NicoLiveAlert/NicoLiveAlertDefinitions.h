//
//  NicoLiveAlertDefinitions.h
//  NicoLiveAlert
//
//  Created by mellanie on 7/20/11.
//  Copyright 2011 n/a. All rights reserved.
//

	// api urls
#define ProgramAPIServerURL	@"http://live.nicovideo.jp/api/getalertinfo"
#define LoginAPIServerURL	@"https://secure.nicovideo.jp/secure/login?site=nicolive_antenna"
#define AlertStatusAPIURL	@"http://live.nicovideo.jp/api/getalertstatus?ticket=%@"
#define StreamInforAPIURL	@"http://live.nicovideo.jp/api/getstreaminfo/%@"
#define EmbedURL	@"http://live.nicovideo.jp/embed/%@"
#define RSSInforURL	@"http://live.nicovideo.jp/recent/rss?%@p=%d"
#define ProgramURL	@"http://live.nicovideo.jp/watch/%@"
	// RSS category
#define	CatTitleCommon	@"一般(その他)"
#define CatTitlePolitics		@"政治"
#define CatTitleAnimal		@"動物"
#define	CatQueryCommon	@"tab=common&"
#define CatTitleCook		@"料理"
#define CatTitlePlay		@"演奏してみた"
#define CatTitleSing		@"歌ってみた"
#define CatTitleDance		@"踊ってみた"
#define CatTitleDraw		@"描いてみた"
#define CatTitleLecture		@"講座"
#define CatQueryTry		@"tab=try&"
#define CatTtileLive	@"ゲーム"
#define	CatQueryLive	@"tab=live&"
#define CatTtileReq		@"動画紹介"
#define	CatQueryReq		@"tab=req&"
#define	CatTitleFace	@"顔出し"
#define	CatQueryFace	@"tab=face&"
#define	CatTitleTotu	@"凸待ち"
#define	CatQueryTotu	@"tab=totu&"
#define	CatTitleR18		@"R18"
#define	CatQueryR18		@"tab=r18&"

	// xPath Querys
#define LoginTicketXPath	@"/nicovideo_user_response/ticket"
#define MyUserIDXPath	@"/getalertstatus/user_id"
#define IsPremiumXPath	@"/getalertstatus/is_premium"
#define MyCommunityXPath	@"/getalertstatus/communities/community_id"
#define ProgramServerXPath	@"/getalertstatus/ms/addr"
#define ProgramPortXPath	@"/getalertstatus/ms/port"
#define ProgramThreadXPath	@"/getalertstatus/ms/thread"
	// getstreaminfo Querys
#define ProgramLiveXPath	@"/getstreaminfo/request_id"
#define ProgramTitleXPath	@"/getstreaminfo/streaminfo/title"
#define ProgramDescXPath	@"/getstreaminfo/streaminfo/description"
#define ProgramCommuXPath	@"/getstreaminfo/communityinfo/default_community"
#define ProgramCommXPath	@"/getstreaminfo/communityinfo/name"
#define ProgramThumXPath	@"/getstreaminfo/communityinfo/thumbnail"
  // RSS Query
#define RSSTotalCountXPath	@"/rss/channel/nicolive:total_count"
#define RSSOneChannelXPath	@"/rss/channel/item"
#define RSSLiveIDXPath		@"/rss/channel/item/guid"
#define ItemLvIDXPath		@"guid"
#define RSSCommunityXPath	@"/rss/channel/item/nicolive:community_id"
#define ItemCommuXPath		@"nicolive:community_id"
#define ItemTitleXPath		@"title"
#define ItemDescXPath		@"description"
#define ItemCategoryXPath	@"category"
#define ItemThumXPath		@"media:thumbnail"


#define ProgramThreadQuery @"<thread thread=\"%@\" version=\"20061206\" res_from=\"-1\"/>\0"
#define CommThmbnailFormat	@"http://icon.nimg.jp/community/%@.jpg"
#define LiveURLFormat	@"http://live.nicovideo.jp/watch/%@"
#define OnAirString	@"(<img src=\"img/embed/img_onair.gif\" alt=\"生放送中\" title=\"生放送中\" class=\"denpa\">)"

	// user default constant
#define UserAccount	@"UserAccount"
#define WatchList	@"WatchList"
#define AutoOpen	@"AutoOpenCheckedLive"
#define CollaborateWithFMELauncher	@"CollaborateWithFMELauncher"
#define DoNotOpenWhenBroadcasting	@"DoNotOpenWhenBroadcasting"

	// resource / dicitonary key constant
#define KeyCommunity	@"community"
#define KeyAutoOpen	@"autoOpen"
#define	KeyComment	@"comment"
#define KeyLiveNo	@"LiveNo"
#define KeyLiveURL	@"LiveURL"
#define KeyLiveTitle	@"LiveTitle"
#define KeyProgDesc	@"ProgDesc"
#define KeyTimer	@"Timer"
#define KeyMenuItem	@"MenuItem"
#define KeyStreamInfoURL @"StreamInfoURL"
#define KeyRSSTab	@"RSSTab"
#define	KeyCheckCount	@"CheckCount"

	// keychain access
#define	ItemName	@"NicoLiveAlert"
#define	ItemKind	@"Application Password"

	// NSConnection other Application definition
#define FMELauncher	@"FMELauncher"

	// Localizable strings
#define LoginProgress	NSLocalizedString(@"LoginProgress", @"")
#define LoginDone	NSLocalizedString(@"LoginDone", @"")
#define LoginFail	NSLocalizedString(@"LoginFail", @"")
	// Localizable menu strings
#define	TitleProgram	NSLocalizedString(@"TitleProgram", @"")
#define	TitleLoginDone	NSLocalizedString(@"TitleLoginDone", @"")
#define	TitleUnLogin	NSLocalizedString(@"TitleUnLogin", @"")
#define TitlePreference	NSLocalizedString(@"TitlePreference", @"")
#define	TitleQuit	NSLocalizedString(@"TitleQuit", @"")
#define	TitleAbout	NSLocalizedString(@"TitleAbout", @"")
	// Program Status
#define	StatusDone	NSLocalizedString(@"ProgramEnd", @"")

#define MenuIconSize	(64.0f)
#define LiveAliveInterval	(60.0)

enum StatusBarMenuItems {
  AutoOpenCheckedLive = 1001,
  MenuProgram,
  MenuLogin,
  MenuPreference,
  MenuQuit,
  MenuAbout
};