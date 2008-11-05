//
//  SPScreenOptionsController.mm
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

#import "SPScreenOptionsController.h"
#import "SPScreenEntry.h"

@implementation SPScreenOptionsController

enum eKeymapPopupValues
{
    kShift = 0,
    kControl,
    kOption,
    kCommand,
    kMeta,
    kNone,
} ;

-(NSString *)keyStringFromTag: (int)tag
{
    NSString * result = nil;
    
    switch((eKeymapPopupValues)tag)
    {
        case kShift:
            result = SPShiftKey;
            break;
        case kControl:
            result = SPCtrlKey;
            break;
        case kOption:
            result = SPSuperKey;
            break;
        case kCommand:
            result = SPAltKey;
            break;
        case kMeta:
            result = SPMetaKey;
            break;
        case kNone:
            result = SPNoneKey;
            break;
    }
    
    return result;
}

-(int)tagFromKeyString: (NSString *)string
{
    if([string isEqualToString: SPShiftKey])
        return kShift;
    if([string isEqualToString: SPCtrlKey])
        return kControl;
    if([string isEqualToString: SPSuperKey])
        return kOption;
    if([string isEqualToString: SPAltKey])
        return kCommand;
    if([string isEqualToString: SPMetaKey])
        return kMeta;
    if([string isEqualToString: SPNoneKey])
        return kNone;
    
    return kNone;
}

-(void)selectedEntryChanged
{
    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    NSString * format = NSLocalizedStringFromTableInBundle( @"Screen Options for: %@", nil, thisBundle, @"");

    [screenNameLabel setStringValue: [NSString stringWithFormat: format, [entry name]]];
    
    if ([entry isHalfDuplexCapsLock])
        [capsLockBtn setState: NSOnState];
    else
        [capsLockBtn setState: NSOffState];

    if ([entry isHalfDuplexNumLock])
        [numLockBtn setState: NSOnState];
    else
        [numLockBtn setState: NSOffState];

    if ([entry isHalfDuplexScrollLock])
        [scrollLockBtn setState: NSOnState];
    else
        [scrollLockBtn setState: NSOffState];

    int tag = [self tagFromKeyString: [entry shiftKeyMapping]];
    int index = [shiftPopupBtn indexOfItemWithTag: tag];
    [shiftPopupBtn selectItemAtIndex: index];

    tag = [self tagFromKeyString: [entry ctrlKeyMapping]];
    index = [controlPopupBtn indexOfItemWithTag: tag];
    [controlPopupBtn selectItemAtIndex: index];

    tag = [self tagFromKeyString: [entry altKeyMapping]];
    index = [commandPopupBtn indexOfItemWithTag: tag];
    [commandPopupBtn selectItemAtIndex: index];

    tag = [self tagFromKeyString: [entry superKeyMapping]];
    index = [optionPopupBtn indexOfItemWithTag: tag];
    [optionPopupBtn selectItemAtIndex: index];
}


-(IBAction)ok:(id)sender
{
    [entry setHalfDuplexCapsLock: [capsLockBtn state] == NSOnState];
    [entry setHalfDuplexNumLock: [numLockBtn state] == NSOnState];
    [entry setHalfDuplexScrollLock: [scrollLockBtn state] == NSOnState];

    NSString * shiftKeyString = [self keyStringFromTag: [[shiftPopupBtn selectedItem] tag]];
    NSString * controlKeyString = [self keyStringFromTag: [[controlPopupBtn selectedItem] tag]];
    NSString * optionKeyString = [self keyStringFromTag: [[optionPopupBtn selectedItem] tag]];
    NSString * commandKeyString = [self keyStringFromTag: [[commandPopupBtn selectedItem] tag]];

    [entry setShiftKeyMapping: shiftKeyString];
    [entry setCtrlKeyMapping: controlKeyString];
    [entry setAltKeyMapping: commandKeyString];
    [entry setSuperKeyMapping: optionKeyString];

    [super ok: sender];
}


@end
