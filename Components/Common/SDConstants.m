//
//  SDConstants.m
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
 * general
 */
NSString* const kSynergyDaemonAppName = @"Synergyd";
NSString* const kServerCommand = @"synergys";
NSString* const kClientCommand = @"synergyc";
NSString* const SDBundleIdentifier = @"net.sourceforge.synergy2.synergyd";
NSString* const SDLogfilePath = @"~/Library/Logs/synergyd.log";

/*
 * rendezvous
 */
int const kSynergyDefaultPort = 24800;
NSString* const SDSynergyDiscoverService = @"_synergydiscover._tcp";


/*
 * notifications observed by synergyd
 */
NSString* const SDSynergydShouldPostStatusUpdateNotification = @"NetSourceforgeSynergydShouldPostStatusUpdate";
NSString* const SDSynergydShouldReloadConfigurationNotification = @"NetSourceforgeSynergydShouldReloadConfiguration";
NSString* const SDSynergydShouldTerminateNotification = @"NetSourceforgeSynergydShouldTerminate";


/*
 * notifications posted by synergyd
 */
NSString* const SDStatusUpdateNotification = @"NetSourceforgeSynergyStatusUpdate";
NSString* const SDSynergydDidTerminateNotification = @"NetSourceforgeSynergydDidTerminate";


/*
 * status update notification keys (userInfo)
 */
NSString* const SDStatusUpdateStatusNumberKey = @"Status";
NSString* const SDStatusUpdateStatusMessageKey = @"StatusMessage";
NSString* const SDStatusUpdateSenderKey = @"Sender";
// status update notification key for connected clients if server is active
NSString* const SDStatusUpdateClientsKey = @"Clients";
// status update notification key for connected clients if server is active
NSString* const SDStatusUpdateCurrentConfigurationKey = @"CurrentConfiguration";


/*
 * configuration keys
 */
NSString* const SDConfEnabledKey = @"Enabled";
NSString* const SDConfStatusMenuVisibleKey = @"StatusMenuVisible";
NSString* const SDConfAutomaticKey = @"AutomaticConfiguration";
NSString* const SDConfActiveConfigKey = @"ActiveConfiguration";
NSString* const SDConfSetsKey = @"ConfigSets";
NSString* const SDConfAddressKey = @"Address";
// NSString* const SDConfServerNameKey = @"ServerName";
NSString* const SDConfServerConfigKey = @"ServerConfig";
NSString* const SDConfListenAddressKey = @"ListenAddress";
// those two can be global (on first level of user defaults) and local (inside a ConfigSet).
// local definition overrides global
NSString* const SDConfDebugLevelKey = @"DebugLevel";
NSString* const SDConfScreenNameKey = @"ScreenName";
