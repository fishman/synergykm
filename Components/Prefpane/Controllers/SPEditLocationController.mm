//
//  SPEditLocationController.mm
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

#import "SPEditLocationController.h"

#import "SPConfigurationManager.h"
#import "SPConfigEntry.h"

#import "SynergyPane.h"

@interface SPEditLocationController (Private)
-(void)updateButton;
-(void)reload;
-(void)syncSelection;
@end

@implementation SPEditLocationController

-(void)reset
{
    selectedConfig = nil;
    changed = NO;
}

-(void)reload
{
    [tableView reloadData];
    [self syncSelection];
}

#pragma mark - Accessors -

-(NSArray*)configEntries
{
    SPConfigurationManager * configManager = [synergyPane configManager];
    return [configManager configEntries];
}

-(NSWindow *)window
{
    return window;
}


-(SPConfigEntry*)configEntryAtIndex:(unsigned int)index
{
    NSArray * configEntries = [self configEntries];
    SPConfigEntry * configEntry = [configEntries objectAtIndex: index];

    return configEntry;
}

-(SPConfigEntry*)currentConfigEntry
{
    return selectedConfig;
    
}

-(void)syncSelection
{
    unsigned int index = [[self configEntries] indexOfObject: selectedConfig];

    [tableView selectRow: index byExtendingSelection: NO];
}

#pragma mark - NSTableView Delegate & DataSource -

- (id)              tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
                          row: (int) rowIndex
{
    NSArray * configEntries = [self configEntries];
    SPConfigEntry * config = [configEntries objectAtIndex: rowIndex];
    return [config name];
}

- (void) tableView: (NSTableView *) aTableView
    setObjectValue: anObject
    forTableColumn: (NSTableColumn *) aTableColumn
               row: (int) rowIndex
{

    SPConfigEntry * configEntry = [self configEntryAtIndex: rowIndex];
    if (! [[configEntry name] isEqualToString: anObject])
    {
        SPConfigurationManager * configManager = [synergyPane configManager];
        if ([configManager existsConfigWithName: anObject])
        {
            NSBeep();
            [self renameLocation: nil];
            return;
        }
        
        [configEntry setName: anObject];
        changed = YES;
        [self reload];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    [self updateButton];

    return [[self configEntries] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    int index = [tableView selectedRow];
        
    if (index != -1)
        selectedConfig = [self configEntryAtIndex: index];
    else
        selectedConfig = nil;
    
    [self updateButton];
}

#pragma mark - Button update - 

-(void)updateButton
{
    [duplicateBtn setEnabled: selectedConfig != nil];
    [renameBtn setEnabled: selectedConfig != nil];
    [deleteBtn setEnabled: selectedConfig != nil];
}


#pragma mark - IBActions -

-(IBAction)duplicateLocation:(id)sender
{
    SPConfigEntry * configEntry = [self currentConfigEntry];
    
    SPConfigurationManager * configManager = [synergyPane configManager];
    SPConfigEntry * duplicatedSet = [configManager duplicateConfigEntry: configEntry];
    
    selectedConfig = duplicatedSet;

    changed = YES;
    [self reload];
    
    
    [self renameLocation: nil];
}

-(IBAction)renameLocation:(id)sender
{
    int index = [tableView selectedRow];
        
    if (index != -1)
    {
        [[tableView window] makeFirstResponder: tableView];
        [tableView editColumn: 0 row: index withEvent: nil select: YES];
    }
}

-(IBAction)deleteLocation:(id)sender
{
    SPConfigEntry * configEntry = [self currentConfigEntry];
    
    SPConfigurationManager * configManager = [synergyPane configManager];
    [configManager deleteConfigEntry: configEntry];

    changed = YES;
    [self reload];
    
    selectedConfig = nil;
}

-(IBAction)ok:(id)sender
{
    int result = NSCancelButton;
    
    if (changed)
        result = NSOKButton;
    
    [window makeFirstResponder: nil];

    [NSApp endSheet: window returnCode: result];
}


@end
