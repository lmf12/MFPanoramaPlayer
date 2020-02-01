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

/// 视角大小，角度越大，视野内的图像越大，30 ~ 100，默认 45
@property (nonatomic, assign) CGFloat perspective;

/// 实际渲染尺寸，不设置则使用原始尺寸
@property (nonatomic, assign) CGSize renderSize;

/// 处理 pixelBuffer，并返回结果
- (CVPixelBufferRef)applyPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
