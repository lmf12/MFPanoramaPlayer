<div align=center><img src="https://raw.githubusercontent.com/lmf12/MFPanoramaPlayer/master/image/title.jpg" width="550"/></div>

# 简介

本项目是基于 `AVPlayer` 封装的全景播放器，接口简单易用。结合手机的陀螺仪，可以使全景视频在移动端具备更好的浏览体验。

# 效果预览

假设我们有一个全景视频：

![](https://raw.githubusercontent.com/lmf12/MFPanoramaPlayer/master/image/image2.gif)

那么，它播放起来的效果是这样的:

![](https://raw.githubusercontent.com/lmf12/MFPanoramaPlayer/master/image/image1.gif)

**它还可以根据手机的倾斜角度自动调节视角。**

# 如何导入

1. 将 `MFPanoramaPlayer` 文件夹拷贝到工程中
2. 引入头文件 `#import "MFPanoramaPlayer.h"`

# 如何使用

`MFPanoramaPlayer` 的使用方式和 `AVPlayer` 并无太大区别，同样是使用 `AVPlayerLayer` 来播放。

```objc
// playerItem
NSURL *url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
AVURLAsset *asset = [AVURLAsset assetWithURL:url];
MFPanoramaPlayerItem *playerItem = [[MFPanoramaPlayerItem alloc] initWithAsset:asset];
playerItem.motionEnable = YES;
CGFloat renderHeight = playerItem.originRenderSize.height / 2;
CGSize renderSize = CGSizeMake(renderHeight * 4.0 / 3, renderHeight);
playerItem.renderSize = renderSize;

// panoramaPlayer
MFPanoramaPlayer *panoramaPlayer = [[MFPanoramaPlayer alloc] initWithPanoramaPlayerItem:playerItem];
panoramaPlayer.delegate = self;

// playerLayer
AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:panoramaPlayer.player];
playerLayer.frame = CGRectMake(0,
                               100,
                               self.view.frame.size.width,
                               self.view.frame.size.width * 3.0 / 4);
[self.view.layer addSublayer:playerLayer];
```

# 接口说明

> 在全景播放器中，所有跟渲染相关的设置选项，都可以在 `MFPanoramaPlayerItem.h` 中找到。

**1、模式切换**

```objc
@property (nonatomic, assign) BOOL motionEnable;
@property (nonatomic, assign) CGFloat angleX;
@property (nonatomic, assign) CGFloat angleY;
```

通过 `motionEnable` 可以设置旋转模式，设置为 `YES` 时，表示启动陀螺仪，视角可以随设备方向旋转。设置为 `NO` 时，表示手动调整视角，可以通过 `angleX` 和 `angleY` 来调整两个方向的角度。

**2、可视范围**

```objc
@property (nonatomic, assign) CGFloat perspective;
```

通过 `perspective` 可以调整可视范围，进行类似 `窄角` 、 ` 广角` 的调节。

**3、渲染尺寸**

```objc
@property (nonatomic, assign, readonly) CGSize originRenderSize;
@property (nonatomic, assign) CGSize renderSize;
```

`originRenderSize` 表示视频资源的原始尺寸，`renderSize` 表示我们最终期望的渲染尺寸。

## 更多介绍

[使用 OpenGL ES 实现全景播放器](http://www.lymanli.com/2020/03/21/ios-opengles-panorama/)


