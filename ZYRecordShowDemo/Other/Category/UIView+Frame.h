//
//  UIView+Frame.h
//  NewZodiac
//
//  Created by XieWei on 2017/3/30.
//  Copyright © 2017年 XieWei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Frame)


@property(nonatomic, assign) CGPoint origin;// 原点

@property(nonatomic, assign) CGFloat left;//左
@property(nonatomic, assign) CGFloat top;//上

@property(nonatomic, assign) CGFloat right;//右
@property(nonatomic, assign) CGFloat bottom;//下

@property(nonatomic, assign) CGFloat width;//宽度
@property(nonatomic, assign) CGFloat height;//高度

@property (assign, nonatomic) CGFloat centerX;
@property (assign, nonatomic) CGFloat centerY;

@end
