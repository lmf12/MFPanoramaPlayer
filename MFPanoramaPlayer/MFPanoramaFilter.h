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

- (CVPixelBufferRef)outputPixelBuffer;

@end

NS_ASSUME_NONNULL_END
