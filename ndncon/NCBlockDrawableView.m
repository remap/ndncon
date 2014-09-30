//
//  NCBlockDrawableView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCBlockDrawableView.h"

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

