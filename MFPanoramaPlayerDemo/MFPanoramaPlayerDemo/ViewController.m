//
//  ViewController.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/22.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFPanoramaPlayer.h"

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) MFPanoramaPlayer *panoramaPlayer;
@property (nonatomic, strong) MFPanoramaPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UILabel *xLabel;
@property (weak, nonatomic) IBOutlet UILabel *yLabel;
@property (weak, nonatomic) IBOutlet UISlider *xSlider;
@property (weak, nonatomic) IBOutlet UISlider *ySlider;
@property (weak, nonatomic) IBOutlet UISlider *perspectiveSlider;

@end

@implementation ViewController

- (void)dealloc {
    [self removeObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
}

#pragma mark - Private

- (void)commonInit {
    [self setupUI];
    [self setupPlayer];
    [self addObservers];
    [self updateUI];
}

- (void)setupUI {
    [self setupPlayButton];
    [self setupModeButton];
    [self setupPerspectiveSlider];
}

- (void)setupPlayButton {
    [self configButton:self.playButton];
    [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.playButton setTitle:@"暂停" forState:UIControlStateSelected];
}

- (void)setupModeButton {
    [self configButton:self.modeButton];
    [self.modeButton setTitle:@"手动" forState:UIControlStateNormal];
    [self.modeButton setTitle:@"自动" forState:UIControlStateSelected];
}

- (void)setupPlayer {
    // playerItem
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    self.playerItem = [[MFPanoramaPlayerItem alloc] initWithAsset:asset];
    self.playerItem.motionEnable = YES;
    CGFloat renderHeight = self.playerItem.originRenderSize.height / 2;
    CGSize renderSize = CGSizeMake(renderHeight * 4.0 / 3, renderHeight);
    self.playerItem.renderSize = renderSize;
    
    // panoramaPlayer
    self.panoramaPlayer = [[MFPanoramaPlayer alloc] initWithPanoramaPlayerItem:self.playerItem];
    __weak ViewController * weakSelf = self;
    [self.panoramaPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                      queue:NULL
                                                 usingBlock:^(CMTime time) {
        [weakSelf updateProgressView];
    }];
    
    // playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.panoramaPlayer];
    self.playerLayer.frame = CGRectMake(0,
                                        100,
                                        self.view.frame.size.width,
                                        self.view.frame.size.width * 3.0 / 4);
    [self.view.layer addSublayer:self.playerLayer];
}

- (void)setupPerspectiveSlider {
    self.perspectiveSlider.value = 15.0 / 70;  // 根据默认值初始化 UI
}

- (void)configButton:(UIButton *)button {
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.tintColor = [UIColor clearColor];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setBackgroundColor:[UIColor blackColor]];
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = YES;
}

- (void)updateProgressView {
    if (self.progressSlider.isHighlighted) {
        return;
    }
    NSTimeInterval duration = CMTimeGetSeconds(self.panoramaPlayer.currentItem.duration);
    CGFloat progress = CMTimeGetSeconds(self.panoramaPlayer.currentItem.currentTime) / duration;
    self.progressSlider.value = progress;
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.panoramaPlayer.currentItem];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playerItemDidReachEnd {
    [self.panoramaPlayer seekToTime:CMTimeMake(0, 600)];
    self.playButton.selected = NO;
}

- (void)updateUI {
    BOOL isAutoMode = !self.modeButton.selected;
    self.xLabel.hidden = isAutoMode;
    self.yLabel.hidden = isAutoMode;
    self.xSlider.hidden = isAutoMode;
    self.ySlider.hidden = isAutoMode;
}

#pragma mark - Action

- (IBAction)playAction:(UIButton *)button {
    if (button.isSelected) {
        [self.panoramaPlayer pause];
    } else {
        [self.panoramaPlayer play];
    }
    button.selected = !button.selected;
}

- (IBAction)modeAction:(UIButton *)button {
    button.selected = !button.selected;
    [self updateUI];
    if (button.selected) {
        self.playerItem.motionEnable = NO;
    } else {
        self.playerItem.motionEnable = YES;
    }
}

- (IBAction)progressSliderValueChangedAction:(UISlider *)slider {
    CGFloat value = slider.value;
    CMTime duration = self.panoramaPlayer.currentItem.duration;
    CMTime currentTime = CMTimeMake(duration.value * value, duration.timescale);
    [self.panoramaPlayer seekToTime:currentTime];
}

- (IBAction)xSliderValueChangedAction:(UISlider *)slider {
    CGFloat value = slider.value;
    self.playerItem.angleX = value * 2 * M_PI;
}

- (IBAction)ySliderValueChangedAction:(UISlider *)slider {
    CGFloat value = slider.value;
    self.playerItem.angleY = value * 2 * M_PI;
}

- (IBAction)perspectiveSliderValueChangedAction:(UISlider *)slider {
    CGFloat value = slider.value;
    self.playerItem.perspective = 30 + value * (100 - 30);
}

@end
