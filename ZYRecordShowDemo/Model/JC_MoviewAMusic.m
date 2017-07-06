//
//  JC_MoviewAMusic.m
//  MusicAndVideo
//
//  Created by TNP on 2017/6/14.
//  Copyright © 2017年 CXMX. All rights reserved.
//

#import "JC_MoviewAMusic.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@implementation JC_MoviewAMusic

+(void)movieFliePaths:(NSArray *_Nullable)moviePaths musicPath:(NSURL *_Nullable)musicpath success:(void (^ _Nullable)(NSURL * _Nullable successPath))success failure:(void (^ _Nullable)(NSString * _Nullable errorMsg))failure
{
    if (moviePaths.count<1)
    return;
    
    // 路径
    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // 最终合成输出路径 时间来做输入路径不会出现重复
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *outPutFilePath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",[formater stringFromDate:[NSDate date]]]];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    // 时间起点
    CMTime startTime = kCMTimeZero;
    
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    //视频通道
    AVMutableCompositionTrack *videoCompositionTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //合成方向处理
//    videoTrack.preferredTransform =  CGAffineTransformMakeRotation(M_PI/2);
    
    for (int i = 0; i < moviePaths.count; i++)
    {
        //****************视频*************************************
        // 视频采集
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:moviePaths[i] options:nil];
        // 视频时间范围
        CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
        
        // 视频采集通道
        AVAssetTrack *videoAssetTrack = nil;
        if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count) {
            videoAssetTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        }
        NSError *errorVideo = nil;
        //  把采集轨道数据加入到可变轨道之中
        if (videoAssetTrack) {
           [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:startTime error:&errorVideo];
        }
        if (errorVideo) {
            NSLog(@"Failed to insert video to composition: %@", errorVideo);
        }
        
        //把时间加起来
        startTime = CMTimeAdd(startTime, videoAsset.duration);
    }
    
    //****************背景音乐*************************************
    if (musicpath) {
        // 声音采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:musicpath options:nil];
        // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);;
        // 音频通道
        AVMutableCompositionTrack *audioCompositionTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频采集通道
        AVAssetTrack *audioAssetTrack = nil;
        if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count) {
            audioAssetTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
        }
        // 加入合成轨道之中
        if (audioAssetTrack) {
            [audioCompositionTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
        }
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
        
        NSString *errorMsg = nil;
        switch (assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
            {
                errorMsg = @"失败AVAssetExportSessionStatusUnknown";
                NSLog(@"失败AVAssetExportSessionStatusUnknown");
            }
                break;
            case AVAssetExportSessionStatusWaiting:
            {
                errorMsg = @"失败AVAssetExportSessionStatusWaiting";
                NSLog(@"失败AVAssetExportSessionStatusWaiting");
            }
                break;
            case AVAssetExportSessionStatusExporting:
            {
                errorMsg = @"失败AVAssetExportSessionStatusExporting";
                NSLog(@"失败AVAssetExportSessionStatusExporting");
            }
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                // 回到主线程
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(outputFileUrl);
                });
            }
                break;
            case AVAssetExportSessionStatusFailed:
            {
                errorMsg = @"失败AVAssetExportSessionStatusFailed";
                NSLog(@"失败AVAssetExportSessionStatusFailed");
            }
                break;
            case AVAssetExportSessionStatusCancelled:
            {
                errorMsg = @"失败AVAssetExportSessionStatusCancelled";
                NSLog(@"失败AVAssetExportSessionStatusCancelled");
            }
                break;
            default:
                break;
        }
        if (errorMsg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(errorMsg);
            });
        }
        
    }];
    if (assetExport.error) {
        NSLog(@"%@",assetExport.error);
    }
    
    
}

@end
