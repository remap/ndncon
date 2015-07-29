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
#import "NSObject+NCAdditions.h"
#import "User.h"
#import "NSDate+NCAdditions.h"
#import "NCStreamBrowserController.h"

@interface Delme : NSTextView

@end

@implementation Delme

-(void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
}

@end

//******************************************************************************
typedef enum _NCChatMessageCellType {
    NCChatMessageCellTypeFirst,
    NCChatMessageCellTypeMiddle,
    NCChatMessageCellTypeLast
} NCChatMessageCellType;

@interface NCChatMessageCell ()

@property (nonatomic) NCChatMessageCellType type;
@property (nonatomic) ChatMessage *message;
@property (nonatomic) NSArray *messageGroup;
@property (nonatomic, weak) IBOutlet NSTextField *userNameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *timestampTextField;
@property (nonatomic, weak) IBOutlet NSTextField *messageTypeTextField;
@property (nonatomic, strong) IBOutlet Delme *messageTextView;

+(NSDictionary *)textviewAttributes;
+(NSString*)messageTextContentFromGroup:(NSArray*)msgGroup;
+(NSRect)calculateTextRectForSize:(NSSize)size
                       andContent:(NSString*)content;
@end

//******************************************************************************
@interface NCChatViewController ()

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *messageTextField;
@property (nonatomic) ChatRoom *chatRoom;
@property (weak) IBOutlet NSArrayController *messages;
@property (nonatomic, readonly) IBOutlet NSManagedObjectContext *context;
@property (nonatomic, strong) NSArray *recentMessages;
@property (nonatomic, strong) NCChatMessageCell *prototypeCell;

@end

//******************************************************************************
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
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self.tableView scrollRowToVisible:self.recentMessages.count-1];
}

// public
-(void)setChatRoomId:(NSString *)chatRoomId
{
    if (![_chatRoomId isEqualTo:chatRoomId])
    {
        _chatRoomId = chatRoomId;
        self.chatRoom = [ChatRoom chatRoomWithId:chatRoomId fromContext:self.context];
        [self reloadData];
        
        {
            // remove all user notifications from this user
//            NSMutableArray *notificationsForRemoval = [NSMutableArray array];
//            [[NSUserNotificationCenter defaultUserNotificationCenter].deliveredNotifications
//             enumerateObjectsUsingBlock:^(NSUserNotification *notification, NSUInteger idx, BOOL *stop)
//            {
//                 User *user = [User userByName:notification.userInfo[kUserNameKey]
//                                     andPrefix:notification.userInfo[kHubPrefixKey]
//                                   fromContext:self.context];
//
//                 if ([self.chatRoom hasParitcipant:user])
//                     [notificationsForRemoval addObject:notification];
//             }];
//            
//            [notificationsForRemoval enumerateObjectsUsingBlock:
//             ^(id obj, NSUInteger idx, BOOL *stop) {
//                 [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:obj];
//             }];
        }
    }
}

-(void)setActive:(BOOL)isActive
{
    _isActive = isActive;
    [self.messageTextField setEnabled:isActive];
    
    if (isActive)
        [self.messageTextField.cell setPlaceholderString:@"type message..."];
    else
        [self.messageTextField.cell setPlaceholderString:@"you must join chatroom to send messages"];
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
        
        [self reloadData];
    }
}

-(void)newChatMessage:(NSNotification*)notification
{
    NSString *chatRoomId = notification.userInfo[NCChatRoomIdKey];
    
    if ([self.chatRoomId isEqualTo:chatRoomId])
    {
        [self reloadData];
    }
}

// NSTableViewDelegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (self.recentMessages)?self.recentMessages.count:0;
}

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSArray *msgGroup = self.recentMessages[row];
    static NSString *cellIdentifier = @"MessageCell";
    NCChatMessageCell *cell = [self.tableView makeViewWithIdentifier:cellIdentifier owner:nil];

    cell.messageGroup = msgGroup;
    
    return cell;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if (row < self.recentMessages.count)
    {
        NSArray *msgGroup = self.recentMessages[row];
        ChatMessage *message = [msgGroup firstObject];
        
        if ([message.type isEqualToNumber:[ChatMessage typeFromString:kChatMesageTypeText]])
        {
            NSString *content = [NCChatMessageCell messageTextContentFromGroup:msgGroup];
            NSRect rect  = [NCChatMessageCell calculateTextRectForSize:NSMakeSize([[tableView.tableColumns firstObject] width], 1000.)
                                                            andContent:content];
            return rect.size.height+40;
        }
        else
            return 25.;
    }
    
    return 55.;
}

// private
-(void)reloadData
{
    [self prepareMessages];
    [self.tableView reloadData];
    [self.tableView scrollRowToVisible:self.tableView.numberOfRows-1];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatViewControllerDidFinishLoadingMessages:)])
        [self.delegate chatViewControllerDidFinishLoadingMessages:self];
}

-(void)prepareMessages
{
    NSSortDescriptor *sortChronologically = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    NSArray *sortedMessages = [[self.chatRoom.messages sortedArrayUsingDescriptors:@[sortChronologically]] mutableCopy];
    
    NSArray *filteredMessages = [sortedMessages filteredArrayUsingPredicate:
                                 [NSPredicate predicateWithFormat:@"type == %@ || type == %@ || type == %@",
                                  [ChatMessage typeFromString:kChatMesageTypeText],
                                  [ChatMessage typeFromString:kChatMesageTypeJoin],
                                  [ChatMessage typeFromString:kChatMesageTypeLeave]]];
    
    NSTimeInterval msgInterval = 120; // seconds
    __block NSMutableArray *msgGroups = [NSMutableArray array];
    __block NSDate *lastTime = nil;
    __block NSNumber *lastMessageType = nil;
    __block NSMutableArray *currentGroup = [NSMutableArray array];
    __block User *lastUser = nil;
    
    [filteredMessages enumerateObjectsUsingBlock:^(ChatMessage *message, NSUInteger idx, BOOL *stop) {
        // if got message from another user - close group or different message type
        BOOL closeGroup = ![lastMessageType isEqualToNumber: message.type];
        
        if (!closeGroup)
            if ([lastMessageType isEqualToNumber:[ChatMessage typeFromString:kChatMesageTypeText]])
            {
                closeGroup = (lastUser != message.user);
            }
        
        if (!closeGroup)
            if ([message.timestamp timeIntervalSinceDate:lastTime] > msgInterval)
                closeGroup = YES;
        
        if (closeGroup && currentGroup.count)
        {
            [msgGroups addObject:currentGroup];
            currentGroup = [NSMutableArray array];
        }
        
        [currentGroup addObject:message];
        
        lastMessageType = message.type;
        lastUser = message.user;
        lastTime = message.timestamp;
        
        // set read timestamp
        if (!message.read)
            message.read = [NSDate date];
    }];
    
    if (currentGroup.count > 0)
        [msgGroups addObject:currentGroup];
    
//    [msgGroups enumerateObjectsUsingBlock:^(NSArray* group, NSUInteger idx, BOOL *stop) {
//        ChatMessage *msg = [group firstObject];
//        NSLog(@"%@-%@:\n", msg.user.name, msg.timestamp);
//        [group enumerateObjectsUsingBlock:^(ChatMessage* m, NSUInteger idx, BOOL *stop) {
//            NSString *sub = (m.body.length > 30)?[m.body substringWithRange:NSMakeRange(0, 30)]:m.body;
//            NSLog(@"\t%@ (%@)\n", sub, m.user.name);
//        }];
//    }];
    
    self.recentMessages = msgGroups;
}

@end

//******************************************************************************
@interface NCChatMessageCell()

@property (nonatomic) BOOL isTypeTextual;

@end

@implementation NCChatMessageCell

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageTextView = [[Delme alloc] init];
        self.messageTextView.editable = NO;
        self.messageTextView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.messageTextView setBackgroundColor:[NSColor clearColor]];
        [self.messageTextView setVerticallyResizable:YES];
        [self.messageTextView.layoutManager ensureLayoutForTextContainer:self.messageTextView.textContainer];
        [self.messageTextView setCanDrawConcurrently:YES];
        [self.messageTextView setAutomaticLinkDetectionEnabled:YES];
        [self.messageTextView setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                                       forOrientation:NSLayoutConstraintOrientationVertical];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self setWantsLayer: YES];
}

-(void)setMessage:(ChatMessage *)message
{
    _message = message;
    [self.messageTextView.textStorage setAttributedString:
     [[NSAttributedString alloc] initWithString:((message.body)?message.body:@"")
                                     attributes:[NCChatMessageCell textviewAttributes]]];
    [self.messageTextView checkTextInDocument:nil];
    self.userNameTextField.stringValue = (!message.user || message.user.isMyself) ? @"me" : message.user.name;
    self.timestampTextField.stringValue = (message.timestamp)?[message.timestamp description]:@"";
    self.messageTypeTextField.stringValue = @"";
}

-(void)setMessageGroup:(NSArray *)messageGroup
{
    _messageGroup = messageGroup;
    
    ChatMessage *message = [messageGroup firstObject];
    
    if ([message.type isEqualToNumber:[ChatMessage typeFromString:kChatMesageTypeText]])
    {
        self.isTypeTextual = YES;
        
        if (message.user == nil || [message.user isMyself])
            self.layer.backgroundColor = [NSColor colorWithWhite:1. alpha:1.].CGColor;
        else
            self.layer.backgroundColor = [NSColor colorWithRed:227./255. green:238./255. blue:249./255. alpha:1.].CGColor;
        
        [self.messageTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:[NCChatMessageCell messageTextContentFromGroup:messageGroup]
                                                                                              attributes:[NCChatMessageCell textviewAttributes]]];
        [self.messageTextView checkTextInDocument:nil];
        self.userNameTextField.stringValue = (!message.user || message.user.isMyself) ? @"me" : message.user.name;
        self.timestampTextField.stringValue = [NSString stringWithFormat:@"(%@):", [NCChatMessageCell textRepresentationForDate:message.timestamp]];
        self.messageTypeTextField.stringValue = @"";
    }
    else
    {
        self.isTypeTextual = NO;
        
        if ([message.type isEqualToNumber:[ChatMessage typeFromString:kChatMesageTypeJoin]])
            self.layer.backgroundColor = [NSColor colorWithWhite:0.98 alpha:1.].CGColor;
        else
            self.layer.backgroundColor = [NSColor colorWithWhite:0.98 alpha:1.].CGColor;
        
        __block NSMutableSet *userNames = [NSMutableSet set];
        [_messageGroup enumerateObjectsUsingBlock:^(ChatMessage *message, NSUInteger idx, BOOL *stop) {
            NSString *userName = (!message.user || message.user.isMyself) ? @"me" : message.user.name;
            [userNames addObject:userName];
        }];
        
        self.userNameTextField.stringValue = [[userNames allObjects] componentsJoinedByString:@","];
        self.timestampTextField.stringValue = [NSString stringWithFormat:@"(%@)", [NCChatMessageCell textRepresentationForDate:message.timestamp]];
        self.messageTypeTextField.stringValue = [kChatMesageTypeJoin lowercaseString];
    }
}

-(void)setIsTypeTextual:(BOOL)isTypeTextual
{
    _isTypeTextual = isTypeTextual;
    
    if (isTypeTextual)
    {
        [self addSubview:self.messageTextView];
        NSView *textView = self.messageTextView;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(30)-[textView]-(10@999)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(textView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10@999)-[textView]-(10@999)-|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(textView)]];
        
        [self.userNameTextField setFont:[NSFont boldSystemFontOfSize:13.]];
        [self.timestampTextField setFont:[NSFont systemFontOfSize:12.]];
    }
    else
    {
        [self.messageTextView removeFromSuperview];
        [self.userNameTextField setFont:[NSFont systemFontOfSize:10.]];
        [self.timestampTextField setFont:[NSFont systemFontOfSize:9.]];
    }
}

-(void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout:YES];
}

+(NSDictionary *)textviewAttributes
{
    static NSDictionary *messagesAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            NSMutableParagraphStyle *pStyle;
            pStyle = [[NSMutableParagraphStyle alloc] init];
            [pStyle setAlignment:NSLeftTextAlignment];
            [pStyle setLineBreakMode:NSLineBreakByWordWrapping];
            messagesAttributes = @{
                                   NSParagraphStyleAttributeName: pStyle,
                                   NSBackgroundColorAttributeName: [NSColor clearColor],
                                   NSFontAttributeName: [NSFont systemFontOfSize:12],
                                   NSForegroundColorAttributeName: [NSColor colorWithWhite:0.3 alpha:1.]
                                   };
        }
    });
    
    return messagesAttributes;
}

+(NSString*)messageTextContentFromGroup:(NSArray*)msgGroup
{
    __block NSString *text = @"";
    [msgGroup enumerateObjectsUsingBlock:^(ChatMessage* obj, NSUInteger idx, BOOL *stop) {
        text = [text stringByAppendingFormat:@"%@", obj.body];

        if (obj != [msgGroup lastObject])
            text = [text stringByAppendingString:@"\n"];
    }];
    
    return text;
}

+(NSRect)calculateTextRectForSize:(NSSize)size
                        andContent:(NSString*)content
{
    NSTextStorage * storage =
    [[NSTextStorage alloc] initWithAttributedString: [[NSAttributedString alloc] initWithString:content attributes: [NCChatMessageCell textviewAttributes]]];
    
    NSSize sz = NSMakeSize(size.width-60., 1000.);
    NSTextContainer * container = [[NSTextContainer alloc] initWithContainerSize: sz];
    NSLayoutManager * manager = [[NSLayoutManager alloc] init];
    
    [manager addTextContainer: container];
    [storage addLayoutManager: manager];
    
    [manager glyphRangeForTextContainer: container];
    
    NSRect idealRect = [manager usedRectForTextContainer: container];
    
    return NSMakeRect(0, 0, idealRect.size.width, idealRect.size.height);
}

+(NSString*)textRepresentationForDate:(NSDate*)date
{
    // check if it's today - then show just time
    if ([date isToday])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        
        return [formatter stringFromDate:date];
    }
    else if ([date isYesterday])
        return @"yesterday";
    if ([date isTomorrow])
        return @"tomorrow";
    else
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        
        return [formatter stringFromDate:date];
    }
}

@end
