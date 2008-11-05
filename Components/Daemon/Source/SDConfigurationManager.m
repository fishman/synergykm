//
//  SDConfigurationManager.m
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

#import "SDConfigurationManager.h"
#import "SDStatusUpdater.h"

#import "SDConfigurationAgent.h"
#import "SDStaticConfigurationAgent.h"
#import "SDAutomaticConfigurationAgent.h"

NSString* const SDConfigurationException = @"SDConfigurationException";


@interface SDConfigurationManager (private)
- (void) synergydShouldReloadConfiguration:(NSNotification *)notification;
- (void) synergydShouldPostStatusUpdate:(NSNotification *)notification;
- (void) statusUpdate:(NSNotification*)notification;

- (void) reloadConfiguration;

- (void) activate;
- (void) deactivate;
@end

@implementation SDConfigurationManager
+ (void)initialize {
	static BOOL	done = NO;
    if ( !done ) {
		NSDictionary*	defaultStatusMessageDict;
		defaultStatusMessageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"",
			[NSNumber numberWithInt:SDStatusClear],
			NSLocalizedString(@"Unknown",@"daemon status message: unknown Status"),
			[NSNumber numberWithInt:SDStatusInvalid],
			NSLocalizedString(@"Error",@"daemon status message: daemon got an error"),
			[NSNumber numberWithInt:SDStatusError],
			NSLocalizedString(@"Not Running",@"daemon status message: daemon is running but idle"),
			[NSNumber numberWithInt:SDStatusNotRunning],
			NSLocalizedString(@"Idle",@"daemon status message: daemon is running but idle"),
			[NSNumber numberWithInt:SDStatusIdle],
			nil];
		
		NSBundle*	b = [NSBundle mainBundle];
		NSDictionary*	defaultStatusImageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			[b pathForImageResource:@"StatusUnknown"],	[NSNumber numberWithInt:SDStatusInvalid],
			[b pathForImageResource:@"StatusError"],	[NSNumber numberWithInt:SDStatusError],
			[b pathForImageResource:@"StatusIdle"],		[NSNumber numberWithInt:SDStatusIdle],
			nil];

		[[SDStatusUpdater defaultStatusUpdater] setDefaultStatusDictionary:defaultStatusMessageDict statusImageDictionary:defaultStatusImageDict andAlias:kSynergyDaemonAppName];
		done = YES;
    }
}

/*
 * - (id) init
 *
 * Constructer
 *
 */

- (id) init
{
	self = [super init];
	if(self) {		
		// register standard user defaults
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSDictionary *standardDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], SDConfAutomaticKey,
			nil];
		[ud registerDefaults:standardDefaults];
		
		// update status
		SDAddStatusUpdateObserverForObject(@selector(statusUpdate:),self);
		SDUpdateStatusCode(SDStatusClear);
		SDUpdateStatusCode(SDStatusIdle);
		
		// setup synergy notification listeners
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(synergydShouldReloadConfiguration:) name:SDSynergydShouldReloadConfigurationNotification object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(synergydShouldPostStatusUpdate:) name:SDSynergydShouldPostStatusUpdateNotification object:nil];
		
		// read configuration
		[self reloadConfiguration];
	}
	return self;
}

- (void) dealloc {	
	if(configAgent) {
		[configAgent stopWrapper];
		SDRemoveStatusUpdateObserverForObject(configAgent);
		[configAgent release];
		configAgent = nil;
	}

	// remove synergy notification listeners
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SDSynergydShouldReloadConfigurationNotification object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:SDSynergydShouldPostStatusUpdateNotification object:nil];
	
	// send not running status
	SDUpdateStatusCode(SDStatusNotRunning);
	SDRemoveStatusUpdateObserverForObject(self);
	[super dealloc];
}

@end

@implementation SDConfigurationManager (private)
/*
 * - (void) synergydShouldReloadConfiguration:(NSNotification *)notification
 *
 * Reload configuration notification captured.
 *
 */

- (void) synergydShouldReloadConfiguration:(NSNotification *)notification
{	
	[self reloadConfiguration];
}


/*
 * - (void) synergydShouldPostStatusUpdate:(NSNotification *)notification
 *
 * Status update request notification captured.
 *
 */

- (void) synergydShouldPostStatusUpdate:(NSNotification *)notification
{
	if(lastStatusUpdate)
		[[NSDistributedNotificationCenter defaultCenter] postNotification:lastStatusUpdate];
}

- (void)statusUpdate:(NSNotification*)notification {
	if(lastStatusUpdate) [lastStatusUpdate release];
	lastStatusUpdate = [[NSNotification notificationWithName:[[notification name] copy]
													  object:kSynergyDaemonAppName
													userInfo:[[notification userInfo] copy]] retain];

	[[NSDistributedNotificationCenter defaultCenter] postNotification:lastStatusUpdate];
}

/*
 * - (void) reloadConfiguration
 *
 * Reads in UserDefaults and (re-)starts synergy task if necessary.
 *
 */

- (void) reloadConfiguration
{
	static BOOL needsReload = YES;
	
	// read configuration
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud synchronize];
	
	needsReload |= (!configAgent || [configAgent status] <= SDStatusIdle);
	
	// restart, if automatic configuration flag changed
	BOOL newAutomatic = [ud boolForKey:SDConfAutomaticKey];
	needsReload |= (newAutomatic != automatic);
	
	automatic = newAutomatic;
	
	if(needsReload) {
		// delete old agent
		if(configAgent) {
			[configAgent stopWrapper];
			SDRemoveStatusUpdateObserverForObject(configAgent);
			[configAgent release];
			configAgent = nil;
		}
		
		SDUpdateStatusCode(SDStatusClear);
		SDUpdateStatusCode(SDStatusIdle);

		// create new agent
		configAgent = automatic ? [[SDAutomaticConfigurationAgent alloc] init] : [[SDStaticConfigurationAgent alloc] init];
		SDAddStatusUpdateObserverForObject(@selector(statusUpdate:), configAgent);
	}
	
	if(configAgent) {
		// (re)load complete configuration
		NSDictionary* config = [ud dictionaryRepresentation];
		[configAgent loadConfiguration:config forceReload:needsReload];
	}
	
	needsReload = NO;
}

- (void) activate {
	if(configAgent) [configAgent activate];
}

- (void) deactivate {
	if(configAgent) [configAgent deactivate];
}

@end
