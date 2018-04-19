//
//  KFDSUIApis.h
//  wxui
//
//  Created by 宁金鹏 on 2017/7/15.
//  Copyright © 2017年 吾协云. All rights reserved.
//

#import <Foundation/Foundation.h>

@import wxcore;

@interface WXUIApis : NSObject

+ (WXUIApis *)sharedInstance;

//- (void) connect;
//
//- (void) connectWithUsername:(NSString *)username withPassword:(NSString *)password;


#pragma mark - 访客端接口


+ (void)visitorPushChat:(UINavigationController *)navigationController
        withWorkgroupId:(NSNumber *)workgroupId
              withTitle:(NSString *)title;


+ (void)visitorPresentChat:(UINavigationController *)navigationController
        withWorkgroupId:(NSNumber *)workgroupId
              withTitle:(NSString *)title;



#pragma mark - 客服端接口

+ (void)adminPushChat:(UINavigationController *)navigationController
       withThreadModel:(WXThreadModel *)threadModel;

+ (void)adminPresentChat:(UINavigationController *)navigationController
      withThreadModel:(WXThreadModel *)threadModel;


#pragma mark - 公共接口




@end






