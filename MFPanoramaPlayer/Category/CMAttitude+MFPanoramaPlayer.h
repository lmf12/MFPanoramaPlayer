//
//  CMAttitude+MFPanoramaPlayer.h
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/29.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMAttitude (MFPanoramaPlayer)

- (GLKVector3)mf_eulerianAngle;

@end

NS_ASSUME_NONNULL_END
