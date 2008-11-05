//
//  SDSynergyServerWrapper.m
//  synergyd
//
//Copyright (c) 2005, Lorenz Schori <lo@znerol.ch>
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
//	¥ 	Neither the name of the Lorenz Schori nor the names of its 
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

#import "SDSynergyServerWrapper.h"
#import "LCSStdIOTaskWrapper.h"
#import "SDStatusUpdater.h"

NSDictionary*	SDServerStatusMessageDict;

@interface SDSynergyServerWrapper (private)
- (void) checkAndWarnForBlockedPort:(int)port;
@end

@implementation SDSynergyServerWrapper

+ (void)initialize {
	static BOOL	done = NO;
    if ( !done ) {
		[[SDStatusUpdater defaultStatusUpdater] setStatusDictionary:nil
											  statusImageDictionary:nil
														   andAlias:kServerCommand
														   forClass:[self class]];
		done = YES;
    }
}

- (void) dealloc
{
	[self stopWrapper];
	
	[serverConfig release];
	[screenName release];
	[address release];
	[clients release];

	if(taskWrapper)
		[taskWrapper release];
	
	[super dealloc];
}

- (void) loadConfiguration:(NSDictionary*)config
{
	if(!config) {
		[NSException exceptionWithName:NSInvalidArgumentException reason:@"" userInfo:nil];
		return;
	}
	
	serverConfig = [config objectForKey:SDConfServerConfigKey];
	if(!serverConfig || ![serverConfig isKindOfClass:[NSDictionary class]]) {
		[NSException exceptionWithName:SDSynergydInvalidConfigurationException reason:@"\"ServerConfig\" missing in configuration set" userInfo:nil];
		return;
	}
	[serverConfig retain];
	
	clients = [[NSMutableSet alloc] init];

	address = [[config objectForKey:SDConfListenAddressKey] retain];
	debugLevel = [[config objectForKey:SDConfDebugLevelKey] retain];
	screenName = [config objectForKey:SDConfScreenNameKey];
	if (!screenName) {
		screenName = (NSString*) SCDynamicStoreCopyLocalHostName(NULL);
	}
	else {
		[screenName retain];
	}
}

- (void) startWrapper
{
	if(taskWrapper && [[taskWrapper task] isRunning]) {
		[NSException exceptionWithName:NSInvalidArgumentException reason:@"cannot start alredy active server wrapper." userInfo:nil];
		return;
	}
	
	// send status update
	SDUpdateStatusCode(SDStatusClear);
	SDUpdateStatusCode(status = SDStatusStarting);
	
	// server configuration file
	configFilePath = NSTemporaryDirectory();
	configFilePath = [configFilePath stringByAppendingPathComponent:
		[NSString stringWithFormat:@"synergy-%@.conf",(NSString*)CFUUIDCreateString (NULL, CFUUIDCreate (NULL))]];
	
	if(!SDWriteSynergyConfig(serverConfig, configFilePath)) {
		SDUpdateStatusCodeWithMessage(SDStatusError, @"Could not write temporary synergy.conf");
		[NSException exceptionWithName:SDSynergydInvalidConfigurationException reason:@"Could not write temporary synergy.conf" userInfo:nil];
		return;
	}
	[configFilePath retain];
	
	//
	// check for firewall
	//
	int port = 24800;
	if(address) {
		NSRange	r;
		r = [address rangeOfString:@":"];
		if(r.location != NSNotFound) {
			port = [[address substringFromIndex:r.location] intValue];
		}
	}
	[self checkAndWarnForBlockedPort:port];
	
	// setup task
	NSTask*		task = [[NSTask alloc] init];
	
	// set launch path
	[task setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kServerCommand]];
		
	// set arguments
//	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-f",@"-1",nil];
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-f",nil];
	
	[args addObject:@"--config"];
	[args addObject:configFilePath];
	
	if(address && [address length]) {
		[args addObject:@"--address"];
		[args addObject:address];
	}
	
	if(screenName && [screenName length]) {
		[args addObject:@"--name"];
		[args addObject:screenName];
	}
	
	if(debugLevel && [debugLevel length]) {
		[args addObject:@"--debug"];
		[args addObject:debugLevel];
	}

	[task setArguments:(NSArray *)args];
	
	// setup taskwrapper
	taskWrapper = [[LCSStdIOTaskWrapper alloc] initWithTask:task];
	[task release];
	[taskWrapper setDelegate:self];
	
	[taskWrapper launch];	
}

- (void) stopWrapper
{
	if([taskWrapper isValid]) {
		[taskWrapper terminate];
	}
	
	if(configFilePath) {
		NSFileManager*	fm = [NSFileManager defaultManager];
		if([fm isDeletableFileAtPath:configFilePath]) {
			[fm removeFileAtPath:configFilePath handler:NULL];
		}
		[configFilePath release];
		configFilePath = nil;
	}
	
	if(clients) {
		[clients release];
		clients = nil;
	}
	// [[SDStatusUpdater defaultStatusUpdater] postStatusUpdateCode:SDStatusIdle message:nil sender:self];
}

@end

@implementation SDSynergyServerWrapper (SDStatusUpdaterAddInfo)
- (NSDictionary*)additionalStatusUpdateInfo
{
	return clients ? [NSDictionary dictionaryWithObject:[clients allObjects] forKey:SDStatusUpdateClientsKey] : nil;
}
@end

@implementation SDSynergyServerWrapper (LCSStdIOTaskWrapperDelegate)
- (void) task:(id)sender didReceiveErrorLine:(NSString*)line
{
	BOOL		needsStatusUpdate = NO;
	
	// log to stdout
	NSLog(line);
	
	NSScanner*	scanner = [NSScanner scannerWithString:line];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	// scan loglevel
	NSString* logLevel;
	[scanner scanUpToString:@": " intoString:&logLevel];
	[scanner scanString:@": " intoString:NULL];
#ifndef NDEBUG
	// (don't) scan filepath
	[scanner scanUpToString:@": " intoString:NULL];
	[scanner scanString:@": " intoString:NULL];
#endif
	// scan message
	NSString* logMessage = [[scanner string] substringFromIndex:[scanner scanLocation]];
	
	if(!logLevel || !logMessage)
		return;
	
	// perform status updates
	int	newStatus = SDStatusInvalid;
	NSString*	message = nil;
	
	if ([logLevel isEqualToString:@"ERROR"] ||
		[logLevel isEqualToString:@"FATAL"]) {
		// handle error messages
		message = logMessage;
		newStatus = SDStatusError;
		needsStatusUpdate |= YES;
		// terminate task afterwards!
		[self performSelector:@selector(stopWrapper) withObject:nil afterDelay:0];
	} else if([logLevel isEqualToString:@"WARNING"]) {
		// handle warning messages
		message = logMessage;
		newStatus = SDStatusWarning;
		needsStatusUpdate |= YES;
	} else if([logLevel isEqualToString:@"NOTE"]) {
		NSRange	r = {0,0};
		// handle server messages
		if([logMessage isEqualTo:@"started server"]) {
			newStatus = SDStatusListening;
			needsStatusUpdate |= YES;
		} else if([logMessage isEqualTo:@"stopped server"]) {
			/* don't capture this
			newStatus = SDStatusIdle;
			needsStatusUpdate |= YES;
			*/
		} else {
			// scan for 
			// - client "x" has connected
			// - client "x" has disconnected
			int msgOffset = [scanner scanLocation];
			if([scanner scanString:@"client \"" intoString:NULL]) {
				NSString *clientName;
				[scanner scanUpToString:@"\" " intoString:&clientName];
				clientName = [clientName lowercaseString];
				[scanner scanString:@"\" " intoString:NULL];
				
				NSString *operation = [[scanner string] substringFromIndex:[scanner scanLocation]];
				if([operation isEqualToString:@"has connected"]) {
					[clients addObject:[NSString stringWithString:clientName]];
					newStatus = SDStatusConnected;
					needsStatusUpdate |= YES;
				} else if([operation isEqualToString:@"has disconnected"]) {
					[clients removeObject:[NSString stringWithString:clientName]];
					if([clients count] == 0) {
						newStatus = SDStatusListening;
						needsStatusUpdate |= YES;
					}
				}
			}
		}
	} // end [logLevel isEqualToString:@"NOTE"]
	
	if(needsStatusUpdate) {
		SDUpdateStatusCodeWithMessage(newStatus, message);
		status = newStatus;
	}
	
}

- (void) checkAndWarnForBlockedPort:(int)port
{
	// check in apples firewall configuration
	CFBooleanRef state = 
		CFPreferencesCopyValue(CFSTR("state"),CFSTR("com.apple.sharing.firewall"),
							   kCFPreferencesAnyUser,kCFPreferencesCurrentHost);
	if(state && CFBooleanGetValue(state)) {
		NSArray* allports = (NSArray*)
			CFPreferencesCopyValue(CFSTR("allports"),CFSTR("com.apple.sharing.firewall"),
								   kCFPreferencesAnyUser,kCFPreferencesCurrentHost);
		if(allports && ![allports containsObject:[NSString stringWithFormat:@"%d",port]]) {
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			SetFrontProcess(&psn);
			int	resp = NSRunAlertPanel(NSLocalizedString(@"Firewall is blocking Synergy",@"Title of firewall alert"),
									   NSLocalizedString(@"The Personal Firewall is currently blocking port %d. This will prevent Synergy clients to connect to this machine. You can use the Firewall tab of the Sharing system preference panel to open the port.",@"Firewall Warning Message"),
									   NSLocalizedString(@"Open Sharing Prefs",@"Open Sharing Prefs Button"),
									   NSLocalizedString(@"Ignore",@"Ignore Button"),
									   @"", port);
			if(resp == NSOKButton) {
				NSString* const SMOpenSharingPrefPaneScript = \
				@"tell application \"System Preferences\"\n\
					activate\n\
					set visible of preferences window to true\n\
					set current pane to pane \"com.apple.preferences.sharing\"\n\
				end tell";
				
				NSAppleScript *as = [[NSAppleScript alloc] initWithSource:SMOpenSharingPrefPaneScript];
				[as executeAndReturnError:nil];
				[as release];
			}
		}
	}
}
@end
