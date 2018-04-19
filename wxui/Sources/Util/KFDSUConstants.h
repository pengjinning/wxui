//
//  KFUConstants.h
//  wxui
//
//  Created by 宁金鹏 on 2017/11/22.
//  Copyright © 2017年 吾协云. All rights reserved.
//

#ifndef KFDSUConstants_h
#define KFDSUConstants_h

#define KFDSScreen [UIScreen mainScreen].bounds.size

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define KFDS_INPUTBAR_HEIGHT 44
#define KFDS_EXTVIEW_HEIGHT  216



#endif /* KFUConstants_h */
