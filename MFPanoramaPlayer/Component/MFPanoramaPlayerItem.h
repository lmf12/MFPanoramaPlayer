//
//  MFPanoramaPlayerItem.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFPanoramaPlayerItem : NSObject

@property (nonatomic, strong, readonly) AVAsset *asset;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;

/// 水平方向旋转角 0 ～ 2 * PI，默认 0，正方向是往右转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleX;
/// 竖直方向旋转角 0 ～ 2 * PI，默认 0，正方向是往上转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleY;
/// 是否启动设备角度检测，默认 NO
@property (nonatomic, assign) BOOL motionEnable;

/// 视角大小，角度越大，视野内的图像越大，30 ~ 100，默认 45
@property (nonatomic, assign) CGFloat perspective;

/// 初始的尺寸
@property (nonatomic, assign, readonly) CGSize originRenderSize;
/// 实际渲染尺寸，不设置则使用 originRenderSize
@property (nonatomic, assign) CGSize renderSize;

- (instancetype)initWithAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
