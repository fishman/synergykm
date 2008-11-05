//
//  SDAppController.m
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


#import "SDAppController.h"
#import "SDConfigurationManager.h"

#import <ExceptionHandling/NSExceptionHandler.h>

@implementation SDAppController
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// debug
	// [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: 1023];
	
	
	// redirect stdout and stderr
	NSString*	logFilePath = [SDLogfilePath stringByStandardizingPath];
	freopen([logFilePath cString], "a", stdout);
	freopen([logFilePath cString], "a", stderr);
	
	// create config
	config = [[SDConfigurationManager alloc] init];
	if(!config) {
		// FIXME: ERROR HANDLING
		return;
	}
		
	// install SDSynergydShouldTerminateNotification notification handler
	[[NSDistributedNotificationCenter defaultCenter] addObserver:[NSApplication sharedApplication] selector:@selector(terminate:) name:SDSynergydShouldTerminateNotification object:nil];
	
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
	if(config) {
		[config release];
	}
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:[NSApplication sharedApplication] name:SDSynergydShouldTerminateNotification object:nil];

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:SDSynergydDidTerminateNotification object:nil];
}
@end
