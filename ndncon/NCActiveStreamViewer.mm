//
//  NCActiveStreamViewer.m
//  NdnCon
//
//  Created by Peter Gusev on 9/26/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#include <ndnrtc/ndnrtc-library.h>
#include <ndnrtc/params.h>

#import "NSView+NCAdditions.h"
#import "NSString+NCAdditions.h"
#import "NCStreamViewController.h"
#import "NCVideoThreadViewController.h"
#import "NCNdnRtcLibraryController.h"
#import "NCErrorController.h"
#import "NSTimer+NCAdditions.h"
#import "NSDictionary+NCAdditions.h"
#import "NSArray+NCAdditions.h"
#import "NCActiveStreamViewer.h"
#import "NCNdnRtcLibraryController.h"
#import "NCStatisticsWindowController.h"

using namespace ndnrtc;
using namespace ndnrtc::new_api;
class StreamObserver;

//******************************************************************************
@interface NCActiveStreamViewer ()
{
    NSDictionary* _currentThread;
    StreamObserver *_activeStreamObserver;
}

@property (weak) IBOutlet NCBlockDrawableView *infoView;
@property (weak) IBOutlet NCBlockDrawableView *statView;
@property (strong) IBOutlet NSView *renderView;
@property (weak) IBOutlet NSTextField *userNameLabel;
@property (weak) IBOutlet NSPopUpButton *mediaThreadsPopup;
@property (weak) IBOutlet NSScrollView *streamEventsScrollView;
@property (weak) IBOutlet NSTextField *videoStatusHintLabel;
@property (weak) IBOutlet NSTextField *consumerStatusLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *toggleStatButton;

@property (nonatomic) BOOL viewUpdated;
@property (unsafe_unretained) IBOutlet NSTextView *streamEventsTextView;
@property (nonatomic) NSTimer *fadeAnimationTimer;
@property (nonatomic) BOOL isStreamEventsViewVisible;
@property (nonatomic) BOOL isStatShown;

@property (nonatomic) NSTrackingArea *trackingArea;

@property (nonatomic) NCActiveUserInfo *userInfo;
@property (nonatomic, readonly) NSArray *mediaThreads;
@property (nonatomic, readonly) NSDictionary *currentThread;
@property (nonatomic) NSInteger currentThreadIdx;

@property (nonatomic, strong) NCStatisticsWindowController *statController;

@end

//******************************************************************************
class StreamObserver : public IConsumerObserver
{
public:
    StreamObserver(NCActiveStreamViewer* viewer):
    streamPrefix_(""),
    viewer_(viewer){}
    
    ~StreamObserver()
    {
        viewer_ = NULL;
        unregisterObserver();
    }
    
    void
    setStreamPrefix(NSString* streamPrefix)
    {
        streamPrefix_ = std::string([streamPrefix cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    
    int
    registerObserver()
    {
        NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
        return lib->setStreamObserver(streamPrefix_, this);
    }
    
    NSString*
    getStreamPrefix()
    {
        return [NSString ncStringFromCString:streamPrefix_.c_str()];
    }
    
    void
    unregisterObserver()
    {
        if (streamPrefix_ != "")
        {
            NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
            lib->removeStreamObserver(streamPrefix_);
        }
    }
    
    void
    onStatusChanged(ConsumerStatus newStatus)
    {
        static std::string statusToString[] = {
            [ConsumerStatusStopped] =     "stopped",
            [ConsumerStatusNoData] =     "chasing",
            [ConsumerStatusAdjusting] =      "adjusting",
            [ConsumerStatusBuffering] =   "buffering",
            [ConsumerStatusFetching] =     "fetching",
        };
        
        lastStatus_ = newStatus;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            viewer_.consumerStatusLabel.stringValue = [NSString ncStringFromCString:statusToString[newStatus].c_str()];
            if (newStatus < ConsumerStatusFetching)
                [viewer_.progressIndicator startAnimation:nil];
            else
                [viewer_.progressIndicator stopAnimation:nil];
        });
    }
    
    void
    onRebufferingOccurred()
    {
        //        [[[NSObject alloc] init] notifyNowWithNotificationName:NCStreamRebufferingNotification
        //                                                   andUserInfo:nil];
    }
    
    void
    onPlaybackEventOccurred(PlaybackEvent event, unsigned int frameSeqNo)
    {
        //        [[[NSObject alloc] init] notifyNowWithNotificationName:NCStreamObserverEventNotification
        //                                                   andUserInfo:@{
        //                                                                 kStreamObserverEventTypeKey:@(event),
        //                                                                 kStreamObserverEventDataKey:@(frameSeqNo)
        //                                                                 }];
    }
    
    void
    onThreadSwitched(const std::string& threadName)
    {
        NSLog(@"active thread is %s for %s", threadName.c_str(),
              streamPrefix_.c_str());
    }
    
private:
    ConsumerStatus lastStatus_;
    std::string streamPrefix_;
    __weak NCActiveStreamViewer* viewer_;
};

//******************************************************************************
@implementation NCActiveStreamViewer

-(id)init
{
    self = [super initWithNibName:@"NCActiveStreamView"
                           bundle:nil];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

-(void)initialize
{
    self.viewUpdated = NO;
    self.isStreamEventsViewVisible = NO;
    _activeStreamObserver = new StreamObserver(self);
    self.statController = [[NCStatisticsWindowController alloc] init];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    [((NCBlockDrawableView*)self.view) addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor blackColor] set];
        NSRectFill(view.bounds);
    }];
    
    [self.infoView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor colorWithWhite:1. alpha:0.3] set];
        NSRectFill(view.bounds);
    }];
    
    [self.statView addDrawBlock:^(NSView *view, NSRect dirtyRect) {
        [[NSColor colorWithWhite:.4 alpha:0.7] set];
        NSRectFill(view.bounds);
    }];
}

-(void)dealloc
{
    _activeStreamObserver->unregisterObserver();
    delete _activeStreamObserver;
}

-(void)awakeFromNib
{
    [self.streamEventsTextView setDrawsBackground:NO];
    [self.streamEventsScrollView setDrawsBackground:NO];
    [self setButtonTitleFor:self.toggleStatButton toString:@"Streaming statistics" withColor:[NSColor colorWithWhite:0.7 alpha:1]];
}

-(void)viewDidLoad
{
    [self updateTrackingAreas];
    self.infoView.alphaValue = 0.;
    [self.progressIndicator startAnimation:nil];
    
    [self.statView addSubview:self.statController.view];
    self.statController.view.frame = self.statView.bounds;
    
    NSView *statisticsView = self.statController.view;
    [self.statView addConstraint:[NSLayoutConstraint constraintWithItem:statisticsView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.statView
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.f constant:0.f]];
    [self.statView addConstraint:[NSLayoutConstraint constraintWithItem:statisticsView
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.statView
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1.f constant:0.f]];
}

#pragma mark - properties
-(void)setRenderer:(NCVideoStreamRenderer *)renderer
{
    _renderer = renderer;
    
    if (self.viewUpdated)
        [self.renderer setRenderingView:self.renderView];
}

-(NSArray *)mediaThreads
{
    NSDictionary *fullStreamConfiguration = [[self.userInfo streamConfigurations] streamWithName:self.activeStreamConfiguration[kNameKey]];
    
    return fullStreamConfiguration[kThreadsArrayKey];
}

-(void)setCurrentThreadIdx:(NSInteger)currentThreadIdx
{
    if (currentThreadIdx >= 0 &&
        _currentThreadIdx != currentThreadIdx)
    {
        [self willChangeValueForKey:@"streamPrefix"];
        _currentThreadIdx = currentThreadIdx;
        [self didChangeValueForKey:@"streamPrefix"];
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(activeStreamViewer:didSelectThreadWithConfiguration:)])
        {
            [self.delegate activeStreamViewer:self didSelectThreadWithConfiguration:self.currentThread];
        }
    }
}

-(NSDictionary *)currentThread
{
    return self.mediaThreads[self.currentThreadIdx];
}

-(NSString *)streamPrefix
{
    return [NSString streamPrefixForStream:self.activeStreamConfiguration[kNameKey]
                                      user:self.userInfo.username
                                withPrefix:self.userInfo.hubPrefix];
}

#pragma mark - actions
- (IBAction)toggleStat:(id)sender {
    if (self.isStatShown)
    {
//        self.statController.view.frame = self.statView.bounds;
        NSLog(@"stat frame %@", NSStringFromRect(self.statController.view.frame));
        [self.statController startStatUpdateForStream:self.activeStreamConfiguration[kNameKey]
                                                 user:self.userInfo.username
                                           withPrefix:self.userInfo.hubPrefix];
    }
    else
        [self.statController stopStatUpdate];
}

#pragma mark - public
-(void)setActiveStream:(NSDictionary*)streamConfiguration
                  user:(NSString*)username
             andPrefix:(NSString*)hubPrefix
{
    [self willChangeValueForKey:@"streamPrefix"];
    [self willChangeValueForKey:@"mediaThreads"];
    [self willChangeValueForKey:@"currentThreadIdx"];
    [self willChangeValueForKey:@"activeStreamConfiguration"];

    BOOL newUser = (![self.userInfo.username isEqualToString:username] ||
                    ![self.userInfo.hubPrefix isEqualToString: hubPrefix]);

    if (newUser)
        self.userInfo = [[NCUserDiscoveryController sharedInstance] userWithName:username andHubPrefix:hubPrefix];
    
    _activeStreamConfiguration = streamConfiguration;
    
    NdnRtcLibrary *lib = (NdnRtcLibrary*)[[NCNdnRtcLibraryController sharedInstance] getLibraryObject];
    std::string streamName([[NSString streamPrefixForStream:streamConfiguration[kNameKey]
                                                        user:username
                                                     withPrefix:hubPrefix] cStringUsingEncoding:NSASCIIStringEncoding]);
    std::string threadName = lib->getStreamThread(streamName);
    NSString *activeThreadName = [NSString ncStringFromCString:threadName.c_str()];

    _currentThreadIdx = [[self.mediaThreads valueForKey:kNameKey] indexOfObject:activeThreadName];
    // set active stream viewer observer
    if (![_activeStreamObserver->getStreamPrefix() isEqualToString:@""])
        _activeStreamObserver->unregisterObserver();
    
    _activeStreamObserver->setStreamPrefix(self.streamPrefix);
    _activeStreamObserver->registerObserver();
    
    if (self.isStatShown)
    {
        if (newUser)
            [self.statController startStatUpdateForStream: _activeStreamConfiguration[kNameKey]
                                                     user:self.userInfo.username
                                                withPrefix:self.userInfo.hubPrefix];
        else
            self.statController.selectedStream = _activeStreamConfiguration[kNameKey];
    }
    
    [self didChangeValueForKey:@"activeStreamConfiguration"];
    [self didChangeValueForKey:@"currentThreadIdx"];
    [self didChangeValueForKey:@"mediaThreads"];
    [self didChangeValueForKey:@"streamPrefix"];
}

-(void)clearStreamEventView
{
    [self.streamEventsTextView setString:@""];
}

-(void)clear
{
    [self clearStreamEventView];
    self.userInfo = nil;
    self.renderer = nil;
    self.isStatShown = NO;
}

-(void)renderStreamEvent:(NSString*)eventDescription
{
    if (!self.isStreamEventsViewVisible)
        return;
    
    static NSDictionary *stringAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *pStyle;
        pStyle = [[NSMutableParagraphStyle alloc] init];
        [pStyle setAlignment:NSRightTextAlignment];
        
        stringAttributes = @{
                             NSParagraphStyleAttributeName: pStyle,
                             NSBackgroundColorAttributeName: [NSColor clearColor],
                             NSFontAttributeName: [NSFont systemFontOfSize:10],
                             NSForegroundColorAttributeName: [NSColor whiteColor]
                             };
    });
    
    NSString *textEntry = [NSString stringWithFormat:@"%@\n", eventDescription];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc]
                                    initWithString:textEntry
                                    attributes:stringAttributes];
        
        [[_streamEventsTextView textStorage] appendAttributedString:attr];
        [_streamEventsTextView scrollRangeToVisible:NSMakeRange([[_streamEventsTextView string] length], 0)];
    });
    
    self.streamEventsTextView.alphaValue = 1.;
    
    __weak NCActiveStreamViewer *selfWeak = self;
    if (self.fadeAnimationTimer)
        [self.fadeAnimationTimer invalidate];
    
    self.fadeAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:2.
                                                     repeats:NO
                                                   fireBlock:^(NSTimer *timer) {
                                                       [[selfWeak streamEventsTextView] setAlphaValue:0.];
                                                       selfWeak.fadeAnimationTimer = nil;
                                                   }];
}

-(void)setIsStreamEventsViewVisible:(BOOL)isStreamEventsViewVisible
{
    if (_isStreamEventsViewVisible != isStreamEventsViewVisible)
    {
        _isStreamEventsViewVisible = isStreamEventsViewVisible;
        [self.streamEventsScrollView setHidden:!isStreamEventsViewVisible];
        
        if (isStreamEventsViewVisible)
            [self renderStreamEvent:@"stream events enabled"];
    }
}

#pragma mark - NCVideoPreviewViewDelegate
-(void)videoPreviewViewDidUpdatedFrame:(NCVideoPreviewView *)videoPreviewView
{
    if (!self.viewUpdated
        && !CGRectEqualToRect(CGRectZero, self.renderView.bounds))
    {
        self.viewUpdated = YES;
        [self.renderer setRenderingView:self.renderView];
    }
}

#pragma mark - overriden
-(void)mouseEntered:(NSEvent *)theEvent
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        [self setOverlaysVisible: YES];
    } completionHandler:^{
        [self setOverlaysVisible: YES];
    }];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    if (!self.isStatShown)
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            [self setOverlaysVisible: NO];
        }
                            completionHandler:^{
                                [self setOverlaysVisible: NO];
                            }];
    
}

-(void)viewDidLayout
{
    [self updateTrackingAreas];
}

-(void)updateTrackingAreas
{
    [self.view removeTrackingArea:self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.view.bounds
                                                     options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                       owner:self
                                                    userInfo:nil];
    [self.view addTrackingArea:self.trackingArea];
}

-(void)setOverlaysVisible:(BOOL)isVisible
{
    self.infoView.alphaValue = isVisible ? 1 : 0;
    self.toggleStatButton.alphaValue = isVisible ? 1 : 0;
}

#pragma mark - private
- (void)setButtonTitleFor:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:title attributes:attrsDictionary];
    [button setAttributedTitle:attrString];
}

@end

//******************************************************************************
@interface NCThreadInfoValueTransformer : NSValueTransformer

@end

@implementation NCThreadInfoValueTransformer

+(BOOL)allowsReverseTransformation
{
    return NO;
}

+(Class)transformedValueClass
{
    return [NSArray class];
}

-(id)transformedArrayValue:(NSArray*)value
{
    __block NSMutableArray *result = [NSMutableArray array];
    
    [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject: [obj mediaThreadFullHint]];
    }];
    
    return result;
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]])
        return [self transformedArrayValue:value];
    
    return nil;
}


@end
