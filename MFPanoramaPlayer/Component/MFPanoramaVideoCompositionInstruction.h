//
//  MFPanoramaVideoCompositionInstruction.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/31.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFPanoramaVideoCompositionInstruction : NSObject <AVVideoCompositionInstruction>

@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, assign) BOOL enablePostProcessing;
@property (nonatomic) BOOL containsTweening;

@property (nonatomic, readonly, nullable) NSArray<NSValue *> *requiredSourceTrackIDs;
@property (nonatomic, readonly) CMPersistentTrackID passthroughTrackID;

@property (nonatomic, copy) NSArray<AVVideoCompositionLayerInstruction *> *layerInstructions;

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)passthroughTrackID timeRange:(CMTimeRange)timeRange;
- (instancetype)initWithSourceTrackIDs:(NSArray<NSValue *> *)sourceTrackIDs timeRange:(CMTimeRange)timeRange;

/// 水平方向旋转角 0 ～ 2 * PI，默认 0，正方向是往右转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleX;
/// 竖直方向旋转角 0 ～ 2 * PI，默认 0，正方向是往上转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleY;
/// 是否启动设备角度检测，默认 NO
@property (nonatomic, assign) BOOL motionEnable;

/// 处理 pixelBuffer，并返回结果
- (CVPixelBufferRef)applyPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
