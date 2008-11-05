//
//  SDStatusUpdater.m
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

#import "SDStatusUpdater.h"

SDStatusUpdater*	defaultStatusUpdater;

@implementation SDStatusUpdater
+ (id) defaultStatusUpdater
{
	if(!defaultStatusUpdater)
		defaultStatusUpdater = [[SDStatusUpdater alloc] init];
	return defaultStatusUpdater;
}

- (id) init
{
	if(self = [super init]) {
		statusUpdateSender = nil;
		statusDict = [[NSMutableDictionary alloc] init];
		aliasDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc
{
	if(statusDict)	[statusDict release];
	if(aliasDict)	[aliasDict release];
	[super dealloc];
}

- (void) setDefaultStatusDictionary:(NSDictionary*)aDictionary statusImageDictionary:(NSDictionary*)anImageDict andAlias:(NSString*)anAlias
{
	[self setStatusDictionary:aDictionary statusImageDictionary:anImageDict andAlias:anAlias forClass:[self class]];
}

- (void) setStatusDictionary:(NSDictionary*)aDictionary statusImageDictionary:(NSDictionary*)anImageDict andAlias:(NSString*)anAlias forClass:(Class)aClass
{
	if(aDictionary)
		[statusDict setObject:aDictionary forKey:aClass];
	
	if(anImageDict)
		[imageDict setObject:anImageDict forKey:aClass];
	
	if(anAlias)
		[aliasDict setObject:anAlias forKey:aClass];
}

/*
- (void) setStatusUpdateSender:(id)aSender
{
	statusUpdateSender = aSender;
}

- (id) statusUpdateSender{
	return statusUpdateSender;
}

- (void) postLastStatusUpdate
{
	if(!lastStatus || !statusUpdateSender || ![statusUpdateSender respondsToSelector:@selector(sendStatusUpdate:)])
		return;
	
	// FIXME: DOIT WITH NOTIFICATIONS: CATCH ON EACH LEVEL (WRAPPER -> AGENT -> MANAGER -> DISTRIBUTEDNOTIFICATIONCENTER)
	[statusUpdateSender sendStatusUpdate:lastStatus];
}
*/

- (void) postStatusUpdateCode:(int)aStatus message:(NSString*)aMessage sender:(id)sender
{
	[self postStatusUpdate:[NSNumber numberWithInt:aStatus] message:aMessage sender:sender];
}

- (void) postStatusUpdate:(id)aStatus message:(NSString*)aMessage sender:(id)sender
{
	id					o = sender;
	NSMutableArray*		addInfo = [NSMutableArray array];
	NSString*			statusString = nil;
//	NSString*			statusImage = nil;
	
	// recurse thru hierarchy
	while(o) {
		NSDictionary *d;
		if([o respondsToSelector:@selector(additionalStatusUpdateInfo)] && (d = [o additionalStatusUpdateInfo]) && d)
			[addInfo addObject:d];

		if(!statusString && (d = [statusDict objectForKey:[o class]])) {
			statusString = [d objectForKey:aStatus];
		}
		
		/*
		if(!statusImage && (d = [imageDict objectForKey:[o class]])) {
			statusImage = [d objectForKey:aStatus];
		}
		 */
		
		o = [o superclass];
	}
	
	// get default status string
	if(!statusString) {
		NSDictionary *d = [statusDict objectForKey:[self class]];
		statusString = [d objectForKey:aStatus];
		if(!statusString)
			NSLocalizedString(@"Unknown",@"unknown status message");
	}
	
	// get default status image path
	/*
	if(!statusImage) {
		NSDictionary *d = [imageDict objectForKey:[self class]];
		statusImage = [d objectForKey:aStatus];
	}
	 */
	
	if(aMessage && ![aMessage isEqualToString:@""])
		statusString = [NSString stringWithFormat:@"%@: %@",statusString,aMessage];

	// get sender alias
	NSString*			senderName = [aliasDict objectForKey:[sender class]];
	if(!senderName)
		senderName = [sender className];
	
	// construct info dictionary
	NSMutableDictionary*	info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		aStatus,		SDStatusUpdateStatusNumberKey,
		statusString,	SDStatusUpdateStatusMessageKey,
		senderName,		SDStatusUpdateSenderKey,
		// last can be nil
		// statusImage,	@"StatusImage",
		nil];
	
	// add (override) additional status infos in reverse order!
	NSEnumerator*	allInfos = [addInfo reverseObjectEnumerator];
	NSDictionary*	i;
	
	while(i = [allInfos nextObject]) {
		[info addEntriesFromDictionary:i];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SDStatusUpdateNotification object:sender userInfo:info];
	//[self postLastStatusUpdate];
}
@end
