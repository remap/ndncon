//
//  NCChatLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#include <ndn-conference-discovery/chrono-chat.h>
#include <ndn-conference-discovery/external-observer.h>

#import "NCChatLibraryController.h"
#import "NSString+NCAdditions.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"
#import "NCPreferencesController.h"
#import "User.h"
#import "ChatRoom.h"
#import "AppDelegate.h"

NSString* const NCChatMessageNotification = @"NCChatMessageNotification";
NSString* const NCChatMessageTypeKey = @"type";
NSString* const NCChatMessageUsernameKey = @"username";
NSString* const NCChatMessageTimestampKey = @"timestamp";
NSString* const NCChatMessageBodyKey = @"msg_body";

NSString* const kChatMesageTypeJoin = @"Join";
NSString* const kChatMesageTypeLeave = @"Leave";
NSString* const kChatMesageTypeText = @"Text";

using namespace chrono_chat;
class NCChatObserver;
typedef std::map<std::string, ptr_lib::shared_ptr<NCChatObserver>> ChatIdToObserverMap;

//******************************************************************************
@interface NCChatLibraryController ()
{
    ChatIdToObserverMap _chatIdToObserver;
    ndn::Face* _chatFace;
    ndn::KeyChain* _chatKeyChain;
    dispatch_queue_t _faceQueue;
    BOOL _isRunningFace;
}

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end

//******************************************************************************
class NCChatObserver : public ChatObserver
{
public:
    NCChatObserver(){}
    ~NCChatObserver()
    {
        delete chat_;
    }
    
    void
    onStateChanged(MessageTypes type, const char *userName, const char *msg,
                   double timestamp)
    {
        NSString *typeStr;
        NSString *userNameStr = [NSString ncStringFromCString:userName];
        NSString *message = [NSString ncStringFromCString:msg];
        
        switch (type) {
            case MessageTypes::JOIN:
                typeStr = kChatMesageTypeJoin;
                break;
            case MessageTypes::LEAVE:
                typeStr = kChatMesageTypeLeave;
                break;
            case MessageTypes::CHAT: // fall throw
            default:
                typeStr = kChatMesageTypeText;
                break;
        }
        
        NSLog(@"%@ - [%f] %@: %@", typeStr, timestamp, userNameStr, message);
        
        [[[NSObject alloc] init]
         notifyNowWithNotificationName:NCChatMessageNotification
         andUserInfo:@{
                       NCChatMessageTypeKey : typeStr,
                       NCChatMessageTimestampKey: @(timestamp),
                       NCChatMessageUsernameKey: userNameStr,
                       NCChatMessageBodyKey: message
                       }];
    }
    
    void
    setChat(Chat *chat)
    { chat_ = chat; }
    
    Chat*
    getChat() { return chat_; }
    
private:
    Chat *chat_;
};

//******************************************************************************
@implementation NCChatLibraryController

+(NCChatLibraryController*)sharedInstance
{
    return (NCChatLibraryController*)[super sharedInstance];
}

+(PTNSingleton *)createInstance
{
    return [[NCChatLibraryController alloc] init];
}

+(dispatch_once_t)token
{
    static dispatch_once_t token;
    return token;
}

-(id)init
{
    self = [super init];
    
    if (self)
    {
        _faceQueue = dispatch_queue_create("chat.queue", DISPATCH_QUEUE_SERIAL);
        _chatFace = NULL;
        _chatKeyChain = NULL;
        
        if (![self initFace])
            return nil;
        
        _isRunningFace = YES;
        [self runFace];
        [[NCPreferencesController sharedInstance] addObserver:self
                                                  forKeyPaths:
         NSStringFromSelector(@selector(chatBroadcastPrefix)),
         nil];
        
        [self subscribeForNotificationsAndSelectors:
         NCLocalSessionStatusUpdateNotification, @selector(sessionStatusUpdate:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [[NCPreferencesController sharedInstance] removeObserver:self
                                                 forKeyPaths:
     NSStringFromSelector(@selector(chatBroadcastPrefix)),
     nil];
    
    _isRunningFace = NO;

    [self leaveAllChatRooms];
    
    delete _chatKeyChain;
    delete _chatFace;
}

// public
-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(NSString *)startChatWithUser:(NSString *)userPrefix
{
    NSString *chatRoomId = [NCChatLibraryController
                            chatRoomIdForUser:[[NCNdnRtcLibraryController sharedInstance] sessionPrefix]
                            andUser:userPrefix];
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].chatBroadcastPrefix
                                 cStringUsingEncoding:NSASCIIStringEncoding]);
    Name broadcastPrefixName(broadcastPrefix);
    const std::string screenName([[NCPreferencesController sharedInstance].userName
                                  cStringUsingEncoding:NSASCIIStringEncoding]);
    const std::string chatRoom([chatRoomId
                                cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string hubPrefix([[NCPreferencesController sharedInstance].prefix
                           cStringUsingEncoding:NSASCIIStringEncoding]);
    Name hubPrefixName(hubPrefix);
    ptr_lib::shared_ptr<ChatObserver> observer(new NCChatObserver());
    
    if (_chatIdToObserver.find(chatRoom) != _chatIdToObserver.end())
    {
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Chat room exists already"];
        return nil;
    }
    else
    {
        __block Chat* chat;
        
        dispatch_sync(_faceQueue, ^{
            chat = new Chat(broadcastPrefixName, screenName, chatRoom,
                            hubPrefixName, NULL, *_chatFace, *_chatKeyChain,
                            _chatKeyChain->getDefaultCertificateName());
        });
        
        dynamic_pointer_cast<NCChatObserver>(observer)->setChat(chat);
        
        NSLog(@"joined chatroom %@", chatRoomId);
        
        _chatIdToObserver[chatRoom] = dynamic_pointer_cast<NCChatObserver>(observer);
        
        if (![ChatRoom chatRoomWithId:chatRoomId fromContext:self.context])
        {
            ChatRoom *newChatRoom = [ChatRoom createChatRoomWithId:chatRoomId inContext:self.context];
            newChatRoom.created = [NSDate date];
            [self.context save:nil];
        }
        //        else
        //            NSLog(@"chatroom %@ (%@-%@) was created previously", chatRoomId,
        //                  [NCNdnRtcLibraryController sharedInstance].sessionPrefix, userPrefix);
    }
    
    return chatRoomId;
}

-(void)sendMessage:(NSString *)message toChat:(NSString *)chatId
{
    std::string chatRoom([chatId cStringUsingEncoding:NSASCIIStringEncoding]);
    ChatIdToObserverMap::iterator it = _chatIdToObserver.find(chatRoom);
    
    if (it == _chatIdToObserver.end())
    {
        NSLog(@"chat room %@ doesn't exist ", chatId);
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Chat room doesn't exist"];
        return;
    }
    
    const std::string msg([message cStringUsingEncoding:NSASCIIStringEncoding]);
    dispatch_async(_faceQueue, ^{
        it->second->getChat()->sendMessage(msg);
    });
}

-(void)leaveChat:(NSString *)chatId
{
    std::string chatRoom([chatId cStringUsingEncoding:NSASCIIStringEncoding]);
    ChatIdToObserverMap::iterator it = _chatIdToObserver.find(chatRoom);
    
    if (it == _chatIdToObserver.end())
        return;

    NSLog(@"left chatroom %s", it->first.c_str());
    dispatch_async(_faceQueue, ^{
        it->second->getChat()->leave();
        _chatIdToObserver.erase(it);
    });
}

-(void)initChatRooms
{
    NSArray *users = [User allUsersFromContext:self.context];
    
    [users enumerateObjectsUsingBlock:^(User* user, NSUInteger idx, BOOL *stop) {
        [self startChatWithUser:user.userPrefix];
    }];
}

-(void)leaveAllChatRooms
{
    for (ChatIdToObserverMap::iterator it = _chatIdToObserver.begin();
         it != _chatIdToObserver.end(); it++)
    {
        NSLog(@"left chatroom %s", it->first.c_str());
        dispatch_sync(_faceQueue, ^{
            it->second->getChat()->leave();
        });
    }
    
    _chatIdToObserver.clear();
}

// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [NCPreferencesController sharedInstance])
        [self reJoinRooms];
}

// notificaitons
-(void)sessionStatusUpdate:(NSNotification*)notification
{
    NCSessionStatus oldStatus = (NCSessionStatus)[[notification.userInfo objectForKey:kNCSessionOldStatusKey] integerValue];
    NCSessionStatus newStatus = (NCSessionStatus)[[notification.userInfo objectForKey:kNCSessionStatusKey] integerValue];
    
    if (oldStatus == SessionStatusOffline &&
        (newStatus == SessionStatusOnlineNotPublishing || newStatus == SessionStatusOnlinePublishing))
    {
        NSLog(@"session status online. rejoin chatrooms");
        [self reJoinRooms];
    }
}

// private
+(NSString*)chatRoomIdForUser:(NSString*)user1 andUser:(NSString*)user2
{
    NSString *concatString = @"";
    
    if ([user1 compare:user2] == NSOrderedDescending)
        concatString = [NSString stringWithFormat:@"%@%@", user2, user1];
    else
        concatString = [NSString stringWithFormat:@"%@%@", user1, user2];
    
    return [concatString md5Hash];
}

-(void)runFace
{
    NCChatLibraryController* strongSelf = self;
    dispatch_async(_faceQueue, ^{
        strongSelf->_chatFace->processEvents();
        usleep(10000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (strongSelf->_isRunningFace)
                [strongSelf runFace];            
        });
    });
}

-(BOOL)initFace
{
    if (_chatFace)
        delete _chatFace;
    
    if (_chatKeyChain)
        delete _chatKeyChain;
    
    const char* host = [[NCPreferencesController sharedInstance].daemonHost cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned short port = (unsigned short)([NCPreferencesController sharedInstance].daemonPort.intValue);
    
    try {
        _chatFace = new Face(host, port);
        _chatKeyChain = new KeyChain();
        _chatFace->setCommandSigningInfo(*_chatKeyChain, _chatKeyChain->getDefaultCertificateName());
    }
    catch (std::exception &exception)
    {
        [[NCErrorController sharedInstance]
         postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
        
        return NO;
    }
    
    return YES;
}

-(void)reJoinRooms
{
    [self leaveAllChatRooms];
    [self initFace];
    [self initChatRooms];
}

@end
