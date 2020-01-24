//
//  MFPanoramaPlayerItem.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFPanoramaPlayerItem : NSObject

@property (nonatomic, strong, readonly) AVAsset *asset;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;

- (instancetype)initWithAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
