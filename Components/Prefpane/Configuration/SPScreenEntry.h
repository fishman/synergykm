//
//  SPScreenEntry.h
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


extern NSString * const SPShiftKey;
extern NSString * const SPCtrlKey;
extern NSString * const SPAltKey;
extern NSString * const SPMetaKey;
extern NSString * const SPSuperKey;
extern NSString * const SPNoneKey;


@interface SPScreenEntry : NSObject 
{
    NSString * name;
    
    NSMutableArray * aliases;

    NSMutableDictionary * attributes;
    
    SPScreenEntry * upScreen;
    SPScreenEntry * downScreen;
    SPScreenEntry * leftScreen;
    SPScreenEntry * rightScreen;
    
    ///This is the position of this screen in Cartesian coordinates.
    ///It makes it easier to display, but we should not save it to disk
    ///since the up,down,left,right attributes are there to persist the position.
    NSPoint position;
    
}

-(NSString *)name;
-(void)setName:(NSString *)newName;
    
-(NSMutableArray *)aliases;

-(NSMutableDictionary *)attributes;
    
-(SPScreenEntry *)upScreen;
-(void)setUpScreen:(SPScreenEntry *)aScreen;

-(SPScreenEntry *)downScreen;
-(void)setDownScreen:(SPScreenEntry *)aScreen;

-(SPScreenEntry *)leftScreen;
-(void)setLeftScreen:(SPScreenEntry *)aScreen;

-(SPScreenEntry *)rightScreen;
-(void)setRightScreen:(SPScreenEntry *)aScreen;

-(NSPoint)position;
-(void)setPosition:(NSPoint)aPosition;

-(BOOL)isHalfDuplexCapsLock;
-(void)setHalfDuplexCapsLock:(BOOL)value;

-(BOOL)isHalfDuplexNumLock;
-(void)setHalfDuplexNumLock:(BOOL)value;

-(BOOL)isHalfDuplexScrollLock;
-(void)setHalfDuplexScrollLock:(BOOL)value;

-(NSString *)shiftKeyMapping;
-(void)setShiftKeyMapping: (NSString *)value;

-(NSString *)ctrlKeyMapping;
-(void)setCtrlKeyMapping: (NSString *)value;

-(NSString *)altKeyMapping;
-(void)setAltKeyMapping: (NSString *)value;

-(NSString *)metaKeyMapping;
-(void)setMetaKeyMapping: (NSString *)value;

-(NSString *)superKeyMapping;
-(void)setSuperKeyMapping: (NSString *)value;

@end
