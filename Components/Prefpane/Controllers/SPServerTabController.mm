//
//  SPServerTabController.mm
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

#import "SPServerTabController.h"
#import "SPConfigurationManager.h"
#import "SynergyPane.h"
#import "SPConfigEntry.h"
#import "SPScreenView.h"
#import "SPScreenEntry.h"
#import "SPAliasesListController.h"
#import "SPScreenOptionsController.h"
#import "SPServerOptionsController.h"

#import <vector>
#import <list>
#import <algorithm>

static unsigned int NbrOfPointsThatAreNeighbours( std::vector<NSPoint> & newPositions );

@interface SPServerTabController (Private)
-(void)updateServerTab;
-(void)selectionChanged;
@end

@implementation SPServerTabController

-(void)dealloc
{
    delete[] cachedPositions;

    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [serverPane release];
    [super dealloc];
}

-(void)awakeFromNib
{
    [serverPane retain];
    superview = [serverPane superview];

    [self updateServerTab];

    [[NSNotificationCenter defaultCenter]
                   addObserver: self 
                      selector: @selector(activeConfigSetChanged:)
                          name: ActiveConfigChanged
                        object: nil];
    
}

-(SPConfigEntry *)activeConfig
{
    return [[synergyPane configManager] activeConfig];
}

-(NSArray *)screens
{
    return [[self activeConfig] screens];
}

-(void)updateServerTab
{
    [screenView reload];
    [screenView setSelectionIndex: NSNotFound];
}

-(void)configurationTypeChanged
{
    BOOL isServerConfig = [[self activeConfig] isServerConfig];

    if (!isServerConfig)
        [serverPane removeFromSuperview];
    else
        [superview addSubview: serverPane];

    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    
    if (isServerConfig)
    {
        [configurationTab setLabel: NSLocalizedStringFromTableInBundle(@"Server Configuration", nil, thisBundle, @"")];
    }
    
    [self updateServerTab];
}

-(void)activeConfigSetChanged:(NSNotification*)notif
{
    [self updateServerTab];
}

-(SPScreenEntry*)selectedScreen
{
    SPScreenEntry * result = nil;
    
    if (selectedIndex != NSNotFound)
    {
        NSArray * screens = [self screens];
        result = [screens objectAtIndex: selectedIndex];
    }
    
    return result;
}

-(IBAction)add:(id)sender
{
    SPConfigEntry * activeConfig = [self activeConfig];
    SPScreenEntry * newScreen = [activeConfig createScreen];
    //Todo: select the new screen & give a default name

    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    NSString * newName = NSLocalizedStringFromTableInBundle(@"New Screen", nil, thisBundle, @"");
    NSString * baseName = newName;

    unsigned int index = 1;
    NSEnumerator * iter = [[activeConfig screens] objectEnumerator];
    while( SPScreenEntry * entry = [iter nextObject] )
    {
        if ([[entry name] isEqualToString: newName])
        {
            iter = [[activeConfig screens] objectEnumerator];
            newName = [NSString stringWithFormat: @"%@ %u", baseName, index];
            
            ++index;
        }
    }

    [newScreen setName: newName];
    [screenView reload];

    index = [[activeConfig screens] indexOfObject: newScreen];
    
    [screenView setSelectionIndex: index];

    [[synergyPane configManager] setDirty: YES];

}

-(BOOL)canRemove
{
    SPScreenEntry * selectedScreen = [self selectedScreen];
    
    BOOL enabled = (selectedScreen != nil);

    if (enabled)
    {
        NSArray * screens = [self screens];
        
        unsigned int screenCount = [screens count];
        
        if (screenCount < 3)
            return YES;

        //Build a list of all the positions
        //except the one we are removing
        std::vector<NSPoint> newPositions; 

        NSEnumerator * iter = [screens objectEnumerator];
        while ( SPScreenEntry * screen = [iter nextObject] )
        {
            if (screen == selectedScreen)
            {
                continue;
            }

            NSPoint screenPosition = [screen position];
            newPositions.push_back(screenPosition);
        }

        //If all the remaining points are neighbours then we can remove
        //this screen.
        enabled = NbrOfPointsThatAreNeighbours( newPositions ) == (screenCount -1);
    }

    return enabled;
}

-(IBAction)remove:(id)sender
{
    [[self activeConfig] removeScreen: [self selectedScreen]];
    [screenView reload];
}

-(void)selectionChanged
{
    SPScreenEntry * selectedScreen = [self selectedScreen];
    
    BOOL enabled = (selectedScreen != nil);
    
    [aliasesBtn setEnabled: enabled];
    [modifiersBtn setEnabled: enabled];
    [optionsBtn setEnabled: YES];
    [removeBtn setEnabled: [self canRemove]];
    [screenNameField setEnabled: enabled];
    [screenNameLabel setEnabled: enabled];

    if (selectedScreen)
        [screenNameField setStringValue: [selectedScreen name]];
    else
        [screenNameField setStringValue: @""];
}

-(IBAction)aliases:(id)sender
{
    [aliasListController setEntry: [self selectedScreen]];

    [NSApp beginSheet: [aliasListController window]
       modalForWindow: [[synergyPane mainView] window]
        modalDelegate: self
       didEndSelector: @selector(onAliasSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)onAliasSheetDidEnd: (NSWindow *) sheet
                returnCode: (int) returnCode 
                contextInfo: (void*) contextInfo
{
    if (returnCode == NSOKButton)
    {
        [[synergyPane configManager] setDirty: YES];
    }

    [sheet orderOut: nil];
}  

-(IBAction)screenOptions:(id)sender
{
    [screenOptionsController setEntry: [self selectedScreen]];

    [NSApp beginSheet: [screenOptionsController window]
       modalForWindow: [[synergyPane mainView] window]
        modalDelegate: self
       didEndSelector: @selector(onScreenOptionSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)onScreenOptionSheetDidEnd: (NSWindow *) sheet
                       returnCode: (int) returnCode 
                      contextInfo: (void*) contextInfo
{
    if (returnCode == NSOKButton)
    {
        [[synergyPane configManager] setDirty: YES];
    }

    [sheet orderOut: nil];
}  

-(IBAction)serverOptions:(id)sender
{
    [serverOptionsController setEntry: [self activeConfig]];

    [NSApp beginSheet: [serverOptionsController window]
       modalForWindow: [[synergyPane mainView] window]
        modalDelegate: self
       didEndSelector: @selector(onServerOptionSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)onServerOptionSheetDidEnd: (NSWindow *) sheet
                       returnCode: (int) returnCode 
                      contextInfo: (void*) contextInfo
{
    if (returnCode == NSOKButton)
    {
        [[synergyPane configManager] setDirty: YES];
    }

    [sheet orderOut: nil];
}  


#pragma mark - Text field callbacks -

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    id object = [aNotification object];
    
    if (object == screenNameField)
    {
        NSString * screenName = [screenNameField stringValue];
        SPScreenEntry * selectedScreen = [self selectedScreen];
        [selectedScreen setName: screenName];
        [screenView reload];
        [[synergyPane configManager] setDirty: YES];
    }
}

#pragma mark - Screen View callbacks - 

-(unsigned int)SPScreenViewNumberOfScreens:(SPScreenView*)screenView
{
    NSArray * screens = [self screens];

    return [screens count];
}

-(NSString *)SPScreenView:(SPScreenView*)screenView nameOfScreenAtIndex:(unsigned int)index
{
    NSArray * screens = [self screens];

    return [[screens objectAtIndex: index] name];
}

-(NSPoint)SPScreenView:(SPScreenView*)screenView positionOfScreenAtIndex:(unsigned int)index
{
    NSArray * screens = [self screens];

    return [[screens objectAtIndex: index] position];
}

//(needed for std::find...)
static bool operator==(const NSPoint & pointA, const NSPoint & pointB)
{
    return NSEqualPoints( pointA, pointB);
}

static bool PointsAreNeighbours(const NSPoint & pointA, const NSPoint & pointB)
{
    if (pointA.x == pointB.x)
    {
        if ( (pointA.y + 1.0f) != pointB.y
            && (pointA.y - 1.0f) != pointB.y)
        {
            return NO;
        }
    }
    else if (pointA.y == pointB.y)
    {
        if ( (pointA.x + 1.0f) != pointB.x
            && (pointA.x - 1.0f) != pointB.x)
        {
            return NO;
        }
    }
    else
        return NO;

    return YES;
}

static unsigned int NbrOfPointsThatAreNeighbours( std::vector<NSPoint> & newPositions )
{
    std::list<NSPoint> toBeProcessed;
    std::list<NSPoint> processed;
    
    toBeProcessed.push_back( newPositions.front() );
    
    while ( !toBeProcessed.empty() )
    {
        NSPoint currentPoint = toBeProcessed.front();
        
        std::vector<NSPoint>::const_iterator iter = newPositions.begin();
        
        for (; iter != newPositions.end(); ++iter)
        {
            NSPoint neighbour = *iter;

            if( PointsAreNeighbours(neighbour, currentPoint ) == NO)
                continue;
        
            if (   (std::find( toBeProcessed.begin() , toBeProcessed.end(), *iter) == toBeProcessed.end())
                && (std::find( processed.begin() , processed.end(), *iter) == processed.end()))
            {
                toBeProcessed.push_back(*iter);
            }
        }
        
        toBeProcessed.pop_front();
        processed.push_back(currentPoint);
    }

    //If the processed count is the same as the number of screen count
    //then every screen are reachable will this change
    return( processed.size() );

}

-(BOOL)SPScreenView:(SPScreenView*)screenView datasourceShouldChangePositionTo: (NSPoint)point atIndex:(unsigned int)index;
{
    NSArray * screens = [self screens];

    SPScreenEntry * movingScreen = [screens objectAtIndex: index];
    
    //Don't waste time on noops
    if (NSEqualPoints( [movingScreen position], point))
        return NO;

    
    unsigned int screenCount = [screens count];
    
    //No point in moving a screen if it is alone.
    if (screenCount < 2)
        return NO;

    //Make sure there is no other screen at the destination
    //and build the new array of positions for the next step
    std::vector<NSPoint> newPositions; 

    BOOL result = YES;
    
    NSEnumerator * iter = [screens objectEnumerator];
    while ( SPScreenEntry * screen = [iter nextObject] )
    {
        if (screen == movingScreen)
        {
            newPositions.push_back( point );
            continue;
        }

        NSPoint screenPosition = [screen position];
        newPositions.push_back(screenPosition);
        
        //can't have 2 screen at the same pos.
        if (NSEqualPoints( screenPosition, point))
        {
            result = NO;
            break;
        }
    }

    //The last test is to make sure every screen can be reached from
    //the first object.
    if (result)
    {
        result = NbrOfPointsThatAreNeighbours( newPositions ) == screenCount;
    }

    return result;
}

-(void)SPScreenView:(SPScreenView*)screenView positionChanged: (NSPoint)newPosition atIndex:(unsigned int)index
{
    NSArray * screens = [self screens];
    SPScreenEntry * movingScreen = [screens objectAtIndex: index];
    
    //disconnect from the previous neighbours
    [movingScreen setUpScreen: nil];
    [movingScreen setDownScreen: nil];
    [movingScreen setLeftScreen: nil];
    [movingScreen setRightScreen: nil];
    
    //set the position so it will display at the right spot.
    [movingScreen setPosition: newPosition];

    //setup the new neighbourhood.
    NSEnumerator * iter = [screens objectEnumerator];
    while ( SPScreenEntry * screen = [iter nextObject] )
    {
        if (screen == movingScreen)
            continue;
        
        NSPoint neighbourPosition = [screen position];
        
        if (PointsAreNeighbours( newPosition, neighbourPosition))
        {
            if(newPosition.x == neighbourPosition.x)
            {
                if (newPosition.y > neighbourPosition.y)
                    [movingScreen setDownScreen: screen];
                else
                    [movingScreen setUpScreen: screen];
            }
            else if(newPosition.y == neighbourPosition.y)
            {
                if (newPosition.x > neighbourPosition.x)
                    [movingScreen setLeftScreen: screen];
                else
                    [movingScreen setRightScreen: screen];
            }
        }
    }
    [[synergyPane configManager] setDirty: YES];
}

-(void)SPScreenView:(SPScreenView*)screenView selectionIndexChangedTo:(unsigned int)index
{
    selectedIndex = index;
    [self selectionChanged];
}

@end
