//
//  MFPanoramaPlayer.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MFPanoramaPlayer.h"

@interface MFPanoramaPlayer ()

@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong, readwrite) MFPanoramaPlayerItem *currentItem;
@property (nonatomic, assign, readwrite) MFPanoramaPlayerState state;

@end

@implementation MFPanoramaPlayer

- (void)dealloc {
    [self removeObservers];
}

- (instancetype)initWithPanoramaPlayerItem:(MFPanoramaPlayerItem *)item {
    self = [super init];
    if (self) {
        _currentItem = item;
        [self commonInit];
    }
    return self;
}

#pragma mark - Public

- (void)seekToTime:(CMTime)time {
    [self.player seekToTime:time];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    [self.player seekToTime:time completionHandler:completionHandler];
}

- (void)play {
    [self.player play];
    self.state = MFPanoramaPlayerStatePlaying;
}

- (void)pause {
    [self.player pause];
    self.state = MFPanoramaPlayerStatePaused;
}

#pragma mark - Private

- (void)commonInit {
    self.state = MFPanoramaPlayerStateUnKnown;
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.currentItem.playerItem];
    [self addObservers];
}

- (void)addObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(willResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    [self.currentItem.playerItem addObserver:self
                                  forKeyPath:@"status"
                                     options:NSKeyValueObservingOptionNew
                                     context:nil];
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                              queue:dispatch_get_main_queue()
                                         usingBlock:^(CMTime time) {
        __weak typeof(self) strongSelf = weakSelf;
        if (strongSelf.state == MFPanoramaPlayerStatePlaying &&
            CMTIME_COMPARE_INLINE(strongSelf.duration, <=, time)) {
            [strongSelf.player pause];
            strongSelf.state = MFPanoramaPlayerStateFinished;
        }
        if ([strongSelf.delegate respondsToSelector:@selector(player:currentTimeDidChanged:)]) {
            [strongSelf.delegate player:strongSelf currentTimeDidChanged:time];
        }
    }];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.currentItem.playerItem removeObserver:self
                                     forKeyPath:@"status"];
}

#pragma mark - Accessors

- (void)setState:(MFPanoramaPlayerState)state {
    _state = state;
    if ([self.delegate respondsToSelector:@selector(player:stateDidChanged:)]) {
        [self.delegate player:self stateDidChanged:state];
    }
}

- (CMTime)duration {
    return [self.currentItem.playerItem duration];
}

- (CMTime)currentTime {
    return [self.currentItem.playerItem currentTime];
}

#pragma mark - Notification

- (void)willResignActive:(NSNotification *)notification {
    if (self.state == MFPanoramaPlayerStatePlaying) {
        [self pause];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if ([keyPath isEqualToString:@"status"]){
            if (playerItem.status == AVPlayerItemStatusReadyToPlay){
                self.state = MFPanoramaPlayerStateReadyToPlay;
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                self.state = MFPanoramaPlayerStateFailed;
            } else{
                self.state = MFPanoramaPlayerStateUnKnown;
            }
        }
    }
}

@end
