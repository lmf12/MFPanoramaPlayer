//
//  MFPanoramaPlayerItem.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaVideoCompositing.h"
#import "MFPanoramaVideoCompositionInstruction.h"

#import "MFPanoramaPlayerItem.h"

@interface MFPanoramaPlayerItem ()

@property (nonatomic, strong, readwrite) AVAsset *asset;
@property (nonatomic, strong, readwrite) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;

@end

@implementation MFPanoramaPlayerItem

- (instancetype)initWithAsset:(AVAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
        [self setupPlayerItem];
    }
    return self;
}

#pragma mark - Private

- (void)setupPlayerItem {
    self.videoComposition = [self createVideoCompositionWithAsset:self.asset];
    self.videoComposition.customVideoCompositorClass = [MFPanoramaVideoCompositing class];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
    self.playerItem.videoComposition = self.videoComposition;
}

- (AVMutableVideoComposition *)createVideoCompositionWithAsset:(AVAsset *)asset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    NSArray *instructions = videoComposition.instructions;
    NSMutableArray *newInstructions = [NSMutableArray array];
    for (AVVideoCompositionInstruction *instruction in instructions) {
        NSArray *layerInstructions = instruction.layerInstructions;
        // TrackIDs
        NSMutableArray *trackIDs = [NSMutableArray array];
        for (AVVideoCompositionLayerInstruction *layerInstruction in layerInstructions) {
            [trackIDs addObject:@(layerInstruction.trackID)];
        }
        MFPanoramaVideoCompositionInstruction *newInstruction = [[MFPanoramaVideoCompositionInstruction alloc] initWithSourceTrackIDs:trackIDs timeRange:instruction.timeRange];
        newInstruction.layerInstructions = instruction.layerInstructions;
        [newInstructions addObject:newInstruction];
    }
    videoComposition.instructions = newInstructions;
    return videoComposition;
}

#pragma mark - Accessors

- (void)setAngleX:(CGFloat)angleX {
    _angleX = angleX;
    NSArray *instructions = self.videoComposition.instructions;
    for (MFPanoramaVideoCompositionInstruction *instruction in instructions) {
        instruction.angleX = angleX;
    }
}

- (void)setAngleY:(CGFloat)angleY {
    _angleY = angleY;
    NSArray *instructions = self.videoComposition.instructions;
    for (MFPanoramaVideoCompositionInstruction *instruction in instructions) {
        instruction.angleY = angleY;
    }
}

- (void)setMotionEnable:(BOOL)motionEnable {
    _motionEnable = motionEnable;
    NSArray *instructions = self.videoComposition.instructions;
    for (MFPanoramaVideoCompositionInstruction *instruction in instructions) {
        instruction.motionEnable = motionEnable;
    }
}

- (void)setPerspective:(CGFloat)perspective {
    _perspective = perspective;
    NSArray *instructions = self.videoComposition.instructions;
    for (MFPanoramaVideoCompositionInstruction *instruction in instructions) {
        instruction.perspective = perspective;
    }
}

@end
