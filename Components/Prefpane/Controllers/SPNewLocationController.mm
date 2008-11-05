//
//  SPNewLocationController.mm
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

#import "SPNewLocationController.h"
#import "SPConfigEntry.h"
#import "SPConfigurationManager.h"

#import "SynergyPane.h"

static NSString * defaultName = nil; 

@implementation SPNewLocationController

-(void)awakeFromNib
{
    if (defaultName == nil)
    {
        NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
        defaultName = [NSLocalizedStringFromTableInBundle( @"untitled", nil, thisBundle, @"default name of a new location") retain];
    }
}

-(void)dealloc
{
    [newLocationName release];

    [super dealloc];
}

-(NSWindow *)window
{
    return window;
}


-(void)setNewLocationName:(NSString*) name
{
    [newLocationName autorelease];
    newLocationName = [name retain];
}

-(NSString*)newLocationName
{
    return newLocationName;
}

-(void)reset
{
    unsigned int index = 1;
    
    NSString * newName = defaultName;
    
    SPConfigurationManager * configManager = [synergyPane configManager];
    
    while ([configManager existsConfigWithName: newName])
    {
        newName = [NSString stringWithFormat: @"%@ %d", defaultName, index];
        ++index;
    } 

    [nameField setStringValue: newName];
    [errorField setStringValue: @""];
    [self setNewLocationName: @""];
}


-(IBAction)ok:(id)sender
{
    SPConfigurationManager * configManager = [synergyPane configManager];
    BOOL notUnique = [configManager existsConfigWithName: [nameField stringValue]];
    
    if (notUnique)
    {
        NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
        NSString * errorString = NSLocalizedStringFromTableInBundle( @"There is already a location with the same name. Please pick another one.", nil, thisBundle, @"");
        [errorField setStringValue: errorString];
    }
    else
    {
        [self setNewLocationName: [nameField stringValue]];
        [errorField setStringValue: @""];

        [NSApp endSheet: window returnCode: NSOKButton];
    }
}

-(IBAction)cancel:(id)sender
{
    [self setNewLocationName: @""];
    [NSApp endSheet: window returnCode: NSCancelButton];
}


@end
