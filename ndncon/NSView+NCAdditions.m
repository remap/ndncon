//
//  NSView+NCDragAndDropAbility.m
//  NdnCon
//
//  Created by Peter Gusev on 10/21/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NSView+NCAdditions.h"
#import "NSString+NCAdditions.h"

//******************************************************************************
@implementation NSView (NCDragAndDropAbility)

@dynamic delegate;

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSArray *validUrls = [NSView validUrlsFromPasteBoard:[sender draggingPasteboard]];
    
    if (validUrls.count &&
        [self delegate] && [[self delegate] respondsToSelector:@selector(dragAndDropView:shouldAcceptDraggedUrls:)])
        return ([[self delegate] dragAndDropView:self shouldAcceptDraggedUrls:validUrls])?NSDragOperationCopy:NSDragOperationNone;
    
    return NSDragOperationNone;
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSArray *validUrls = [NSView validUrlsFromPasteBoard:[sender draggingPasteboard]];
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(dragAndDropView:didAcceptDraggedUrls:)])
        [[self delegate] dragAndDropView:self didAcceptDraggedUrls:validUrls];
    
    return YES;
}

+(NSArray*)validUrlsFromPasteBoard:(NSPasteboard*)pasteboard
{
    __block NSMutableArray *validUrls = [[NSMutableArray alloc] init];
    
    NSArray *pasteItems = [pasteboard readObjectsForClasses:@[[NSString class]] options:nil];
    
    [pasteItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BOOL isValidUrl = ([obj prefixFromNrtcUrlString] != nil && [obj userNameFromNrtcUrlString] != nil);
        
        if (isValidUrl)
            [validUrls addObject:obj];
    }];
    
    return validUrls;
}

@end

//******************************************************************************

@interface NCBlockDrawableView ()

@property (nonatomic, strong) NSMutableArray *drawBlocks;

@end

@implementation NCBlockDrawableView

-(void)initialize
{
    self.drawBlocks = [[NSMutableArray alloc] init];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)dealloc
{
    [self.drawBlocks removeAllObjects];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(NSRect)dirtyRect
{
    @synchronized (self.drawBlocks)
    {
        [self.drawBlocks enumerateObjectsUsingBlock:^(NCDrawBlock drawBlock, NSUInteger idx, BOOL *stop){
            drawBlock(self, dirtyRect);
        }];
    }
}

-(void)addDrawBlock:(NCDrawBlock)drawBlock
{
    @synchronized (self.drawBlocks)
    {
        [self.drawBlocks addObject:drawBlock];
    }
}

-(void)removeDrawBlock:(NCDrawBlock)drawBlock
{
    @synchronized (self.drawBlocks)
    {
        [self.drawBlocks removeObject:drawBlock];
    }
}

@end

//******************************************************************************
@implementation NCTrackableView

-(void)dealloc
{
    self.updateTrackingAreasBlock = nil;
}

-(void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if (self.updateTrackingAreasBlock)
        self.updateTrackingAreasBlock(self);
}

@end