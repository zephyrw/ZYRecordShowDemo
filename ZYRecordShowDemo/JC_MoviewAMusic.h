//
//  JC_MoviewAMusic.h
//  MusicAndVideo
//
//  Created by TNP on 2017/6/14.
//  Copyright © 2017年 CXMX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZYRecordAudio;

@interface JC_MoviewAMusic : NSObject
/**
 合并多个视频和单个音频
 
 * @ parameter moviePaths  传入视频数组路径
 * @ parameter musicpath   传入音乐地址 支持m4a
 *
 */
+ (void)movieFliePaths:(NSArray *)moviePaths musicPath:(NSURL *)musicpath success:(void (^)(NSURL * successPath))success failure:(void(^)(NSString *errorMsg))failure;

/**
 合并音频
 
 @param recordAudios 音频地址数组 支持m4a caf
 */
+ (void)combineRecordAudios:(NSArray<NSURL *> *)recordAudios needRemoveOriginAudios:(BOOL)needRemove success:(void (^)(NSURL *))success failure:(void (^)(NSString *))failure;

/**
 合并覆盖音频
 
 @param recordAudios 音频数组
 @param startTime 第二个音频开始时间
 */
+ (void)combineAndCoverRecordAudios:(NSArray<NSURL *> *)recordAudios secondAudioStartTime:(NSTimeInterval)startTime needRemoveOriginAudios:(BOOL)needRemove success:(void (^)(NSURL *))success failure:(void (^)(NSString *))failure;

/**
 剪切音频
 
 @param audioURL 音频URL地址
 @param cutTime 剪切时间
 */
+ (void)cutAudioTrackWithAudioURL:(NSURL * )audioURL cutTime:(NSTimeInterval)cutTime success:(void (^)(NSURL * successURL))success failure:(void(^)(NSString * errorMsg))failure;

/**
 生成当前时间生成录音地址
 
 @return 录音文件保存地址
 */
+ (NSURL *)recordFileURL;

+ (void)clearRecordDirectory;

@end
