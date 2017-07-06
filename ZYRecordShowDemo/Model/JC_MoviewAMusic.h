//
//  JC_MoviewAMusic.h
//  MusicAndVideo
//
//  Created by TNP on 2017/6/14.
//  Copyright © 2017年 CXMX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JC_MoviewAMusic : NSObject
/**
 * @ parameter moviePaths  传入视频数组路径
 * @ parameter musicpath   传入音乐地址 支持caf, m4a
 * @ return 如果合成成功返回合成视频路径url  注意是URL 不是nsstring 失败返回nil
 *
 */
+(void)movieFliePaths:(NSArray *_Nullable)moviePaths musicPath:(NSURL *_Nullable)musicpath success:(void (^ __nullable)(NSURL * _Nullable successPath))success failure:(void(^ __nullable)(NSString * _Nullable errorMsg))failure;

@end
