//
//  SKMServerController.m
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

#import "SKMServerController.h"
#import "SDConstants.h"

SKMServerController	*sharedInstance = nil;

@interface SKMServerController (private)
- (void)updateStatus:(NSNotification*)aNotification;
- (void)reloadConfiguration:(NSNotification*)aNotification;

- (void) setLaunchAtLogin:(BOOL)launchAtLogin;
- (NSString*)pathToServer;

- (void)performDelegateSelector:(SEL)sel;
- (void)performDelegateSelector:(SEL)sel withArgument:(id)arg;
@end

@implementation SKMServerController
+ (id) sharedInstance
{
	
	if(!sharedInstance) {
		sharedInstance = [[SKMServerController alloc] init];
	}
	return sharedInstance;
}

- (id) init
{
	self = [super init];
	if(!self) {
		return nil;
	}
	
	
	delegate = nil;
	blockStatusUpdate = NO;
	delayStatusUpdate = NO;
	
	delayedStatusUpdates = [[NSMutableArray alloc] init];
	
	status = SDStatusNotRunning;
	lastStatus = SDStatusInvalid;
	
	// status update notification observer
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(updateStatus:)
															name:SDStatusUpdateNotification
														  object:nil];
	// reload configuration observer
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(reloadConfiguration:)
															name:SDSynergydShouldReloadConfigurationNotification
														  object:nil];
	
	// application termination notification observer
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(applicationTerminated:)
															   name:NSWorkspaceDidTerminateApplicationNotification
															 object:nil];
	return self;
}

- (void) dealloc {	
	// remove queued status updates
	[self undelayStatus];
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(undelayStatus) object:nil];
	
	[delayedStatusUpdates release];
	
	// remove application termination notification observer
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
																  name:NSWorkspaceDidTerminateApplicationNotification
																object:nil];
		
	// remove synergy notification listeners
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:SDSynergydShouldReloadConfigurationNotification
															 object:nil];
	
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:SDSynergydShouldPostStatusUpdateNotification
															 object:nil];
	[super dealloc];
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (id) delegate;
{
	return delegate;
}

- (void) start
{
	// install synergy to autostart login items
	[self setLaunchAtLogin:YES];
	
	// if running check active and requestConfigurationReload
	if([self isRunning]) {
		[self requestConfigurationReload];
	}
	else {
		NSString * synergydPath = [self pathToServer];
		if(!synergydPath) {
			// FIXME. LOGGING?
		}
	
		BOOL res = [[NSWorkspace sharedWorkspace] launchApplication:synergydPath];
		
		ProcessSerialNumber me = {0, kCurrentProcess};
		SetFrontProcess(&me);
		if(!res) {
			// FIXME. LOGGING?
		}
	}
}

- (void) stop
{
	[self setLaunchAtLogin:NO];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SDSynergydShouldTerminateNotification object:nil];
}

- (void) toggle
{
	if([self isRunning] && [self isActive]) {
		[self stop];
	}
	else {
		[self start];
	}
}

- (void) setLaunchAtLogin:(BOOL)launchAtLogin
{
	NSString* synergydPath = [self pathToServer];
	
	NSMutableArray *autoLaunchApps = (NSMutableArray *)
		CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
									 CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"),
															   CFSTR("loginwindow")),
									 kCFPropertyListMutableContainersAndLeaves);
	
	NSEnumerator *appEnumerator = [autoLaunchApps objectEnumerator];
	NSDictionary *item;
	while ( item = [appEnumerator nextObject] ) {
		if ([[[item objectForKey:@"Path"] stringByStandardizingPath] isEqualToString: synergydPath]) {
			break;
		}
	}
	
	BOOL	updatePrefs = NO;
	// if synergyd is not contained, add it to the login items
	if(!item && launchAtLogin) {
		NSDictionary *synergydEntry = [NSDictionary dictionaryWithObjectsAndKeys:
			synergydPath,					@"Path",
			[NSNumber numberWithBool:NO],	@"Hide",
			nil];
		[autoLaunchApps addObject:synergydEntry];
		updatePrefs = YES;
	}
	// if synergyd is contained, remove it from the login items
	else if (item && !launchAtLogin) {
		[autoLaunchApps removeObject:item];
		updatePrefs = YES;
	}
	// update preferences if nessesary
	if(updatePrefs) {
		CFPreferencesSetAppValue(CFSTR("AutoLaunchedApplicationDictionary"),
								 (CFArrayRef)autoLaunchApps,
								 CFSTR("loginwindow"));
		CFPreferencesAppSynchronize(CFSTR("loginwindow"));
	}
	[autoLaunchApps release];
}

- (BOOL) isRunning
{
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
	
	while(GetNextProcess(&PSN) == noErr) {
		NSDictionary * infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if ([[infoDict objectForKey: @"CFBundleIdentifier"] isEqualToString: SDBundleIdentifier]) {
			isRunning = YES;
			[infoDict release];
			break;
		}
		[infoDict release];
	}
	
	return isRunning;
}

- (BOOL) isActive
{
	return status > SDStatusIdle;
}

- (void) requestStatusUpdate
{
	[[NSDistributedNotificationCenter defaultCenter]
		postNotificationName:SDSynergydShouldPostStatusUpdateNotification object:nil];
}

- (void) requestConfigurationReload
{
	[[NSDistributedNotificationCenter defaultCenter]
		postNotificationName:SDSynergydShouldReloadConfigurationNotification object:nil];
}

#pragma mark -

- (void)applicationTerminated:(NSNotification*)aNotification
{
	NSDictionary* app = [aNotification userInfo];
	if([SDBundleIdentifier isEqualToString:[app objectForKey:@"NSApplicationBundleIdentifier"]]) {
		
	}
}

#pragma mark -

- (void)updateStatus:(NSNotification*)aNotification
{
	id statusVal = [[aNotification userInfo] objectForKey:SDStatusUpdateStatusNumberKey];
	if(!statusVal)
		return;
	
	status = [statusVal intValue];
	
	// update status if not blocked
	if(blockStatusUpdate) {
	}
	// queue status items if a warning is active. don't queue warning, error and clear status messages.
	else if(delayStatusUpdate && status != SDStatusWarning && status > SDStatusNotRunning) {
		[delayedStatusUpdates addObject:aNotification];
	}
	else {
		[self performDelegateSelector:@selector(server:didChangeStatus:)
						 withArgument:aNotification];
	}
	
	// block / delay / unblock status update
	if(status == SDStatusError) {
		// block status updates until they are unblocked by SDStatusClear
		blockStatusUpdate = YES;
	}
	else if(status == SDStatusWarning) {
		delayStatusUpdate = YES;
		// delay status updates for three seconds
		[self performSelector:@selector(undelayStatus) withObject:nil afterDelay:3.0];
	}
	else if(status == SDStatusClear) {
		// clear blocked status updates
		blockStatusUpdate = NO;
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(undelayStatus) object:nil];
		[self undelayStatus];
	}
	lastStatus = status;
}

- (void)undelayStatus
{
	delayStatusUpdate = NO;
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(undelayStatus) object:nil];

	id item;
	// get last object, remove it from the queue and process it using updateStatus
	while(item = [delayedStatusUpdates lastObject]) {
		[item retain];
		[delayedStatusUpdates removeObject:item];
		[self updateStatus:item];
		[item release];
	}
}

- (void)reloadConfiguration:(NSNotification*)aNotification
{
	[self performDelegateSelector:@selector(serverShouldReloadConfiguration:)
					 withArgument:aNotification];
}

#pragma mark -

- (void)performDelegateSelector:(SEL)sel
{
	if(delegate && [delegate respondsToSelector:sel]) {
		[delegate performSelector:sel withObject:self];
	}
}

- (void)performDelegateSelector:(SEL)sel withArgument:(id)arg
{
	if(delegate && [delegate respondsToSelector:sel]) {
		[delegate performSelector:sel withObject:self withObject:arg];
	}
}

- (NSString*)pathToServer
{
	NSString * synergydPath = nil;
	// first look in resources
	synergydPath = [[NSBundle bundleForClass:[self class]] pathForResource:kSynergyDaemonAppName ofType:@"app"];
	
	if(synergydPath)
		return synergydPath;
	
	// look in current folder
	synergydPath = [[[[[NSBundle bundleForClass:[self class]] bundlePath]
								stringByDeletingLastPathComponent]
								stringByAppendingPathComponent:kSynergyDaemonAppName]
								stringByAppendingPathExtension:@"app"];
	
	return synergydPath;
	
}

@end