//
//  UIView+FeedBack.h
//  feedback
//
//  Created by 宁金鹏 on 2017/2/18.
//  Copyright © 2017年 宁金鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (KFDSUI)

@property (nonatomic) CGFloat wxui_left;

/**
 * Shortcut for frame.origin.y
 *
 * Sets frame.origin.y = top
 */
@property (nonatomic) CGFloat wxui_top;

/**
 * Shortcut for frame.origin.x + frame.size.width
 *
 * Sets frame.origin.x = right - frame.size.width
 */
@property (nonatomic) CGFloat wxui_right;

/**
 * Shortcut for frame.origin.y + frame.size.height
 *
 * Sets frame.origin.y = bottom - frame.size.height
 */
@property (nonatomic) CGFloat wxui_bottom;

/**
 * Shortcut for frame.size.width
 *
 * Sets frame.size.width = width
 */
@property (nonatomic) CGFloat wxui_width;

/**
 * Shortcut for frame.size.height
 *
 * Sets frame.size.height = height
 */
@property (nonatomic) CGFloat wxui_height;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat wxui_centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat wxui_centerY;
/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint wxui_origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize wxui_size;

//找到自己的vc
- (UIViewController *)wxui_viewController;

@end
