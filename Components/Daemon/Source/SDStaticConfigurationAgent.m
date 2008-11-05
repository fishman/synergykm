//
//  SDStaticConfigurationAgent.m
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

#import "SDStaticConfigurationAgent.h"
#import "SDStatusUpdater.h"
#import "SDSynergyWrapper.h"

@implementation SDStaticConfigurationAgent
+ (void) initialize {
	static BOOL	done = NO;
    if ( !done ) {
		[[SDStatusUpdater defaultStatusUpdater] setStatusDictionary:nil
											  statusImageDictionary:nil
														   andAlias:@"SynergyStaticConfigurationAgent"
														   forClass:[self class]];
		done = YES;
    }
}

- (void) dealloc
{
	[self forgetActiveConfiguration];
	[super dealloc];
}

- (void) loadConfiguration:(NSDictionary*)config forceReload:(BOOL)forceReload
{
	BOOL	needsRestart = forceReload;
	
	// read configuration set
	NSDictionary* configs = [config objectForKey:SDConfSetsKey];
	NSString *newActiveConfigName = [config objectForKey:SDConfActiveConfigKey];
	if(!configs) {
		[NSException exceptionWithName:SDConfigurationException reason:@"No Configuration Available." userInfo:nil];
		SDUpdateStatusCodeWithMessage(SDStatusError, @"No configuration available.");
		return;
	}
	
	NSDictionary* newConfig = [configs objectForKey:newActiveConfigName];
	if(!newConfig) {
		[NSException exceptionWithName:SDConfigurationException reason:@"Active configuration not available" userInfo:nil];
		SDUpdateStatusCodeWithMessage(SDStatusError, @"Active configuration not available");
		return;
	}
	
	needsRestart |= (![newActiveConfigName isEqualToString:activeConfigName]);
	needsRestart &= active;
	
	// restart synergy if required
	if(needsRestart) {
		[self forgetActiveConfiguration];		
		[self createActiveConfiguration:newConfig withName:newActiveConfigName];
	}
}

- (void) updateStatus:(NSNotification*)notification {
	SDForwardStatus(notification);
}
@end
