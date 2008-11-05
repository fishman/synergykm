//
//  SPConfigurationManager.mm
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

#import "SPConfigurationManager.h"
#import "SPConfigEntry.h"
#import "SPScreenEntry.h"

#import "SDConstants.h"

@interface SPConfigurationManager (Private)
-(void)readPreferencesFromDisk;
@end

NSString * const ActiveConfigChanged = @"ActiveConfigChanged";
NSString * const IsDirtyChanged = @"IsDitryChanged";

@implementation SPConfigurationManager

-(id)init
{
    if (self = [super init])
    {
        configEntries = [NSMutableArray new];
        menuVisible = YES;
        automatic = NO;
        enabled = YES;

        [self readPreferencesFromDisk];
    }
    
    return self;
}

-(void)dealloc
{
    [configEntries release];
    [super dealloc];
}

#pragma mark - Accessors -

-(BOOL)isDirty
{
    return isDirty;
}

-(void)setDirty:(BOOL)dirty
{
    isDirty = dirty;
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: IsDirtyChanged 
                      object: nil 
                    userInfo: nil];
}

-(BOOL)isEnabled
{
    return enabled;
}

-(void)setEnabled:(BOOL)isEnabled
{
    enabled = isEnabled;
}

-(BOOL)isAutomatic
{
    return automatic;
}

-(void)setAutomatic:(BOOL)isAutomatic
{
    automatic = isAutomatic;
}

-(BOOL)isMenuVisible
{
    return menuVisible;
}

-(void)setMenuVisible:(BOOL)isAutomatic
{
    menuVisible = isAutomatic;
}


-(SPConfigEntry*)activeConfig
{
    return activeConfig;
}

-(NSString*)debugLevel
{
    return debugLevel;
}

-(void)setDebugLevel:(NSString *)newLevel
{
    [debugLevel autorelease];
    debugLevel = [newLevel retain];
}

-(void)setActiveConfig:(SPConfigEntry*)config
{
    [activeConfig autorelease];
    activeConfig = [config retain];
    
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName: ActiveConfigChanged 
                      object: nil 
                    userInfo: nil];
    
}

-(NSArray*)configEntries
{
//    if ([configEntries respondsToSelector: @selector (sortedArrayUsingDescriptors:)])
//    {
//        NSSortDescriptor * sortDescritor = [[[NSSortDescriptor alloc] initWithKey: @"name"
//                                                                       ascending: YES
//                                                                        selector: @selector(localizedCaseInsensitiveCompare:)] autorelease];
//
//        return [configEntries sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortDescritor]];
//    }
    
    return configEntries;
}

-(void)newConfigWithName:(NSString*)name
{
    SPConfigEntry * newConfig = [[SPConfigEntry new] autorelease];

    [newConfig setName: name];
    
    [configEntries addObject: newConfig];
    
    [self setActiveConfig: newConfig];
}

-(BOOL)existsConfigWithName:(NSString *)name
{
    NSEnumerator * iter = [configEntries objectEnumerator];

    while (SPConfigEntry * config = [iter nextObject])
    {
        if ([[config name] isEqualToString: name])
        {
            return YES;
        }
    }
    return NO;
}

-(NSString *)nameForDuplicatedConfigName:(NSString *)name
{
    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    NSString * suffix = NSLocalizedStringFromTableInBundle( @" Copy", nil, thisBundle, @"");
    
    NSString * baseNewName = [name stringByAppendingString: suffix];

    unsigned int index = 1;
    
    NSString * newName = baseNewName;
    
    while ([self existsConfigWithName: newName])
    {
        newName = [NSString stringWithFormat: @"%@ %d", baseNewName, index];
        ++index;
    } 

    return newName;
}

-(SPConfigEntry *)duplicateConfigEntry:(SPConfigEntry*)config
{
    SPConfigEntry * copyConfig = [[config copy] autorelease];

    [configEntries addObject: copyConfig];
    
    NSString * newName = [self nameForDuplicatedConfigName: [copyConfig name]];
    
    [copyConfig setName: newName];
    
    [self setActiveConfig: copyConfig];
    
    return copyConfig;
}

-(void)deleteConfigEntry:(SPConfigEntry*)config
{
    [[config retain] autorelease];
    
    [configEntries removeObject: config];
    
    if ([[activeConfig name] isEqualToString: [config name]])
    {
        if ([configEntries count] != 1)
        {
            [self setActiveConfig: [configEntries lastObject]];
        }
        else
        {
            [self setActiveConfig: nil];
        }
    }
}

#pragma mark - read config file -

-(void)readOptionsFromDictionary: (NSDictionary *)options intoConfigEntry: (SPConfigEntry *)configEntry
{
    //Format is a Dictionary that contains numbers for each of the options

    if (options)
    {
        NSNumber * hb = [options objectForKey: @"heartbeat"];
        if (hb)
        {
            [configEntry setHeartbeatEnabled: YES];
            [configEntry setHeartbeat: [hb unsignedIntValue]];
        }

        NSNumber * sd = [options objectForKey: @"switchDelay"];
        if (sd)
        {
            [configEntry setSwitchDelayEnabled: YES];
            [configEntry setSwitchDelay: [sd unsignedIntValue]];
        }

        NSNumber * dt = [options objectForKey: @"switchDoubleTap"];
        if (dt)
        {
            [configEntry setSwitchDoubleTapEnabled: YES];
            [configEntry setSwitchDoubleTap: [dt unsignedIntValue]];
        }

        NSString * ss = [options objectForKey: @"screenSaverSync"];
        [configEntry setScreenSaverSync: [ss isEqualToString: @"true"]];

        NSString * mm = [options objectForKey: @"relativeMouseMoves"];
        [configEntry setRelativeMouseMoves: [mm isEqualToString: @"true"]];
    }
}

-(void)readScreensFromDictionary: (NSDictionary *)screensDict intoConfigEntry: (SPConfigEntry *)configEntry
{
    //Format is a Dictionary that contains dictionaries of string or an empty string. 
    //the dictionaries are attributes of the screen (keymapping)

    NSEnumerator * iter = [screensDict keyEnumerator];
    
    while (NSString * screenName = [iter nextObject])
    {
        SPScreenEntry * screen = [configEntry newBlankScreen];
        
        [screen setName: screenName];
        
        id keyMapping = [screensDict objectForKey: screenName];
        
        if ([keyMapping isKindOfClass: [NSDictionary class]])
        {
            NSMutableDictionary * attributes = [screen attributes];                    
            [attributes removeAllObjects];
            [attributes addEntriesFromDictionary: keyMapping];
        }
    }
}

-(void)readAliasesFromDictionary: (NSDictionary *)aliasesDict intoConfigEntry: (SPConfigEntry *)configEntry
{
    //Format is a Dictionary that contains arrays of string. Each key is the name of a screen, and the array
    //the key points to is the array of aliases for that screen. 

    NSEnumerator * iter = [aliasesDict keyEnumerator];

    while (NSString * screenName = [iter nextObject])
    {
        NSArray * aliases = [aliasesDict objectForKey: screenName];
        if (aliases)
        {
            SPScreenEntry * screen = [configEntry screenForName: screenName];
            if (screen)
            {
                NSMutableArray * array = [screen aliases];
                [array removeAllObjects];
                [array addObjectsFromArray: aliases];
            }
        }
    }
}

-(void)readLinksFromDictionary: (NSDictionary *)linksDict intoConfigEntry: (SPConfigEntry *)configEntry
{
    //format is a dictionary of a dictionary of string.
    //the keys of the first dict is a screen name 
    //the keys of the second dict is a direction
    //and the strings are the screen names of the screens in that direction
    
    NSEnumerator * iter = [linksDict keyEnumerator];

    while (NSString * screenName = [iter nextObject])
    {
        SPScreenEntry * mainScreen = [configEntry screenForName: screenName];
        if (mainScreen)
        {
            NSDictionary * directionsDict = [linksDict objectForKey: screenName];
            NSEnumerator * directionIter = [directionsDict keyEnumerator];
            while (NSString * direction = [directionIter nextObject])
            {
                NSString * pointedScreenName = [directionsDict objectForKey: direction];
                SPScreenEntry * pointedScreen = [configEntry screenForName: pointedScreenName];
                if (pointedScreen)
                {
                    if ([direction isEqualTo:@"up"])
                    {
                        [mainScreen setUpScreen: pointedScreen];
                    }
                    else if ([direction isEqualTo:@"down"])
                    {
                        [mainScreen setDownScreen: pointedScreen];
                    }
                    else if ([direction isEqualTo:@"left"])
                    {
                        [mainScreen setLeftScreen: pointedScreen];
                    }
                    else if ([direction isEqualTo:@"right"])
                    {
                        [mainScreen setRightScreen: pointedScreen];
                    }
                }
            }
        }
    }

    //Validate the screen links & calculate their Cartesian positions
    [configEntry calculateScreenLayout];
}


-(void)readPreferencesFromDisk
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary * diskPrefs = [defaults persistentDomainForName: SDBundleIdentifier];
    
    [configEntries removeAllObjects];

    NSMutableDictionary * newConfigEntries = [diskPrefs objectForKey: SDConfSetsKey];

    NSNumber * automaticConfiguration = [diskPrefs objectForKey: SDConfAutomaticKey];
    [self setAutomatic: [automaticConfiguration boolValue]];

    NSNumber * menuVisibilityValue = [diskPrefs objectForKey: SDConfStatusMenuVisibleKey];
    [self setMenuVisible: [menuVisibilityValue boolValue]];

    NSString * debugLevelValue = [diskPrefs objectForKey: SDConfDebugLevelKey];
    [self setDebugLevel: debugLevelValue];

    NSString * activeConfigName = nil;

    if(![self isAutomatic])
    {
        activeConfigName = [diskPrefs objectForKey: SDConfActiveConfigKey];
    }
    
    SPConfigEntry * activeConfigEntry = nil;
    
    if (newConfigEntries != nil)
    {
        NSEnumerator * iter = [newConfigEntries keyEnumerator];
        
        while (NSString * key = [iter nextObject])
        {
            NSDictionary * configEntryDict = [newConfigEntries objectForKey: key];

            SPConfigEntry * configEntry = [[SPConfigEntry new] autorelease];

            [configEntries addObject: configEntry];

            [configEntry setName: key];

            NSString * address = [configEntryDict objectForKey:SDConfAddressKey];
            if (address)
                [configEntry setAddress: address];

            NSString * screenName = [configEntryDict objectForKey: SDConfScreenNameKey];
            if (screenName)
                [configEntry setScreenName: screenName];
            
            if ( [activeConfigName isEqualToString: key] )
            {
                activeConfigEntry = configEntry;
            }
            
            NSDictionary * serverConfig = [configEntryDict objectForKey: SDConfServerConfigKey];
            
            [configEntry setIsServerConfig: (serverConfig != nil)];

            if (serverConfig)
            {
                NSDictionary * options = [serverConfig objectForKey: @"options"];

                [self readOptionsFromDictionary: options intoConfigEntry: configEntry];
           
                NSDictionary * screensDict = [serverConfig objectForKey: @"screens"];
                
                [self readScreensFromDictionary: screensDict intoConfigEntry: configEntry];

                NSDictionary * aliasesDict = [serverConfig objectForKey: @"aliases"];
                
                [self readAliasesFromDictionary: aliasesDict intoConfigEntry: configEntry];

                NSDictionary * linksDict = [serverConfig objectForKey: @"links"];
                
                [self readLinksFromDictionary: linksDict intoConfigEntry: configEntry];

            }
        }
    }

    [self setDirty: NO];

    if ([configEntries count] == 0)
    {
        NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
        SPConfigEntry * defaultConfig = [[SPConfigEntry new] autorelease];

        [defaultConfig setName: NSLocalizedStringFromTableInBundle(@"default",nil, thisBundle,@"")];
        
        [configEntries addObject: defaultConfig];
        
        activeConfigEntry = defaultConfig;
        [self setDirty: YES];
    }

    [self setActiveConfig: activeConfigEntry];
}

#pragma mark - write config file -

-(NSDictionary *)optionsDictionaryForEntry:(SPConfigEntry*)configEntry
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];

    if ([configEntry isHeartbeatEnabled])
    {
        [result setObject: [NSNumber numberWithUnsignedInt: [configEntry heartbeat]] 
                   forKey: @"heartbeat"];
    }

    if ([configEntry isSwitchDelayEnabled])
    {
        [result setObject: [NSNumber numberWithUnsignedInt: [configEntry switchDelay]] 
                   forKey: @"switchDelay"];
    }

    if ([configEntry isSwitchDoubleTapEnabled])
    {
        [result setObject: [NSNumber numberWithUnsignedInt: [configEntry heartbeat]] 
                   forKey: @"switchDoubleTap"];
    }

    if ([configEntry screenSaverSync])
        [result setObject: @"true"
                   forKey: @"screenSaverSync"];
    else
        [result setObject: @"false"
                   forKey: @"screenSaverSync"];

    if ([configEntry relativeMouseMoves])
        [result setObject: @"true"
                   forKey: @"relativeMouseMoves"];
    else
        [result setObject: @"false"
                   forKey: @"relativeMouseMoves"];
    
    
    return result;
}
          
-(NSDictionary *)screensDictionaryForEntry:(SPConfigEntry*)configEntry
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];

    NSArray * screens = [configEntry screens];

    NSEnumerator * iter = [screens objectEnumerator];
    
    while (SPScreenEntry * screen = [iter nextObject])
    {
        NSString * screenName = [screen name];
        NSDictionary * attributes = [screen attributes];
    
        if (attributes == nil || [attributes count] == 0)
        {
            [result setObject: @"" forKey: screenName];
        }
        else
        {
            [result setObject: attributes forKey: screenName];
        }
    }


    return result;
}

-(NSDictionary *)aliasesDictionaryForEntry:(SPConfigEntry*)configEntry
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];

    NSArray * screens = [configEntry screens];

    NSEnumerator * iter = [screens objectEnumerator];

    while (SPScreenEntry * screen = [iter nextObject])
    {
        NSArray * aliases = [screen aliases];
        NSString * screenName = [screen name];

        [result setObject: aliases forKey: screenName];
    }

    return result;
}

-(NSDictionary *)linksDictionaryForEntry:(SPConfigEntry*) configEntry
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];

    NSArray * screens = [configEntry screens];

    NSEnumerator * iter = [screens objectEnumerator];

    while (SPScreenEntry * screen = [iter nextObject])
    {
        NSMutableDictionary * screenLinks = [NSMutableDictionary dictionary];
        
        SPScreenEntry * upScreen = [screen upScreen];
        if (upScreen)
        {
            [screenLinks setObject: [upScreen name] forKey: @"up"];
        }
        
        SPScreenEntry * downScreen = [screen downScreen];
        if (downScreen)
        {
            [screenLinks setObject: [downScreen name] forKey: @"down"];
        }

        SPScreenEntry * leftScreen = [screen leftScreen];
        if (leftScreen)
        {
            [screenLinks setObject: [leftScreen name] forKey: @"left"];
        }

        SPScreenEntry * rightScreen = [screen rightScreen];
        if (rightScreen)
        {
            [screenLinks setObject: [rightScreen name] forKey: @"right"];
        }

        NSString * screenName = [screen name];

        [result setObject: screenLinks forKey: screenName];
    }

    return result;
}


-(void)savePreferencesToDisk
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary * diskPrefs = [defaults persistentDomainForName: SDBundleIdentifier];

    NSMutableDictionary * mutableDiskPrefs = [[diskPrefs mutableCopy] autorelease];
    
    if (mutableDiskPrefs == nil)
    {
        mutableDiskPrefs = [NSMutableDictionary dictionary];
    }

    NSMutableDictionary * mutableConfigSets = [NSMutableDictionary dictionary];
    
    NSEnumerator * iter = [configEntries objectEnumerator];
    while (SPConfigEntry * configEntry = [iter nextObject])
    {
        NSMutableDictionary * configSetDict = [[[mutableConfigSets objectForKey: [configEntry name]] mutableCopy] autorelease];
        if (configSetDict == nil)
        {
            configSetDict = [NSMutableDictionary dictionary];
        }

        [configSetDict setObject: [configEntry address] forKey:SDConfAddressKey];

        NSString * screenName = [configEntry screenName];
        if ([screenName length] != 0)
        {
            [configSetDict setObject: screenName forKey: SDConfScreenNameKey];
        }

        if ([configEntry isServerConfig])
        {
            NSMutableDictionary * serverConfig = [[[configSetDict objectForKey: SDConfServerConfigKey] mutableCopy] autorelease];
            if (serverConfig == nil)
            {
                serverConfig = [NSMutableDictionary dictionary];
            }
            
            NSDictionary * options = [self optionsDictionaryForEntry: configEntry];

            [serverConfig setObject: options forKey: @"options"];
           
            NSDictionary * screensDict = [self screensDictionaryForEntry: configEntry];

            [serverConfig setObject: screensDict forKey: @"screens"];

            NSDictionary * aliasesDict = [self aliasesDictionaryForEntry: configEntry];

            [serverConfig setObject: aliasesDict forKey: @"aliases"];

            NSDictionary * linksDict = [self linksDictionaryForEntry: configEntry];

            [serverConfig setObject: linksDict forKey: @"links"];

            [configSetDict setObject: serverConfig forKey: SDConfServerConfigKey];
        }
        else
        {
            [configSetDict removeObjectForKey: SDConfServerConfigKey];
        }
        
        [mutableConfigSets setObject: configSetDict forKey: [configEntry name]];
    }

    [mutableDiskPrefs setObject: mutableConfigSets forKey: SDConfSetsKey];

    [mutableDiskPrefs setObject: [NSNumber numberWithBool: [self isAutomatic]] forKey: SDConfAutomaticKey];

    [mutableDiskPrefs setObject: [NSNumber numberWithBool: [self isMenuVisible]] forKey: SDConfStatusMenuVisibleKey];

    if ([activeConfig name])
        [mutableDiskPrefs setObject: [activeConfig name]  forKey: SDConfActiveConfigKey];
    else
        [mutableDiskPrefs removeObjectForKey: SDConfActiveConfigKey];

    if ([self debugLevel])
        [mutableDiskPrefs setObject: [self debugLevel]  forKey: SDConfDebugLevelKey];
    else
        [mutableDiskPrefs removeObjectForKey: SDConfDebugLevelKey];

    [mutableDiskPrefs setObject: [NSNumber numberWithBool: YES] forKey: SDConfEnabledKey];

    [defaults setPersistentDomain: mutableDiskPrefs forName: SDBundleIdentifier];

    [defaults synchronize];

    [[NSDistributedNotificationCenter defaultCenter] 
        postNotificationName: SDSynergydShouldReloadConfigurationNotification 
                      object: nil 
                    userInfo: nil];

    [self setDirty: NO];
}

@end
