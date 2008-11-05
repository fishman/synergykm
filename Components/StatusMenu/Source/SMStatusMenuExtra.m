//
//  SMStatusMenuExtra.m
//  SynergyKM
//
//Copyright (c) 2005, Lorenz Schori <lo@znerol.ch>
// All rights reserved.
//
//Redistribution and use in source and binary forms, with or without modification, 
//are permitted provided that the following conditions are met:
//
//	• 	Redistributions of source code must retain the above copyright notice, 
//      this list of conditions and the following disclaimer.
//	• 	Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation 
//      and/or other materials provided with the distribution.
//	• 	Neither the name of the Lorenz Schori nor the names of its 
//      contributors may be used to endorse or promote products derived from 
//      this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
//"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
//LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
//A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
//OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
//OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
//OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
//USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SMStatusMenuExtra.h"
#import "SKMServerController.h"
#import "SPProcessInfoAdditions.h"
#import "SDConstants.h"

const NSTimeInterval SDDiscoveringImageCycleInterval = 1.0;
const NSTimeInterval SDConnectingImageCycleInterval = 0.2;
NSDictionary*	statusImages;
NSDictionary*	statusUpdateIntervals;

#define SMImageNamed(name)([[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:name]] autorelease])

NSString* const SMOpenPrefPaneScript = \
	@"tell application \"System Preferences\"\n\
		activate\n\
		set visible of preferences window to true\n\
		set current pane to pane \"net.sourceforge.synergy2.synergypane\"\n\
	end tell";

@interface SMStatusMenuExtra (private)
- (void) reloadConfiguration:(id)sender;
- (void) cycleStatusImage:(id)imgs;
@end

@interface NSImage (privateExtensions)
+ (NSImage*)imageNamed:(NSString*)name;
@end

@implementation SMStatusMenuExtra

+ (void) initialize
{
	static BOOL done = NO;
	if(!done) {
		statusImages = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSArray arrayWithObjects: SMImageNamed(@"StatusInvalid"),				SMImageNamed(@"StatusInvalid_P"),nil],
			[NSNumber numberWithInt:SDStatusInvalid],
			[NSArray arrayWithObjects: SMImageNamed(@"StatusError"),					SMImageNamed(@"StatusError_P"),nil],
			[NSNumber numberWithInt:SDStatusError],
			[NSArray arrayWithObjects: SMImageNamed(@"StatusIdle"),					SMImageNamed(@"StatusIdle_P"),nil],
			[NSNumber numberWithInt:SDStatusNotRunning],
			[NSArray arrayWithObjects: SMImageNamed(@"StatusIdle"),					SMImageNamed(@"StatusIdle_P"),nil],
			[NSNumber numberWithInt:SDStatusIdle],
			
			[NSArray arrayWithObjects:
				[NSArray arrayWithObjects: SMImageNamed(@"StatusDiscovering_1"),		SMImageNamed(@"StatusDiscovering_1_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusDiscovering_2"),		SMImageNamed(@"StatusDiscovering_2_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusDiscovering_3"),		SMImageNamed(@"StatusDiscovering_3_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusDiscovering_2"),		SMImageNamed(@"StatusDiscovering_2_P"),nil],
				[NSNumber numberWithDouble: SDDiscoveringImageCycleInterval],nil],
			[NSNumber numberWithInt:SDStatusDiscovering],
			
			[NSArray arrayWithObjects: SMImageNamed(@"StatusDisconnected"),			SMImageNamed(@"StatusDisconnected_P"),nil],
			[NSNumber numberWithInt:SDStatusStarting],
			[NSArray arrayWithObjects: SMImageNamed(@"StatusDisconnected"),			SMImageNamed(@"StatusDisconnected_P"),nil],
			[NSNumber numberWithInt:SDStatusTerminating],
			
			[NSArray arrayWithObjects:
				[NSArray arrayWithObjects: SMImageNamed(@"StatusDisconnected"),		SMImageNamed(@"StatusDisconnected_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusConnecting_1"),		SMImageNamed(@"StatusConnecting_1_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusConnecting_2"),		SMImageNamed(@"StatusConnecting_2_P"),nil],
				[NSArray arrayWithObjects: SMImageNamed(@"StatusConnected"),			SMImageNamed(@"StatusConnected_P"),nil],
				[NSNumber numberWithDouble:SDConnectingImageCycleInterval],nil],
			[NSNumber numberWithInt:SDStatusConnecting],
			
			[NSArray arrayWithObjects: SMImageNamed(@"StatusDisconnected"),			SMImageNamed(@"StatusDisconnected_P"),nil],
			[NSNumber numberWithInt:SDStatusListening],
			
			[NSArray arrayWithObjects: SMImageNamed(@"StatusConnected"),				SMImageNamed(@"StatusConnected_P"),nil],
			[NSNumber numberWithInt:SDStatusConnected],

			[NSArray arrayWithObjects: SMImageNamed(@"StatusWarning"),					SMImageNamed(@"StatusWarning_P"),nil],
			[NSNumber numberWithInt:SDStatusWarning],
			nil];
		done = YES;
	}
}

- (id)initWithBundle:(NSBundle *)bundle
{
    self = [super initWithBundle:bundle];
    if(!self)
        return nil;
	
	
	lastConfig = nil;
	
	//
	// construct menu
	//
	statusMenu = [[NSMenu alloc] initWithTitle:@""];
	
	statusMenuItem = (NSMenuItem*)[statusMenu addItemWithTitle:NSLocalizedString(@"Synergy: Not Running", nil)
														action:NULL keyEquivalent:@""];
	
	enabledMenuItem = (NSMenuItem*)[statusMenu addItemWithTitle:NSLocalizedString(@"Turn Synergy On", nil)
														 action:@selector(toggleEnabled:)
												  keyEquivalent:@""];
	[enabledMenuItem setTarget:self];
	
	[statusMenu addItem:[NSMenuItem separatorItem]];
	
	SPOperatingSystemVersion version = [NSProcessInfo operatingSystemVersion];
	if ( version < SPTigerVersion) {
		automaticMenuItem = (NSMenuItem*)[statusMenu
				addItemWithTitle:NSLocalizedString(@"Enable Rendezvous",nil)
						  action:@selector(toggleAutomatic:)
				   keyEquivalent:@""];
	}
	else {
		automaticMenuItem = (NSMenuItem*)[statusMenu
				addItemWithTitle:NSLocalizedString(@"Enable Bonjour",nil)
						  action:@selector(toggleAutomatic:)
				   keyEquivalent:@""];
	}
	[automaticMenuItem setTarget:self];
	
	openPrefsMenuItem = (NSMenuItem*)[statusMenu
			addItemWithTitle:NSLocalizedString(@"Open Synergy Preferences...",nil)
					  action:@selector(openPreferencesPane:) keyEquivalent:@""];
	[openPrefsMenuItem setTarget:self];
	
	[self reloadConfiguration:self];
	
	// setup server controller
	[[SKMServerController sharedInstance] setDelegate:self];
	[[SKMServerController sharedInstance] requestStatusUpdate];
	
    // we will create and set the MenuExtraView
    //statusView = [[SMStatusMenuView alloc] initWithFrame:
	//					   [[self view] frame] menuExtra:self];
	
	// show idle status on startup
	NSArray*	imgs = [statusImages objectForKey:[NSNumber numberWithInt:SDStatusIdle]];
	[self setImage:[imgs objectAtIndex:0]];
	[self setAlternateImage:[imgs objectAtIndex:1]];
	
    return self;
}

- (void)dealloc
{	
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(cycleStatusImage:) object:lastImages];
    [statusMenu release];
    // [statusView release];
	
    [super dealloc];
}

- (void) reloadConfiguration:(id)sender {
	// set automatic flag
	CFBooleanRef prefAutomatic = CFPreferencesCopyValue ((CFStringRef) SDConfAutomaticKey,
														 (CFStringRef) SDBundleIdentifier,
														 kCFPreferencesCurrentUser,
														 kCFPreferencesAnyHost);
	automatic = prefAutomatic ? CFBooleanGetValue(prefAutomatic) : YES;
	[automaticMenuItem setState:automatic];
	
	if(!configs) {
		configs = [NSMutableSet set];
		[configs retain];
	}
	
	// clear
	NSEnumerator* allConfigs = [configs objectEnumerator];
	id config;
	while(config = [allConfigs nextObject]) {
		[statusMenu removeItem:config];
	}
	[configs removeAllObjects];
	
	// reload locations
	NSDictionary* configSets = (NSDictionary*)CFPreferencesCopyValue ((CFStringRef) SDConfSetsKey,
																	  (CFStringRef) SDBundleIdentifier,
																	  kCFPreferencesCurrentUser,
																	  kCFPreferencesAnyHost);
	NSString*	  activeConfig = (NSString*)CFPreferencesCopyValue ((CFStringRef) SDConfActiveConfigKey,
																	(CFStringRef) SDBundleIdentifier,
																	kCFPreferencesCurrentUser,
																	kCFPreferencesAnyHost);
	
	if(!configSets || [[configSets allKeys] count] < 2)
		return;
	
	NSEnumerator* keys = [configSets keyEnumerator];
	
	int i=2;
	NSMenuItem* sep = [NSMenuItem separatorItem];
	[statusMenu insertItem:sep atIndex:i];
	[configs addObject:sep];
	
	id key;
	while(key = [keys nextObject]) {
		NSMenuItem* item = (NSMenuItem*)[statusMenu insertItemWithTitle:key action:@selector(chooseConfiguration:) keyEquivalent:@"" atIndex:++i];
		[item setTarget:self];
		if([key isEqualToString:activeConfig] && !automatic)
			[item setState:NSOnState];
		
		[configs addObject:item];
	}
}

- (NSMenu *)menu
{
    return statusMenu;
}

- (void) openPreferencesPane:(id)sender {
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:SMOpenPrefPaneScript];
	[as executeAndReturnError:nil];
	[as release];
}

- (void) toggleEnabled:(id)sender {
	[[SKMServerController sharedInstance] toggle];
}

- (void) toggleAutomatic:(id)sender {
	CFBooleanRef prefAutomatic = CFPreferencesCopyValue ((CFStringRef) SDConfAutomaticKey, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	automatic = prefAutomatic ? CFBooleanGetValue(prefAutomatic) : YES;
	
	CFBooleanRef setAuto;
	if(!automatic) {
		setAuto = kCFBooleanTrue;
		CFPreferencesSetValue((CFStringRef) SDConfEnabledKey, kCFBooleanTrue, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	} else {
		setAuto = kCFBooleanFalse;
	}
	
	CFPreferencesSetValue((CFStringRef) SDConfAutomaticKey, setAuto, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	
	[[SKMServerController sharedInstance] requestConfigurationReload];
}

- (void) chooseConfiguration:(id)sender {
	if(![sender isKindOfClass:[NSMenuItem class]])
		return;
	
	// write config
	CFPreferencesSetValue((CFStringRef) SDConfActiveConfigKey, (CFStringRef) [sender title], (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	[[SKMServerController sharedInstance] requestConfigurationReload];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem {
	if([menuItem isEqualTo:openPrefsMenuItem] || 
	   [menuItem isEqualTo:enabledMenuItem] || 
	   [menuItem isEqualTo:automaticMenuItem] ||
	   ([configs containsObject:menuItem]) && !automatic) {
		return YES;
	}
	return NO;
}

- (void)cycleStatusImage:(id)imgs {
	if(++lastImagePos > [imgs count] - 2) lastImagePos = 0;
	
	[self setImage:[[imgs objectAtIndex:lastImagePos] objectAtIndex:0]];
	[self setAlternateImage:[[imgs objectAtIndex:lastImagePos] objectAtIndex:1]];
	
	lastImages = imgs;
	[self performSelector:@selector(cycleStatusImage:) withObject:imgs afterDelay:[[imgs lastObject] doubleValue]];
}
@end

@implementation SMStatusMenuExtra (SKMServerControllerDelegate)
- (void) server:(id)srv didChangeStatus:(NSNotification*)aNotification
{		
	NSDictionary	*userInfo = [aNotification userInfo];
	
	// enable / disable menu item
	if([srv isActive]) {
		[enabledMenuItem setTitle:NSLocalizedString(@"Turn Synergy Off", nil)];
	} else {
		[enabledMenuItem setTitle:NSLocalizedString(@"Turn Synergy On", nil)];
	}
	
	// update locationas menu for automatic configuration
	id newCurrentConfig = [userInfo objectForKey: SDStatusUpdateCurrentConfigurationKey];
	if(newCurrentConfig && ![newCurrentConfig isEqualToString:lastConfig]) {
		[configs makeObjectsPerformSelector:@selector(setState:) withObject:NSOffState];
		NSEnumerator* allConfigs = [configs objectEnumerator];
		id config;
		while(config = [allConfigs nextObject]) {
			[config setState:[newCurrentConfig isEqualToString:[config title]]];
			break;
		}
	}
	
	if(lastConfig)
		[lastConfig release];
	lastConfig = [newCurrentConfig retain];
	
	[statusMenuItem setTitle:[NSString stringWithFormat:@"Synergy: %@",[userInfo objectForKey:SDStatusUpdateStatusMessageKey]]];

	// update status image
	id newStatus = [userInfo objectForKey:SDStatusUpdateStatusNumberKey];
	id	imgs = [statusImages objectForKey:newStatus];
	if(imgs) {
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(cycleStatusImage:) object:lastImages];
		
		if([[imgs lastObject] isKindOfClass:[NSNumber class]]) {
			lastImagePos = -1;
			[self performSelector:@selector(cycleStatusImage:) withObject:imgs afterDelay:0.0];
		} else {
			[self setImage:[imgs objectAtIndex:0]];
			[self setAlternateImage:[imgs objectAtIndex:1]];
		}
	}
}

- (void) serverShouldReloadConfiguration:(id)srv
{
	[self reloadConfiguration:srv];
}
@end
