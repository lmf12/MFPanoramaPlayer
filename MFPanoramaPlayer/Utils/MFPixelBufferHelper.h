//
//  MFPixelBufferHelper.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/25.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFPixelBufferHelper : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;

/// 创建 RGB 格式的 pixelBuffer
- (CVPixelBufferRef)createPixelBufferWithSize:(CGSize)size;

/// YUV 格式的 PixelBuffer 转化为纹理
- (GLuint)convertYUVPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

/// RBG 格式的 PixelBuffer 转化为纹理
- (GLuint)convertRGBPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
