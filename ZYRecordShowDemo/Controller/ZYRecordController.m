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

@interface ZYRecordController ()

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *videoPlayBtn;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *startLineView;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *silenceVideoURL;
@property (strong, nonatomic) NSURL *mixedVideoURL;
@property (strong, nonatomic) NSURL *recordURL;

@end

@implementation ZYRecordController

- (NSURL *)recordURL {
    if (!_recordURL) {
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.m4a"];
        _recordURL = [NSURL fileURLWithPath:filePath];
    }
    return _recordURL;
}

- (NSURL *)videoURL {
    if (!_videoURL) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"myVideo" ofType:@"mp4"];
        _videoURL = [NSURL fileURLWithPath:path];
    }
    return _videoURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
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

- (IBAction)recordBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
}

- (IBAction)resetBtnClick:(UIButton *)sender {
}

- (IBAction)previewBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
}

- (IBAction)closeBtnClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
