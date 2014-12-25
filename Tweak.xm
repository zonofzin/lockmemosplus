#import <SpringBoard/SpringBoard.h> 
#import <notify.h>

#define PreferencesChangedNotification "com.zonofzin.lockmemosplus.prefs"
#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.zonofzin.lockmemosplus.plist"]

static NSDictionary* preferences = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[preferences release];
	CFStringRef appID = CFSTR("com.zonofzin.lockmemosplus");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		NSLog(@"There's been an error getting the key list!");
		return;
	}
	preferences = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!preferences) {
		NSLog(@"There's been an error getting the preferences dictionary!");
	}
	CFRelease(keyList);
}

__attribute__((constructor)) static void LockMemosPlus_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);

	[pool release];
}

static void LockMemosPlusAlert (void) {
	NSMutableString* msg = [[NSMutableString alloc] init];
	int msg_lines = 0;
	
	// Memo list
		
	for (int i=1; i<=4; i++) {
		NSString* key = [NSString stringWithFormat:@"Memo%d",i];
		NSString* line = [preferences objectForKey:key];
		if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]>0) {
			[msg appendString:line];
			[msg appendString:@"\n"];
			msg_lines++;
		}
	}
	
	// Check battery level
	
	UIDevice *dev = [UIDevice currentDevice];     
    [dev setBatteryMonitoringEnabled:YES]; 
    int batLeft = (int)([dev batteryLevel]*100); 
    
    if (batLeft <= [[preferences objectForKey:@"ChargeAlertLevel"] integerValue]) {
    	[msg appendString:[NSString stringWithFormat:@"— Charge is low (%d%%) —\n", batLeft]];
    	msg_lines++;
    }
    
	// Check ringer state
	
	uint64_t state; 
	int token; 
	notify_register_check("com.apple.springboard.ringerstate", &token); 
	notify_get_state(token, &state); 
	notify_cancel(token); 	
	bool muted = (!state);
	
	int ringAlert = [[preferences objectForKey:@"RingerAlertType"] integerValue];
	
	if (muted && (ringAlert==1 || ringAlert==3)) {
		[msg appendString:@"— Ringer is OFF —\n"];
		msg_lines++;
	}
	
	if (!muted && (ringAlert==2 || ringAlert==3)) {
		[msg appendString:@"— Ringer is ON —\n"];
		msg_lines++;
	}
	    
	// Show Alert
	
	if ([msg length]>0) {
		NSString* title_string = nil;
		
		if (([[preferences objectForKey:@"AlertTitleOn"] integerValue]==0 & [preferences objectForKey:@"AlertTitleOn"]!=nil) | (msg_lines>5))
			title_string = [[NSString alloc] initWithString:@""];
		else if (msg_lines>1)
			title_string = [[NSString alloc] initWithString:@"Memos"];
		else
			title_string = [[NSString alloc] initWithString:@"Memo"];
		
	 	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title_string
        	message:msg    
        	delegate:nil 
        	cancelButtonTitle:@"OK" 
        	otherButtonTitles:nil];
   	 	[alert show];
   	 	[alert release];
   	 	
   	 	[title_string release];
	}

	[msg release]; 
}

// iOS >= 7.0

%hook SBLockScreenViewController

-(void)activate
{
	%orig;
	if (([[preferences objectForKey:@"AlertOption"] intValue] ?: 1)==1) LockMemosPlusAlert();
}

- (void)prepareForUIUnlock
{
	%orig;
	if ([[preferences objectForKey:@"AlertOption"] intValue]==2) LockMemosPlusAlert();
}

%end

// iOS < 7.0

%hook SBAwayController

-(void)activate
{
	%orig;
	if (([[preferences objectForKey:@"AlertOption"] intValue] ?: 1)==1) LockMemosPlusAlert();
}

-(void)_sendToDeviceLockOwnerDeviceUnlockSucceeded
{
	%orig;
	if ([[preferences objectForKey:@"AlertOption"] intValue]==2) LockMemosPlusAlert();
}

%end
