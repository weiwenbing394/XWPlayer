//
//  DetailViewController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/20.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "DetailViewController.h"
#import "XWPlayer.h"

@interface DetailViewController (){
    UIButton *playButton;
    UIImageView *playImageView;
}

@property (nonatomic,strong) XWPlayer *xwPlayer;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    self.navigationItem.title=self.titleStr;
    
    playImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenWidth*3/4.0)];
    playImageView.backgroundColor=[UIColor blackColor];
    playImageView.userInteractionEnabled=YES;
    playImageView.contentMode=UIViewContentModeScaleAspectFit;
    [playImageView sd_setImageWithURL:[NSURL URLWithString:self.imageStr]];
    [self.view addSubview:playImageView];
    
    playButton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 64, 64)];
    [playButton setImage:[UIImage imageNamed:@"video_play_btn_bg.png"] forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(rePlay:) forControlEvents:UIControlEventTouchUpInside];
    playButton.center=CGPointMake(playImageView.frame.size.width/2.0, playImageView.frame.size.height/2.0);
    [playImageView addSubview:playButton];
    
    self.xwPlayer=[[XWPlayer alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*3/4.0) videoURLStr:self.urlStr];
    [playImageView addSubview:self.xwPlayer];
    
    //注册播放完成通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(videoDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //注册全屏播放通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fullScreenBtnClick:) name:@"fullScreenBtnClickNotice" object:nil];
}

//注册播放完成通知
- (void)videoDidFinished:(UIButton *)sender{
    [self.view sendSubviewToBack:self.xwPlayer];
    [self releaseXWPlayer];
}

//注册全屏播放通知
- (void)fullScreenBtnClick:(NSNotification *)notice{
    UIButton *fullScreenBtn=(UIButton *)[notice object];
    if (fullScreenBtn.isSelected) {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        [self toNormal];
    }
}


//恢复普通状态
- (void)toNormal{
    [_xwPlayer removeFromSuperview];
    [UIView animateWithDuration:0.25 animations:^{
        _xwPlayer.transform=CGAffineTransformIdentity;
        _xwPlayer.frame=playImageView.bounds;
        [playImageView addSubview:_xwPlayer];
        [playImageView bringSubviewToFront:_xwPlayer];
        [_xwPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_xwPlayer).with.offset(0);
            make.right.equalTo(_xwPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(_xwPlayer).with.offset(0);
        }];
        [_xwPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_xwPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(_xwPlayer).with.offset(5);
            
        }];
    } completion:^(BOOL finished) {
        _xwPlayer.isFullscreen=NO;
        _xwPlayer.fullScreenBtn.selected=NO;
    }];

}


- (void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    [_xwPlayer removeFromSuperview];
    _xwPlayer.transform=CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        _xwPlayer.transform=CGAffineTransformMakeRotation(-M_PI_2);
    }else if (interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        _xwPlayer.transform=CGAffineTransformMakeRotation(M_PI_2);
    }
    _xwPlayer.frame=CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [_xwPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(self.view.frame.size.width-40);
        make.width.mas_equalTo(self.view.frame.size.height);
    }];
    [_xwPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_xwPlayer).with.offset((-self.view.frame.size.height/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(_xwPlayer).with.offset(5);
        
    }];
    
    [[UIApplication sharedApplication].keyWindow addSubview:_xwPlayer];
    _xwPlayer.isFullscreen=YES;
    _xwPlayer.fullScreenBtn.selected=YES;
    [_xwPlayer bringSubviewToFront:_xwPlayer.bottomView];
    [_xwPlayer bringSubviewToFront:_xwPlayer.closeBtn];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSLog(@"监听播放器");
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onDeviceOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

//屏幕旋转通知
- (void)onDeviceOrientationChange:(NSNotification *)noti{
    if (_xwPlayer==nil||_xwPlayer.superview==nil) {
        return;
    };
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            if (_xwPlayer.isFullscreen) {
                [self toNormal];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            if (_xwPlayer.fullScreenBtn.selected == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            if (_xwPlayer.fullScreenBtn.selected == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        default:
            break;
    }
}


//重新播放
- (void)rePlay:(UIButton *)btn{
    [self.view sendSubviewToBack:playButton];
    self.xwPlayer=[[XWPlayer alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*3/4.0) videoURLStr:self.urlStr];
    self.xwPlayer.closeBtn.hidden=YES;
    [playImageView addSubview:self.xwPlayer];
}


- (void)viewDidDisappear:(BOOL)animated{
    NSLog(@"关闭播放器");
    [super viewDidDisappear:animated];
    [self releaseXWPlayer];
}

- (void)releaseXWPlayer{
    [self.xwPlayer setVideoURLStr:@""];
    [self.xwPlayer.player pause];
    [self.xwPlayer.player.currentItem cancelPendingSeeks];
    [self.xwPlayer.player.currentItem.asset cancelLoading];
    [self.xwPlayer removeFromSuperview];
    [self.xwPlayer.playerView removeFromSuperview];
    self.xwPlayer=nil;
    self.xwPlayer.player=nil;
    self.xwPlayer.playerView=nil;
    self.xwPlayer.currentItem=nil;
    self.xwPlayer.playOrPauseBtn=nil;
    self.xwPlayer.bottomView=nil;
}

- (void)dealloc{
    [self releaseXWPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
