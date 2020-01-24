//
//  MFPanoramaPlayer.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaPlayerItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFPanoramaPlayer : NSObject

@property (nonatomic, strong, readonly) AVPlayer *player;

- (instancetype)initWithPlayerItem:(MFPanoramaPlayerItem *)item;

- (void)play;

@end

NS_ASSUME_NONNULL_END
