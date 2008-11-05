//
//  SDSynergyWrapper.m
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

#import "LCSStdIOTaskWrapper.h"

#import "SDSynergyWrapper.h"
#import "SDSynergyClientWrapper.h"
#import "SDSynergyServerWrapper.h"

NSString* const SDSynergydInvalidConfigurationException = @"SDSynergydInvalidConfigurationException";

@implementation SDSynergyWrapper
+ (void)initialize {
	static BOOL	done = NO;
    if ( !done ) {
		NSDictionary*	statusMessageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedString(@"Starting up",@"task status message: task is starting up"),
			[NSNumber numberWithInt:SDStatusStarting],
			NSLocalizedString(@"Terminating",@"task status message: task is terminating"),
			[NSNumber numberWithInt:SDStatusTerminating],
			NSLocalizedString(@"Waiting for connections",@"server status message: server is listening"),
			[NSNumber numberWithInt:SDStatusListening],
			NSLocalizedString(@"Connecting...",@"task status message: client is connecting"),
			[NSNumber numberWithInt:SDStatusConnecting],
			NSLocalizedString(@"Connected",@"task status message: task has connection"),
			[NSNumber numberWithInt:SDStatusConnected],
			NSLocalizedString(@"Disconnected",@"task status message: client has no connection"),
			[NSNumber numberWithInt:SDStatusDisconnected],
			NSLocalizedString(@"Warning",@"task status message: synergy task got a warning"),
			[NSNumber numberWithInt:SDStatusWarning],
			nil];
		
		NSBundle*	b = [NSBundle mainBundle];
		NSDictionary* statusImageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			[b pathForImageResource:@"StatusStarting"],		[NSNumber numberWithInt:SDStatusStarting],
			[b pathForImageResource:@"StatusTerminating"],	[NSNumber numberWithInt:SDStatusTerminating],
			[b pathForImageResource:@"StatusListening"],	[NSNumber numberWithInt:SDStatusListening],
			[b pathForImageResource:@"StatusConnecting"],	[NSNumber numberWithInt:SDStatusConnecting],
			[b pathForImageResource:@"StatusConnected"],	[NSNumber numberWithInt:SDStatusConnected],
			[b pathForImageResource:@"StatusDisconnected"],	[NSNumber numberWithInt:SDStatusDisconnected],
			[b pathForImageResource:@"StatusWarning"],		[NSNumber numberWithInt:SDStatusWarning],
			nil];
		
		[[SDStatusUpdater defaultStatusUpdater] setStatusDictionary:statusMessageDict
											  statusImageDictionary:statusImageDict
														   andAlias:nil
														   forClass:[self class]];
		done = YES;
    }
}

+ (id) synergyWrapperWithConfiguration:(NSDictionary*)config
{
	id	wrapper = nil;
	id	serverConfig = [config objectForKey:SDConfServerConfigKey];
	if(serverConfig && [serverConfig isKindOfClass:[NSDictionary class]]) {
		wrapper = [[[SDSynergyServerWrapper alloc] initWithConfiguration:config] autorelease];
	} else if ([config objectForKey:SDConfAddressKey]) {
		wrapper = [[[SDSynergyClientWrapper alloc] initWithConfiguration:config] autorelease];
	} else {
		SDUpdateStatusCode(SDStatusError);
		[NSException exceptionWithName:SDSynergydInvalidConfigurationException reason:@"" userInfo:nil];
	}
	return wrapper;
}

- (id) init {
	if(self = [super init]) {
		status = SDStatusIdle;
	}
	return self;
}

- (id) initWithConfiguration:(NSDictionary*)config
{
	if(self = [self init]) {
		// actual init
		[self loadConfiguration:config];
	}
	return self;
}

- (int) status
{
	return status;
}

- (void) loadConfiguration:(NSDictionary*)config {}
- (void) startWrapper {}
- (void) stopWrapper {}
@end

@implementation SDSynergyWrapper (LCSStdIOTaskWrapperDelegate)
- (void) taskWillTerminate:(id)sender {
	if([sender isEqual:taskWrapper]) {
		SDUpdateStatusCode(status = SDStatusTerminating);
	}
}

- (void) taskDidTerminate:(id)sender withStatus:(int)terminationStatus {
	if([sender isEqual:taskWrapper]) {
		[taskWrapper release];
		taskWrapper = nil;
		SDUpdateStatusCode(status = SDStatusIdle);
	}
}
@end
