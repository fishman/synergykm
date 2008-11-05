//
//  SKMMenuExtraController.m
//  SynergyKM
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

//
// this file contains excerpts of code written by Alex Harper
// http://www.ragingmenace.com
//

#import "SKMMenuExtraController.h"

#define kWaitForExtraLoadMS		2000000
#define kWaitForExtraLoadStepMS	250000

#define kMenuCrackerURL			[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"MenuCracker" ofType:@"menu"]]
#define kMenuCrackerBundleID	@"net.sourceforge.menucracker"

#define kSKMMenuURL				[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SynergyKM" ofType:@"menu"]]
#define kSKMMenuBundleID		@"net.sourceforge.synergy2.synergykmmenu"

@interface SKMMenuExtraController (private)
+ (BOOL)isExtraLoaded:(NSString *)extraID;
@end

@implementation SKMMenuExtraController
+ (BOOL) loadMenuExtra
{
	int			sleepCount = 0;
	BOOL		result = NO;
	
	NSURL* menuExtraURL = kSKMMenuURL;

	// Try the basic way, user might already have a menu cracker of their own
	CoreMenuExtraAddMenuExtra((CFURLRef)menuExtraURL, 0, 0, 0, 0, 0);
	// Nasty sleep code because on Panther this sometimes doesn't respond right away
	while (![self isExtraLoaded:kSKMMenuBundleID] && (sleepCount < kWaitForExtraLoadMS)) {
		sleepCount += kWaitForExtraLoadStepMS;
		usleep(kWaitForExtraLoadStepMS);
	}
	// Did we load yet?
	if (![self isExtraLoaded:kSKMMenuBundleID]) {
		// No load, check for crack and load again if needed
		if (![self isExtraLoaded:kMenuCrackerBundleID]) {
			// Load the cracker
			CoreMenuExtraAddMenuExtra((CFURLRef)kMenuCrackerURL, 0, 0, 0, 0, 0);
			// Load the request again
			CoreMenuExtraAddMenuExtra((CFURLRef)menuExtraURL, 0, 0, 0, 0, 0);
		}
	}
	// Wait again
	sleepCount = 0;
	while (![self isExtraLoaded:kSKMMenuBundleID] && (sleepCount < kWaitForExtraLoadMS)) {
		sleepCount += kWaitForExtraLoadStepMS;
		usleep(kWaitForExtraLoadStepMS);
	}
	
	// Now after crack and sleep check for the last time
	if ([self isExtraLoaded:kSKMMenuBundleID]) {
		result = YES;
	}
	return result;
}

+ (BOOL) isExtraLoaded {
	return [self isExtraLoaded:kSKMMenuBundleID];
}

+ (void) removeExtra {
	// The extra we're removing
	void		*anExtra;
	
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)kSKMMenuBundleID, &anExtra) == 0) && anExtra) {
		CoreMenuExtraRemoveMenuExtra(anExtra, 0);
	}
	
} // removeExtra

	
+ (BOOL) isExtraLoaded:(NSString *)extraID {
	// The extra we're checking
	void		*anExtra = nil;
	
	if ((CoreMenuExtraGetMenuExtra((CFStringRef)extraID, &anExtra) == 0) && anExtra) {
		return YES;
	}
	else {
		return NO;
	}
	
} // isExtraLoaded

@end
