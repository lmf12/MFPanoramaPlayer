//
//  MFPanoramaPlayer.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaPlayer.h"

@interface MFPanoramaPlayer ()

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong, readwrite) AVPlayer *player;

@end

@implementation MFPanoramaPlayer

- (instancetype)initWithPlayerItem:(AVPlayerItem *)item {
    self = [super init];
    if (self) {
        self.playerItem = item;
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
    }
    return self;
}

#pragma mark - Public

- (void)play {
    [self.player play];
}

@end
