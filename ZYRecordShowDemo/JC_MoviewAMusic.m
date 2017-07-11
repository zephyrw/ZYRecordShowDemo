//
//  JC_MoviewAMusic.m
//  MusicAndVideo
//
//  Created by TNP on 2017/6/14.
//  Copyright © 2017年 CXMX. All rights reserved.
//

#import "JC_MoviewAMusic.h"
#import <AVFoundation/AVFoundation.h>

@implementation JC_MoviewAMusic

+(void)movieFliePaths:(NSArray *)moviePaths musicPath:(NSURL *)musicpath success:(void (^ )(NSURL *  successPath))success failure:(void (^ )(NSString *  errorMsg))failure
{
    if (moviePaths.count < 1)
    return;
    
    NSURL *outputFileUrl = [self outputFileURL];
    // 时间起点
    CMTime startTime = kCMTimeZero;
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    // 视频通道
    AVMutableCompositionTrack *videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //合成方向处理
//    videoTrack.preferredTransform = CGAffineTransformMakeRotation(M_PI/2);
    
    for (int i = 0; i < moviePaths.count; i++)
    {
        //****************视频*************************************
        // 视频采集
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:moviePaths[i] options:nil];
        // 视频时间范围
        CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
        
        // 视频采集通道
        AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        NSError *errorVideo = nil;
        //  把采集轨道数据加入到可变轨道之中
       [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:startTime error:&errorVideo];
        
        //把时间加起来
        startTime = CMTimeAdd(startTime, videoAsset.duration);
    }
    
    //****************背景音乐*************************************
    if (musicpath) {
        // 声音采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:musicpath options:nil];
        // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, startTime);;
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频采集通道
        AVAssetTrack *audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        // 加入合成轨道之中
        [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetMediumQuality];
    
    // 输出类型
    assetExport.outputFileType = AVFileTypeMPEG4;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    //模糊
    assetExport.canPerformMultiplePassesOverSourceMediaData = NO;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        [self handleResultWithAssetExport:assetExport outputURL:outputFileUrl success:success failure:failure];
        
    }];
    if (assetExport.error) {
        NSLog(@"%@",assetExport.error);
    }
    
}

+ (void)combineAudioWithRecordAudios:(NSArray<ZYRecordAudio *> *)recordAudios success:(void (^)(NSURL * ))success failure:(void (^)(NSString * ))failure {
    
    if (recordAudios.count < 1)
        return;
    
    NSURL *outputFileUrl = [self outputFileURL];
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    
    //****************背景音乐*************************************
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime startTime = kCMTimeZero;
    for (NSURL *audioURL in recordAudios) {
        // 声音采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
        // 拼接每段音频
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        // 音频采集通道
        AVAssetTrack *audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        // 加入合成轨道之中
        [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:startTime error:nil];
        CMTimeAdd(startTime, audioAsset.duration);
    }
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetAppleM4A];
    
    // 输出类型
    assetExport.outputFileType = AVFileTypeAppleM4A;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    //模糊
    assetExport.canPerformMultiplePassesOverSourceMediaData = NO;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        [self handleResultWithAssetExport:assetExport outputURL:outputFileUrl success:success failure:failure];
        
    }];
    if (assetExport.error) {
        NSLog(@"%@",assetExport.error);
    }
    
}

+ (void)combineAudioWithRecordAudios:(NSArray<NSURL *> *)recordAudios secondAudioStartTime:(NSTimeInterval)startTime success:(void (^)(NSURL *))success failure:(void (^)(NSString *))failure {
    
    if (recordAudios.count != 2)
        return;
    
    NSURL *outputFileUrl = [self outputFileURL];
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    
    //****************背景音乐*************************************
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime mStartTime = CMTimeMake(startTime * 1000, 1000);
    AVURLAsset *firstAsset;
    AVURLAsset *secondAsset;
    NSUInteger index = 0;
    for (NSURL *audioURL in recordAudios) {
        // 声音采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
        if (index == 0) {
            firstAsset = audioAsset;
        } else {
            secondAsset = audioAsset;
        }
        // 拼接每段音频
        CMTime toTime = kCMTimeZero;
        if (index == 0) {
            toTime = mStartTime;
        } else if (index == 1) {
            toTime = audioAsset.duration;
        }
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, toTime);
        // 音频采集通道
        AVAssetTrack *audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        // 加入合成轨道之中
        [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:mStartTime error:nil];
        index += 1;
    }
    if (firstAsset.duration.timescale && secondAsset.duration.timescale) {
        NSInteger firstDuration = firstAsset.duration.value / firstAsset.duration.timescale;
        NSInteger secondDuration = secondAsset.duration.value / secondAsset.duration.timescale;
        if (firstDuration > secondDuration + startTime) {
            CMTime firstAudioStartTime = CMTimeMake((secondDuration + startTime) * 1000, 1000);
            CMTimeRange audioTimeRange = CMTimeRangeMake(firstAudioStartTime, CMTimeMake((firstDuration - secondDuration - startTime) * 1000, 1000));
            // 音频采集通道
            AVAssetTrack *audioAssetTrack = [firstAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            // 加入合成轨道之中
            [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:firstAudioStartTime error:nil];
        }
    }
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetAppleM4A];
    
    // 输出类型
    assetExport.outputFileType = AVFileTypeAppleM4A;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    //模糊
    assetExport.canPerformMultiplePassesOverSourceMediaData = NO;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        [self handleResultWithAssetExport:assetExport outputURL:outputFileUrl success:success failure:failure];
        
    }];
    if (assetExport.error) {
        NSLog(@"%@",assetExport.error);
    }
    
}

+ (void)cutAudioTrackWithAudioURL:(NSURL *)audioURL cutTime:(NSTimeInterval)cutTime success:(void (^ )(NSURL * ))success failure:(void (^ )(NSString * ))failure {
    
    NSURL *outputFileUrl = [self outputFileURL];
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    
    //****************背景音乐*************************************
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 声音采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    // 拼接每段音频
    if (cutTime >= audioAsset.duration.value / audioAsset.duration.timescale) {
        NSLog(@"音频处理失败：剪切时长大于音频时长！");
        return;
    }
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(audioAsset.duration, CMTimeMake(cutTime, 1)));
    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    // 加入合成轨道之中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetAppleM4A];
    
    // 输出类型
    assetExport.outputFileType = AVFileTypeAppleM4A;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    //模糊
    assetExport.canPerformMultiplePassesOverSourceMediaData = NO;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        [self handleResultWithAssetExport:assetExport outputURL:outputFileUrl success:success failure:failure];
        
    }];
    if (assetExport.error) {
        NSLog(@"%@",assetExport.error);
    }
    
}

+ (NSURL *)outputFileURL {
    
    // 路径
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // 最终合成输出路径 时间来做输入路径不会出现重复
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *outPutFilePath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",[formater stringFromDate:[NSDate date]]]];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    return outputFileUrl;
    
}

+ (void)handleResultWithAssetExport:(AVAssetExportSession *)assetExport outputURL:(NSURL *)outputURL success:(void (^ )(NSURL * ))success failure:(void (^ )(NSString * ))failure {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
            {
                failure(@"失败AVAssetExportSessionStatusUnknown");
                NSLog(@"失败AVAssetExportSessionStatusUnknown");
            }
                break;
            case AVAssetExportSessionStatusWaiting:
            {
                failure(@"失败AVAssetExportSessionStatusWaiting");
                NSLog(@"失败AVAssetExportSessionStatusWaiting");
            }
                break;
            case AVAssetExportSessionStatusExporting:
            {
                failure(@"失败AVAssetExportSessionStatusExporting");
                NSLog(@"失败AVAssetExportSessionStatusExporting");
            }
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                success(outputURL);
            }
                break;
            case AVAssetExportSessionStatusFailed:
            {
                failure(@"失败AVAssetExportSessionStatusFailed");
                NSLog(@"失败AVAssetExportSessionStatusFailed");
            }
                break;
            case AVAssetExportSessionStatusCancelled:
            {
                failure(@"失败AVAssetExportSessionStatusCancelled");
                NSLog(@"失败AVAssetExportSessionStatusCancelled");
            }
                break;
            default:
                break;
        }
    });
    
}

@end
