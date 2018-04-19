//
//  KFDSChatViewController.m
//  wxui
//
//  Created by 宁金鹏 on 2017/11/29.
//  Copyright © 2017年 吾协云. All rights reserved.
//

#import "WXChatViewController.h"
//#import "KFDSInputView.h"
//#import "KFDSRecordVoiceViewHUD.h"
#import "KFDSMsgViewCell.h"
#import "KFDSMsgNotificationViewCell.h"
#import "KFDSUserinfoViewController.h"
//#import "QDMultipleImagePickerPreviewViewController.h"
#import "QDSingleImagePickerPreviewViewController.h"
#import "QDNavigationController.h"
#import "KFDSUConstants.h"

#define MaxSelectedImageCount 9
#define NormalImagePickingTag 1045
#define ModifiedImagePickingTag 1046
#define MultipleImagePickingTag 1047
#define SingleImagePickingTag 1048

static CGFloat const kToolbarHeight = 56;
static CGFloat const kEmotionViewHeight = 232;

@import wxcore;

//define this constant if you want to enable auto-boxing for default syntax
//#define MAS_SHORTHAND_GLOBALS
//#import <Masonry/Masonry.h>

static QMUIAlbumContentType const kAlbumContentType = QMUIAlbumContentTypeOnlyPhoto;

// QDMultipleImagePickerPreviewViewControllerDelegate
// KFDSInputViewDelegate
@interface WXChatViewController ()<UINavigationControllerBackButtonHandlerProtocol, KFDSMsgViewCellDelegate, QMUIAlbumViewControllerDelegate,QMUIImagePickerViewControllerDelegate,QDSingleImagePickerPreviewViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QMUITextFieldDelegate, QMUIImagePreviewViewDelegate>
{
//    __weak WXChatViewController *weakSelf;
//    UIView *weakSuperView;
}


@property(nonatomic, strong) UIView *toolbarView;
@property(nonatomic, strong) QMUITextField *toolbarTextField;
//@property(nonatomic, strong) QMUIButton *faceButton;
@property(nonatomic, strong) QMUIButton *sendButton;
@property(nonatomic, strong) QMUIButton *plusButton;
//@property(nonatomic, strong) QMUIQQEmotionManager *emotionInputManager;

//
//@property(nonatomic, strong) NSString *mRole;

@property(nonatomic, strong) QMUIImagePreviewViewController *imagePreviewViewController;
@property(nonatomic, strong) UIImageView *currentImageView;
//@property(nonatomic, strong) NSArray<UIImage *> *images;

// 是否为访客端
@property(nonatomic, assign) BOOL mIsVisitor;
@property(nonatomic, assign) BOOL mIsPush;
@property(nonatomic, assign) BOOL mIsDefaultRobot;
@property(nonatomic, assign) BOOL mIsThreadClosed;

@property(nonatomic, assign) BOOL mIsInternetReachable;
@property(nonatomic, strong) NSString *mTitle;

@property(nonatomic, strong) UIRefreshControl *mRefreshControl;
@property(nonatomic, strong) NSMutableArray<WXMessageModel *> *mMessageArray;

@property(nonatomic, strong) UIView *parentView;

//@property(nonatomic, strong) KFDSInputView *mInputView;
//@property(nonatomic, strong) KFDSRecordVoiceViewHUD *mRecordVoiceViewHUD;

@property(nonatomic, assign) NSInteger mGetMessageFromChannelOffset;
@property(nonatomic, assign) NSInteger mGetMessageFromChannelStepLength;

//客服端
@property(nonatomic, strong) WXThreadModel *mThreadModel;

@property (nonatomic, strong) UIImagePickerController    *m_imagePickerController;

@end

@implementation WXChatViewController

@synthesize m_imagePickerController;


#pragma mark - 访客端接口

- (void)initWithWorkgroupId:(NSNumber *)workgroupId withTitle:(NSString *)title withPush:(BOOL)isPush{
    // titleView状态：1. 连接中...(发送请求到服务器，进入队列)，2. 排队中...(队列中等待客服接入会话), 3. 接入会话（一闪而过）
//    self.mRole = KFDS_ROLE_VISITOR;
    self.mIsVisitor = YES;
    self.mIsPush = isPush;
//    self.mIsDefaultRobot = isDefaultRobot;
    self.mIsThreadClosed = NO;
    self.titleView.needsLoadingView = YES;
    self.titleView.loadingViewHidden = NO;
    self.title = _mTitle = title;
    self.titleView.title = _mTitle;
    self.titleView.subtitle = @"连接中...";
    self.titleView.style = QMUINavigationTitleViewStyleSubTitleVertical;
    self.mThreadModel = [[WXThreadModel alloc] init];
    self.mThreadModel.workgroup_id = workgroupId;
    self.m_imagePickerController = [[UIImagePickerController alloc] init];
    self.m_imagePickerController.delegate = self;
    
    if (!self.mIsPush) {
        self.navigationItem.leftBarButtonItem = [QMUINavigationButton barButtonItemWithType:QMUINavigationButtonTypeBack title:@"" tintColor:[UIColor whiteColor] position:QMUINavigationButtonPositionLeft target:self action:@selector(handleLeftBarButtonItemClicked)];
    }
//    TODO: title 应该根据状态显示不同内容：机器人（转人工客服），人工客服（结束会话）
//    self.navigationItem.rightBarButtonItem = [QMUINavigationButton barButtonItemWithType:QMUINavigationButtonTypeNormal title:@"结束会话" position:QMUINavigationButtonPositionRight target:self action:@selector(handleRightBarButtonItemClicked)];
    //
    [WXCoreApis visitorRequestThreadWithWorkgroupId:workgroupId
                                      resultSuccess:^(NSDictionary *dict) {
                                        NSLog(@"%s, %@", __PRETTY_FUNCTION__, dict);
                                          // TODO: 一个访客同时也在其他端有登录的话，其他客户端也应该同步显示)
                                          // TODO: 优化为服务器端直接加入
                                          NSNumber *status_code = [dict objectForKey:@"status_code"];
                                          if ([status_code isEqualToNumber:[NSNumber numberWithInt:100]]
                                              || [status_code isEqualToNumber:[NSNumber numberWithInt:101]]
                                              || [status_code isEqualToNumber:[NSNumber numberWithInt:102]]) {
                                              // 排队
                                              self.titleView.title = dict[@"data"][@"title"];
                                              self.titleView.subtitle = @"排队中";
                                              self.mThreadModel.mid = dict[@"data"][@"message"][@"thread_id"];
                                              // 接入会话
                                              WXMessageModel *messageModel = [[WXMessageModel alloc] initWithDictionary:dict[@"data"][@"message"]];
                                              [[WXDBApis sharedInstance] insertMessage:messageModel];
                                              [self reloadTableData];
                                              // 加入queue队列
                                              NSString *queue_id = dict[@"data"][@"queue_id"];
                                              NSString *visitorQueueChannel = [NSString stringWithFormat:@"queue/%@", queue_id];
                                              [[WXSocketApis sharedInstance] visitorJoinChannel:visitorQueueChannel
                                                                                    resultSuccess:^(NSDictionary *dict) {
                                                                                        
                                                                                    }
                                                                                     resultFailed:^(NSError *error) {
                                                                                         NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
                                                                                     }];
                                              // 加入thread会话channel
                                              NSString *thread_id = dict[@"data"][@"message"][@"thread_id"];
                                              NSString *visitorThreadChannel = [NSString stringWithFormat:@"thread/%@", thread_id];
                                              [[WXSocketApis sharedInstance] visitorJoinChannel:visitorThreadChannel
                                                                                    resultSuccess:^(NSDictionary *dict) {
                                                                                        
                                                                                    }
                                                                                     resultFailed:^(NSError *error) {
                                                                                         NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
                                                                                     }];
                                          } else if ([status_code isEqualToNumber:[NSNumber numberWithInt:200]]){
                                              //
                                              self.titleView.title = dict[@"data"][@"title"];
                                              self.titleView.subtitle = @"会话中";
                                              self.titleView.needsLoadingView = NO;
                                              self.mThreadModel.mid = dict[@"data"][@"message"][@"thread_id"];
                                              // 会话
                                              WXMessageModel *messageModel = [[WXMessageModel alloc] initWithDictionary:dict[@"data"][@"message"]];
                                              [[WXDBApis sharedInstance] insertMessage:messageModel];
                                              [self reloadTableData];
                                              //
                                              NSString *thread_id = dict[@"data"][@"message"][@"thread_id"];
                                              NSString *visitorThreadChannel = [NSString stringWithFormat:@"thread/%@", thread_id];
                                              [[WXSocketApis sharedInstance] visitorJoinChannel:visitorThreadChannel
                                                                                    resultSuccess:^(NSDictionary *dict) {
                                                                                        NSLog(@"%s %@", __PRETTY_FUNCTION__, dict);
                                                                                    }
                                                                                     resultFailed:^(NSError *error) {
                                                                                         NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
                                                                                     }];
                                          } else if ([status_code isEqualToNumber:[NSNumber numberWithInt:300]]) {
                                              // 机器人
                                          }
                                    } resultFailed:^(NSError *error) {
                                        NSLog(@"%s, %@", __PRETTY_FUNCTION__, error);
                                    }];
    
}

#pragma mark - 客服端接口

- (void)initWithThreadModel:(WXThreadModel *)threadModel withPush:(BOOL)isPush{
    // 变量初始化
    self.mIsVisitor = NO;
    self.mIsPush = isPush;
    self.mThreadModel = threadModel;
    self.m_imagePickerController = [[UIImagePickerController alloc] init];
    self.m_imagePickerController.delegate = self;
    //
    if (!self.mIsPush) {
        self.navigationItem.leftBarButtonItem = [QMUINavigationButton barButtonItemWithType:QMUINavigationButtonTypeBack title:@"" tintColor:[UIColor whiteColor] position:QMUINavigationButtonPositionLeft target:self action:@selector(handleLeftBarButtonItemClicked)];
    }
    // 右上角按钮
    self.navigationItem.rightBarButtonItem =[QMUINavigationButton barButtonItemWithNavigationButton:[QMUINavigationButton buttonWithType:UIButtonTypeInfoLight] position:QMUINavigationButtonPositionRight target:self action:@selector(handleRightBarButtonItemClicked)];
}

#define UIColorGray5 UIColorMake(133, 140, 150)

#pragma mark - 公共接口

- (void)initSubviews {
    [super initSubviews];
//    weakSelf = self;
//    weakSuperView = weakSelf.view;
    //
    self.tableView.separatorColor = [UIColor clearColor];
    //
//    self.mInputView = [[KFDSInputView alloc] init];
//    self.mInputView.delegate = self;
//    [self.view addSubview:self.mInputView];
    //
    _toolbarView = [[UIView alloc] init];
    self.toolbarView.backgroundColor = UIColorWhite;
    self.toolbarView.qmui_borderColor = UIColorSeparator;
    self.toolbarView.qmui_borderPosition = QMUIBorderViewPositionTop;
    [self.view addSubview:self.toolbarView];
    
    _toolbarTextField = [[QMUITextField alloc] init];
    self.toolbarTextField.delegate = self;
    self.toolbarTextField.placeholder = @"请输入...";
    self.toolbarTextField.font = UIFontMake(15);
    self.toolbarTextField.backgroundColor = UIColorWhite;
    self.toolbarTextField.returnKeyType = UIReturnKeySend;
    [self.toolbarView addSubview:self.toolbarTextField];
    
//    __weak __typeof(self)weakSelf = self;
//    self.toolbarTextField.qmui_keyboardWillChangeFrameNotificationBlock = ^(QMUIKeyboardUserInfo *keyboardUserInfo) {
//        if (!weakSelf.faceButton.isSelected) {
//            [QMUIKeyboardManager handleKeyboardNotificationWithUserInfo:keyboardUserInfo showBlock:^(QMUIKeyboardUserInfo *keyboardUserInfo) {
//                [weakSelf showToolbarViewWithKeyboardUserInfo:keyboardUserInfo];
//            } hideBlock:^(QMUIKeyboardUserInfo *keyboardUserInfo) {
//                [weakSelf hideToolbarViewWithKeyboardUserInfo:keyboardUserInfo];
//            }];
//        } else {
//            [weakSelf showToolbarViewWithKeyboardUserInfo:nil];
//        }
//    };
    
    //
    /*
    _faceButton = [[QMUIButton alloc] init];
    self.faceButton.qmui_outsideEdge = UIEdgeInsetsMake(-12, -12, -12, -12);
    [self.faceButton setImage:[UIImage imageNamed:@"ToolViewEmotion_ios7" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.faceButton setImage:[UIImage imageNamed:@"ToolViewEmotionHL_ios7" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    [self.faceButton sizeToFit];
    [self.faceButton addTarget:self action:@selector(handleFaceButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:self.faceButton];
     */
    
    self.sendButton = [[QMUIButton alloc] init];
    self.sendButton.titleLabel.font = UIFontMake(16);
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendButton sizeToFit];
    [self.sendButton addTarget:self action:@selector(handleSendButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:self.sendButton];
    
    ///
    self.plusButton = [[QMUIButton alloc] init];
    self.plusButton.titleLabel.font = UIFontMake(16);
    self.plusButton.qmui_outsideEdge = UIEdgeInsetsMake(-12, -12, -12, -12);
    [self.plusButton setImage:[UIImage imageNamed:@"TypeSelectorBtn_Black_ios7" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [self.plusButton setImage:[UIImage imageNamed:@"TypeSelectorBtnHL_Black_ios7" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil] forState:UIControlStateHighlighted];
    [self.plusButton sizeToFit];
    [self.plusButton addTarget:self action:@selector(handlePlusButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:self.plusButton];
    
    ///
//    self.emotionInputManager = [[QMUIQQEmotionManager alloc] init];
//    self.emotionInputManager.boundTextField = self.toolbarTextField;
//    self.emotionInputManager.emotionView.qmui_borderPosition = QMUIBorderViewPositionTop;
////    self.emotionInputManager.emotionView.emotions = [QDUIHelper qmuiEmotions];
//    [self.emotionInputManager.emotionView.sendButton addTarget:self action:@selector(handleSendButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.emotionInputManager.emotionView];
    
    //
//    self.mRecordVoiceViewHUD = [[KFDSRecordVoiceViewHUD alloc] init];
//    [self.tableView addSubview:self.mRecordVoiceViewHUD];
    //
    self.mGetMessageFromChannelOffset = 0;
    self.mGetMessageFromChannelStepLength = 10;
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.tableView addGestureRecognizer:singleFingerTap];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
//    self.mInputView.frame = CGRectMake(0, KFDSScreen.height - KFDS_INPUTBAR_HEIGHT, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT);
    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - kToolbarHeight);
    
    CGRect toolbarRect = CGRectFlatMake(0, CGRectGetHeight(self.view.bounds) - kToolbarHeight, CGRectGetWidth(self.view.bounds), kToolbarHeight);
    self.toolbarView.frame = CGRectApplyAffineTransform(toolbarRect, self.toolbarView.transform);
    
    CGFloat textFieldInset = 20;
    CGFloat textFieldHeight = kToolbarHeight - textFieldInset * 2;
    CGFloat emotionRight = 12;
    
//    self.faceButton.frame = CGRectSetXY(self.faceButton.frame, CGRectGetWidth(self.toolbarView.bounds) - CGRectGetWidth(self.faceButton.bounds) - emotionRight, CGFloatGetCenter(CGRectGetHeight(self.toolbarView.bounds), CGRectGetHeight(self.faceButton.bounds)));
    self.sendButton.frame = CGRectSetXY(self.sendButton.frame, CGRectGetWidth(self.toolbarView.bounds) - CGRectGetWidth(self.sendButton.bounds) - emotionRight, CGFloatGetCenter(CGRectGetHeight(self.toolbarView.bounds), CGRectGetHeight(self.sendButton.bounds)));
    
    self.plusButton.frame = CGRectSetXY(self.plusButton.frame, 12, CGFloatGetCenter(CGRectGetHeight(self.toolbarView.bounds), CGRectGetHeight(self.plusButton.bounds)));
    
    CGFloat textFieldWidth = CGRectGetMinX(self.sendButton.frame) - textFieldInset * 2;
    self.toolbarTextField.frame = CGRectFlatMake(50, textFieldInset, textFieldWidth, textFieldHeight);
    
//    if (self.emotionInputManager.emotionView) {
//        CGRect emotionViewRect = CGRectMake(0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), kEmotionViewHeight);
//        self.emotionInputManager.emotionView.frame = CGRectApplyAffineTransform(emotionViewRect, self.emotionInputManager.emotionView.transform);
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = _mThreadModel ? _mThreadModel.nickname : _mTitle;
    self.parentView = self.navigationController.view;
//    [self.view setQmui_shouldShowDebugColor:YES];
    //
    if (self.mIsPush) {
        QMUINavigationButton *backButton = [[QMUINavigationButton alloc] initWithType:QMUINavigationButtonTypeBack];
        self.navigationItem.leftBarButtonItem = [QMUINavigationButton barButtonItemWithNavigationButton:backButton position:QMUINavigationButtonPositionLeft target:self action:@selector(handleLeftBarButtonItemClicked)];
    }
    else {
        self.navigationItem.leftBarButtonItem = [QMUINavigationButton closeBarButtonItemWithTarget:self action:@selector(handleLeftBarButtonItemClicked)];
    }
    //
    self.mRefreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [self.tableView addSubview:self.mRefreshControl];
    [self.mRefreshControl addTarget:self action:@selector(refreshControlSelector) forControlEvents:UIControlEventValueChanged];
    //
    [self registerNotifications];
    [self reloadTableData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setNavigationItemsIsInEditMode:(BOOL)isInEditMode animated:(BOOL)animated {
    [super setNavigationItemsIsInEditMode:isInEditMode animated:animated];
}

/**
    针对Present打开模式，左上角返回按钮处理action
 */
- (void)handleLeftBarButtonItemClicked {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    //
    if (self.mIsPush) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            // 善后
        }];
    }
}

- (void)handleRightBarButtonItemClicked {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // 访客端
    if (self.mIsVisitor) {
        //
        QMUIDialogViewController *dialogViewController = [[QMUIDialogViewController alloc] init];
        dialogViewController.title = @"满意度评价";
        //
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
        contentView.backgroundColor = UIColorWhite;
//        UILabel *label = [[UILabel alloc] initWithFont:UIFontMake(14) textColor:UIColorBlack];
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.text = @"自定义contentView";
        [label sizeToFit];
        label.center = CGPointMake(CGRectGetWidth(contentView.bounds) / 2.0, CGRectGetHeight(contentView.bounds) / 2.0);
        [contentView addSubview:label];
        dialogViewController.contentView = contentView;
        //
        [dialogViewController addCancelButtonWithText:@"取消" block:nil];
        [dialogViewController addSubmitButtonWithText:@"确定" block:^(QMUIDialogViewController *aDialogViewController) {
            [aDialogViewController hide];
            // TODO: 发送满意度评价
            // TODO: 通知客服用户关闭会话
            // TODO: 关闭当前会话窗口
            if (self.mIsPush) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    // 善后
                }];
            }
        }];
        [dialogViewController show];
    } else {
        // 客服端
        QMUIAlertAction *cancelAction = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:^(QMUIAlertAction *action) {
            NSLog(@"%s", __PRETTY_FUNCTION__);
        }];
        QMUIAlertAction *closeAction = [QMUIAlertAction actionWithTitle:@"关闭会话" style:QMUIAlertActionStyleDestructive handler:^(QMUIAlertAction *action) {
            // TODO: 关闭会话
            NSLog(@"%s", __PRETTY_FUNCTION__);
            [WXCoreApis adminCloseThread:self.mThreadModel.mid
                resultSuccess:^(NSDictionary *dict) {
                    // TODO: 关闭当前会话窗口
                    if (self.mIsPush) {
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        [self.navigationController dismissViewControllerAnimated:YES completion:^{
                            // 善后
                        }];
                    }
                } resultFailed:^(NSError *error) {
                    NSLog(@"%s, %@", __PRETTY_FUNCTION__, error);
                }];
        }];
        // TODO: <二期开发>
//        QMUIAlertAction *rateAction = [QMUIAlertAction actionWithTitle:@"评价会话" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//            //TODO: 评价会话
//            NSLog(@"%s", __PRETTY_FUNCTION__);
//            //
//
//        }];
//        QMUIAlertAction *inviteAction = [QMUIAlertAction actionWithTitle:@"邀请会话" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//            //TODO: 邀请会话
//            NSLog(@"%s", __PRETTY_FUNCTION__);
//            //
//
//        }];
//        QMUIAlertAction *transferAction = [QMUIAlertAction actionWithTitle:@"转接会话" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//            //TODO: 转接会话
//            NSLog(@"%s", __PRETTY_FUNCTION__);
//            //
//        }];
//        QMUIAlertAction *userInfoAction = [QMUIAlertAction actionWithTitle:@"用户信息" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//            //TODO: 用户信息
//            NSLog(@"%s", __PRETTY_FUNCTION__);
//            KFDSUserinfoViewController *userinfoViewController = [[KFDSUserinfoViewController alloc] init];
//            [userinfoViewController initWithThreadModel:self.mThreadModel];
//            [self.navigationController pushViewController:userinfoViewController animated:YES];
//        }];
        //
        QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"工具栏" message:@"" preferredStyle:QMUIAlertControllerStyleActionSheet];
        [alertController addAction:cancelAction]; // 最底部
        [alertController addAction:closeAction]; // 中间
        // TODO: <二期开发>
//        [alertController addAction:rateAction]; //
//        [alertController addAction:inviteAction];
//        [alertController addAction:transferAction];
//        [alertController addAction:userInfoAction];
        [alertController showWithAnimated:YES];
    }
    
}

#pragma mark - <QMUITableViewDataSource, QMUITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.mMessageArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *notifyIdentifier = @"notifyCell";
    static NSString *msgIdentifier = @"msgCell";
    //
    WXMessageModel *messageModel = [self.mMessageArray objectAtIndex:indexPath.row];
    if ([messageModel isNotification]) {
        //
        KFDSMsgNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:notifyIdentifier];
        if (!cell) {
            cell = [[KFDSMsgNotificationViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:notifyIdentifier];
        }
        [cell initWithMessageModel:messageModel];
        cell.tag = indexPath.row;
        //
        return cell;
    } else {
        //
        KFDSMsgViewCell *cell = [tableView dequeueReusableCellWithIdentifier:msgIdentifier];
        if (!cell) {
            cell = [[KFDSMsgViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:msgIdentifier];
            cell.delegate = self;
        }
        //
        [cell initWithMessageModel:messageModel];
        cell.tag = indexPath.row;
        //
        return cell;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //
    CGFloat height = 0.0;
    //
    WXMessageModel *messageModel = [self.mMessageArray objectAtIndex:indexPath.row];
    if ([messageModel isNotification]) {
        //
        height = 50;
    } else {
        //
        if ([messageModel.type isEqualToString:KFDS_MESSAGE_TYPE_TEXT]) {
            if ([messageModel isSend]) {
                height = messageModel.contentSize.height + messageModel.contentViewInsets.top + messageModel.contentViewInsets.bottom + 30;
            }
            else {
                height = messageModel.contentSize.height + messageModel.contentViewInsets.top + messageModel.contentViewInsets.bottom + 40;
            }
            //
            if (height < 45) {
                height = 45;
            }
        } else if ([messageModel.type isEqualToString:KFDS_MESSAGE_TYPE_IMAGE]) {
            height = 280;
        }
        else {
            height = 80;
        }
    }
    
    
    return height;
}


#pragma mark - Utils

- (void)reloadTableData {
    
    // TODO: 仅适用于访客端，客服端需要增加访客id参数
    self.mMessageArray = [WXCoreApis getMessagesWithWorkgroup:self.mThreadModel.workgroup_id];
    if ([self.mMessageArray count] == 0) {
        [self showEmptyViewWithText:@"消息记录为空" detailText:@"请尝试下拉刷新" buttonTitle:nil buttonAction:NULL];
    } else if (self.emptyViewShowing){
        [self hideEmptyView];
    }
    // 刷新tableView
    [self.tableView reloadData];
    [self tableViewScrollToBottom:NO];
}

#pragma mark - UINavigationControllerBackButtonHandlerProtocol 拦截退出界面

- (BOOL)shouldHoldBackButtonEvent {
    return YES;
}

- (BOOL)canPopViewController {
    // 这里不要做一些费时的操作，否则可能会卡顿。
    NSLog(@"%s", __PRETTY_FUNCTION__);
    //
//    [self unregisterNotifications];
    // 保存草稿
//    return NO; //拦截，不能退出界面
    return YES; //
}

#pragma mark - Notifications

- (void)registerNotifications {
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyQueueAccept:) name:KFDS_NOTIFICATION_QUEUE_ACCEPT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyThreadClose:) name:KFDS_NOTIFICATION_THREAD_CLOSE object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMessageAdd:) name:KFDS_NOTIFICATION_MESSAGE_ADD object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMessageDelete:) name:KFDS_NOTIFICATION_MESSAGE_DELETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMessageRetract:) name:KFDS_NOTIFICATION_MESSAGE_RETRACT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMessageStatus:) name:KFDS_NOTIFICATION_MESSAGE_STATUS object:nil];
}


- (void)unregisterNotifications {
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - TableViewRelated

-(void)tableViewScrollToBottom:(BOOL)animated{
    
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    
    if(rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
    }
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.view endEditing:YES];

//    self.mInputView.frame = CGRectMake(0, KFDSScreen.height - KFDS_INPUTBAR_HEIGHT, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT);
//    [self.mInputView.emotionView setHidden:TRUE];
//    [self.mInputView.plusView setHidden:TRUE];
    
    UIEdgeInsets tableViewInsets = self.tableView.contentInset;
    tableViewInsets.bottom = KFDS_INPUTBAR_HEIGHT;
    self.tableView.contentInset = tableViewInsets;
    self.tableView.scrollIndicatorInsets = tableViewInsets;
}


#pragma mark - Handle Keyboard Show/Hide

- (void)handleWillShowKeyboard:(NSNotification *)notification {
//    NSLog(@"%s", __PRETTY_FUNCTION__);

    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGRect keyboardFrame = [self.view convertRect:keyboardRect fromView:nil];
//    NSUInteger keyboardY = keyboardFrame.origin.y;

    NSUInteger keyboardHeight = keyboardFrame.size.height;
//    NSLog(@"%s keyboard height:%lu", __PRETTY_FUNCTION__, keyboardHeight);

    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
//                         weakSelf.mInputView.frame = CGRectMake(0, keyboardY - KFDS_INPUTBAR_HEIGHT, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT);
//                         CGRect inputViewFrame = [weakSelf.mInputView frame];
//                         inputViewFrame.origin.y = keyboardY - KFDS_INPUTBAR_HEIGHT;
//                         [weakSelf.mInputView setFrame:inputViewFrame];

                         //
                         UIEdgeInsets tableViewInsets = self.tableView.contentInset;
                         tableViewInsets.bottom = keyboardHeight + kToolbarHeight;
                         self.tableView.contentInset = tableViewInsets;
                         self.tableView.scrollIndicatorInsets = tableViewInsets;

                     } completion:^(BOOL finished) {
                         [self tableViewScrollToBottom:YES];
                     }];

}


- (void)handleWillHideKeyboard:(NSNotification *)notification {
//    NSLog(@"%s", __PRETTY_FUNCTION__);

//    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

//    NSUInteger keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;//键盘位置的y坐标
//    self.mInputView.frame = CGRectMake(0, keyboardY - KFDS_INPUTBAR_HEIGHT, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT);

    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{

                         UIEdgeInsets tableViewInsets = self.tableView.contentInset;
                         tableViewInsets.bottom = KFDS_INPUTBAR_HEIGHT;
                         self.tableView.contentInset = tableViewInsets;
                         self.tableView.scrollIndicatorInsets = tableViewInsets;

                     } completion:^(BOOL finished) {

                     }];

    [self tableViewScrollToBottom:YES];

}

//- (void)inputViewExtShowConstraints {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [UIView animateWithDuration:0.3f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//
//                         CGFloat Y = KFDSScreen.height - KFDS_INPUTBAR_HEIGHT - KFDS_EXTVIEW_HEIGHT;
//                         weakSelf.mInputView.frame = CGRectMake(0, Y, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT + KFDS_EXTVIEW_HEIGHT);
//
//                     } completion:^(BOOL finished) {
//                         [weakSelf tableViewScrollToBottom:YES];
//                     }];
//
//}
//
//- (void)inputViewExtHideConstraints {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [UIView animateWithDuration:0.3f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//
//                         CGFloat Y = KFDSScreen.height - KFDS_INPUTBAR_HEIGHT;
//                         weakSelf.mInputView.frame = CGRectMake(0, Y, KFDSScreen.width, KFDS_INPUTBAR_HEIGHT);
//
//                     } completion:^(BOOL finished) {
//
//                     }];
//}

#pragma mark - KFDSInputViewDelegate
//
//-(void)textViewHeightChanged:(NSString *)text height:(CGFloat)textHeight {
//    NSLog(@"%s, text: %@, height: %f", __PRETTY_FUNCTION__, text, textHeight);
//
//    CGRect inputFrame = self.mInputView.frame;
//    CGFloat Y = inputFrame.origin.y - (textHeight + 10 - inputFrame.size.height);
//    NSLog(@"origin.y:%f, Y:%f", inputFrame.origin.y, Y);
//
//    self.mInputView.frame = CGRectMake(0, Y, KFDSScreen.width, textHeight);
//}
//
//-(void)showMenuButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//-(void)switchVoiceButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [self.mInputView.emotionView setHidden:TRUE];
//    [self.mInputView.plusView setHidden:TRUE];
//
////    [self inputViewExtHideConstraints];
//    [self tableViewScrollToBottom:YES];
//}
//
//-(void)switchEmotionButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
////    if (self.mInputView.inputToolbar.inputTextView) {
////
////    }
//
//    [self.view endEditing:YES];
//
//    //
//    if ([self.mInputView.emotionView isHidden]) {
//        [self.mInputView.emotionView setHidden:FALSE];
//        //
//        if ([self.mInputView.plusView isHidden]) {
//            [self inputViewExtShowConstraints];
//            [self tableViewScrollToBottom:YES];
//        }
//        else {
////            NSLog(@"%s 1", __PRETTY_FUNCTION__);
//            [self.mInputView.plusView setHidden:TRUE];
//        }
//    }
//    else {
////        NSLog(@"%s 2", __PRETTY_FUNCTION__);
//        [self.mInputView.emotionView setHidden:TRUE];
//        [self inputViewExtHideConstraints];
//        [self tableViewScrollToBottom:YES];
//    }
//}
//
//-(void)switchPlusButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//    [self.view endEditing:YES];
//
//    if ([self.mInputView.plusView isHidden]) {
//        [self.mInputView.plusView setHidden:FALSE];
//
//        if ([self.mInputView.emotionView isHidden]) {
//            [self inputViewExtShowConstraints];
//            [self tableViewScrollToBottom:YES];
//        }
//        else {
//            [self.mInputView.emotionView setHidden:TRUE];
//        }
//    }
//    else {
//        [self.mInputView.plusView setHidden:TRUE];
//
//        [self inputViewExtHideConstraints];
//        [self tableViewScrollToBottom:YES];
//    }
//}

#pragma mark - 发送消息

-(void)sendMessage:(NSString *)content {
    NSLog(@"%s, content:%@ ", __PRETTY_FUNCTION__, content);
    //
    if (self.mIsThreadClosed) {
         [QMUITips showError:@"客服已经关闭会话,不能发送消息" inView:self.parentView hideAfterDelay:2];
        return;
    }
    
    //
    if (!self.mIsVisitor) {
        [WXCoreApis sendTextMessageToThread:self.mThreadModel.mid
                                  withContent:content
                                     withRole:KFDS_ROLE_AGENT
                                resultSuccess:^(NSDictionary *dict) {
                                    NSLog(@"%s, %@", __PRETTY_FUNCTION__, dict);
                                    
                                } resultFailed:^(NSError *error) {
                                    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
                                }];
    }
    else {
        // TODO: threadId待定
        [WXCoreApis sendTextMessageToThread:self.mThreadModel.mid
                                  withContent:content
                                     withRole:KFDS_ROLE_VISITOR
                                resultSuccess:^(NSDictionary *dict) {
                                    NSLog(@"%s, %@", __PRETTY_FUNCTION__, dict);
                                    
                                } resultFailed:^(NSError *error) {
                                    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
                                }];
    }
    
}


- (void)sendImage:(NSData *)imageData {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    //
    NSString *imageName = [NSString stringWithFormat:@"%@_%@_%@.png", [KFDSCSettings getUsername], self.mThreadModel.mid, [KFDSCUtils getCurrentTimeString]];
    [WXCoreApis uploadImageData:imageData withImageName:imageName resultSuccess:^(NSDictionary *dict) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, dict);
        NSString *pic_url = dict[@"data"][@"pic_url"];
        if (!self.mIsVisitor) {
            //
            [WXCoreApis sendImageMessageToThread:self.mThreadModel.mid withImageUrl:pic_url withRole:KFDS_ROLE_AGENT resultSuccess:^(NSDictionary *dict) {
                
            } resultFailed:^(NSError *error) {
                
            }];
        } else {
            //
            [WXCoreApis sendImageMessageToThread:self.mThreadModel.mid withImageUrl:pic_url withRole:KFDS_ROLE_VISITOR resultSuccess:^(NSDictionary *dict) {
                
            } resultFailed:^(NSError *error) {
                
            }];
        }
        
    } resultFailed:^(NSError *error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
    }];
}


#pragma mark - 录音

//-(void)recordVoiceButtonTouchDown:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//-(void)recordVoiceButtonTouchUpInside:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//-(void)recordVoiceButtonTouchUpOutside:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//-(void)recordVoiceButtonTouchDragInside:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//-(void)recordVoiceButtonTouchDragOutside:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}

#pragma mark - 拍照等Plus

-(void)sharePickPhotoButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self authorizationPresentAlbumViewControllerWithTitle:@"选择图片"];
}

-(void)shareTakePhotoButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusDenied
       || authStatus ==AVAuthorizationStatusRestricted) {
        // The user has explicitly denied permission for media capture.
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
//                                                            message:@"请在iPhone的‘设置-隐私-相机’选项中，允许访问你的相机"
//                                                           delegate:self
//                                                  cancelButtonTitle:@"确定"
//                                                  otherButtonTitles:nil, nil];
//
//        [alertView show];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@""
                                     message:@"请在iPhone的‘设置-隐私-相机’选项中，允许访问你的相机"
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"确定"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                    }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if(authStatus == AVAuthorizationStatusAuthorized) {//允许访问
        // The user has explicitly granted permission for media capture,
        //or explicit user permission is not necessary for the media type in question.
        //NSLog(@"Authorized");
        
        m_imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:m_imagePickerController animated:YES completion:nil];
        
    }else if(authStatus == AVAuthorizationStatusNotDetermined){
        // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){//点击允许访问时调用
                //用户明确许可与否，媒体需要捕获，但用户尚未授予或拒绝许可。
                //NSLog(@"Granted access to %@", AVMediaTypeVideo);
                self.m_imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:self.m_imagePickerController animated:YES completion:nil];
            }
            else {
                //NSLog(@"Not granted access to %@", AVMediaTypeVideo);
            }
        }];
        
    }else {
        NSLog(@"Unknown authorization status");
    }
}

//-(void)shareRateButtonPressed:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//
//}


#pragma mark - KFDSMsgViewCellDelegate

//- (void)tapCellWith:(NSInteger)tag  {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}

- (void)removeCellWith:(NSInteger)tag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    UIActionSheet *deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"确定要删除？"
//                                                                   delegate:self
//                                                          cancelButtonTitle:@"取消"
//                                                     destructiveButtonTitle:nil
//                                                          otherButtonTitles:@"确定", nil];
//    deleteActionSheet.tag = tag;
//    [deleteActionSheet showInView:self.tableView];
    //
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"确定要删除"
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"确定"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                    //
                                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag inSection:0];
                                    if (indexPath.row < [self.mMessageArray count]) {
                                        WXMessageModel *itemToDelete = [self.mMessageArray objectAtIndex:indexPath.row];
                                        [[WXDBApis sharedInstance] deleteMessage:itemToDelete.mid];
                                        [self.mMessageArray removeObjectAtIndex:indexPath.row];
                                        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                    }
                                    
                                }];
    UIAlertAction* cancelButton = [UIAlertAction
                                actionWithTitle:@"取消"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                }];
    [alert addAction:yesButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)avatarClicked:(WXMessageModel *)messageModel {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, messageModel.avatar);
    
}

// TODO: 打开放大图片
- (void) imageViewClicked:(UIImageView *)imageView {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.currentImageView = imageView;
    
    if (!self.imagePreviewViewController) {
        self.imagePreviewViewController = [[QMUIImagePreviewViewController alloc] init];
        self.imagePreviewViewController.imagePreviewView.delegate = self;
        self.imagePreviewViewController.imagePreviewView.currentImageIndex = 0;// 默认查看的图片的 index
    }
    [self.imagePreviewViewController startPreviewFromRectInScreen:[imageView convertRect:imageView.frame toView:nil] cornerRadius:imageView.layer.cornerRadius];
}

#pragma mark - <QMUIImagePreviewViewDelegate>

- (NSUInteger)numberOfImagesInImagePreviewView:(QMUIImagePreviewView *)imagePreviewView {
    return 1;
}

- (void)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView renderZoomImageView:(QMUIZoomImageView *)zoomImageView atIndex:(NSUInteger)index {
    zoomImageView.image = self.currentImageView.image;
}

- (QMUIImagePreviewMediaType)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView assetTypeAtIndex:(NSUInteger)index {
    return QMUIImagePreviewMediaTypeImage;
}

#pragma mark - <QMUIZoomImageViewDelegate>

- (void)singleTouchInZoomingImageView:(QMUIZoomImageView *)zoomImageView location:(CGPoint)location {
    [self.currentImageView setImage:zoomImageView.image];
    [self.imagePreviewViewController endPreviewToRectInScreen:[self.currentImageView convertRect:self.currentImageView.frame toView:nil]];
}


#pragma mark - 发送图片

- (void)authorizationPresentAlbumViewControllerWithTitle:(NSString *)title {
    if ([QMUIAssetsManager authorizationStatus] == QMUIAssetAuthorizationStatusNotDetermined) {
        [QMUIAssetsManager requestAuthorization:^(QMUIAssetAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentAlbumViewControllerWithTitle:title];
            });
        }];
    } else {
        [self presentAlbumViewControllerWithTitle:title];
    }
}

- (void)presentAlbumViewControllerWithTitle:(NSString *)title {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // 创建一个 QMUIAlbumViewController 实例用于呈现相簿列表
    QMUIAlbumViewController *albumViewController = [[QMUIAlbumViewController alloc] init];
    albumViewController.albumViewControllerDelegate = self;
    albumViewController.contentType = kAlbumContentType;
    albumViewController.title = title;
//    albumViewController.view.tag = SingleImagePickingTag;
    
    QDNavigationController *navigationController = [[QDNavigationController alloc] initWithRootViewController:albumViewController];
    // 获取最近发送图片时使用过的相簿，如果有则直接进入该相簿
    QMUIAssetsGroup *assetsGroup = [QMUIImagePickerHelper assetsGroupOfLastestPickerAlbumWithUserIdentify:nil];
    if (assetsGroup) {
        QMUIImagePickerViewController *imagePickerViewController = [self imagePickerViewControllerForAlbumViewController:albumViewController];
        [imagePickerViewController refreshWithAssetsGroup:assetsGroup];
        imagePickerViewController.title = [assetsGroup name];
        [navigationController pushViewController:imagePickerViewController animated:NO];
    }
    
    [self presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - <QMUIAlbumViewControllerDelegate>

- (QMUIImagePickerViewController *)imagePickerViewControllerForAlbumViewController:(QMUIAlbumViewController *)albumViewController {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    QMUIImagePickerViewController *imagePickerViewController = [[QMUIImagePickerViewController alloc] init];
    imagePickerViewController.imagePickerViewControllerDelegate = self;
    imagePickerViewController.maximumSelectImageCount = 1;
    imagePickerViewController.view.tag = albumViewController.view.tag;
    imagePickerViewController.allowsMultipleSelection = NO;
    
    return imagePickerViewController;
}


#pragma mark - <QMUIImagePickerViewControllerDelegate>

//- (void)imagePickerViewController:(QMUIImagePickerViewController *)imagePickerViewController didFinishPickingImageWithImagesAssetArray:(NSMutableArray<QMUIAsset *> *)imagesAssetArray {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}

- (QMUIImagePickerPreviewViewController *)imagePickerPreviewViewControllerForImagePickerViewController:(QMUIImagePickerViewController *)imagePickerViewController {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    QDSingleImagePickerPreviewViewController *imagePickerPreviewViewController = [[QDSingleImagePickerPreviewViewController alloc] init];
    imagePickerPreviewViewController.delegate = self;
    imagePickerPreviewViewController.assetsGroup = imagePickerViewController.assetsGroup;
    imagePickerPreviewViewController.view.tag = imagePickerViewController.view.tag;
    return imagePickerPreviewViewController;
}

#pragma mark - <QMUIImagePickerPreviewViewControllerDelegate>

//- (void)imagePickerPreviewViewController:(QMUIImagePickerPreviewViewController *)imagePickerPreviewViewController didCheckImageAtIndex:(NSInteger)index {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//}

#pragma mark - <QDMultipleImagePickerPreviewViewControllerDelegate>

//- (void)imagePickerPreviewViewController:(QDMultipleImagePickerPreviewViewController *)imagePickerPreviewViewController sendImageWithImagesAssetArray:(NSMutableArray<QMUIAsset *> *)imagesAssetArray {
//    // 储存最近选择了图片的相册，方便下次直接进入该相册
//    [QMUIImagePickerHelper updateLastestAlbumWithAssetsGroup:imagePickerPreviewViewController.assetsGroup ablumContentType:kAlbumContentType userIdentify:nil];
//    // 显示 loading
//    [self startLoading];
//    // 使用 delay 模拟网络请求时长
//    NSString *succeedTip;
//    if (imagePickerPreviewViewController.shouldUseOriginImage) {
//        succeedTip = @"成功发送%@张原图";
//    } else {
//        succeedTip = @"成功发送%@张图片";
//    }
//    [self performSelector:@selector(showTipLabelWithText:) withObject:[NSString stringWithFormat:succeedTip, @([imagesAssetArray count])] afterDelay:1.5];
//}

#pragma mark - <QDSingleImagePickerPreviewViewControllerDelegate>

- (void)imagePickerPreviewViewController:(QDSingleImagePickerPreviewViewController *)imagePickerPreviewViewController didSelectImageWithImagesAsset:(QMUIAsset *)imageAsset {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // 储存最近选择了图片的相册，方便下次直接进入该相册
    [QMUIImagePickerHelper updateLastestAlbumWithAssetsGroup:imagePickerPreviewViewController.assetsGroup ablumContentType:kAlbumContentType userIdentify:nil];
    // 显示 loading
//    [self startLoading];
    
    [imageAsset requestImageData:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGIF, BOOL isHEIC) {
        [self sendImage:imageData];
    }];
    
//    [imageAsset requestImageData:^(NSData *imageData, NSDictionary<NSString *,id> *info, BOOL isGif) {
////        UIImage *targetImage = [UIImage imageWithData:imageData];
////        [self performSelector:@selector(sendImage::) withObject:imageData afterDelay:1.8];
//        [self sendImage:imageData];
//    }];
    
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self performSelector:@selector(dealWithImage:) withObject:info];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)dealWithImage:(NSDictionary *)info {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:@"public.movie"])            //被选中的是视频
    {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
//                                                            message:@"请选择图片"
//                                                           delegate:self
//                                                  cancelButtonTitle:@"确定"
//                                                  otherButtonTitles:nil, nil];
//
//        [alertView show];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@""
                                     message:@"请选择图片"
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"确定"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                    }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if([mediaType isEqualToString:@"public.image"])    //被选中的是图片
    {
        //获取照片实例
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        // 旋转
        UIImageOrientation imageOrientation = image.imageOrientation;
        if (imageOrientation != UIImageOrientationUp) {
            
            UIGraphicsBeginImageContext(image.size);
            [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        NSData *imageData = UIImageJPEGRepresentation(image, 0);
        //
        [self sendImage:imageData];
    }
}


#pragma mark UIActionSheetDelegate

//-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//    NSLog(@"%s, buttonIndex:%ld", __PRETTY_FUNCTION__, (long)buttonIndex);
//
//    if (buttonIndex == 0) {
//
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:actionSheet.tag inSection:0];
//        if (indexPath.row < [self.mMessageArray count]) {
//            WXMessageModel *itemToDelete = [self.mMessageArray objectAtIndex:indexPath.row];
//            [[WXDBApis sharedInstance] deleteMessage:itemToDelete.mid];
//            [self.mMessageArray removeObjectAtIndex:indexPath.row];
//            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        }
//    }
//}


#pragma mark -

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.toolbarTextField resignFirstResponder];
    [self hideToolbarViewWithKeyboardUserInfo:nil];
}

#pragma mark - QMUITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self handleSendButtonEvent:nil];
    
    return YES;
}

- (void)textField:(QMUITextField *)textField didPreventTextChangeInRange:(NSRange)range replacementString:(NSString *)replacementString {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    self.faceButton.selected = NO;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    self.emotionInputManager.selectedRangeForBoundTextInput = self.toolbarTextField.qmui_selectedRange;
    return YES;
}

#pragma mark - ToolbarView Show And Hide

- (void)showToolbarViewWithKeyboardUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    if (keyboardUserInfo) {
        // 相对于键盘
        [QMUIKeyboardManager animateWithAnimated:YES keyboardUserInfo:keyboardUserInfo animations:^{
            CGFloat distanceFromBottom = [QMUIKeyboardManager distanceFromMinYToBottomInView:self.view keyboardRect:keyboardUserInfo.endFrame];
            
            self.toolbarView.layer.transform = CATransform3DMakeTranslation(0, - distanceFromBottom, 0);
//            self.emotionInputManager.emotionView.layer.transform = CATransform3DMakeTranslation(0, - distanceFromBottom, 0);
            
        } completion:NULL];
    } else {
        // 相对于表情面板
        [UIView animateWithDuration:0.25 delay:0 options:QMUIViewAnimationOptionsCurveOut animations:^{
//            self.toolbarView.layer.transform = CATransform3DMakeTranslation(0, - CGRectGetHeight(self.emotionInputManager.emotionView.bounds), 0);
        } completion:NULL];
    }
}

- (void)hideToolbarViewWithKeyboardUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    if (keyboardUserInfo) {
        [QMUIKeyboardManager animateWithAnimated:YES keyboardUserInfo:keyboardUserInfo animations:^{
            self.toolbarView.layer.transform = CATransform3DIdentity;
//            self.emotionInputManager.emotionView.layer.transform = CATransform3DIdentity;
        } completion:NULL];
    } else {
        [UIView animateWithDuration:0.25 delay:0 options:QMUIViewAnimationOptionsCurveOut animations:^{
            self.toolbarView.layer.transform = CATransform3DIdentity;
//            self.emotionInputManager.emotionView.layer.transform = CATransform3DIdentity;
        } completion:NULL];
    }
}


#pragma mark - Selectors

// TODO: bug显示表情面板的时候，会遮挡聊天记录
- (void)handleFaceButtonEvent:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    //
//    self.faceButton.selected = !self.faceButton.selected;
//    if (!self.faceButton.isSelected) {
//        [self.toolbarTextField becomeFirstResponder];
//    } else {
//        [self showEmotionView];
//    }
}

- (void)handlePlusButtonEvent:(id)sender {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    QMUIAlertAction *cancelAction = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:^(QMUIAlertAction *action) {
//        NSLog(@"%s", __PRETTY_FUNCTION__);
    }];
    QMUIAlertAction *pickAction = [QMUIAlertAction actionWithTitle:@"照片" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//        NSLog(@"%s", __PRETTY_FUNCTION__);
        [self sharePickPhotoButtonPressed:nil];
    }];
    QMUIAlertAction *cameraAction = [QMUIAlertAction actionWithTitle:@"拍照" style:QMUIAlertActionStyleDefault handler:^(QMUIAlertAction *action) {
//        NSLog(@"%s", __PRETTY_FUNCTION__);
        [self shareTakePhotoButtonPressed:nil];
    }];
    //
    QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"工具栏" message:@"" preferredStyle:QMUIAlertControllerStyleActionSheet];
    [alertController addAction:cancelAction];
    [alertController addAction:pickAction]; //
    [alertController addAction:cameraAction]; //
    [alertController showWithAnimated:YES];
}

- (void)handleSendButtonEvent:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSString *content = self.toolbarTextField.text;
    if ([content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
        [self sendMessage:content];
        [self.toolbarTextField setText:@""];
    }
}

- (void)showEmotionView {
    [UIView animateWithDuration:0.25 delay:0 options:QMUIViewAnimationOptionsCurveOut animations:^{
        self.toolbarView.layer.transform = CATransform3DMakeTranslation(0, - kEmotionViewHeight, 0);
//        self.emotionInputManager.emotionView.layer.transform = CATransform3DMakeTranslation(0, - CGRectGetHeight(self.emotionInputManager.emotionView.bounds), 0);
    } completion:NULL];
    [self.toolbarTextField resignFirstResponder];
}

#pragma mark - 下拉刷新

- (void)refreshControlSelector {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // TODO: 访客端根据工作组id获取其工作组内全部聊天记录
    [WXCoreApis getMessageWithWorkgroup:self.mThreadModel.workgroup_id withOffset:self.mGetMessageFromChannelOffset withStepLength:self.mGetMessageFromChannelStepLength resultSuccess:^(NSDictionary *dict) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, dict);
        self.mGetMessageFromChannelOffset += self.mGetMessageFromChannelStepLength;
        [self reloadTableData];
        [self.mRefreshControl endRefreshing];
    } resultFailed:^(NSError *error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
        [QMUITips showError:@"加载失败" inView:self.parentView hideAfterDelay:2.0f];
        [self.mRefreshControl endRefreshing];
    }];
     // TODO: 客服端根据访客id获取其全部聊天记录
    
    
}


#pragma mark - 通知


/**
 客服接入会话通知

 @param notification <#notification description#>
 */
- (void)notifyQueueAccept:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.titleView.subtitle = @"接入会话";
    self.titleView.needsLoadingView = NO;
    
}


/**
 客服关闭会话通知

 @param notification <#notification description#>
 */
- (void)notifyThreadClose:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.titleView.subtitle = @"客服关闭会话";
    self.mIsThreadClosed = YES;
}


/**
 收到新消息通知

 @param notification <#notification description#>
 */
- (void)notifyMessageAdd:(NSNotification *)notification {
    
//    KFDSMessageModel *messageModel = [notification object];
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, messageModel.content);
//    [self.mMessageArray addObject:messageModel];
//    //
//    NSArray *indexPathArray = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:[self.mMessageArray count]-1 inSection:0], nil];
//    [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
    
    // TODO: 优化处理
    [self reloadTableData];
}


/**
 暂未启用

 @param notification <#notification description#>
 */
- (void)notifyMessageDelete:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // TODO: 优化处理
    [self reloadTableData];
}


/**
 消息撤回通知

 @param notification <#notification description#>
 */
- (void)notifyMessageRetract:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // TODO: 优化处理
    [self reloadTableData];
}


/**
 发送消息状态通知

 @param notification <#notification description#>
 */
- (void)notifyMessageStatus:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // TODO: 优化处理
    [self reloadTableData];
}





@end














