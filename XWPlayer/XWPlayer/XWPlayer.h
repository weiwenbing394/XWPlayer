//
//  XWPlayer.h
//  XWPlayer
//
//  Created by 大家保 on 2016/12/14.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"
#import "TBPlayerLayerView.h"
@import MediaPlayer;
@import AVFoundation;

@interface XWPlayer : UIView

//播放器
@property (nonatomic, strong) AVPlayer *player;

//播放的视频信息载体
@property (nonatomic, strong) AVPlayerItem *currentItem;

//底部操作栏
@property (nonatomic, strong) UIView *bottomView;

//关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;

//播放视图
@property (nonatomic,retain)TBPlayerLayerView *playerView;

//播放url地址
@property (nonatomic, copy) NSString *videoURLStr;

//是否全屏幕
@property (nonatomic, assign) BOOL isFullscreen;

//全屏幕按钮
@property (nonatomic, strong) UIButton *fullScreenBtn;

//播放暂停按钮
@property (nonatomic, strong) UIButton *playOrPauseBtn;

//初始化方法
- (instancetype) initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr;

@end
