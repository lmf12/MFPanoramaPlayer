//
//  MFPanoramaVideoCompositing.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaFilter.h"

#import "MFPanoramaVideoCompositing.h"

@interface MFPanoramaVideoCompositing ()

@property (nonatomic, strong) dispatch_queue_t renderContextQueue;
@property (nonatomic, strong) dispatch_queue_t renderingQueue;
@property (nonatomic, assign) BOOL shouldCancelAllRequests;

@property (nonatomic, strong) AVVideoCompositionRenderContext *renderContext;
@property (nonatomic, strong) MFPanoramaFilter *panoramaFilter;

@end

@implementation MFPanoramaVideoCompositing

- (instancetype)init {
    self = [super init];
    if (self) {
        _sourcePixelBufferAttributes = @{(id)kCVPixelBufferOpenGLCompatibilityKey: @YES,
                                         (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
        _requiredPixelBufferAttributesForRenderContext = @{(id)kCVPixelBufferOpenGLCompatibilityKey: @YES,
                                                           (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};

        _renderContextQueue = dispatch_queue_create("com.lymamli.panorama.rendercontextqueue", 0);
        _renderingQueue = dispatch_queue_create("com.lymamli.panorama.renderingqueue", 0);
        _panoramaFilter = [[MFPanoramaFilter alloc] init];
        _panoramaFilter.motionEnable = YES;
    }
    return self;
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    dispatch_sync(self.renderContextQueue, ^{
        self.renderContext = newRenderContext;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)asyncVideoCompositionRequest {
    dispatch_async(self.renderingQueue, ^{
        @autoreleasepool {
            if (self.shouldCancelAllRequests) {
                [asyncVideoCompositionRequest finishCancelledRequest];
            } else {
                CVPixelBufferRef resultPixels = [self newRenderdPixelBufferForRequest:asyncVideoCompositionRequest];
                if (resultPixels) {
                    [asyncVideoCompositionRequest finishWithComposedVideoFrame:resultPixels];
                    CVPixelBufferRelease(resultPixels);
                } else {
                    NSError *error = [NSError errorWithDomain:@"com.lymamli.panorama.videocompositor" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Composition request new pixel buffer failed.", nil)}];
                    [asyncVideoCompositionRequest finishWithError:error];
                }
            }
        }
    });
}

- (void)cancelAllPendingVideoCompositionRequests {
    self.shouldCancelAllRequests = YES;
    dispatch_barrier_async(self.renderingQueue, ^{
        self.shouldCancelAllRequests = NO;
    });
}

- (CVPixelBufferRef)newRenderdPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request {
    CVPixelBufferRef pixelBuffer = [self pixelBufferWithRequest:request];
    self.panoramaFilter.pixelBuffer = pixelBuffer;
    CVPixelBufferRef outputPixelBuffer = self.panoramaFilter.outputPixelBuffer;
    CVPixelBufferRetain(outputPixelBuffer);
    
    return outputPixelBuffer;
}

- (CVPixelBufferRef)pixelBufferWithRequest:(AVAsynchronousVideoCompositionRequest *)request {
    AVVideoCompositionInstruction *videoCompositionInstruction = (AVVideoCompositionInstruction *)request.videoCompositionInstruction;
    NSArray<AVVideoCompositionLayerInstruction *> *layerInstructions = videoCompositionInstruction.layerInstructions;
    CMPersistentTrackID trackID = layerInstructions.firstObject.trackID;
    
    return [request sourceFrameByTrackID:trackID];
}

@end
