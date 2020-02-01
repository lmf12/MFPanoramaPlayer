//
//  MFPanoramaFilter.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFPanoramaFilter : NSObject

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

/// 水平方向旋转角 0 ～ 2 * PI，默认 0，正方向是往右转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleX;
/// 竖直方向旋转角 0 ～ 2 * PI，默认 0，正方向是往上转，motionEnable 为 NO 才有效
@property (nonatomic, assign) CGFloat angleY;
/// 是否启动设备角度检测，默认 NO
@property (nonatomic, assign) BOOL motionEnable;

/// 视角大小，角度越大，视野内的图像越大，30 ~ 100，默认 45
@property (nonatomic, assign) CGFloat perspective;
/// 最终的渲染尺寸，设置为 CGSizeZero 时，使用 pixelBuffer 的尺寸
@property (nonatomic, assign) CGSize renderSize;

- (CVPixelBufferRef)outputPixelBuffer;

@end

NS_ASSUME_NONNULL_END
