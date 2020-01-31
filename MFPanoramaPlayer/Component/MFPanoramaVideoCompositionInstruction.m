//
//  MFPanoramaVideoCompositionInstruction.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/31.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaFilter.h"

#import "MFPanoramaVideoCompositionInstruction.h"

@interface MFPanoramaVideoCompositionInstruction ()

@property (nonatomic, strong) MFPanoramaFilter *panoramaFilter;

@end

@implementation MFPanoramaVideoCompositionInstruction

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)passthroughTrackID timeRange:(CMTimeRange)timeRange {
    self = [super init];
    if (self) {
        _passthroughTrackID = passthroughTrackID;
        _timeRange = timeRange;
        _requiredSourceTrackIDs = @[];
        _containsTweening = NO;
        _enablePostProcessing = NO;
        _panoramaFilter = [[MFPanoramaFilter alloc] init];
    }
    return self;
}

- (instancetype)initWithSourceTrackIDs:(NSArray<NSValue *> *)sourceTrackIDs timeRange:(CMTimeRange)timeRange {
    self = [super init];
    if (self) {
        _requiredSourceTrackIDs = sourceTrackIDs;
        _timeRange = timeRange;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _containsTweening = YES;
        _enablePostProcessing = NO;
        _panoramaFilter = [[MFPanoramaFilter alloc] init];
    }
    return self;
}

#pragma mark - Public

- (CVPixelBufferRef)applyPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    self.panoramaFilter.pixelBuffer = pixelBuffer;
    CVPixelBufferRef outputPixelBuffer = self.panoramaFilter.outputPixelBuffer;
    CVPixelBufferRetain(outputPixelBuffer);
    return outputPixelBuffer;
}

#pragma marl - Accessors

- (void)setAngleX:(CGFloat)angleX {
    _angleX = angleX;
    self.panoramaFilter.angleX = angleX;
}

- (void)setAngleY:(CGFloat)angleY {
    _angleY = angleY;
    self.panoramaFilter.angleY = angleY;
}

- (void)setMotionEnable:(BOOL)motionEnable {
    _motionEnable = motionEnable;
    self.panoramaFilter.motionEnable = motionEnable;
}

- (void)setPerspective:(CGFloat)perspective {
    _perspective = perspective;
    self.panoramaFilter.perspective = perspective;
}

@end
