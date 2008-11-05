//
//  SPProcessInfoAdditions.m
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

#import "SPProcessInfoAdditions.h"


@implementation NSProcessInfo ( SPProcessInfoAdditions )

+(SPOperatingSystemVersion)operatingSystemVersion
{
    static SPOperatingSystemVersion operatingSystemVersion = SPVersionNotChecked;

    if (operatingSystemVersion == SPVersionNotChecked)
    {
        long response = 0L;
        
        if (Gestalt( gestaltSystemVersion, &response) != noErr)
        {
            [NSException raise:@"Gestalt Exception" format:@"gestaltSystemVersion failed"];
        }
        if ( response < 0x1000) 
        {
            operatingSystemVersion = SPPreCheetahVersion;
        }
        else if (response >= 0x1050)
        {
            operatingSystemVersion = SPUnknownNewerVersion;
        }
        else if (response >= 0x1040) 
        {
            operatingSystemVersion = SPTigerVersion;
        }
        else if (response >= 0x1030) 
        {
            operatingSystemVersion = SPPantherVersion;
        }
        else if (response >= 0x1020) 
        {
            operatingSystemVersion = SPJaguarVersion;
        }
        else if (response >= 0x1010) 
        {
            operatingSystemVersion = SPPumaVersion;
        }
        else if (response >= 0x1000) 
        {
            operatingSystemVersion = SPCheetahVersion;
        }
    }

    return operatingSystemVersion;
}

@end
