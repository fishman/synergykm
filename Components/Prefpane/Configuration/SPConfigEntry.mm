//
//  SPConfigEntry.mm
//  SynergyPane
//
//Copyright (c) 2005, Bertrand Landry-Hetu
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
//	¥ 	Neither the name of the Bertrand Landry-Hetu nor the names of its 
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

#import "SPConfigEntry.h"
#import "SPScreenEntry.h"

@implementation SPConfigEntry

-(id)init
{
    if (self = [super init])
    {
        name = [NSString new];
        address = [NSString new];
        screenName = [NSString new];
        screens = [NSMutableArray new];

        isServerConfig = NO;

        heartbeatEnabled = NO;
        heartbeat = 250;
        switchDelayEnabled = NO;
        switchDelay = 250;
        switchDoubleTapEnabled = NO;
        switchDoubleTap = 500;

        screenSaverSync = NO;
        relativeMouseMoves = NO;
    }

    return self;
}

-(void)dealloc
{
    [name release];
    [address release];
    [screenName release];
    [screens release];

    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    SPConfigEntry * copy = [SPConfigEntry new];
    
    [copy setName: name];
    [copy setAddress: address];
    [copy setScreenName: screenName];
    
    return copy;
}

-(NSString*)name
{
    return name;
}

-(void)setName:(NSString*)newName
{
    [name autorelease];
    name = [newName retain];
}

-(BOOL)isServerConfig
{
    return isServerConfig;
}

-(void)setIsServerConfig:(BOOL)isServer
{
    isServerConfig = isServer;
}

-(NSString*)address
{
    return address;
}

-(void)setAddress:(NSString*)newAddress
{
    [address autorelease];
    address = [newAddress retain];
}

-(NSString*)screenName
{
    return screenName;
}

-(void)setScreenName:(NSString*)newScreenName
{
    [screenName autorelease];
    screenName = [newScreenName retain];
}

-(void)removeScreen:(SPScreenEntry*)screen
{
    [screen setDownScreen: nil];
    [screen setUpScreen: nil];
    [screen setLeftScreen: nil];
    [screen setRightScreen: nil];
    
    [screens removeObject: screen];
}

-(SPScreenEntry*)newBlankScreen
{
    SPScreenEntry * result = [[SPScreenEntry new] autorelease];
    
    [screens addObject: result];
    
    return result;
}

-(SPScreenEntry*)createScreen
{
    SPScreenEntry * result = [[SPScreenEntry new] autorelease];
    
    [screens addObject: result];
    
    if ([screens count] == 1)
    {
        [result setPosition: NSZeroPoint];
    }
    else
    {
        SPScreenEntry * leftNeighbour = [screens objectAtIndex: 0];
        while( [leftNeighbour rightScreen] != 0 )
        {
            leftNeighbour = [leftNeighbour rightScreen];
        }
        [result setLeftScreen: leftNeighbour];
        NSPoint pos = [leftNeighbour position];
        pos.x += 1.0f;
        [result setPosition: pos];
    }
    
    return result;
}

-(SPScreenEntry*)screenForName:(NSString *)aName
{
    NSEnumerator * iter = [screens objectEnumerator];
    while (SPScreenEntry * screen = [iter nextObject])
    {
        if ([[screen name] isEqualToString: aName])
        {
            return screen;
        }
    }
    
    return nil;
}

-(NSArray*)screens
{
    return screens;
}

static void UpdateNeighbour(
    NSMutableArray * toBeProcessed, 
    NSMutableArray * processed, 
    SPScreenEntry * neighbour,
    NSPoint newPos)
{
    if (    [toBeProcessed containsObject: neighbour] == NO
        &&  [processed containsObject: neighbour] == NO)
    {
        [neighbour setPosition: newPos];
        [toBeProcessed addObject: neighbour];
    }
}

static void UpdateNeighbours( 
    NSMutableArray * toBeProcessed, 
    NSMutableArray * processed, 
    SPScreenEntry * currentScreen)
{
    NSPoint currentPos = [currentScreen position];

    if (SPScreenEntry * upScreen = [currentScreen upScreen])
    {
        NSPoint newPos = currentPos;
        newPos.y += 1.0f;
        
        UpdateNeighbour( toBeProcessed, processed, upScreen, newPos);
    }

    if (SPScreenEntry * downScreen = [currentScreen downScreen])
    {
        NSPoint newPos = currentPos;
        newPos.y -= 1.0f;

        UpdateNeighbour( toBeProcessed, processed, downScreen, newPos);
    }

    if (SPScreenEntry * leftScreen = [currentScreen leftScreen])
    {
        NSPoint newPos = currentPos;
        newPos.x -= 1.0f;

        UpdateNeighbour( toBeProcessed, processed, leftScreen, newPos);
    }

    if (SPScreenEntry * rightScreen = [currentScreen rightScreen])
    {
        NSPoint newPos = currentPos;
        newPos.x += 1.0f;

        UpdateNeighbour( toBeProcessed, processed, rightScreen, newPos);
    }
}

-(void)calculateScreenLayout
{
    unsigned int count = [screens count];
    
    if (count == 0)
        return;
    
    SPScreenEntry * firstScreen = [screens objectAtIndex: 0];
    //Array of objets that have their position set but not their neighbours.
    NSMutableArray * toBeProcessed = [NSMutableArray arrayWithObject: firstScreen];
    //Array of objets that have their position set and their neighbours too.
    NSMutableArray * processed = [NSMutableArray new];

    while([toBeProcessed count] != 0)
    {
        SPScreenEntry * currentScreen = [toBeProcessed objectAtIndex: 0];
        UpdateNeighbours( toBeProcessed, processed, currentScreen );

        [toBeProcessed removeObject: currentScreen];
        [processed addObject: currentScreen];
    }

    //If a screen was not processed then it is not connected to another screen so remove it.
    [screens release];
    screens = processed;
}


-(BOOL)screenSaverSync
{
    return screenSaverSync;
}

-(void)setScreenSaverSync:(BOOL)sync
{
    screenSaverSync = sync;
}

-(BOOL)isHeartbeatEnabled
{
    return heartbeatEnabled;
}

-(void)setHeartbeatEnabled:(BOOL)enabled
{
    heartbeatEnabled = enabled;
}

-(unsigned int)heartbeat
{
    return heartbeat;
}

-(void)setHeartbeat:(unsigned int)millisec
{
    heartbeat = millisec;
}

-(BOOL)isSwitchDelayEnabled
{
    return switchDelayEnabled;
}

-(void)setSwitchDelayEnabled:(BOOL)enabled
{
    switchDelayEnabled = enabled;
}

-(unsigned int)switchDelay
{
    return switchDelay;
}

-(BOOL)isSwitchDoubleTapEnabled
{
    return switchDoubleTapEnabled;
}

-(void)setSwitchDoubleTapEnabled:(BOOL)enabled
{
    switchDoubleTapEnabled = enabled;
}

-(void)setSwitchDelay:(unsigned int)millisec
{
    switchDelay = millisec;
}

-(unsigned int)switchDoubleTap
{
    return switchDoubleTap;
}

-(void)setSwitchDoubleTap:(unsigned int)millisec
{
    switchDoubleTap = millisec;
}


-(BOOL)relativeMouseMoves
{
    return relativeMouseMoves;
}

-(void)setRelativeMouseMoves:(BOOL)relative
{
    relativeMouseMoves = relative;
}


-(NSString *)description
{
    return [NSString stringWithFormat: @"name: %@\n address: %@\n screenName: %@\n", name, address, screenName];
}

@end
