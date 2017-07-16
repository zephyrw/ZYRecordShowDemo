//
//  ZYPlayController.m
//  ZYRecordShowDemo
//
//  Created by wpsd on 2017/7/13.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYPlayController.h"
#import "UIView+Frame.h"
#import <AVFoundation/AVFoundation.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface ZYPlayController ()

@property (strong, nonatomic) UIView *playerView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIButton *playBtn;

@end

@implementation ZYPlayController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:38 / 255.0 green:44 / 255.0 blue:60 / 255.0 alpha:1];
    [self setupUI];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver];
}

- (void)setupUI {
    
    UIButton *returnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [returnBtn setImage:[UIImage imageNamed:@"ds_material_icon_delete"] forState:UIControlStateNormal];
    [returnBtn sizeToFit];
    returnBtn.frame = CGRectMake(16, 8, returnBtn.width, returnBtn.height);
    [returnBtn addTarget:self action:@selector(returnBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:returnBtn];
    
    self.playerView = [[UIView alloc] initWithFrame:CGRectMake(0, returnBtn.bottom + 8, SCREEN_WIDTH, SCREEN_WIDTH * 9 / 16)];
    self.playerView.center = self.view.center;
    [self.view addSubview:self.playerView];
    [self setupPlayerWithVideoURL:self.videoURL];
    UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerViewTapped)];
    [self.playerView addGestureRecognizer:tapGest];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn setImage:[UIImage imageNamed:@"58_costar_icon_watch_play"] forState:UIControlStateNormal];
    playBtn.frame = CGRectMake(0, 0, 50, 50);
    playBtn.center = self.playerView.center;
    [playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    self.playBtn = playBtn;
    
}

- (void)playBtnClick:(UIButton *)sender {
    
    sender.selected = YES;
    sender.hidden = YES;
    [self.player play];
    
}

- (void)playerViewTapped {
    
    if (self.playBtn.isHidden) {
        [self.player pause];
        self.playBtn.hidden = NO;
        self.playBtn.selected = NO;
    }
    
}

- (void)returnBtnClick:(UIButton *)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (void)setupPlayerWithVideoURL:(NSURL *)videoURL {
    
    [self setAudioSessionWithType:AVAudioSessionCategoryPlayback];
    
    self.playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.playerView.layer insertSublayer:self.playerLayer atIndex:0];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.playerView.bounds;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
        }else if (status == AVPlayerStatusFailed) {
            NSLog(@"播放失败");
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CMTimeRange timeRange = [[[change objectForKey:@"new"] lastObject] CMTimeRangeValue];
        CGFloat startTime = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        CGFloat completeSeconds = startTime + durationSeconds;
        CGFloat totalDuration = CMTimeGetSeconds(playerItem.duration);
        CGFloat percent = completeSeconds / totalDuration;
        NSLog(@"缓冲进度：%.2f", percent);
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty");
    }
    if ([keyPath isEqualToString:@"rate"]) {
        NSLog(@"rate: %f", [[change objectForKey:@"new"] floatValue]);
        if ([[change objectForKey:@"new"] floatValue] == 0.0) {
            //            self.playBtn.selected = NO;
        }else {
            //            self.playBtn.selected = YES;
        }
    }
}

- (void)removeObserver {
    
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player = nil;
    self.playerItem = nil;
    
}

- (void)setAudioSessionWithType:(NSString *)type {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:type error:&error];
    if (error) {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
}

@end
