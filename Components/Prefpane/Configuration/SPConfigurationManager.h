//
//  SPConfigurationManager.h
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

@class SPConfigEntry;

@interface SPConfigurationManager : NSObject 
{
    NSMutableArray * configEntries;

    SPConfigEntry * activeConfig;
        
    BOOL enabled;
    BOOL automatic;
    BOOL menuVisible;
    
    NSString * debugLevel;
    
    BOOL isDirty;
}

-(BOOL)isDirty;
-(void)setDirty:(BOOL)dirty;

-(BOOL)isEnabled;
-(void)setEnabled:(BOOL)isEnabled;

-(BOOL)isAutomatic;
-(void)setAutomatic:(BOOL)isAutomatic;

-(BOOL)isMenuVisible;
-(void)setMenuVisible:(BOOL)isMenuVisible;

-(NSString*)debugLevel;
-(void)setDebugLevel:(NSString*)newLevel;

-(SPConfigEntry*)activeConfig;
-(void)setActiveConfig:(SPConfigEntry*)config;

-(void)savePreferencesToDisk;
-(void)readPreferencesFromDisk;

-(NSArray*)configEntries;

-(BOOL)existsConfigWithName:(NSString *)name;

-(void)newConfigWithName:(NSString*)name;

-(SPConfigEntry*)duplicateConfigEntry:(SPConfigEntry*)config;
-(void)deleteConfigEntry:(SPConfigEntry*)config;

@end


extern NSString * const ActiveConfigChanged;
extern NSString * const IsDirtyChanged;
