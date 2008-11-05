//
//  SDSynergyClientWrapper.m
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

#import "SDSynergyClientWrapper.h"
#import "LCSStdIOTaskWrapper.h"

NSDictionary*	SDClientStatusMessageDict;

@implementation SDSynergyClientWrapper
+ (void)initialize {
	static BOOL	done = NO;
    if ( !done ) {
		[[SDStatusUpdater defaultStatusUpdater] setStatusDictionary:nil
											  statusImageDictionary:nil
														   andAlias:kClientCommand
														   forClass:[self class]];
		done = YES;
    }
}

- (void) dealloc
{
	[self stopWrapper];
		
	[screenName release];
	[address release];

	if(taskWrapper) {
		[taskWrapper release];
		taskWrapper = nil;
	}
	
	[super dealloc];
}

- (void) loadConfiguration:(NSDictionary*)config
{
	if(!config) {
		[NSException exceptionWithName:NSInvalidArgumentException reason:@"" userInfo:nil];
		return;
	}
				
	address = [config objectForKey:SDConfAddressKey];
	if(!address) {
		[NSException exceptionWithName:SDSynergydInvalidConfigurationException reason:@"\"Address\" missing in configuration" userInfo:nil];
		return;
	}
	[address retain];
	
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
		[NSException exceptionWithName:NSInvalidArgumentException reason:@"cannot start alredy active client wrapper." userInfo:nil];
		return;
	}

	// send status update
	SDUpdateStatusCode(SDStatusClear);
	SDUpdateStatusCode(status = SDStatusStarting);
	
	// setup task
	NSTask*		task = [[NSTask alloc] init];
	
	// set launch path
	[task setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kClientCommand]];
	
	// set arguments
	//	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-f",@"-1",nil];
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-f",nil];
	
	if(screenName && [screenName length]) {
		[args addObject:@"--name"];
		[args addObject:screenName];
	}

	if(debugLevel && [screenName length]) {
		[args addObject:@"--debug"];
		[args addObject:debugLevel];
	}
	
	[args addObject:address];
	
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
}
@end

@implementation SDSynergyClientWrapper (LCSStdIOTaskWrapperDelegate)
- (void) task:(id)sender didReceiveErrorLine:(NSString*)line {
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
		// stop before next runloop cycle
		[self performSelector:@selector(stopWrapper) withObject:nil afterDelay:0];
	} else if([logLevel isEqualToString:@"WARNING"]) {
		// handle warning messages
		message = logMessage;
		newStatus = SDStatusWarning;
		needsStatusUpdate |= YES;
	} else if([logLevel isEqualToString:@"NOTE"]) {
		NSRange	r = {0,0};
		// handle client messages
		if([logMessage isEqualTo:@"started client"]) {
			newStatus = SDStatusConnecting;
			needsStatusUpdate |= YES;
		} else if([logMessage isEqualTo:@"connected to server"]) {
			newStatus = SDStatusConnected;
			needsStatusUpdate |= YES;
		} else if([logMessage isEqualTo:@"disconnected from server"]) {
			newStatus = SDStatusDisconnected;
			needsStatusUpdate |= YES;
		} else if([logMessage isEqualTo:@"stopped client"]) {
			/* dont capture
			newStatus = SDStatusDisconnected;
			needsStatusUpdate |= YES;
			*/
		}
	} // end [logLevel isEqualToString:@"NOTE"]
	
	if(needsStatusUpdate) {
		SDUpdateStatusCodeWithMessage(status = newStatus, message);
	}
}
@end