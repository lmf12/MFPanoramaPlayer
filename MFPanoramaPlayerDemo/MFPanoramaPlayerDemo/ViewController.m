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
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
    
    [self.panoramaPlayer play];
}

#pragma mark - Private

- (void)commonInit {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp4"];
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    MFPanoramaPlayerItem *playerItem = [[MFPanoramaPlayerItem alloc] initWithAsset:asset];
    self.panoramaPlayer = [[MFPanoramaPlayer alloc] initWithPlayerItem:playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.panoramaPlayer.player];
    self.playerLayer.frame = CGRectMake(0,
                                        100,
                                        self.view.frame.size.width,
                                        400);
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    [self.view.layer addSublayer:self.playerLayer];
}


@end
