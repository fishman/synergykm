//
//  SynergyPane.mm
//  SynergyPane
//
//Copyright (c) 2005, Bertrand Landry-Hetu
// All rights reserved.
//
//Redistribution and use in source and binary forms, with or without modification, 
//are permitted provided that the following conditions are met:
//
//	¥ 	Redistributions of source code must retain the above copyright notice, 
//      this list of conditions and the following disclaimer.
//	¥ 	Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation 
//      and/or other materials provided with the distribution.
//	¥ 	Neither the name of the Bertrand Landry-Hetu nor the names of its 
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

#import "SynergyPane.h"

#import "SPConfigurationManager.h"
#import "SPNewLocationController.h"
#import "SPEditLocationController.h"
#import "SPClientTabController.h"
#import "SPServerTabController.h"
#import "SPProcessInfoAdditions.h"

#import "SPConfigEntry.h"

#import "SDConstants.h"
#import "SKMMenuExtraController.h"
#import "SKMServerController.h"

#include <unistd.h>

@interface SynergyPane (Private)

-(void)updatePopupMenu;
-(void)updateGeneralTab;

-(BOOL)launchSynergydAtLogin;
-(void)setLaunchSynergydAtLogin:(BOOL)flag;

/*
-(BOOL)isSynergydRunning;
-(void)startStopSynergyd:(BOOL)start;
*/

-(void)loadVersionInfo;

-(void)updateApplyButton;

-(void)activeConfigSetChanged:(NSNotification*)notif;

@end

@implementation SynergyPane

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [configManager release];
    [super dealloc];
}


-(void)awakeFromNib
{
    thisBundle = [NSBundle bundleForClass: [self class]];

    configManager = [SPConfigurationManager new];
    
    NSNotificationCenter * defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver: self 
                      selector: @selector(activeConfigSetChanged:)
                          name: ActiveConfigChanged
                        object: nil];

    [defaultCenter addObserver: self 
                      selector: @selector(isDirtyChanged:)
                          name: IsDirtyChanged
                        object: nil];
	/*
    [[NSDistributedNotificationCenter defaultCenter] 
            addObserver: self 
               selector: @selector(statusChanged:)
                   name: SDStatusUpdateNotification
                 object: nil];
	 */
    
    SPOperatingSystemVersion version = [NSProcessInfo operatingSystemVersion];
    
    if ( version < SPTigerVersion)
    {
        [rendezvousBtn setTitle:  NSLocalizedStringFromTableInBundle(@"Enable Rendezvous",nil, thisBundle,@"")];
        [rendezvousBtn setToolTip:  NSLocalizedStringFromTableInBundle(@"Synergy will use Rendezvous to choose which configuration to use.",nil, thisBundle,@"")];
    }
    else
    {
        [rendezvousBtn setTitle:  NSLocalizedStringFromTableInBundle(@"Enable Bonjour",nil, thisBundle,@"")];
        [rendezvousBtn setToolTip:  NSLocalizedStringFromTableInBundle(@"Synergy will use Bonjour to choose which configuration to use.",nil, thisBundle,@"")];
    }
}

#pragma mark - NSPreferencePane override -

- (void)willSelect 
{
    [configManager readPreferencesFromDisk];
	
	[synergyStatus setStringValue: NSLocalizedStringFromTableInBundle(@"Not Running", nil, thisBundle, @"")];
	
    [self updateGeneralTab];
	/*
    BOOL launchSynergydAtLogin = [self launchSynergydAtLogin];

    [self startStopSynergyd: launchSynergydAtLogin];

    [[NSDistributedNotificationCenter defaultCenter] 
        postNotificationName: SDSynergydShouldPostStatusUpdateNotification 
                      object: nil];
	*/
	SKMServerController *s = [SKMServerController sharedInstance];
	[s setDelegate:self];
	[s requestStatusUpdate];
    [self activeConfigSetChanged: nil];
	
}

- (void) mainViewDidLoad
{
    [self loadVersionInfo];
}

#pragma mark - Accessors -

-(SPConfigurationManager *)configManager
{
    return configManager;
}

//-(void)loadDefaultScreenName
//{
//    char name[256];
//    if (gethostname(name, sizeof(name)) != -1) 
//    {
//        [[screennameField cell]
//            setPlaceholderString: [NSString stringWithUTF8String: name]];
//    }
//}

//-(IBAction)screenNameChanged:(id)sender
//{
//    SPConfigEntry * activeConfig = [configManager activeConfig];
//    
//    [activeConfig setScreenName: [sender stringValue]];
//    
//    [self setDirty: YES];
//}

#pragma mark - "General" Tab -

/*
-(void)updateLaunchBtn
{
    BOOL launchSynergydAtLogin = [self launchSynergydAtLogin];
    
    if (launchSynergydAtLogin)
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy Off",nil, thisBundle,@"")];
    else
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy On",nil, thisBundle,@"")];
}
*/

-(void)updateGeneralTab
{
    SPConfigEntry * activeConfig = [configManager activeConfig];
    
    if ([activeConfig isServerConfig])
        [configTypeRadioBtn selectCellWithTag: 1];
    else
        [configTypeRadioBtn selectCellWithTag: 0];

    [self updatePopupMenu];
/*    [self updateLaunchBtn]; */
}

#pragma mark - Actions - 

-(IBAction)launchAtLoginToggled: (id)sender
{
	/*
    BOOL value = ![self launchSynergydAtLogin];

    [self setLaunchSynergydAtLogin: value];

    if (value)
    {
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy Off",nil, thisBundle,@"")];
    }
    else
    {
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy On",nil, thisBundle,@"")];
    }
	 */
	[[SKMServerController sharedInstance] toggle];
}

-(IBAction)rendezvousToggled:(id)sender
{
    [configManager setAutomatic: [sender state] == NSOnState];
    [configManager setDirty: YES];
}

-(IBAction)menuVisibilityToggled:(id)sender
{
//    [configManager setMenuVisible: [sender state] == NSOnState];
//    [configManager setDirty: YES];
	
	if([sender state] == NSOnState) {
		[SKMMenuExtraController loadMenuExtra];
	}
	else {
		[SKMMenuExtraController removeExtra];
	}
}

-(IBAction)openLogFile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile: [SDLogfilePath stringByExpandingTildeInPath]];
}

/*
#pragma mark - Launch support -
-(BOOL)launchSynergydAtLogin
{
	NSUserDefaults * defaults = [[[NSUserDefaults alloc] init] autorelease];
    
    NSString * synergydPath = [thisBundle pathForResource: kSynergyDaemonAppName ofType: @"app"];

	NSDictionary * loginWindowDefaults = [defaults persistentDomainForName:@"loginwindow"];

	NSArray * loginItems = [loginWindowDefaults objectForKey: @"AutoLaunchedApplicationDictionary"];
    
	NSEnumerator * iter = [loginItems objectEnumerator];

	while ( NSDictionary * item = [iter nextObject] ) 
    {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString: synergydPath]) 
        {
            return YES;
		}
	}

    return NO;
}

- (void) setLaunchSynergydAtLogin:(BOOL)flag 
{
	NSUserDefaults * defaults = [[[NSUserDefaults alloc] init] autorelease];
        
    NSString * synergydPath = [thisBundle pathForResource: kSynergyDaemonAppName ofType: @"app"];

	NSMutableDictionary * loginWindowDefaults = [[[defaults persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];

	NSArray * loginItems = [loginWindowDefaults objectForKey: @"AutoLaunchedApplicationDictionary"];
    
	NSMutableArray *mutableLoginItems = [[loginItems mutableCopy] autorelease];

	NSEnumerator * iter = [loginItems objectEnumerator];

	while ( NSDictionary *item = [iter nextObject] ) 
    {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString: synergydPath]) 
        {
			[mutableLoginItems removeObject: item];
		}
	}
	
	if ( flag ) 
    {
		NSMutableDictionary * launchDict = [NSMutableDictionary dictionary];
		[launchDict setObject: [NSNumber numberWithBool: NO] forKey: @"Hide"];
		[launchDict setObject: synergydPath forKey: @"Path"];
		[mutableLoginItems addObject:launchDict];
	}
	
	[loginWindowDefaults setObject:[NSArray arrayWithArray:mutableLoginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
                         
	[defaults setPersistentDomain:[NSDictionary dictionaryWithDictionary: loginWindowDefaults] 
                          forName:@"loginwindow"];
                      
	[defaults synchronize];
    
    [self startStopSynergyd: flag];
}

- (void)startStopSynergyd:(BOOL) start 
{
    NSString * synergydPath = [thisBundle pathForResource: kSynergyDaemonAppName ofType: @"app"];

    //Todo need a way to know if we are already running...

    BOOL isSynergydRunning = [self isSynergydRunning];

    if (start == isSynergydRunning)
    {
        return;
    }

    if (start)
    {
		// We want to launch in background, so we have to resort to Carbon
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = ::FSPathMakeRef((const UInt8 *)[synergydPath fileSystemRepresentation], &appRef, NULL);
		
		if (status == noErr) 
        {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec(&spec, NULL);
		}
		
	} 
    else if (isSynergydRunning)
    {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SDSynergydShouldTerminateNotification object:nil];
	}

}

- (BOOL)isSynergydRunning 
{
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
	
	while (::GetNextProcess(&PSN) == noErr) 
    {
		NSDictionary * infoDict = (NSDictionary *)::ProcessInformationCopyDictionary(&PSN, static_cast<UInt32>(kProcessDictionaryIncludeAllInformationMask));
		
		if ([[infoDict objectForKey: @"CFBundleIdentifier"] isEqualToString: SDBundleIdentifier]) 
        {
			isRunning = YES;
			[infoDict release];
			break;
		}
		[infoDict release];
	}
	
	return isRunning;
}
*/
#pragma mark - version info support - 

-(NSString*)versionInfoForApp:(NSString*)appName
{
    NSString * synergydPath = [thisBundle pathForResource: kSynergyDaemonAppName ofType: @"app"];

    NSBundle * synergydBundle = [NSBundle bundleWithPath: synergydPath];

    NSString * path = [synergydBundle pathForResource: appName ofType: @""];

    NSTask * task = [[[NSTask alloc] init] autorelease];

    [task setLaunchPath: path];
    [task setArguments: [NSArray arrayWithObjects:@"--version", nil]];

    NSPipe *pipe=[[[NSPipe alloc] init] autorelease];
    [task setStandardError:pipe];

    NSFileHandle *handle;
    handle=[pipe fileHandleForReading];

    [task launch];
    
    NSData * data = [handle availableData];

    return [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

}

-(void)loadVersionInfo
{
    [clientVersionInfo setStringValue: 
        [self versionInfoForApp: kClientCommand]];

    [serverVersionInfo setStringValue: 
        [self versionInfoForApp: kServerCommand]];
}


#pragma mark - Configuration Type -

-(IBAction)configurationTypeToggled:(id)sender
{
    SPConfigEntry * activeConfig = [configManager activeConfig];
    [activeConfig setIsServerConfig: ([[sender selectedCell] tag] == 1)];
    [clientTabController configurationTypeChanged];
    [serverTabController configurationTypeChanged];
    
    [configManager setDirty: YES];
}

#pragma mark - Bottom status -

/*
-(void)statusChanged:(NSNotification *) notif
{
    NSString * statusMessage = [[notif userInfo] objectForKey: @"StatusMessage"];
    
    [synergyStatus setStringValue: statusMessage];
}
*/

-(void)updateApplyButton
{
    [applyBtn setEnabled: [configManager isDirty]];
}

-(void)isDirtyChanged:(NSNotification*)notif
{
    [self updateApplyButton];
}

-(IBAction)apply:(id)sender
{
    [[[self mainView] window] makeFirstResponder: nil];

    [configManager savePreferencesToDisk];

    [self updateApplyButton];
}


#pragma mark - popup menu support -

-(void)updatePopupMenu
{
    NSMenuItem * selectedMenu = nil;

    NSMenu * menu = [locationPopup menu];
    [locationPopup removeAllItems];

    NSArray * configEntries = [configManager configEntries];
    
    NSEnumerator * iter = [configEntries objectEnumerator];
    
    int index = 0;
    
    SPConfigEntry * activeConfig = [configManager activeConfig];    
    
    while ( SPConfigEntry * configSet = [iter nextObject])
    {
        NSMenuItem * configSetMenuItem = [[NSMenuItem new] autorelease];
        [configSetMenuItem setTitle: [configSet name]];
        [configSetMenuItem setTag: index];

        if (activeConfig == configSet)
        {
            [configSetMenuItem setState: NSOnState];
            selectedMenu = configSetMenuItem;
        }
        else
            [configSetMenuItem setState: NSOffState];
        
        [menu addItem: configSetMenuItem];
        
        ++index;
    }
    
    if ([configEntries count] > 0)
    {
        [menu addItem: [NSMenuItem separatorItem]];
    }
    
    
    {
        NSMenuItem * newLocationMenuItem = [[NSMenuItem new] autorelease];
            
        NSString * newLocationTitle = NSLocalizedStringFromTableInBundle(@"New Location...",nil, thisBundle,@"");
        
        [newLocationMenuItem setTitle: newLocationTitle];
        [newLocationMenuItem setTag: -1];
        
        [menu addItem: newLocationMenuItem];
    }
    {
        NSMenuItem * editLocationMenuItem = [[NSMenuItem new] autorelease];
            
        NSString * editLocationTitle = NSLocalizedStringFromTableInBundle(@"Edit Locations...",nil, thisBundle,@"");
        
        [editLocationMenuItem setTitle: editLocationTitle];
        [editLocationMenuItem setTag: -2];

        [menu addItem: editLocationMenuItem];
    }
    
    [locationPopup selectItem: selectedMenu];
}

-(void)newLocation
{
    [newLocationController reset];

    [NSApp beginSheet: [newLocationController window]
       modalForWindow: [[self mainView] window]
        modalDelegate: self
       didEndSelector: @selector(onNewLocationSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];

}

- (void)onNewLocationSheetDidEnd: (NSWindow *) sheet
                      returnCode: (int) returnCode 
                     contextInfo: (void*) contextInfo
{
    if (returnCode == NSOKButton)
    {
        [configManager newConfigWithName: [newLocationController newLocationName]];
        [configManager setDirty: YES];
    }

    [sheet orderOut: nil];
    [self updatePopupMenu];
}  

-(void)editLocations
{
    [editLocationsController reset];

    [NSApp beginSheet: [editLocationsController window]
       modalForWindow: [[self mainView] window]
        modalDelegate: self
       didEndSelector: @selector(onEditLocationSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];

}

- (void)onEditLocationSheetDidEnd: (NSWindow *) sheet
                      returnCode: (int) returnCode 
                     contextInfo: (void*) contextInfo
{
    if (returnCode == NSOKButton)
    {
        [configManager setDirty: YES];
    }

    [sheet orderOut: nil];
    [self updatePopupMenu];
}  


-(IBAction)locationPopupChanged:(id)sender
{
    NSMenuItem * menuItem = [sender selectedItem];
    switch ([menuItem tag])
    {
        case -1:
        {
            [self newLocation];
        } break;
        
        case -2:
        {
            [self editLocations];
        } break;

        case -3:
        {
            [self editLocations];
        } break;

        default:
        {
            int index = [menuItem tag];
            SPConfigEntry * newActiveSet = [[configManager configEntries] objectAtIndex: index];
            [configManager setActiveConfig: newActiveSet];
            [configManager setDirty: YES];

        }break;
    }

}

#pragma mark - Menu Item -

-(void)updateMenuItemButton
{
    [menuVisibilityBtn setState: [SKMMenuExtraController isExtraLoaded] ? NSOnState : NSOffState];
}

#pragma mark - logging popup -

static int StringLevelToMenuTag(NSString * level)
{
    if ([level isEqualToString: @"NOTE"])
    {
        return 1;
    }
    else if ([level isEqualToString: @"INFO"])
    {
        return 2;
    }
    else if ([level isEqualToString: @"DEBUG"])
    {
        return 3;
    }
    else if ([level isEqualToString: @"DEBUG1"])
    {
        return 4;
    }
    else if ([level isEqualToString: @"DEBUG2"])
    {
        return 5;
    }
    return 0;
}

static NSString * MenuTagToStringLevel(int tag)
{
    switch( tag )
    {
        case 1:
        {
            return @"NOTE";
        }break;
        
        case 2:
        {
            return @"INFO";
        }break;
        
        case 3:
        {
            return @"DEBUG";
        }break;
        
        case 4:
        {
            return @"DEBUG1";
        }break;
        
        case 5:
        {
            return @"DEBUG2";
        }break;
    }
    
    return nil;
}


-(void)updateLoggingPopupMenu
{
    int tag = StringLevelToMenuTag([configManager debugLevel]);
    [logLevelPopup selectItemAtIndex: [logLevelPopup indexOfItemWithTag: tag]];
}

-(IBAction)loggingLevelPopupChanged:(id)sender
{
    NSMenuItem * menuItem = [sender selectedItem];

    NSString * debugLevel = MenuTagToStringLevel([menuItem tag]);

    if (debugLevel == nil || ![debugLevel isEqualToString: [configManager debugLevel]])
    {
        [configManager setDebugLevel: debugLevel];
        [configManager setDirty: YES];
    }
}

#pragma mark - config changes -

-(void)activeConfigSetChanged:(NSNotification*)notif
{
    [self updateLoggingPopupMenu];
    [self updatePopupMenu];
    [self updateMenuItemButton];
    [rendezvousBtn setState: [configManager isAutomatic] ? NSOnState : NSOffState];
    
    [self updateGeneralTab];
    [clientTabController configurationTypeChanged];
    [serverTabController configurationTypeChanged];
}

- (void) server:(id)srv didChangeStatus:(NSNotification*)aNotification
{
	NSDictionary*	userInfo = [aNotification userInfo];
	
	// button title
	if ([[SKMServerController sharedInstance] isActive])
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy Off",nil, thisBundle,@"")];
    else
        [launchBtn setTitle: NSLocalizedStringFromTableInBundle(@"Turn Synergy On",nil, thisBundle,@"")];

	// status message
	[synergyStatus setStringValue:[userInfo objectForKey:SDStatusUpdateStatusMessageKey]];
}

/*
- (void) serverShouldReloadConfiguration:(id)srv
{
	
}
*/

@end
