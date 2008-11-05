//
//  SPAliasesListController.mm
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

#import "SPAliasesListController.h"
#import "SPScreenEntry.h"

#include <unistd.h>

@interface SPAliasesListController(Private)
-(void)updateButton;
@end

@implementation SPAliasesListController

-(void)dealloc
{
    [aliases release];
    [super dealloc];
}

-(void)selectedEntryChanged
{
    NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
    NSString * format = NSLocalizedStringFromTableInBundle( @"Aliases for: %@", nil, thisBundle, @"");

    [screenNameLabel setStringValue: [NSString stringWithFormat: format, [entry name]]];
    
    [aliases release];
    aliases = [[entry aliases] mutableCopy];

//    if ([aliases respondsToSelector: @selector(sortUsingDescriptors:)])
//    {
//        [aliases sortUsingDescriptors: [tableView sortDescriptors]];
//    }

    [tableView reloadData];
    [tableView deselectAll: nil];

    [self updateButton];
}

-(NSWindow*)window
{
    return window;
}

-(IBAction)addAlias:(id)sender
{
    NSString * name = [NSString stringWithString: [entry name]];
    [aliases addObject: name];
//    if ([aliases respondsToSelector: @selector(sortUsingDescriptors:)])
//    {
//        [aliases sortUsingDescriptors: [tableView sortDescriptors]];
//    }
    
    int index = [aliases indexOfObject: name];
    [tableView reloadData];
    [tableView selectRow:  index byExtendingSelection: NO];

    [[tableView window] makeFirstResponder: tableView];
    [tableView editColumn: 0 row: index withEvent: nil select: YES];

}

-(IBAction)deleteAlias:(id)sender
{
    int index = [tableView selectedRow];
    if (index != -1)
    {
        [aliases removeObjectAtIndex: index];
    }
    [tableView reloadData];
}

-(IBAction)ok:(id)sender
{
    [[entry aliases] removeAllObjects];
    
    [[entry aliases] addObjectsFromArray: aliases];

    [super ok: sender];
}

-(void)updateButton
{
    int index = [tableView selectedRow];
    
    [deleteAliasBtn setEnabled: index != -1];
}

#pragma mark - NSTableView Delegate & DataSource -

- (id)              tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
                          row: (int) rowIndex
{
    return [aliases objectAtIndex: rowIndex];
}

- (void) tableView: (NSTableView *) aTableView
    setObjectValue: anObject
    forTableColumn: (NSTableColumn *) aTableColumn
               row: (int) rowIndex
{
    [aliases replaceObjectAtIndex: rowIndex withObject: anObject];
//    if ([aliases respondsToSelector: @selector(sortUsingDescriptors:)])
//    {
//        [aliases sortUsingDescriptors: [tableView sortDescriptors]];
//    }
    [tableView reloadData];
    int row = [aliases indexOfObject: anObject];
    [tableView selectRow: row byExtendingSelection: NO];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [aliases count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self updateButton];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    int row = [tableView selectedRow];
    id object = [aliases objectAtIndex: row];
    
//    if ([aliases respondsToSelector: @selector(sortUsingDescriptors:)])
//    {
//        [aliases sortUsingDescriptors: [tableView sortDescriptors]];
//    }
    
    [tableView reloadData];

    row = [aliases indexOfObject: object];
    [tableView selectRow: row byExtendingSelection: NO];
}

@end
