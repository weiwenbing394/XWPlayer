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
@class XWPlayer;

@protocol XWPlayerDelegate <NSObject>

@optional

//点击关闭按钮代理方法
-(void)xwplayer:(XWPlayer *)xwplayer clickedCloseButton:(UIButton *)closeBtn;

//点击全屏按钮代理方法
-(void)xwplayer:(XWPlayer *)xwplayer clickedFullScreenButton:(UIButton *)fullScreenBtn;

//播放完毕的代理方法
-(void)xwplayerFinishedPlay:(XWPlayer *)xwplayer;

@end

@interface XWPlayer : UIView

//播放器
@property (nonatomic, strong) AVPlayer *player;

//播放的视频信息载体
@property (nonatomic, strong) AVPlayerItem *currentItem;

//播放视图
@property (nonatomic,retain)TBPlayerLayerView *playerView;

//底部操作栏
@property (nonatomic, strong) UIView *bottomView;

//关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;

//播放url地址
@property (nonatomic, copy) NSString *videoURLStr;

//跳到time处播放
@property (nonatomic, assign) double  seekTime;

//是否全屏幕
@property (nonatomic, assign) BOOL isFullscreen;

//全屏幕按钮
@property (nonatomic, strong) UIButton *fullScreenBtn;

//播放暂停按钮
@property (nonatomic, strong) UIButton *playOrPauseBtn;

//加载失败label
@property (nonatomic, copy)UILabel *faildLabel;

//代理方法
@property (nonatomic,assign) id<XWPlayerDelegate> xwDelegate;

//初始化播放器
-(void )resetXWPlayer;

@end
