//
//  KFDSUserinfoViewController.h
//  wxui
//
//  Created by 宁金鹏 on 2017/12/18.
//  Copyright © 2017年 吾协云. All rights reserved.
//

#import <QMUIKit/QMUIKit.h>

@class WXThreadModel;

@interface KFDSUserinfoViewController : QMUICommonTableViewController

- (void) initWithThreadModel:(WXThreadModel *)threadModel;

@end
