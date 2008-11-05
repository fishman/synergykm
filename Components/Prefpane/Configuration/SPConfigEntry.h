//
//  SPConfigEntry.h
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

#import <Cocoa/Cocoa.h>

@class SPScreenEntry;

@interface SPConfigEntry : NSObject 
{
    NSString * name;

    BOOL isServerConfig;
    
    NSString * address;
    NSString * screenName;
    
    NSMutableArray * screens;
    
    BOOL heartbeatEnabled;
    unsigned int heartbeat;

    BOOL switchDelayEnabled;
    unsigned int switchDelay;

    BOOL switchDoubleTapEnabled;
    unsigned int switchDoubleTap;

    BOOL screenSaverSync;
    BOOL relativeMouseMoves;
}

-(NSString*)name;
-(void)setName:(NSString*)newName;

-(BOOL)isServerConfig;
-(void)setIsServerConfig:(BOOL)isServer;

-(NSString*)address;
-(void)setAddress:(NSString*)newAddress;

-(NSString*)screenName;
-(void)setScreenName:(NSString*)newScreenName;

//For when reading from disk
-(SPScreenEntry*)newBlankScreen;
//for when the user adds a screen from the GUI
-(SPScreenEntry*)createScreen;
-(void)removeScreen:(SPScreenEntry*)screen;

-(SPScreenEntry*)screenForName:(NSString *)name;

-(void)calculateScreenLayout;

-(NSArray*)screens;

-(BOOL)isHeartbeatEnabled;
-(void)setHeartbeatEnabled:(BOOL)enabled;

-(unsigned int)heartbeat;
-(void)setHeartbeat:(unsigned int)millisec;

-(BOOL)isSwitchDelayEnabled;
-(void)setSwitchDelayEnabled:(BOOL)enabled;

-(unsigned int)switchDelay;
-(void)setSwitchDelay:(unsigned int)millisec;

-(BOOL)isSwitchDoubleTapEnabled;
-(void)setSwitchDoubleTapEnabled:(BOOL)enabled;

-(unsigned int)switchDoubleTap;
-(void)setSwitchDoubleTap:(unsigned int)millisec;

-(BOOL)screenSaverSync;
-(void)setScreenSaverSync:(BOOL)sync;

-(BOOL)relativeMouseMoves;
-(void)setRelativeMouseMoves:(BOOL)relative;

@end
