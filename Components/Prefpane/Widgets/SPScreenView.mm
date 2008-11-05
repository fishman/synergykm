//
//  SPScreenView.mm
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

#import "SPScreenView.h"
#import "SPBezierPath+RoundRect.h"

#import <algorithm>
#import <cmath>

@interface SPScreenView (Private)

-(unsigned int)datasourceNumberOfScreen;

-(NSString *)datasourceNameOfScreenAtIndex:(unsigned int)index;

-(NSPoint)datasourcePositionOfScreenAtIndex:(unsigned int)index;

-(void)recalcLayout;

-(void)datasourceSelectionIndexChangedTo:(unsigned int)index;

-(void)datasourcePositionChanged:(NSPoint)point atIndex:(unsigned int)index;

-(BOOL)datasourceShouldChangePositionTo:(NSPoint)point atIndex:(unsigned int)index;

@end

static const float kMaxScreenSize = 100.0f;

@implementation SPScreenView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        screens = [NSMutableArray new];
        selectionIndex = NSNotFound;
        draggedIndex = NSNotFound;
    }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)awakeFromNib
{
    [self reload];
}

-(NSRect)positionForScreen:(NSDictionary*)screen
{
    NSRect position = screenRect;
    
    position.origin = screenAreaRect.origin;
    
    position.origin.x += ([[screen objectForKey: @"x"] floatValue] - bottomLeftPoint.x) * screenRect.size.width;
    position.origin.y += ([[screen objectForKey: @"y"] floatValue] - bottomLeftPoint.y) * screenRect.size.height;
    
    return position;
}

-(NSPoint)screenPositionForPoint:(NSPoint)point
{
    NSPoint translatedPoint;
    translatedPoint.x = point.x - screenAreaRect.origin.x; 
    translatedPoint.y = point.y - screenAreaRect.origin.y;

    NSPoint result;
    
    result.x = floorf(translatedPoint.x / screenRect.size.width);
    result.y = floorf(translatedPoint.y / screenRect.size.height);
    
    result.x += bottomLeftPoint.x;
    result.y += bottomLeftPoint.y;
    
    return result;
}

-(unsigned int)screenAtPoint:(NSPoint) point
{
    unsigned int count = [screens count];
    
    for (unsigned int i = 0; i < count; ++i)
    {
        NSDictionary * screen = [screens objectAtIndex: i];
        
        NSRect position = [self positionForScreen: screen];
        
        if(NSPointInRect( point, position))
        {
            return i;
        }
    }
    
    return NSNotFound;
}

-(unsigned int)selectionIndex
{
    return selectionIndex;
}

-(void)setSelectionIndex:(unsigned int)index
{
    selectionIndex = index;
    
    [self datasourceSelectionIndexChangedTo: index];
}

#pragma mark - accessors - 

-(BOOL)isOpaque
{
    return NO;
}

#pragma mark - data - 

-(void)reload
{
    [screens removeAllObjects];

    //1 calculate min and max coordinates ( needed to calculate the drawing area)

    topRightPoint.x = -FLT_MAX;
    topRightPoint.y = -FLT_MAX;

    bottomLeftPoint.x = FLT_MAX;
    bottomLeftPoint.y = FLT_MAX;
    
    unsigned int count = [self datasourceNumberOfScreen];
    
    if (selectionIndex >= count)
        selectionIndex = NSNotFound;
    
    for(unsigned int i = 0; i < count; ++i)
    {
        //While we are at it build our local cache of screens
        
        NSString * name = [self datasourceNameOfScreenAtIndex: i];
        NSPoint pos = [self datasourcePositionOfScreenAtIndex: i];
    
        NSDictionary * entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    name, @"name",
                                    [NSNumber numberWithFloat: pos.x], @"x",
                                    [NSNumber numberWithFloat: pos.y], @"y",
                                    nil];

        [screens addObject: entry];

        topRightPoint.x = std::max(pos.x, topRightPoint.x);
        topRightPoint.y = std::max(pos.y, topRightPoint.y);

        bottomLeftPoint.x = std::min(pos.x, bottomLeftPoint.x);
        bottomLeftPoint.y = std::min(pos.y, bottomLeftPoint.y);
    }
    
    [self recalcLayout];
}



#pragma mark - drawing support -

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize: newSize];
    [self recalcLayout];
}

-(void)recalcLayout
{
    //1 calculate the size of 1 screen.
    
    NSSize screenSize = NSZeroSize;
    
    float deltaX = std::fabs((topRightPoint.x + 1) - bottomLeftPoint.x);
    float deltaY = std::fabs((topRightPoint.y + 1) - bottomLeftPoint.y);
    
    NSRect viewBounds = [self bounds];
    
    screenRect = NSZeroRect;
    
    screenRect.size.width = viewBounds.size.width / deltaX;
    screenRect.size.height = viewBounds.size.height / deltaY;
    
    screenRect.size.width = floorf(std::min(screenRect.size.width, screenRect.size.height));
    //enforce the maximum size.
    screenRect.size.width = floorf(std::min(screenRect.size.width, kMaxScreenSize));
    screenRect.size.height = screenRect.size.width;
    
    //2 calculate the bounds of all rectangles. (so we can center the screens)
    
    screenAreaRect = NSZeroRect;
    screenAreaRect.size.width = deltaX * screenRect.size.width;
    screenAreaRect.size.height = deltaY * screenRect.size.height;
    
    screenAreaRect.origin.x = floorf((viewBounds.size.width - screenAreaRect.size.width)/2.0f);
    screenAreaRect.origin.y = floorf((viewBounds.size.height - screenAreaRect.size.height)/2.0f);

    //3 force a redraw

    [self setNeedsDisplay: YES];
}

+(NSImage*)screenImage
{
    static NSImage * screenImage = nil;
    if (screenImage == nil)
    {
        NSBundle * thisBundle = [NSBundle bundleForClass: [self class]];
        NSString * imagePath = [thisBundle pathForResource: @"screen" ofType: @"tiff"];
        screenImage = [[NSImage alloc] initWithContentsOfFile: imagePath];
    }
    
    return screenImage;
}

+(NSImage*)selectedScreenImage
{
    static NSImage * selectedScreenImage = nil;
    if (selectedScreenImage == nil)
    {
        NSImage * screenImage = [SPScreenView screenImage];
        selectedScreenImage = [[NSImage alloc] initWithSize: [screenImage size]];
        
        NSRect frame = NSZeroRect;
        frame.size = [screenImage size];
        
        [selectedScreenImage lockFocus];
        
        [[NSColor clearColor] set];
        NSRectFill(frame);
        
        [screenImage compositeToPoint: NSZeroPoint operation: NSCompositeCopy];
        
        
        [[[NSColor alternateSelectedControlColor] colorWithAlphaComponent: 0.5f] set];
        NSRectFillUsingOperation(frame, NSCompositeSourceAtop);
        
        [selectedScreenImage unlockFocus];
    }
    
    return selectedScreenImage;
}


-(void)drawBackground: (NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor colorWithCalibratedWhite: 1.0f 
                                 alpha: 0.54f] set];

    NSRectFillUsingOperation( rect, NSCompositeSourceOver );

    [[NSColor colorWithCalibratedWhite: 0.5f 
                                 alpha: 1.0f] set];

    NSFrameRect( rect );

    [NSGraphicsContext restoreGraphicsState];
}

-(void)drawScreen:(NSRect) rect withName: (NSString*)name andSelected:(BOOL)isSelected andFraction:(float)fraction
{
    rect = NSInsetRect( rect, 4.0f, 4.0f);

    //1 Draw Image 
    
    NSImage * screenImage;
    if (isSelected)
        screenImage = [SPScreenView selectedScreenImage];
    else
        screenImage = [SPScreenView screenImage];
        
    NSRect imageRect = NSZeroRect;
    imageRect.size = [screenImage size];
    
    [screenImage  
        drawInRect: rect 
          fromRect: imageRect
         operation: NSCompositeSourceOver
          fraction: fraction];

    
          
    //2 Create an attributed string to display the name ( adding an ellipsis at the end )

    NSMutableParagraphStyle * parStyle 
        = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopyWithZone:nil] autorelease];

    [parStyle setLineBreakMode: NSLineBreakByTruncatingTail];
    [parStyle setAlignment: NSCenterTextAlignment];

    NSDictionary * ellipsisAttributedParagraph 
        = [NSDictionary 
            dictionaryWithObject: parStyle
                          forKey: NSParagraphStyleAttributeName];

    NSAttributedString * attributedString = 
        [[[NSAttributedString alloc] initWithString: name
                                         attributes: ellipsisAttributedParagraph] autorelease];
    
    //3 Create a small background for the string (bubble like round rect)

    rect.size.height = [attributedString size].height;
    rect = NSInsetRect( rect, -2.0f, -2.0f);

    NSBezierPath * path = [NSBezierPath bezierPath];

    [path appendBezierPathWithRoundedRectangle: rect withRadius: rect.size.height/2.0f];

    [[NSColor colorWithCalibratedWhite: 1.0f 
                                 alpha: 0.54f] set];

    [path fill];
    
    [[NSColor colorWithCalibratedWhite: 0.5f 
                                 alpha: 1.0f] set];

    [path stroke];

    //4 Draw the string

    rect = NSInsetRect( rect, 2.0f, 2.0f);

    [attributedString drawInRect: rect];
}

-(void)drawRect:(NSRect)rect
{
    [super drawRect: rect];

    //1 draw the background of the whole view (semi transparent)
    [self drawBackground: [self bounds]];
    
    NSDictionary * selectedScreen = nil;
    
    if (selectionIndex != NSNotFound)
        selectedScreen = [screens objectAtIndex: selectionIndex];
    
    NSEnumerator * iter = [screens objectEnumerator];
    
    while (NSDictionary * screen = [iter nextObject])
    {
        NSRect position = [self positionForScreen: screen];
        
        NSAffineTransform * transform = [NSAffineTransform transform];

        [transform translateXBy: position.origin.x yBy: position.origin.y];
        
        [transform concat];

        position.origin = NSZeroPoint; 
        
        [self drawScreen: position 
                withName: [screen objectForKey: @"name"] 
             andSelected: selectedScreen == screen
             andFraction: 1.0f];

        [transform invert];
        [transform concat];
    }

    if (draggedIndex != NSNotFound)
    {
        NSDictionary * draggedScreen = [screens objectAtIndex: draggedIndex];
        NSRect position = [self positionForScreen: draggedScreen];
        
        NSAffineTransform * transform = [NSAffineTransform transform];

        [transform translateXBy: dragPoint.x yBy: dragPoint.y];
        
        [transform concat];

        position.origin = NSZeroPoint; 
        
        [self drawScreen: position 
                withName: [draggedScreen objectForKey: @"name"] 
             andSelected: NO
             andFraction: 0.5f];

        [transform invert];
        [transform concat];
    }
}

#pragma mark - user input -


- (void)mouseDown:(NSEvent *)theEvent;
{
    NSPoint lastPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint originalPoint = lastPoint;
    unsigned int selection = [self screenAtPoint: originalPoint];

    [self setSelectionIndex: selection];
    [self setNeedsDisplay: YES];
    
    NSPoint translation;
    
    do 
    {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];

        if (    (selection != NSNotFound)
            &&  !NSEqualPoints(lastPoint, point))
        {
            if (draggedIndex == NSNotFound)
            {
                draggedIndex = selection;
                
                NSMutableDictionary * draggedScreen = [screens objectAtIndex: draggedIndex];
                NSRect draggedScreenRect = [self positionForScreen: draggedScreen];
                
                translation.x = point.x - draggedScreenRect.origin.x;
                translation.y = point.y - draggedScreenRect.origin.y;
            }

            NSMutableDictionary * draggedScreen = [screens objectAtIndex: draggedIndex];

            dragPoint.x = point.x - translation.x;
            dragPoint.y = point.y - translation.y;

            NSPoint newPos = [self screenPositionForPoint: point];

            if (   [[draggedScreen objectForKey: @"x"] floatValue] != newPos.x
                || [[draggedScreen objectForKey: @"y"] floatValue] != newPos.y)
            {
                if ([self datasourceShouldChangePositionTo: newPos atIndex: draggedIndex])
                {
                    [self datasourcePositionChanged: newPos atIndex: draggedIndex];
                    [self reload];
                }
            }
            
            [self setNeedsDisplay: YES];
        }

        lastPoint = point;

        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
    } while ([theEvent type] != NSLeftMouseUp);

    draggedIndex = NSNotFound;
    [self setNeedsDisplay: YES];
}





#pragma mark - Datasource callbacks - 

-(unsigned int)datasourceNumberOfScreen
{
    if ([datasource respondsToSelector: @selector(SPScreenViewNumberOfScreens:)] == YES)
    {
        return [datasource SPScreenViewNumberOfScreens: self];
    }
    
    return 0;
}

-(NSString *)datasourceNameOfScreenAtIndex:(unsigned int)index
{
    if ([datasource respondsToSelector: @selector(SPScreenView:nameOfScreenAtIndex:)] == YES)
    {
        return [datasource SPScreenView: self nameOfScreenAtIndex: index];
    }
    
    return @"";
}

-(NSPoint)datasourcePositionOfScreenAtIndex:(unsigned int)index
{
    if ([datasource respondsToSelector: @selector(SPScreenView:positionOfScreenAtIndex:)] == YES)
    {
        return [datasource SPScreenView: self positionOfScreenAtIndex: index];
    }
    
    return NSZeroPoint;
}

-(void)datasourceSelectionIndexChangedTo:(unsigned int)index
{
    if ([datasource respondsToSelector: @selector(SPScreenView:selectionIndexChangedTo:)] == YES)
    {
        [datasource SPScreenView: self selectionIndexChangedTo: index];
    }
}

-(BOOL)datasourceShouldChangePositionTo:(NSPoint)point atIndex:(unsigned int)index
{
    if ([datasource respondsToSelector: @selector(SPScreenView:datasourceShouldChangePositionTo:atIndex:)] == YES)
    {
        return [datasource SPScreenView: self datasourceShouldChangePositionTo: point atIndex: index];
    }
    
    return NO;
}

-(void)datasourcePositionChanged:(NSPoint)point atIndex:(unsigned int)index
{
    if ([datasource respondsToSelector: @selector(SPScreenView:positionChanged:atIndex:)] == YES)
    {
        [datasource SPScreenView: self positionChanged: point atIndex: index];
    }
}


@end
