//
//  LCSStdIOTaskWrapper.m
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

NSString* const LCSStdIOTaskException = @"LCSStdIOTaskException";

@interface LCSStdIOTaskWrapper (private)
- (void) getData: (NSNotification *)aNotification;
- (void) handleData:(NSData*)data withSelector:(SEL)sel incompleteLine:(NSString**)incompleteLine;
- (void) callDelegateSelector:(SEL)sel;
- (void) callDelegateSelector:(SEL)sel withObject:(id)object;
@end

@implementation LCSStdIOTaskWrapper
- (id) initWithTask:(NSTask*)aTask {
	if(self = [super init]) {
		task = [aTask retain];
	
		[task setStandardInput:[NSPipe pipe]];
		[task setStandardOutput:[NSPipe pipe]];
		[task setStandardError:[NSPipe pipe]];
		
		// add stdout read completition observer
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(readCompletition:) 
													 name:NSFileHandleReadCompletionNotification 
												   object:[[task standardOutput] fileHandleForReading]];
		
		[[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
		
		// add stderr read completition observer
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(readCompletition:) 
													 name:NSFileHandleReadCompletionNotification 
												   object:[[task standardError] fileHandleForReading]];
		
		[[[task standardError] fileHandleForReading] readInBackgroundAndNotify];
		valid = YES;
	}
	return self;
}

- (void)dealloc
{
	if(valid) {
		[self terminate];
	}
	
	[task release];
    [super dealloc];
}

- (id) task {
	return task;
}

- (void) launch {
	if(!valid) {
		[NSException exceptionWithName:LCSStdIOTaskException reason:@"attpemt to launch invalid task wrapper" userInfo:nil];
		return;
	}
	
	[self callDelegateSelector:@selector(taskWillLaunch:)];

	// add task termination completition observer and launch task
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(processDidTerminate:) 
												 name:NSTaskDidTerminateNotification 
											   object:task];
	[task launch];
	
	[self callDelegateSelector:@selector(taskDidLaunch:)];
}

- (void) terminate {
	if(!valid)
		return;
	
	valid = NO;
	
	// remove observers bofore terminating task
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:task];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[[task standardOutput] fileHandleForReading]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[[task standardError] fileHandleForReading]];
	
	// terminate task
	if(task && [task isRunning]) {
		[self callDelegateSelector:@selector(taskWillTerminate:)];
    
		[task terminate];
		[task waitUntilExit];
	}
	
	// receive rest of stdout data
	NSData*			data;
	while ((data = [[[task standardOutput] fileHandleForReading] availableData]) && [data length]) {
		[self handleData:data withSelector:@selector(task:didReceiveOutputLine:) incompleteLine:&incompleteOutputLine];
	}

	// receive rest of stderr data
	while ((data = [[[task standardError] fileHandleForReading] availableData]) && [data length])
	{
		[self handleData:data withSelector:@selector(task:didReceiveErrorLine:) incompleteLine:&incompleteErrorLine];
	}
	
	// call delegate finally.
	[self callDelegateSelector:@selector(taskDidTerminate:withStatus:) withObject:[NSNumber numberWithInt:[task terminationStatus]]];
}

- (void) writeString:(NSString*)s {
	NSFileHandle*	h = [[task standardInput] fileHandleForWriting];
	unsigned int	n = [s length];
	NSData*			d = [s dataUsingEncoding:NSUTF8StringEncoding];
	
	if(h && n && d)
		[h writeData:d];
}

- (void) setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

- (id) delegate {
	return delegate;
}

- (BOOL) isValid {
	return valid;
}


- (void) readCompletition:(NSNotification*)notification {
    NSData*		data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if (![data length]) {
		[self terminate];
		return;
	}
	
	if ([[notification object] isEqual:[[task standardOutput] fileHandleForReading]]) {
		[self handleData:data withSelector:@selector(task:didReceiveOutputLine:) incompleteLine:&incompleteOutputLine];
	} else if ([[notification object] isEqual:[[task standardError] fileHandleForReading]]) {
		[self handleData:data withSelector:@selector(task:didReceiveErrorLine:) incompleteLine:&incompleteErrorLine];
	} else {
		return;
	}
    
    [[notification object] readInBackgroundAndNotify];  
}

- (void) processDidTerminate:(NSNotification*)notification {
	if([[notification object] isEqual:task]) {
		[self terminate];
	}
}

- (void) handleData:(NSData*)data withSelector:(SEL)sel incompleteLine:(NSString**)incompleteLine {
	// NSCharacterSet*	ctlchars = [NSCharacterSet controlCharacterSet];
	
	// setup our own autorelease pool because we don't have one if we are called by a read completition routine
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString*	dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSScanner*	dataScanner = [NSScanner scannerWithString:dataString];
	
	[dataScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	NSString*	line;
	while([dataScanner scanUpToString:@"\n" intoString:&line]) {
		if(*incompleteLine) {
			line = [(*incompleteLine) stringByAppendingString:line];
			[(*incompleteLine) release];
			(*incompleteLine) = nil;
		}
		
		if([dataScanner scanString:@"\n" intoString:nil]) {
			[self callDelegateSelector:sel withObject:line];
		} else {
			(*incompleteLine) = [[NSString alloc] initWithString:[[dataScanner string] substringFromIndex:[dataScanner scanLocation]]];
			break;
		}
	}
	[pool release];
}

- (void) callDelegateSelector:(SEL)sel {
	if(delegate && [delegate respondsToSelector:sel]) {
		[delegate performSelector:sel withObject:self];
	}
}

- (void) callDelegateSelector:(SEL)sel withObject:(id)object {
	if(delegate && [delegate respondsToSelector:sel]) {
		[delegate performSelector:sel withObject:self withObject:object];
	}
}
@end
