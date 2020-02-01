//
//  MFPanoramaPlayer.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaPlayerItem.h"

typedef NS_ENUM(NSInteger, MFPanoramaPlayerState) {
    MFPanoramaPlayerStateUnKnown,
    MFPanoramaPlayerStateReadyToPlay,  // 准备好播放
    MFPanoramaPlayerStatePlaying,  // 正在播放
    MFPanoramaPlayerStatePaused,  // 播放暂停
    MFPanoramaPlayerStateFinished,  // 播放完成
    MFPanoramaPlayerStateFailed,  //加载失败
};

@class MFPanoramaPlayer;

NS_ASSUME_NONNULL_BEGIN

@protocol MFPanoramaPlayerDelegate <NSObject>

/// 状态变化回调
- (void)player:(MFPanoramaPlayer *)player stateDidChanged:(MFPanoramaPlayerState)currentState;
/// 播放进度回调
- (void)player:(MFPanoramaPlayer *)player currentTimeDidChanged:(CMTime)currentTime;

@end

@interface MFPanoramaPlayer : NSObject

@property (nonatomic, weak) id <MFPanoramaPlayerDelegate> delegate;

@property (nonatomic, strong, readonly) AVPlayer *player;
@property (nonatomic, strong, readonly) MFPanoramaPlayerItem *currentItem;

/// 播放状态
@property (nonatomic, assign, readonly) MFPanoramaPlayerState state;
/// 当前播放进度
@property (nonatomic, assign, readonly) CMTime currentTime;
/// 视频总时长
@property (nonatomic, assign, readonly) CMTime duration;

- (instancetype)initWithPanoramaPlayerItem:(MFPanoramaPlayerItem *)item;

- (void)seekToTime:(CMTime)time;
- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)play;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
