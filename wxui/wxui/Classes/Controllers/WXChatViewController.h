//
//  KFDSChatViewController.h
//  wxui
//
//  Created by 宁金鹏 on 2017/11/29.
//  Copyright © 2017年 吾协云. All rights reserved.
//

#import <QMUIKit/QMUIKit.h>

@import wxcore;

@interface WXChatViewController : QMUICommonTableViewController



#pragma mark - 访客端接口
/**
 访客端SDK请求会话初始化参数
 
 @param workgroupId 工作组id
 */
- (void) initWithWorkgroupId:(NSNumber *)workgroupId withTitle:(NSString *)title withPush:(BOOL)isPush;


#pragma mark - 客服端接口
/**
 客服端打开会话的时候传入初始化数据
 */
- (void) initWithThreadModel:(WXThreadModel *)threadModel withPush:(BOOL)isPush;


#pragma mark - 公共接口



@end





