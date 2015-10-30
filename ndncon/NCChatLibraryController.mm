//
//  NCChatLibraryController.m
//  NdnCon
//
//  Created by Peter Gusev on 10/13/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndn-entity-discovery/chrono-chat.h>
#include <ndn-entity-discovery/external-observer.h>

#import "NCChatLibraryController.h"
#import "NCNdnRtcLibraryController.h"
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
NSString* const NCChatMessageUserPrefixKey = @"userPrefix";
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
        NSString *userPrefixStr = [[NSString ncStringFromCString:userHubPrefix] getNdnRtcHubPrefix];
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
                                                                                          NCChatMessageUserPrefixKey: userPrefixStr,
                                                                                          NCChatMessageBodyKey: message
                                                                                          }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ChatMessage *chatMessage = [[NCChatLibraryController sharedInstance] addChatMessageOfType:typeStr
                                                                                             fromUser:userSessionPrefix
                                                                                          messageBody:message
                                                                                     inChatRoomWithId:chatRoomId_];

            if (chatMessage.user &&
                ![chatMessage.user.name isEqualToString:[NCPreferencesController sharedInstance].userName] &&
                ![chatMessage.user.prefix isEqualToString:[NCPreferencesController sharedInstance].prefix])
                userInfo[NCChatMessageUserKey] = chatMessage.user;
            
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

-(void)joinChatroom:(NCChatRoom *)chatroom
{
    if ([NCFaceSingleton sharedInstance].isValid)
    {
        NSString *chatRoomId = chatroom.chatroomName;
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
            return;
        else
        {
            ndn::ptr_lib::shared_ptr<ChatObserver> observer(new NCChatObserver(chatRoomId));
            __block boost::shared_ptr<Chat> chat(new Chat(broadcastPrefixName, screenName, chatRoom,
                                                          chatPrefixName, observer.get(),
                                                          *[[NCFaceSingleton sharedInstance] getFace],
                                                          *[[NCFaceSingleton sharedInstance] getKeyChain],
                                                          [[NCFaceSingleton sharedInstance] getKeyChain]->getDefaultCertificateName(),
                                                          60000, 120000));
            __block BOOL success = YES;
            
            [[NCFaceSingleton sharedInstance] performSynchronizedWithFaceBlocking:^{
                try {
                    chat->start();
                } catch (std::exception &exception) {
                    chat.reset();
                    success = NO;
                    NSLog(@"Exception while starting chat: %@", [NSString ncStringFromCString:exception.what()]);
                    [[NCFaceSingleton sharedInstance] markInvalid];
                    [[NCErrorController sharedInstance] postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
                }
            }];
            
            if (success)
            {
                boost::dynamic_pointer_cast<NCChatObserver>(observer)->setChat(chat);
                
                NSLog(@"joined chatroom %@", chatRoomId);
                
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
    }
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
            [[NCErrorController sharedInstance] postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
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
    }
    else
        if (oldStatus == SessionStatusOffline)
        {
            if (!self.initialized)
            {
                if (![NCFaceSingleton sharedInstance].isValid)
                    [[NCFaceSingleton sharedInstance] reset];
                
                self.initialized = YES;
            }
        }
#endif
}

// private
-(ChatMessage*)addChatMessageOfType:(NSString*)msgType
                   fromUser:(NSString*)userSessionPrefix
                messageBody:(NSString*)messageBody
           inChatRoomWithId:(NSString*)chatRoomId
{
    User *user = [User userByName:[userSessionPrefix getNdnRtcUserName]
                        andPrefix:[userSessionPrefix getNdnRtcHubPrefix]
                      fromContext:self.context];
    
    if (!user)
        user = [User newUserWithName:[userSessionPrefix getNdnRtcUserName]
                           andPrefix:[userSessionPrefix getNdnRtcHubPrefix]
                           inContext:self.context];
    
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

+(NSString*)chatsAppPrefixWithHubPrefix:(NSString*)hubPrefix
{
    return [NSString stringWithFormat:@"%@/%@/chat",
            hubPrefix, [NSString ndnRtcAppNameComponent]];
}

@end
