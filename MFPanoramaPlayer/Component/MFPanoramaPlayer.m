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

@end

@implementation MFPanoramaPlayer

- (instancetype)initWithPanoramaPlayerItem:(MFPanoramaPlayerItem *)item {
    self = [super initWithPlayerItem:item.playerItem];
    if (self) {
        _playerItem = item;
    }
    return self;
}

@end
