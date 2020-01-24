//
//  MFPanoramaPlayer.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaPlayer.h"

@interface MFPanoramaPlayer ()

@property (nonatomic, strong) MFPanoramaPlayerItem *playerItem;
@property (nonatomic, strong, readwrite) AVPlayer *player;

@end

@implementation MFPanoramaPlayer

- (instancetype)initWithPlayerItem:(MFPanoramaPlayerItem *)item {
    self = [super init];
    if (self) {
        _playerItem = item;
        _player = [[AVPlayer alloc] initWithPlayerItem:item.playerItem];
    }
    return self;
}

#pragma mark - Public

- (void)play {
    [self.player play];
}

@end
