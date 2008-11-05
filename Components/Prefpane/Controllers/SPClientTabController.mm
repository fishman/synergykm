//
//  SPClientTabController.mm
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

#import "SPClientTabController.h"
#import "SPConfigurationManager.h"
#import "SynergyPane.h"
#import "SPConfigEntry.h"

#import <SystemConfiguration/SystemConfiguration.h>

@interface SPClientTabController (Private)

-(void)updateClientTab;

@end


@implementation SPClientTabController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [clientPane release];
    [super dealloc];
}

-(void)awakeFromNib
{
    [clientPane retain];
    superview = [clientPane superview];

    [self updateClientTab];

    [[NSNotificationCenter defaultCenter]
                   addObserver: self 
                      selector: @selector(activeConfigSetChanged:)
                          name: ActiveConfigChanged
                        object: nil];
    
}

-(void)updateClientTab
{
    SPConfigEntry * activeConfig = [[synergyPane configManager] activeConfig];
    
    if (activeConfig)
    {
        [serverAddressField setStringValue: [activeConfig address]];
    }
    else
    {
        [serverAddressField setStringValue: @""];
    }

    [serverAddressField setEnabled: activeConfig != nil];
    
    NSString * localHostName = nil;
    localHostName = (NSString *)SCDynamicStoreCopyLocalHostName( NULL );
    
    [screenNameField setStringValue: localHostName];

    [localHostName release];

}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    id object = [aNotification object];
    
    if (object == serverAddressField)
    {
        [self serverAddressChanged: serverAddressField];
    }
}

-(IBAction)serverAddressChanged:(id)sender
{
    SPConfigEntry * activeConfig = [[synergyPane configManager] activeConfig];
    
    //Todo validate
    
    [activeConfig setAddress: [sender stringValue]];

    [[synergyPane configManager] setDirty: YES];
}

-(void)activeConfigSetChanged:(NSNotification*)notif
{
    [self updateClientTab];
}

-(void)configurationTypeChanged
{
    SPConfigEntry * activeConfig = [[synergyPane configManager] activeConfig];
    BOOL isServerConfig = [activeConfig isServerConfig];

    if (isServerConfig)
        [clientPane removeFromSuperview];
    else
    {
        if ([clientPane superview] != superview)
            [superview addSubview: clientPane];
    }

    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    
    if (!isServerConfig)
    {
        [configurationTab setLabel: NSLocalizedStringFromTableInBundle(@"Client Configuration", nil, thisBundle, @"")];
    }
}



@end
