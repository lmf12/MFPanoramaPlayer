//
//  CMAttitude+MFPanoramaPlayer.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/29.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "CMAttitude+MFPanoramaPlayer.h"

@implementation CMAttitude (MFPanoramaPlayer)

#pragma mark - Public

- (GLKVector3)mf_eulerianAngle {
    return [self eulerianAngleWithQuaternion:self.quaternion];
}

#pragma mark - Private

/// 四元数转欧拉角 (roll, pitch, yaw)
- (GLKVector3)eulerianAngleWithQuaternion:(CMQuaternion)quaternion {
    GLKVector3 v3;
    
    double ysqr = quaternion.y * quaternion.y;

    // roll (x-axis rotation)
    double t0 = 2.0 * (quaternion.w * quaternion.x + quaternion.y * quaternion.z);
    double t1 = 1.0 - 2.0 * (quaternion.x * quaternion.x + ysqr);
    double roll = atan2(t0, t1);

    // pitch (y-axis rotation)
    double t2 = 2.0 * (quaternion.w * quaternion.y - quaternion.z * quaternion.x);
    t2 = ((t2 > 1.0) ? 1.0 : t2);
    t2 = ((t2 < -1.0) ? -1.0 : t2);
    double pitch = asin(t2);

    // yaw (z-axis rotation)
    double t3 = 2.0 * (quaternion.w * quaternion.z + quaternion.x * quaternion.y);
    double t4 = 1.0 - 2.0 * (ysqr + quaternion.z * quaternion.z);
    double yaw = atan2(t3, t4);
    
    v3.x = roll;
    v3.y = pitch;
    v3.z = yaw;
    
    return v3;
}

@end
