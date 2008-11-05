//
//  SDAutomaticConfigurationAgent.m
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

#import <SystemConfiguration/SystemConfiguration.h>

#import "SDAutomaticConfigurationAgent.h"
#import "SDSynergyWrapper.h"
#import "SDStatusUpdater.h"

@interface SDAutomaticConfigurationAgent (privat)
- (void) reloadConfiguration;
- (void) handleNetServiceError:(NSDictionary *)errorDict sender:(id)sender;
- (void) updateStatus:(NSNotification*)notification;
@end

@implementation SDAutomaticConfigurationAgent
+ (void) initialize {
	static BOOL	done = NO;
    if ( !done ) {
		NSDictionary*	statusMessageDict;
		statusMessageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedString(@"Looking for Peers",@"automatic configuration agent is looking for peers"),
			[NSNumber numberWithInt:SDStatusDiscovering],
			nil];
		
		NSBundle*	b = [NSBundle mainBundle];
		NSDictionary* statusImageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			[b pathForImageResource:@"StatusSearching"],	[NSNumber numberWithInt:SDStatusDiscovering],
			nil];
		
		[[SDStatusUpdater defaultStatusUpdater] setStatusDictionary:statusMessageDict
											  statusImageDictionary:statusImageDict
														   andAlias:@"SynergyAutomaticConfigurationAgent"
														   forClass:[self class]];
		done = YES;
    }
}

- (id) init {
	if(self = [super init]) {
		peers = [[NSMutableDictionary alloc] init];
		services = [[NSMutableSet alloc] init];

		// setup rendezvous service
		
		// use screen name for rendezvous service name. if none is specified use localhostname
		NSString* serverName = (NSString*) CFPreferencesCopyValue ((CFStringRef)SDConfScreenNameKey, (CFStringRef) SDBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if(!serverName) {
			serverName = (NSString*) SCDynamicStoreCopyLocalHostName(NULL);
		}
		
		if(server = [[NSNetService alloc] initWithDomain:@"" type:SDSynergyDiscoverService name:serverName port:kSynergyDefaultPort])
		{
			[server setDelegate:self];
			[server publish];
		}
		[serverName release];
		
		// setup rendezvous browser
		if(browser = [[NSNetServiceBrowser alloc] init]) {
			[browser setDelegate:self];
			[browser searchForServicesOfType:SDSynergyDiscoverService inDomain:@""];
		}
		
		status = SDStatusDiscovering;
	}
	return self;
}

- (void) dealloc {
	if(server) {
		[server stop];
		[server release];
		server = nil;
	}
	
	if(browser) {
		[browser stop];
		[browser release];
		browser = nil;
	}
	
	[self forgetActiveConfiguration];
	
	if(peers) {
		[peers release];
		peers = nil;
	}
	
	if(currentConfigs) {
		[currentConfigs release];
		currentConfigs = nil;
	}
	
	[super dealloc];
}

- (void) loadConfiguration:(NSDictionary*)config forceReload:(BOOL)forceReload {
	if(forceReload) {
		// release active config name if reload was forced (force wrapper to restart)
		[self forgetActiveConfiguration];
		
		if(currentConfigs) {
			[currentConfigs release];
			currentConfigs = nil;
		}
		currentConfigs = [config retain];
	}
	
	[self reloadConfiguration];
}
	
- (void) reloadConfiguration {
	NSDictionary*	configs = [currentConfigs objectForKey:SDConfSetsKey];
	
	// construct dictionary with configurated sets and peers
	NSMutableSet*	peerNames = [NSMutableSet set];
	NSEnumerator*	allAvailablePeers = [peers keyEnumerator];
	id peer;
	while(peer = [allAvailablePeers nextObject]) {
		id	val = [peers objectForKey:peer];
		if(val && [val isKindOfClass:[NSArray class]] && [val count] > 0)
			[peerNames addObject:peer];
	}
		
	NSMutableDictionary* availableSets = [NSMutableDictionary dictionary];
	NSEnumerator* allConfigSetNames = [configs keyEnumerator];
	NSString* configSetName;		
	while(configSetName = [allConfigSetNames nextObject]) {
		NSMutableSet*	availablePeerNames = [NSMutableSet set];
		id				searchField;
		NSDictionary*	c = [configs objectForKey:configSetName];
		if(searchField = [c objectForKey:SDConfServerConfigKey]) {
			// search for peer names in screen sections (server config)
			NSDictionary*	screens = [searchField objectForKey:@"screens"];
			[availablePeerNames addObjectsFromArray:[screens allKeys]];
			// search for peer names in alias sections (server config)
			NSDictionary*	aliases = [searchField objectForKey:@"aliases"];
			NSEnumerator*	allAliases = [aliases objectEnumerator];
			id				alias;
			while(alias = [allAliases nextObject]) {
				if([alias isKindOfClass:[NSArray class]]) {
					[availablePeerNames addObjectsFromArray:alias];
				}
				else if([alias isKindOfClass:[NSString class]]) {
					[availablePeerNames addObject:alias];
				}
			}
		}
		// search for peer name in ServerAddress field (client config)
		else if(searchField = [c objectForKey:SDConfAddressKey]) {
			[availablePeerNames addObject:searchField];
		}
		
		// remove own name from set and intersect with available peers. continue if no peers are available for this set
		[availablePeerNames removeObject:[server name]];
		[availablePeerNames intersectSet:peerNames];
		
		if([availablePeerNames count] < 1)
			continue;
		
		// add peer names to set dict
		[availableSets setObject:availablePeerNames forKey:configSetName];
	}
	
	// choose best configuration (the more available and matching peers in a config set the better)
	float			score = 0.0;
	NSEnumerator*	allAvailableSets = [availableSets keyEnumerator];
	id				setName, bestSet = nil;
	while(setName = [allAvailableSets nextObject]) {
		NSMutableSet*	setPeers = [availableSets objectForKey:setName];
		float			setScore = [setPeers count];
		if(setScore == 0)
			continue;
		
		setScore = [setPeers count] / setScore;
		if(setScore > score) {
			bestSet = setName;
			score = setScore;
		}
	}
	
	// restart (stop) if no config set was found or if config set (network environment) changed
	BOOL	needsRestart = NO;
	needsRestart |= !bestSet;
	needsRestart |= !activeConfigName;
	needsRestart |= (bestSet && ![bestSet isEqualToString:activeConfigName]);

	// restart if task is not running or got an error
	needsRestart |= (synergyWrapper && ([synergyWrapper status] <= SDStatusIdle));
	
	// only restart if active
	needsRestart &= active;

	// don't restart if not needed
	if(!needsRestart)
		return;
	
	// release old stuff
	[self forgetActiveConfiguration];		

	// update status
	SDUpdateStatusCode(status = SDStatusDiscovering);
	
	// construct new, if new set was found
	if(bestSet) {
		NSMutableDictionary*	tmpConfig = [NSMutableDictionary dictionaryWithDictionary:[configs objectForKey:bestSet]];
		
		// set address property of clients to resolved server address
		if(![tmpConfig objectForKey:SDConfServerConfigKey]) {
			NSString*	tmpAddress = [[peers objectForKey:[tmpConfig objectForKey:SDConfAddressKey]] objectAtIndex:0];
			if(tmpAddress) {
				[tmpConfig setObject:tmpAddress forKey:SDConfAddressKey];
			}
		}
		
		[self createActiveConfiguration:tmpConfig withName:bestSet];
	}
}

- (void) updateStatus:(NSNotification*)notification {
	NSNumber *stat = [[notification userInfo] objectForKey:SDStatusUpdateStatusNumberKey];
	if([stat intValue] == SDStatusError) {
		// restart automatically after failure
		[self performSelector:@selector(reloadConfiguration) withObject:nil afterDelay:5.0];
		SDForwardStatus(notification);
	} else if ([stat intValue] == SDStatusIdle) {
		SDUpdateStatusCode(status = SDStatusDiscovering);
		// clear status for next status change only
		SDUpdateStatusCode(SDStatusClear);
		[self performSelector:@selector(reloadConfiguration) withObject:nil afterDelay:5.0];
	} else {
		SDForwardStatus(notification);
	}
}

# pragma mark -

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
//	NSLog(NSStringFromSelector(_cmd));
	
	NSString	*nsname = [aNetService name],*sname = [server name];
	if(![aNetServiceBrowser isEqual:browser] ||
	   [[aNetService name] isEqual:[server name]])
		return;
	
	// we must have a service array or set because we have to retain them
	[services addObject:aNetService];
	[peers setObject:[NSMutableArray array] forKey:[aNetService name]];
	[aNetService setDelegate:self];
		
	[aNetService resolve];
	return;
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSMutableArray*	addresses = [peers objectForKey:[sender name]];
	
	// extract addresses and port from senders addresses record
	
	struct sockaddr * socketAddress;
	char buffer[256];
	uint16_t port;
	
	NSEnumerator*	allAdresses = [[sender addresses] objectEnumerator];
	id	address;
	/* Search for the IPv4 addresses in the array. */
	while (address = [allAdresses nextObject]) {
		
		socketAddress = (struct sockaddr *)[address bytes];
		
		/* Only continue if this is an IPv4 address. */
		if (socketAddress && socketAddress->sa_family == AF_INET) {
			
			if (inet_ntop(AF_INET, &((struct sockaddr_in *)
									 socketAddress)->sin_addr, buffer, sizeof(buffer))) {
				
				port = ntohs(((struct sockaddr_in *)socketAddress)->sin_port);
				
				[addresses addObject:[[NSString alloc] initWithCString:buffer]];
				//printf("IP Address = %s\n", buffer);
				// printf("Port Number = %d\n", port);
			}
		}
	}
			
	[self reloadConfiguration];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
//	NSLog(NSStringFromSelector(_cmd));

	if(![aNetServiceBrowser isEqual:browser])
		return;
	
	[peers removeObjectForKey:[aNetService name]];
	[services removeObject:aNetService];
	
	if(!moreComing)
	{
		[self reloadConfiguration];
	}
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	//	NSLog(NSStringFromSelector(_cmd));
	[self handleNetServiceError:errorDict sender:sender];
}

- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
//	NSLog(NSStringFromSelector(_cmd));
	[self handleNetServiceError:errorDict sender:sender];
}


- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {	
//	NSLog(NSStringFromSelector(_cmd));
	[self handleNetServiceError:errorDict sender:aNetServiceBrowser];
}

- (void) handleNetServiceError:(NSDictionary *)errorDict sender:(id)sender {
	NSNetServicesError errCode = [[errorDict objectForKey:NSNetServicesErrorCode] intValue];
	
	int			s = SDStatusError;
	NSString*	message = nil;
	BOOL		notify = NO;

	switch(errCode) {
		// dont notify on these
		case NSNetServicesActivityInProgress:			
		case NSNetServicesCancelledError:
			break;
		
		// notify specific on these errors
		case NSNetServicesCollisionError:
			message = NSLocalizedString(@"Rendezvous: Service name alredy exists on network",nil);
			notify = YES;
			break;
			
		case NSNetServicesNotFoundError:
			message = NSLocalizedString(@"Rendezvous: No services could be found",nil);
			notify = YES;
			break;
			
		// notify general on these errors
		// case NSNetServicesBadArgumentError:
		// case NSNetServicesInvalidError:
		// case NSNetServicesUnknownError:
		default:
			message = NSLocalizedString(@"Rendezvous: An unknown error occured",nil);
			notify = YES;
			break;
			
	}
	if(notify) {
		SDUpdateStatusCodeWithMessage(status = s, message);
	}
}
@end

#pragma mark -

@implementation SDAutomaticConfigurationAgent (SDStatusUpdaterAddInfo)
- (NSDictionary*)additionalStatusUpdateInfo
{
	return [NSDictionary dictionaryWithObject:(activeConfigName ? activeConfigName : @"") forKey:SDStatusUpdateCurrentConfigurationKey];
}
@end
