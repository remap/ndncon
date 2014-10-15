//
//  NCChatViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCChatViewController.h"
#import "NCChatLibraryController.h"
#import "ChatRoom.h"
#import "ChatMessage.h"
#import "AppDelegate.h"

@interface NCChatViewController ()

@property (weak) IBOutlet NSTextField *messageTextField;
@property (nonatomic) ChatRoom *chatRoom;
@property (weak) IBOutlet NSArrayController *messages;
@property (nonatomic, readonly) IBOutlet NSManagedObjectContext *context;

@end

@implementation NCChatViewController

-(id)init
{
    self = [super initWithNibName:@"NCChatView" bundle:nil];
    
    if (self)
    {
        
    }
    
    return self;
}

-(void)dealloc
{
    
}

-(void)awakeFromNib
{
    
}

// public
-(void)setChatRoomId:(NSString *)chatRoomId
{
    if (![_chatRoomId isEqualTo:chatRoomId])
    {
        _chatRoomId = chatRoomId;
        self.chatRoom = [ChatRoom chatRoomWithId:chatRoomId fromContext:self.context];
    }
}

-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

- (IBAction)sendMessage:(id)sender {
    NSString *message = self.messageTextField.stringValue;
    
    if (message.length > 0)
    {
        [[NCChatLibraryController sharedInstance] sendMessage:message
                                                       toChat:self.chatRoomId];
        self.messageTextField.stringValue = @"";
    }
}

// private

// NSTableView datasource

// NSTableViewDelegate

@end
