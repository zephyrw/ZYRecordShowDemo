//
//  ZYRecordController.m
//  ZYRecordShowDemo
//
//  Created by wpsd on 2017/7/6.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYRecordController.h"
#import "EZAudio.h"
#import "JC_MoviewAMusic.h"
#import "SVProgressHUD.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Frame.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

static const CGFloat audioPlotMaxSecondsPerScreen = 28;

@interface ZYRecordController ()<EZMicrophoneDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *videoPlayBtn;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *startLineView;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *processView;
@property (weak, nonatomic) IBOutlet UIButton *previewBtn;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UIView *centerLineView;
@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) IBOutlet UIView *bottomLineView;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *silenceVideoURL;
@property (strong, nonatomic) NSURL *mixedVideoURL;
@property (strong, nonatomic) NSURL *currentRecordURL;
@property (strong, nonatomic) NSURL *preRecordURL;
@property (strong, nonatomic) NSURL *baseRecordURL;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) EZAudioPlot *firstAudioPlot;
@property (strong, nonatomic) EZAudioPlot *secondAudioPlot;
@property (strong, nonatomic) EZAudioFile *firstAudioFile;
@property (strong, nonatomic) EZAudioFile *secondAudioFile;
@property (strong, nonatomic) EZMicrophone *microphone;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (assign, nonatomic) NSTimeInterval previewCurrentTime;
@property (assign, nonatomic) NSTimeInterval recordCurrentTime;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) NSTimeInterval videoDuration;
@property (assign, nonatomic) BOOL hasRetry;
@property (assign, nonatomic) NSInteger audioCount;
@property (assign, nonatomic) CGPoint originOffset;
@property (assign, nonatomic) BOOL needRedAudioPlot;
@property (assign, nonatomic) BOOL needCombineRed;
@property (assign, nonatomic) CGFloat redAudioPlotOffset;
@property (assign, nonatomic) CGFloat prePlotOffset;

@end

@implementation ZYRecordController

#pragma mark - Lazy Load

- (NSURL *)videoURL {
    if (!_videoURL) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"myVideo" ofType:@"mp4"];
        _videoURL = [NSURL fileURLWithPath:path];
    }
    return _videoURL;
}

#pragma mark - Life Circle

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self prepareForAudioPlot];
    [self removeAudioTrack];
    
}

- (void)setupUI {
    
    UIView *topCircle = [[UIView alloc] initWithFrame:CGRectMake(-1.5, -4, 4, 4)];
    topCircle.layer.cornerRadius = 2;
    topCircle.layer.borderWidth = 1;
    topCircle.layer.borderColor = self.startLineView.backgroundColor.CGColor;
    topCircle.clipsToBounds = YES;
    [self.startLineView addSubview:topCircle];
    
    UIView *bottomCircle = [[UIView alloc] initWithFrame:CGRectMake(-1.5, self.startLineView.frame.size.height, 4, 4)];
    bottomCircle.layer.cornerRadius = 2;
    bottomCircle.layer.borderWidth = 1;
    bottomCircle.layer.borderColor = self.startLineView.backgroundColor.CGColor;
    bottomCircle.clipsToBounds = YES;
    [self.startLineView addSubview:bottomCircle];
    
    [self handleAudioViewIsHidden:YES];
    
    self.processView.layer.anchorPoint = CGPointMake(0, 0.5);
    self.processView.layer.position = CGPointMake(-1, self.processView.height / 2);
    
}

- (void)prepareForAudioPlot {
    
    [self setAudioSessionWithType:AVAudioSessionCategoryPlayAndRecord];
    
    self.firstAudioPlot = [[EZAudioPlot alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    self.firstAudioPlot.layer.anchorPoint = CGPointMake(0, 0.5);
    self.firstAudioPlot.layer.position = CGPointMake(self.startLineView.left, 20);
    self.firstAudioPlot.backgroundColor = [UIColor clearColor];
    self.firstAudioPlot.color           = [UIColor whiteColor];
    self.firstAudioPlot.plotType        = EZPlotTypeBuffer;
    self.firstAudioPlot.shouldFill      = YES;
    self.firstAudioPlot.shouldMirror    = YES;
    
    self.secondAudioPlot = [[EZAudioPlot alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    self.secondAudioPlot.layer.anchorPoint = CGPointMake(0, 0.5);
    self.secondAudioPlot.layer.position = CGPointMake(self.startLineView.left, 20);
    self.secondAudioPlot.backgroundColor = [UIColor clearColor];
    self.secondAudioPlot.color           = [UIColor redColor];
    self.secondAudioPlot.plotType        = EZPlotTypeBuffer;
    self.secondAudioPlot.shouldFill      = YES;
    self.secondAudioPlot.shouldMirror    = YES;
    
    self.scrollView.contentSize = CGSizeMake(self.startLineView.left + SCREEN_WIDTH, self.scrollView.height);
    [self.scrollView addSubview:self.firstAudioPlot];
    [self.scrollView addSubview:self.secondAudioPlot];
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
}

- (void)removeAudioTrack {
    
    [SVProgressHUD showWithStatus:@"正在准备视频，请稍候..."];
    [JC_MoviewAMusic movieFliePaths:@[self.videoURL] musicPath:nil success:^(NSURL * _Nullable successPath){
        self.silenceVideoURL = successPath;
        [SVProgressHUD showSuccessWithStatus:@"视频准备完毕"];
        NSLog(@"successPath: %@", successPath);
    } failure:^(NSString * _Nullable errorMsg){
        [SVProgressHUD showErrorWithStatus:errorMsg];
        NSLog(@"errorMsg: %@", errorMsg);
    }];
    
}

#pragma mark - Actions

- (IBAction)recordBtnClick:(UIButton *)sender {
    if (!sender.isSelected && self.previewBtn.isSelected) {
        [self previewBtnClick:self.previewBtn];
    }
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [self handleAudioViewIsHidden:YES];
        [self setAudioSessionWithType:AVAudioSessionCategoryPlayAndRecord];
        [self setupPlayerWithVideoURL:self.videoURL];
        [self setupAudioRecorder];
        if (self.recordCurrentTime > self.videoDuration) {
            [SVProgressHUD showErrorWithStatus:@"已录制完毕，不能再继续录制"];
            sender.selected = !sender.isSelected;
            return;
        }
        if ([self.audioRecorder prepareToRecord] == YES){
            self.audioRecorder.meteringEnabled = YES;
            [self.audioRecorder record];
            [self.player seekToTime:CMTimeMake(self.recordCurrentTime, 1)];
            [self.player play];
            self.videoPlayBtn.hidden = YES;
            self.previewBtn.hidden = YES;
            self.resetBtn.hidden = YES;
            [self listenToTimeChange];
            [self.microphone startFetchingAudio];
        }else {
            NSLog(@"FlyElephant--初始化录音失败");
        }
        return;
    }
    [self handleAudioViewIsHidden:NO];
    [self.timer invalidate];
    [self.player pause];
    [self.audioRecorder stop];
    [self.microphone stopFetchingAudio];
    [self openAudioFile];
    self.previewBtn.hidden = NO;
    self.videoPlayBtn.hidden = NO;
    self.resetBtn.hidden = NO;
}

- (IBAction)resetBtnClick:(UIButton *)sender {
}

- (IBAction)previewBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        self.previewCurrentTime = 0;
        [self setAudioSessionWithType:AVAudioSessionCategoryPlayback];
        [self setupPlayerWithVideoURL:self.silenceVideoURL];
        [self.player play];
        [self setupAudioPlayerWithURL:self.preRecordURL];
        self.videoPlayBtn.hidden = YES;
        self.resetBtn.hidden = YES;
        [self listenToTimeChange];
    } else {
        [self.timer invalidate];
        self.videoPlayBtn.hidden = NO;
        self.resetBtn.hidden = YES;
        [self.player pause];
        [self.audioPlayer pause];
    }
}

- (IBAction)closeBtnClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Help Method

- (void)mixAudioAndVideo {
    
    [SVProgressHUD showWithStatus:@"正在合成中..."];
    [JC_MoviewAMusic movieFliePaths:@[self.videoURL] musicPath:self.currentRecordURL success:^(NSURL * _Nullable successPath) {
        self.mixedVideoURL = successPath;
        [SVProgressHUD showSuccessWithStatus:@"合成成功！"];
    } failure:^(NSString * _Nullable errorMsg) {
        [SVProgressHUD showErrorWithStatus:@"合成失败"];
        NSLog(@"%@", errorMsg);
    }];
    
}

- (void)setupAudioRecorder {
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Failed to set category: %@", error);
    }
    NSError *recorderError = nil;
    self.audioCount += 1;
    self.currentRecordURL = [self currentFileURL];
    self.needRedAudioPlot = self.scrollView.contentOffset.x != self.originOffset.x || self.needRedAudioPlot;
    self.needCombineRed = self.scrollView.contentOffset.x == self.originOffset.x && self.needRedAudioPlot;
    if (self.needRedAudioPlot && !self.needCombineRed) {
        self.prePlotOffset = self.redAudioPlotOffset;
        self.redAudioPlotOffset = fabs(self.scrollView.contentOffset.x - self.originOffset.x);
        self.recordCurrentTime -= self.redAudioPlotOffset / SCREEN_WIDTH * audioPlotMaxSecondsPerScreen;
    }
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.currentRecordURL settings:[self audioRecordingSettings] error:&recorderError];
    if (recorderError) {
        NSLog(@"Failed to create recorder: %@", recorderError);
    }
    self.audioRecorder.meteringEnabled = YES;
    
}

- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *result = nil;
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    result = [NSDictionary dictionaryWithDictionary:recordSetting];
    return result;
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


- (void)setupPlayerWithVideoURL:(NSURL *)videoURL {
    
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

- (void)setupAudioPlayerWithURL:(NSURL *)audioURL {
    
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
    if (error) {
        NSLog(@"Failed to load audio player: %@", error);
        return;
    }
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
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


- (void)listenToTimeChange {
    if (self.timer) { self.timer = nil; }
    __weak typeof(self) weakSelf = self;
    if (self.firstAudioFile.duration / audioPlotMaxSecondsPerScreen > 80.0 / SCREEN_WIDTH) {
        self.startLineView.transform = CGAffineTransformMakeTranslation(SCREEN_WIDTH / 2 - 80, 0);
        self.firstAudioPlot.layer.position = CGPointMake(SCREEN_WIDTH / 2, 20);
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.015 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf countTime];
    }];
}

- (void)countTime {
    
    if (self.player.currentTime.timescale == 0) { return; }
    NSTimeInterval playTime = self.player.currentTime.value / self.player.currentTime.timescale;
    if (self.previewCurrentTime < playTime && self.previewBtn.isSelected) {
        self.previewCurrentTime = playTime;
    } else if (self.recordCurrentTime < playTime && self.recordBtn.isSelected) {
        self.recordCurrentTime = playTime;
    }
    NSTimeInterval currentTime = self.recordBtn.isSelected ? self.recordCurrentTime : self.previewCurrentTime;
    if (currentTime < self.firstAudioFile.duration && !self.recordBtn.isSelected) {
        self.scrollView.contentOffset = CGPointMake(currentTime / audioPlotMaxSecondsPerScreen * SCREEN_WIDTH, 0);
    }
    int currentMin = (int)currentTime / 60;
    int currentSec = (int)currentTime % 60;
    
    NSTimeInterval duration = self.playerItem.duration.value / (self.playerItem.duration.timescale == 0 ? 1 : self.playerItem.duration.timescale);
    if (!duration) { return; }
    self.videoDuration = duration;
    int maxMin = (int)duration / 60;
    int maxSec = (int)duration % 60;
    CGFloat percent = currentTime / duration;
    self.processView.transform = CGAffineTransformMakeScale(percent * SCREEN_WIDTH, 1);
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d/%02d:%02d",currentMin, currentSec, maxMin, maxSec];
    if (self.previewBtn.isSelected) {
        self.previewCurrentTime += 0.015;
    } else if (self.recordBtn.isSelected) {
        self.recordCurrentTime += 0.015;
    }
    if (percent >= 1 && self.previewBtn.isSelected) {
        [self previewBtnClick:self.previewBtn];
    } else if (percent >= 1 && self.recordBtn.isSelected) {
        [self recordBtnClick:self.recordBtn];
    }
    
}

- (void)openAudioFile {
    
    NSLog(@"current audio count -------> %ld", self.audioCount);
    NSLog(@"pre url ---------> %@", self.preRecordURL);
    NSLog(@"current url ---------> %@", self.currentRecordURL);
    NSLog(@"base url ---------> %@", self.baseRecordURL);
    if (self.audioCount == 2) {
        if (self.needRedAudioPlot) {
            self.secondAudioFile = [EZAudioFile audioFileWithURL:self.currentRecordURL];
            self.baseRecordURL = self.preRecordURL;
            [self updateUI];
            self.preRecordURL = self.currentRecordURL;
        } else {
            [self combineAudioTrack];
        }
    } else if (self.audioCount == 1) {
        self.preRecordURL = self.currentRecordURL;
        [self updateUI];
    } else if (self.audioCount == 3) {
        if (self.needCombineRed) {
            [self combineAudioTrack];
        } else {
            [self combineAndCoverAudioTrack];
        }
    }
}

- (void)combineAudioTrack {
    
    [self handleAudioViewIsHidden:YES];
    [JC_MoviewAMusic combineAudioWithRecordAudios:@[self.preRecordURL, self.currentRecordURL] success:^(NSURL * _Nullable successURL) {
        self.preRecordURL = successURL;
        self.audioCount -= 1;
        if (self.needCombineRed) {
            self.secondAudioFile = [EZAudioFile audioFileWithURL:successURL];
        }
        [self updateUI];
        [self handleAudioViewIsHidden:NO];
    } failure:^(NSString * _Nullable errorMsg) {
        [self handleAudioViewIsHidden:NO];
        NSLog(@"Failed to combine audio track: %@", errorMsg);
    }];
    
}

- (void)combineAndCoverAudioTrack {
    
    [self handleAudioViewIsHidden:YES];
    EZAudioFile *baseFile = [EZAudioFile audioFileWithURL:self.baseRecordURL];
    NSTimeInterval startTime = baseFile.duration - self.prePlotOffset / SCREEN_WIDTH * audioPlotMaxSecondsPerScreen;
    [JC_MoviewAMusic combineAudioWithRecordAudios:@[self.baseRecordURL, self.preRecordURL] secondAudioStartTime:startTime success:^(NSURL *successURL) {
        self.baseRecordURL = successURL;
        self.preRecordURL = successURL;
        self.secondAudioFile = [EZAudioFile audioFileWithURL:self.currentRecordURL];
        self.audioCount -= 1;
        [self updateUI];
        self.preRecordURL = self.currentRecordURL;
        [self handleAudioViewIsHidden:NO];
    } failure:^(NSString *errorMsg) {
        [self handleAudioViewIsHidden:NO];
        NSLog(@"Failed to cover and combine audio track: %@", errorMsg);
    }];
    
}

- (void)updateUI {
    
    self.firstAudioFile = [EZAudioFile audioFileWithURL:self.preRecordURL];
    if (self.needCombineRed) {
        self.firstAudioFile = [EZAudioFile audioFileWithURL:self.baseRecordURL];
    }
    double firstScale = self.firstAudioFile.duration / audioPlotMaxSecondsPerScreen;
    double secondScale = self.secondAudioFile.duration / audioPlotMaxSecondsPerScreen;
    if (firstScale + secondScale > 80 / SCREEN_WIDTH) {
        self.startLineView.transform = CGAffineTransformMakeTranslation(SCREEN_WIDTH / 2 - 80, 0);
        self.firstAudioPlot.layer.position = CGPointMake(SCREEN_WIDTH / 2, 20);
    } else {
        self.startLineView.transform = CGAffineTransformIdentity;
        self.firstAudioPlot.layer.position = CGPointMake(80, 20);
    }
    self.firstAudioPlot.transform = CGAffineTransformMakeScale(firstScale, 1);
    if (self.needRedAudioPlot) {
        self.secondAudioPlot.layer.position = CGPointMake(self.firstAudioPlot.right - self.redAudioPlotOffset, 20);
        self.secondAudioPlot.transform = CGAffineTransformMakeScale(secondScale, 1);
    }
    CGFloat scrollOffset = self.needRedAudioPlot ? self.secondAudioPlot.width + self.firstAudioPlot.width - self.redAudioPlotOffset : self.firstAudioPlot.width;
    self.scrollView.contentOffset = CGPointMake(scrollOffset, 0);
    CGFloat scrollContentSizeDelta = self.needRedAudioPlot ? ((self.secondAudioPlot.width + self.redAudioPlotOffset) > self.firstAudioPlot.width ? (self.secondAudioPlot.width + self.redAudioPlotOffset) : self.firstAudioPlot.width) : self.firstAudioPlot.width;
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH + scrollContentSizeDelta, self.scrollView.height);
    self.originOffset = self.scrollView.contentOffset;
    __weak typeof (self) weakSelf = self;
    [self.firstAudioFile getWaveformDataWithCompletionBlock:^(float **waveformData, int length) {
        [weakSelf.firstAudioPlot updateBuffer:waveformData[0] withBufferSize:length];
    }];
    if (self.needRedAudioPlot) {
        [self.secondAudioFile getWaveformDataWithCompletionBlock:^(float **waveformData, int length) {
            [weakSelf.secondAudioPlot updateBuffer:waveformData[0] withBufferSize:length];
        }];
    }
    
}

- (void)handleAudioViewIsHidden:(BOOL)hidden {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.startLineView.hidden = hidden;
        self.topLineView.hidden = hidden;
        self.centerLineView.hidden = hidden;
        self.bottomLineView.hidden = hidden;
        self.scrollView.hidden = hidden;
    });
    
}

- (NSURL *)currentFileURL {
    // 路径
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // 最终合成输出路径 时间来做输入路径不会出现重复
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *outPutFilePath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",[formater stringFromDate:[NSDate date]]]];
    return [NSURL fileURLWithPath:outPutFilePath];
}

#pragma mark - EZMicrophoneDelegate

- (void)microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels {
    
    dispatch_async(dispatch_get_main_queue(), ^{
    });
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.previewBtn.isSelected) { return; }
    CGFloat newTime = scrollView.contentOffset.x / SCREEN_WIDTH * audioPlotMaxSecondsPerScreen;
    if (!self.playerItem.duration.timescale) { return; }
    if (newTime <= self.playerItem.duration.value / self.playerItem.duration.timescale) {
        [self.player seekToTime:CMTimeMake(newTime, 1)];
        int currentMin = (int)newTime / 60;
        int currentSec = (int)newTime % 60;
        NSTimeInterval duration = self.playerItem.duration.value / (self.playerItem.duration.timescale == 0 ? 1 : self.playerItem.duration.timescale);
        if (!duration) { return; }
        int maxMin = (int)duration / 60;
        int maxSec = (int)duration % 60;
        CGFloat percent = newTime / duration;
        self.processView.transform = CGAffineTransformMakeScale(percent * SCREEN_WIDTH, 1);
        self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d/%02d:%02d",currentMin, currentSec, maxMin, maxSec];
    }
    
}

- (void)dealloc {
    
    self.timer = nil;
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    self.playerItem = nil;
    
}

@end
