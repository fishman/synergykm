//
//  SPScreenEntry.mm
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

#import "SPScreenEntry.h"

static NSString * const SPHalfDuplexCapsLockKey = @"halfDuplexCapsLock";
static NSString * const SPHalfDuplexNumLockKey = @"halfDuplexNumLock";
static NSString * const SPHalfDuplexScrollLockKey  = @"halfDuplexScrollLock";

static NSString * const SPTrueStringValue = @"true";
static NSString * const SPFalseStringValue  = @"false";


NSString * const SPShiftKey = @"shift";
NSString * const SPCtrlKey = @"ctrl";
NSString * const SPAltKey = @"alt";
NSString * const SPMetaKey = @"meta";
NSString * const SPSuperKey = @"super";
NSString * const SPNoneKey = @"none";


@implementation SPScreenEntry

-(id)init
{
    if (self = [super init])
    {
        name = [NSString new];
        aliases = [NSMutableArray new];
        attributes = [NSMutableDictionary new];
    }
    
    return self;
}

-(void)dealloc
{
    [name release];
    [aliases release];
    [attributes release];

    [super dealloc];
}

#pragma mark - accessors -

-(NSString *)name
{
    return name;
}

-(void)setName:(NSString *)newName
{
    [name autorelease];
    name = [newName retain];
}
    
-(NSMutableArray *)aliases
{
    return aliases;
}

-(NSMutableDictionary *)attributes
{
    return attributes;
}
    
-(SPScreenEntry *)upScreen
{
    return upScreen;
}

-(void)setUpScreen:(SPScreenEntry *)aScreen
{
//don't retain othewise it'll introduce a cyclic dependency and it'll leak.
    if (upScreen)
        upScreen->downScreen = nil;

    upScreen = aScreen;

    if (aScreen)
        aScreen->downScreen = self;
}

-(SPScreenEntry *)downScreen
{
    return downScreen;
}

-(void)setDownScreen:(SPScreenEntry *)aScreen
{
//don't retain othewise it'll introduce a cyclic dependency and it'll leak.
    if (downScreen)
        downScreen->upScreen = nil;

    downScreen = aScreen;

    if (aScreen)
        aScreen->upScreen = self;
}

-(SPScreenEntry *)leftScreen
{
    return leftScreen;
}

-(void)setLeftScreen:(SPScreenEntry *)aScreen
{
//don't retain othewise it'll introduce a cyclic dependency and it'll leak.
    if (leftScreen)
        leftScreen->rightScreen = nil;
        
    leftScreen = aScreen;

    if (aScreen)
        aScreen->rightScreen = self;
}

-(SPScreenEntry *)rightScreen
{
    return rightScreen;
}

-(void)setRightScreen:(SPScreenEntry *)aScreen
{
//don't retain othewise it'll introduce a cyclic dependency and it'll leak.
    if (rightScreen)
        rightScreen->leftScreen = nil;

    rightScreen = aScreen;
    
    if (aScreen)
        aScreen->leftScreen = self;
}

-(NSPoint)position
{
    return position;
}

-(void)setPosition:(NSPoint)aPosition
{
    position = aPosition;
}

-(BOOL)isHalfDuplexCapsLock
{
    NSString * value = [attributes objectForKey: SPHalfDuplexCapsLockKey];
    if (value)
    {
        if ([value isEqualToString: SPTrueStringValue])
            return YES;

        if ([value isEqualToString: SPFalseStringValue])
            return NO;
 
        NSLog( @"invalid value found for isHalfDuplexCapsLock: %@ ", value);
    }
    return NO;
}

-(void)setHalfDuplexCapsLock:(BOOL)boolValue
{
    NSString * value = nil;

    if (boolValue)
        value = SPTrueStringValue;
    else
        value = SPFalseStringValue;
        
    [attributes setObject: value forKey: SPHalfDuplexCapsLockKey];
}

-(BOOL)isHalfDuplexNumLock
{
    NSString * value = [attributes objectForKey: SPHalfDuplexNumLockKey];
    if (value)
    {
        if ([value isEqualToString: SPTrueStringValue])
            return YES;

        if ([value isEqualToString: SPFalseStringValue])
            return NO;
 
        NSLog( @"invalid value found for isHalfDuplexNumLock: %@ ", value);
    }
    return NO;
}

-(void)setHalfDuplexNumLock:(BOOL)boolValue
{
    NSString * value = nil;

    if (boolValue)
        value = SPTrueStringValue;
    else
        value = SPFalseStringValue;
        
    [attributes setObject: value forKey: SPHalfDuplexNumLockKey];
}


-(BOOL)isHalfDuplexScrollLock
{
    NSString * value = [attributes objectForKey: SPHalfDuplexScrollLockKey];
    if (value)
    {
        if ([value isEqualToString: SPTrueStringValue])
            return YES;

        if ([value isEqualToString: SPFalseStringValue])
            return NO;
 
        NSLog( @"invalid value found for isHalfDuplexScrollLock: %@ ", value);
    }
    return NO;

}

-(void)setHalfDuplexScrollLock:(BOOL)boolValue
{
    NSString * value = nil;

    if (boolValue)
        value = SPTrueStringValue;
    else
        value = SPFalseStringValue;
        
    [attributes setObject: value forKey: SPHalfDuplexScrollLockKey];
}

-(NSString *)shiftKeyMapping
{
    NSString * value = [attributes objectForKey: SPShiftKey];
    if (value == nil)
    {
        value = SPShiftKey;
    }

    return value;
}

-(void)setShiftKeyMapping: (NSString *)value
{
    [attributes setObject: value forKey: SPShiftKey];
}

-(NSString *)ctrlKeyMapping
{
    NSString * value = [attributes objectForKey: SPCtrlKey];
    if (value == nil)
    {
        value = SPCtrlKey;
    }
    return value;
}

-(void)setCtrlKeyMapping: (NSString *)value
{
    [attributes setObject: value forKey: SPCtrlKey];
}

-(NSString *)altKeyMapping
{
    NSString * value = [attributes objectForKey: SPAltKey];
    if (value == nil)
    {
        value = SPAltKey;
    }
    return value;
}

-(void)setAltKeyMapping: (NSString *)value
{
    [attributes setObject: value forKey: SPAltKey];
}

-(NSString *)metaKeyMapping
{
    NSString * value = [attributes objectForKey: SPMetaKey];
    if (value == nil)
    {
        value = SPMetaKey;
    }
    return value;
}

-(void)setMetaKeyMapping: (NSString *)value
{
    [attributes setObject: value forKey: SPMetaKey];
}

-(NSString *)superKeyMapping
{
    NSString * value = [attributes objectForKey: SPSuperKey];
    if (value == nil)
    {
        value = SPSuperKey;
    }
    return value;
}

-(void)setSuperKeyMapping: (NSString *)value
{
    [attributes setObject: value forKey: SPSuperKey];
}

@end
