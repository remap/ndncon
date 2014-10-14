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
    ndn::Face _chatFace;
    ndn::KeyChain _chatKeyChain;
}

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

-(id)init
{
    self = [super init];
    
    if (self)
    {
        try
        {
            _chatFace = Face([[NCPreferencesController sharedInstance].daemonHost cStringUsingEncoding:NSASCIIStringEncoding],
                            (unsigned short)[NCPreferencesController sharedInstance].daemonPort.intValue);
            _chatFace.setCommandSigningInfo(_chatKeyChain, _chatKeyChain.getDefaultCertificateName());
        }
        catch (std::exception &exception)
        {
            [[NCErrorController sharedInstance]
             postErrorWithMessage:[NSString ncStringFromCString:exception.what()]];
            
            return nil;
        }
    }
    
    return self;
}

-(void)dealloc
{
    
}

// public
-(NSString *)startChatWithUser:(NSString *)username
{
    NSString *chatRoomId = [NCChatLibraryController chatRoomIdForUser:[NCPreferencesController sharedInstance].userName
                                                              andUser:username];
    std::string broadcastPrefix([[NCPreferencesController sharedInstance].chatBroadcastPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    Name broadcastPrefixName(broadcastPrefix);
    const std::string screenName([[NCPreferencesController sharedInstance].userName cStringUsingEncoding:NSASCIIStringEncoding]);
    const std::string chatRoom([chatRoomId cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string hubPrefix([[NCPreferencesController sharedInstance].prefix cStringUsingEncoding:NSASCIIStringEncoding]);
    Name hubPrefixName(hubPrefix);
    ptr_lib::shared_ptr<ChatObserver> observer(new NCChatObserver());
    Chat* chat = new Chat(broadcastPrefixName, screenName, chatRoom,
                          hubPrefixName, observer, _chatFace, _chatKeyChain, _chatKeyChain.getDefaultCertificateName());
    
    dynamic_pointer_cast<NCChatObserver>(observer)->setChat(chat);
    
    if (_chatIdToObserver.find(chatRoom) != _chatIdToObserver.end())
    {
        [[NCErrorController sharedInstance] postErrorWithMessage:@"Chat room exists already"];
        return nil;
    }
    else
        _chatIdToObserver[chatRoom] = dynamic_pointer_cast<NCChatObserver>(observer);
    
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
    it->second->getChat()->sendMessage(msg);
}

-(void)leaveChat:(NSString *)chatId
{
    std::string chatRoom([chatId cStringUsingEncoding:NSASCIIStringEncoding]);
    ChatIdToObserverMap::iterator it = _chatIdToObserver.find(chatRoom);
    
    if (it == _chatIdToObserver.end())
        return;
    
    it->second->getChat()->leave();
    _chatIdToObserver.erase(it);
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

@end
