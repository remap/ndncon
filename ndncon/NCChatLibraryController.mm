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
#import "ChatMessage.h"
#import "AppDelegate.h"
#import "NCFaceSingleton.h"

NSString* const NCChatMessageNotification = @"NCChatMessageNotification";
NSString* const NCChatMessageTypeKey = @"type";
NSString* const NCChatMessageUsernameKey = @"username";
NSString* const NCChatMessageTimestampKey = @"timestamp";
NSString* const NCChatMessageBodyKey = @"msg_body";
NSString* const NCChatRoomIdKey = @"chatroomId";
NSString* const NCChatMessageUserKey = @"user";

using namespace chrono_chat;
class NCChatObserver;
typedef std::map<std::string, ndn::ptr_lib::shared_ptr<NCChatObserver>> ChatIdToObserverMap;

//******************************************************************************
@interface NCChatLibraryController ()
{
    ChatIdToObserverMap _chatIdToObserver;
}

@property (nonatomic) BOOL initialized;
@property (nonatomic, readonly) NSManagedObjectContext *context;

-(ChatMessage*)addChatMessageOfType:(NSString*)msgType
                           fromUser:(NSString*)userSessionPrefix
                        messageBody:(NSString*)messageBody
                   inChatRoomWithId:(NSString*)chatRoomId;

@end

//******************************************************************************
class NCChatObserver : public ChatObserver
{
public:
    NCChatObserver(NSString *chatRoomId):chatRoomId_(chatRoomId), chat_(NULL){}
    virtual ~NCChatObserver()
    {}
    
    void
    onStateChanged(MessageTypes type, const char *userHubPrefix,
                   const char *userName, const char *msg, double timestamp)
    {
        NSString *typeStr;
        NSString *userNameStr = [NSString ncStringFromCString:userName];
        NSString *userPrefixStr = [NSString ncStringFromCString:userHubPrefix];
        NSString *userSessionPrefix = [NSString userSessionPrefixForUser:userNameStr
                                                           withHubPrefix:userPrefixStr];
        NSString *message = [NSString ncStringFromCString:msg];
        
        switch (type) {
            case MessageTypes::JOIN:
                typeStr = kChatMesageTypeJoin;
                break;
            case MessageTypes::LEAVE:
                typeStr = kChatMesageTypeLeave;
                break;
            case MessageTypes::CHAT: // fall through
            default:
                typeStr = kChatMesageTypeText;
                break;
        }
        
        NSLog(@"%@ - [%f] %@: %@", typeStr, timestamp, userNameStr, message);
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                          NCChatRoomIdKey: chatRoomId_,
                                                                                          NCChatMessageTypeKey : typeStr,
                                                                                          NCChatMessageTimestampKey: @(timestamp),
                                                                                          NCChatMessageUsernameKey: userNameStr,
                                                                                          NCChatMessageBodyKey: message
                                                                                          }];

        ChatMessage *chatMessage = [[NCChatLibraryController sharedInstance] addChatMessageOfType:typeStr
                                                                                         fromUser:userSessionPrefix
                                                                                      messageBody:message
                                                                                 inChatRoomWithId:chatRoomId_];
        
        if (chatMessage.user)
            userInfo[NCChatMessageUserKey] = chatMessage.user;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[NSObject alloc] init]
             notifyNowWithNotificationName:NCChatMessageNotification
             andUserInfo:userInfo];
        });
    }
    
    void
    setChat(boost::shared_ptr<Chat> chat)
    { chat_ = chat; }
    
    boost::shared_ptr<Chat>
    getChat() { return chat_; }
    
private:
    NSString *chatRoomId_;
    boost::shared_ptr<Chat> chat_;
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

+(dispatch_once_t*)token
{
    static dispatch_once_t token;
    return &token;
}

+(NSString*)privateChatRoomIdWithUser:(NSString*)userPrefix
{
    NSString *localPrefix = [NSString stringWithFormat:@"%@/%@",
                             [NCPreferencesController sharedInstance].prefix,
                             [NCPreferencesController sharedInstance].userName];
    return [self chatRoomIdForUser:localPrefix
                           andUser:userPrefix];
}

-(id)init
{
    self = [super init];
    
    if (self)
    {
        if (![NCFaceSingleton sharedInstance])
            return nil;
        
        [[NCFaceSingleton sharedInstance] startProcessingEvents];

        [self subscribeForNotificationsAndSelectors:
         NCLocalSessionStatusUpdateNotification, @selector(onLocalSessionStatusChanged:),
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
    
    [self leaveAllChatRooms];
}

// public
-(NSManagedObjectContext *)context
{
    return [(AppDelegate*)[NSApp delegate] managedObjectContext];
}

-(NSString *)startChatWithUser:(NSString *)userPrefix
{
    NSString *chatRoomId = [NCChatLibraryController
                            privateChatRoomIdWithUser:userPrefix];
    
    if ([NCFaceSingleton sharedInstance].isValid)
    {
#ifdef CHATS_ENABLED
        std::string broadcastPrefix([[NCPreferencesController sharedInstance].chatBroadcastPrefix
                                     cStringUsingEncoding:NSASCIIStringEncoding]);
        ndn::Name broadcastPrefixName(broadcastPrefix);
        const std::string screenName([[NCPreferencesController sharedInstance].userName
                                      cStringUsingEncoding:NSASCIIStringEncoding]);
        const std::string chatRoom([chatRoomId
                                    cStringUsingEncoding:NSASCIIStringEncoding]);
        std::string chatPrefix([[NCChatLibraryController chatsAppPrefixWithHubPrefix:[NCPreferencesController sharedInstance].prefix]
                                cStringUsingEncoding:NSASCIIStringEncoding]);
        ndn::Name chatPrefixName(chatPrefix);
        
        if (_chatIdToObserver.find(chatRoom) != _chatIdToObserver.end())
            return chatRoomId;
        else
        {
            ndn::ptr_lib::shared_ptr<ChatObserver> observer(new NCChatObserver(chatRoomId));
            __block boost::shared_ptr<Chat> chat(new Chat(broadcastPrefixName, screenName, chatRoom,
                                                          chatPrefixName, observer.get(),
                                                          *[[NCFaceSingleton sharedInstance] getFace],
                                                          *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                          [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName()));
            __block BOOL success = YES;
            
            [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
                try {
                    chat->start();
                } catch (std::exception &exception) {
                    chat.reset();
                    success = NO;
                    NSLog(@"Exception while starting chat: %@", [NSString ncStringFromCString:exception.what()]);
                    [[NCFaceSingleton sharedInstance] markInvalid];
                }
            }];
            
            if (success)
            {
                boost::dynamic_pointer_cast<NCChatObserver>(observer)->setChat(chat);
                
                NSLog(@"joined chatroom %@ (%@-%@)", chatRoomId,
                      [[NCNdnRtcLibraryController sharedInstance] sessionPrefix], userPrefix);
                
                _chatIdToObserver[chatRoom] = boost::dynamic_pointer_cast<NCChatObserver>(observer);
                
                if (![ChatRoom chatRoomWithId:chatRoomId fromContext:self.context])
                {
                    ChatRoom *newChatRoom = [ChatRoom newChatRoomWithId:chatRoomId inContext:self.context];
                    newChatRoom.created = [NSDate date];
                    [self.context save:nil];
                }
            } // if success
            else
                self.initialized = NO;
        }
#endif
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
        return;
    }
    
    // get rid of any unicode characters if any
    NSData *strData = [message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    message = [[NSString alloc] initWithData:strData encoding:NSASCIIStringEncoding];
    
    const std::string msg([message cStringUsingEncoding:NSASCIIStringEncoding]);
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
        try {
            NSLog(@"Send message to %@: %@", chatId, message);
            it->second->getChat()->sendMessage(msg);
        }
        catch (std::exception &exception) {
            NSLog(@"Exception while sending message to chat: %@", [NSString ncStringFromCString:exception.what()]);
            [[NCFaceSingleton sharedInstance] markInvalid];
        }
    }];
}

-(void)leaveChat:(NSString *)chatId
{
    std::string chatRoom([chatId cStringUsingEncoding:NSASCIIStringEncoding]);
    ChatIdToObserverMap::iterator it = _chatIdToObserver.find(chatRoom);
    
    if (it == _chatIdToObserver.end())
        return;

    NSLog(@"left chatroom %s", it->first.c_str());
    
    [[NCFaceSingleton sharedInstance] performSynchronizedWithFace:^{
        it->second->getChat()->leave();
        it->second->getChat()->shutdown();
        _chatIdToObserver.erase(it);
    }];
}

-(void)initChatRooms
{
    NSLog(@"intializing chatrooms...");
    
    self.initialized = YES;
    [[User allUsersFromContext:self.context]
     enumerateObjectsUsingBlock:^(User* user, NSUInteger idx, BOOL *stop) {
        [self startChatWithUser:user.userPrefix];
    }];
}

-(void)leaveAllChatRooms
{
    if (self.initialized)
    {
        NSLog(@"leaving all chatrooms...");
        
        for (ChatIdToObserverMap::iterator it = _chatIdToObserver.begin();
             it != _chatIdToObserver.end(); it++)
        {
            NSLog(@"left chatroom %s", it->first.c_str());
            [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
                try {
                    if (it->second->getChat())
                    {
                        it->second->getChat()->leave();
                    }
                }
                catch (std::exception &exception) {
                     NSLog(@"Exception while leaving chat: %@", [NSString ncStringFromCString:exception.what()]);
                }
                
                try {
                    it->second->getChat()->shutdown();
                    NSLog(@"chat shut down");
                } catch (std::exception &exception) {
                    NSLog(@"Exception while shutting down chat: %@", [NSString ncStringFromCString:exception.what()]);
                }
            }];
        }
        
        _chatIdToObserver.clear();
    }
}

// KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [NCPreferencesController sharedInstance])
        [self reJoinRooms];
}

// notificaitons
-(void)onLocalSessionStatusChanged:(NSNotification*)notification
{
#ifdef CHATS_ENABLED
    NCSessionStatus status = (NCSessionStatus)[notification.userInfo[kSessionStatusKey] integerValue];
    NCSessionStatus oldStatus = (NCSessionStatus)[notification.userInfo[kSessionOldStatusKey] integerValue];
    
    if (status == SessionStatusOffline)
    {
        [self leaveAllChatRooms];
        self.initialized = NO;
        [[NCFaceSingleton sharedInstance] markInvalid];
    }
    else
        if (oldStatus == SessionStatusOffline)
        {
            if (!self.initialized)
            {
                if (![NCFaceSingleton sharedInstance].isValid)
                    [[NCFaceSingleton sharedInstance] reset];
                
                [self initChatRooms];
            }
        }
#endif
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

-(ChatMessage*)addChatMessageOfType:(NSString*)msgType
                   fromUser:(NSString*)userSessionPrefix
                messageBody:(NSString*)messageBody
           inChatRoomWithId:(NSString*)chatRoomId
{
    User *user = [User userByName:[userSessionPrefix getNdnRtcUserName]
                        andPrefix:[userSessionPrefix getNdnRtcHubPrefix]
                      fromContext:self.context];
    ChatMessage *chatMessage = [ChatMessage
                                newChatMessageFromUser:user
                                ofType:msgType
                                withMessageBody:messageBody
                                inContext:self.context];
    ChatRoom *chatRoom = [ChatRoom chatRoomWithId:chatRoomId
                                      fromContext:self.context];
    [chatRoom addMessagesObject:chatMessage];
    
    NSError *error = nil;
    [self.context save:&error];
    
    return chatMessage;
}

-(void)reJoinRooms
{
    [self leaveAllChatRooms];
    [self initChatRooms];
}

+(NSString*)chatsAppPrefixWithHubPrefix:(NSString*)hubPrefix
{
    return [NSString stringWithFormat:@"%@/%@/chat",
            hubPrefix, [NSString ndnRtcAppNameComponent]];
}

@end
