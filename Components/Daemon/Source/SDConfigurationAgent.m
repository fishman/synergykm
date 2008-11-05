//
//  SDConfigurationAgent.m
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

#import "SDConfigurationAgent.h"
#import "SDSynergyWrapper.h"

@implementation SDConfigurationAgent
- (id) init
{
	if(self = [super init])
	{
		active = YES;
		status = SDStatusIdle;
	}
	return self;
}

- (int)	status {
	return status;
}

- (void) activate {
	active = YES;
	[self startWrapper];
}

- (void) deactivate {
	active = NO;
	[self stopWrapper];
}

- (void) createActiveConfiguration:(NSDictionary*)config withName:(NSString*)name
{
	activeConfigName = [name retain];
	
	// create new configuration using global defaults
	NSMutableDictionary*	tmpConfig = [[NSMutableDictionary alloc] init];
	
	NSString* debugLevel = (NSString*)CFPreferencesCopyValue ((CFStringRef)SDConfDebugLevelKey, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	NSSet* validLevels = [NSArray arrayWithObjects:@"NOTE",@"INFO",@"DEBUG",@"DEBUG1",@"DEBUG2",nil];
	if(debugLevel && [validLevels containsObject:debugLevel]) {
		[tmpConfig setObject:debugLevel forKey:SDConfDebugLevelKey];
		[debugLevel release];
	}
	
	NSString* screenName = (NSString*)CFPreferencesCopyValue ((CFStringRef)SDConfScreenNameKey, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if(screenName) {
		[tmpConfig setObject:screenName forKey:SDConfScreenNameKey];
		[screenName release];
	}
	
	// overwrite global default entrys with actual config
	[tmpConfig addEntriesFromDictionary:config];
	
	activeConfig = tmpConfig;
	
	// start wrapper
	[self startWrapper];
}

- (void) forgetActiveConfiguration
{
	[self stopWrapper];
	
	if(activeConfigName) {
		[activeConfigName release];
		activeConfigName = nil;
	}
	if(activeConfig) {
		[activeConfig release];
		activeConfig = nil;
	}
}

- (void) startWrapper {
	if(synergyWrapper || !active || !activeConfig)
		return;
	
	SDUpdateStatusCode(SDStatusClear);		
	synergyWrapper = [SDSynergyWrapper synergyWrapperWithConfiguration:activeConfig];
	if(!synergyWrapper)
		return;
	
	synergyWrapper = [synergyWrapper retain];
	
	SDAddStatusUpdateObserverForObject(@selector(updateStatus:), synergyWrapper);
	[synergyWrapper startWrapper];
}

- (void) stopWrapper {
	if(!synergyWrapper)
		return;
	
	[synergyWrapper stopWrapper];
	SDRemoveStatusUpdateObserverForObject(synergyWrapper);
	[synergyWrapper release];
	synergyWrapper = nil;
}

- (void) loadConfiguration:(NSDictionary*)config forceReload:(BOOL)forceReload {}
@end
