/*
 *  quitsynergyd.c
 *  Install Synergy
 *
 *  Created by Lorenz Schori on 30.07.05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#import <CoreFoundation/CoreFoundation.h>

int main (int argc, const char * argv[]) {
	CFNotificationCenterRef dnc = CFNotificationCenterGetDistributedCenter ();
	CFNotificationCenterPostNotification (dnc, CFSTR("NetSourceforgeSynergydShouldTerminate"), NULL, NULL, false);
	return 0;
}

