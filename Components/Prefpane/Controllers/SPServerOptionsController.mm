//
// SPServerOptionsController.mm
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


#import "SPServerOptionsController.h"
#import "SPConfigEntry.h"

@implementation SPServerOptionsController

-(IBAction)switchAfterDelayBtnChanged:(id)sender
{
    [switchAfterDelayTextField setEnabled:
        [switchAfterDelayBtn state] == NSOnState];
}

-(IBAction)switchOnDoubleTapBtnChanged:(id)sender
{
    [switchOnDoubleTapTextField setEnabled:
        [switchOnDoubleTapBtn state] == NSOnState];
}

-(IBAction)enableClientChecksBtnChanged:(id)sender
{
    [enableClientChecksTextField setEnabled:
        [enableClientChecksBtn state] == NSOnState];
}

-(void)selectedEntryChanged
{
    if ([entry isSwitchDelayEnabled])
        [switchAfterDelayBtn setState: NSOnState];
    else
        [switchAfterDelayBtn setState: NSOffState];
    
    if ([entry isSwitchDoubleTapEnabled])
        [switchOnDoubleTapBtn setState: NSOnState];
    else
        [switchOnDoubleTapBtn setState: NSOffState];
    
    if ([entry isHeartbeatEnabled])
        [enableClientChecksBtn setState: NSOnState];
    else
        [enableClientChecksBtn setState: NSOffState];

    if ([entry screenSaverSync])
        [synchronizeScreenSavers setState: NSOnState];
    else
        [synchronizeScreenSavers setState: NSOffState];

    if ([entry relativeMouseMoves])
        [useRelativeMouseMoves setState: NSOnState];
    else
        [useRelativeMouseMoves setState: NSOffState];
    
    [switchAfterDelayTextField setEnabled:
        [switchAfterDelayBtn state] == NSOnState];

    [switchAfterDelayTextField setObjectValue: 
        [NSNumber numberWithUnsignedInt: [entry switchDelay]]];

    [switchOnDoubleTapTextField setEnabled:
        [switchOnDoubleTapBtn state] == NSOnState];

    [switchOnDoubleTapTextField setObjectValue: 
        [NSNumber numberWithUnsignedInt: [entry switchDoubleTap]]];

    [enableClientChecksTextField setEnabled:
        [enableClientChecksBtn state] == NSOnState];

    [enableClientChecksTextField setObjectValue: 
        [NSNumber numberWithUnsignedInt: [entry heartbeat]]];
    
}

-(void)setEntry:(SPConfigEntry *)newEntry
{
    entry = newEntry;
    [self selectedEntryChanged];
}

-(IBAction)ok:(id)sender
{
    [entry setSwitchDelayEnabled: [switchAfterDelayBtn state] == NSOnState];
    [entry setSwitchDelay: [switchAfterDelayTextField intValue]];

    [entry setSwitchDoubleTapEnabled: [switchOnDoubleTapBtn state] == NSOnState];
    [entry setSwitchDoubleTap: [switchOnDoubleTapTextField intValue]];

    [entry setHeartbeatEnabled: [enableClientChecksBtn state] == NSOnState];
    [entry setHeartbeat: [enableClientChecksTextField intValue]];

    [entry setScreenSaverSync: [synchronizeScreenSavers state] == NSOnState];
    [entry setRelativeMouseMoves: [useRelativeMouseMoves state] == NSOnState];

    [super ok: sender];
}


@end
