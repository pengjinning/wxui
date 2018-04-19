//
//  KFDSMsgBaseContentView.h
//  feedback
//
//  Created by 宁金鹏 on 2017/2/18.
//  Copyright © 2017年 宁金鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

@import wxcore;


@protocol KFDSMsgBaseContentViewDelegate <NSObject>

// TODO: 点击客服/访客头像，显示其相关信息

// TODO: text点击超链接

// TODO: 打开放大图片
- (void) imageViewClicked:(UIImageView *)imageView;

@end



@interface KFDSMsgBaseContentView : UIControl

@property (nonatomic, strong, readonly)  WXMessageModel   *model;

@property (nonatomic, strong) UIImageView * bubbleImageView;

@property (nonatomic, weak) id<KFDSMsgBaseContentViewDelegate> delegate;

/**
 *  contentView初始化方法
 *
 *  @return content实例
 */
- (instancetype)initMessageContentView;

/**
 *  刷新方法
 *
 *  @param data 刷新数据
 */
- (void)refresh:(WXMessageModel*)data;


///**
// *  手指从contentView内部抬起
// */
//- (void)onTouchUpInside:(id)sender;
//
//
///**
// *  手指从contentView外部抬起
// */
//- (void)onTouchUpOutside:(id)sender;
//
///**
// *  手指按下contentView
// */
//- (void)onTouchDown:(id)sender;


/**
 *  聊天气泡图
 *
 *  @param state    目前的按压状态
 *  @param outgoing 是否是发出去的消息
 *
 */
- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing;


@end






