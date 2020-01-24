//
//  MFPanoramaPlayerItem.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaVideoCompositing.h"

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
    self.videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.asset];
    self.videoComposition.customVideoCompositorClass = [MFPanoramaVideoCompositing class];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
    self.playerItem.videoComposition = self.videoComposition;
}

@end
