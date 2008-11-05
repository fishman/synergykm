//
//  SDUtilities.m
//  synergyd
//
//Copyright (c) 2005, Lorenz Schori <lo@znerol.ch>
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
//	¥ 	Neither the name of the Lorenz Schori nor the names of its 
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

#import "SDUtilities.h"
void SDWriteValue(id inValue, NSString* inKey, NSMutableString* inString, int inLevel);

BOOL SDWriteSynergyConfig(NSDictionary* config, NSString* path)
{
	NSMutableString *configString = [NSMutableString stringWithString:@"# Generated automatically by Synergy Daemon\n"];
	
	// write screen section:
	NSDictionary *screens = [config objectForKey:@"screens"];
	if(screens) {
		[configString appendString:@"section: screens\n"];
		NSDictionary* dict = screens;
		NSEnumerator* keys = [dict keyEnumerator];
		
		NSString* key;
		while(key = [keys nextObject]) {
			SDWriteValue([dict objectForKey:key], key, configString, 1);
		}
		[configString appendString:@"end\n\n"];
	}
	
	// write alias section:
	NSDictionary *aliases = [config objectForKey:@"aliases"];
	if(aliases) {
		[configString appendString:@"section: aliases\n"];
		NSDictionary* dict = aliases;
		NSEnumerator* keys = [dict keyEnumerator];
		
		NSString* key;
		while(key = [keys nextObject]) {
			SDWriteValue([dict objectForKey:key], key, configString, 1);
		}
		[configString appendString:@"end\n\n"];
	}
	
	// write links section:
	NSDictionary *links = [config objectForKey:@"links"];
	if(links) {
		[configString appendString:@"section: links\n"];
		NSDictionary* dict = links;
		NSEnumerator* keys = [dict keyEnumerator];
		
		NSString* key;
		while(key = [keys nextObject]) {
			SDWriteValue([dict objectForKey:key], key, configString, 1);
		}
		[configString appendString:@"end\n\n"];
	}
	
	// write options section:
	NSDictionary *options = [config objectForKey:@"options"];
	if(options) {
		[configString appendString:@"section: options\n"];
		NSDictionary* dict = options;
		NSEnumerator* keys = [dict keyEnumerator];
		
		NSString* key;
		while(key = [keys nextObject]) {
			SDWriteValue([dict objectForKey:key], key, configString, 1);
		}
		[configString appendString:@"end\n\n"];
	}
	
	// write out to configuration file
	return [configString writeToFile:path atomically:NO];
}

void SDWriteValue(id inValue, NSString* inKey, NSMutableString* inString, int inLevel)
{
	int i;
	BOOL hasKey = (inKey && ![inKey isEqualToString:@""]);
	
	// indent
	for(i=0; i<inLevel; i++)
		[inString appendString:@"\t"];
	
	// write key
	if(hasKey)
		[inString appendString:inKey];
	
	// write value
	if([inValue isKindOfClass:[NSDictionary class]]) {
		// write dictionary
		[inString appendString:@":\n"];
		NSDictionary* dict = (NSDictionary*)inValue;
		NSEnumerator* keys = [dict keyEnumerator];
		
		NSString* key;
		while(key = [keys nextObject]) {
			SDWriteValue([dict objectForKey:key], key, inString, inLevel + 1);
		}
	} else if([inValue isKindOfClass:[NSArray class]]) {
		// write array
		[inString appendString:@":\n"];
		NSArray* list = (NSArray*)inValue;
		NSEnumerator* vals = [list objectEnumerator];
		
		id value;
		while(value = [vals nextObject]) {
			SDWriteValue(value, nil, inString, inLevel + 1);
		}
	} else if([inValue isKindOfClass:[NSString class]]) {
		// write string
		if(inValue && ![inValue isEqualToString:@""]) {
			if(hasKey) {
				[inString appendFormat:@" = %@\n", inValue];
			} else {
				[inString appendFormat:@"%@\n", inValue];
			}
		} else {
			[inString appendString:@":\n"];
		}
	} else if([inValue respondsToSelector:@selector(stringValue)]) {
		// write other value
		NSString*	sval = [inValue stringValue];
		if(inValue && ![sval isEqualToString:@""]) {
			if(hasKey) {
				[inString appendFormat:@" = %@\n", sval];
			} else {
				[inString appendFormat:@"%@\n", sval];
			}
		} else {
			[inString appendString:@":\n"];
		}
	} else {
		// FIXME: ERROR HANDLING HERE
	}
}