//
//  SDConstants.h
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


/*
 * status update numbers
 */
enum {
	SDStatusInvalid	= -3,		// unknown status (must be first)
	SDStatusError = -2,			// synergy task had error
	SDStatusClear = -1,			// clear last (error) status
	
	SDStatusNotRunning = 0,		// synergyd is not running
	
	SDStatusIdle = 100,			// no synergy task launched
	SDStatusDiscovering = 120,	// rendezvous searching

	SDStatusStarting = 200,		// synergy task is starting up
	SDStatusTerminating,		// synergy task is terminating
	
	SDStatusConnecting,			// synergy task is connecting (client)
	SDStatusListening,			// synergy task is listening (server)
	SDStatusConnected,			// synergy task is connected
	SDStatusDisconnected,		// synergy task is not connected
	
	SDStatusWarning				// synergy task got a warning
};


/*
 * general
 */
extern NSString* const kSynergyDaemonAppName;
extern NSString* const kServerCommand;
extern NSString* const kClientCommand;
extern NSString* const SDBundleIdentifier;
extern NSString* const SDLogfilePath;

extern NSString* const SMBundleIdentifier;

/*
 * rendezvous
 */
extern NSString* const SDSynergyDiscoverService;
extern int const kSynergyDefaultPort;


/*
 * notifications observed by synergyd
 */
extern NSString* const SDSynergydShouldPostStatusUpdateNotification;
extern NSString* const SDSynergydShouldReloadConfigurationNotification;
extern NSString* const SDSynergydShouldTerminateNotification;


/*
 * notifications posted by synergyd
 */
extern NSString* const SDStatusUpdateNotification;
extern NSString* const SDSynergydDidTerminateNotification;


/*
 * status update notification keys (userInfo)
 */
extern NSString* const SDStatusUpdateStatusNumberKey;
extern NSString* const SDStatusUpdateStatusMessageKey;
extern NSString* const SDStatusUpdateSenderKey;
// status update notification key for connected clients if server is active (ALL LOWERCASE FOR NOW)
extern NSString* const SDStatusUpdateClientsKey;
// status update notification key for current configuration (selected by rendezvous)
extern NSString* const SDStatusUpdateCurrentConfigurationKey;


/*
 * configuration keys
 */
extern NSString* const SDConfEnabledKey;
extern NSString* const SDConfStatusMenuVisibleKey;
extern NSString* const SDConfAutomaticKey;
extern NSString* const SDConfActiveConfigKey;
extern NSString* const SDConfSetsKey;
extern NSString* const SDConfAddressKey;
// extern NSString* const SDConfServerNameKey;
extern NSString* const SDConfServerConfigKey;
extern NSString* const SDConfListenAddressKey;
// those two can be global (on first level of user defaults) and local (inside a ConfigSet).
// local definition overrides global
extern NSString* const SDConfDebugLevelKey;
extern NSString* const SDConfScreenNameKey;
