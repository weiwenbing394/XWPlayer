//
//  PlayerViewController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/19.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "PlayerViewController.h"
#import "DMHeartFlyView.h"
#import <Accelerate/Accelerate.h>
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "BarrageWalkImageTextSprite.h"
#define XJScreenH [UIScreen mainScreen].bounds.size.height
#define XJScreenW [UIScreen mainScreen].bounds.size.width


@interface PlayerViewController ()

@property (nonatomic, strong) IJKFFMoviePlayerController * player;

@property (nonatomic, strong) NSMutableArray *fireworksArray;

@property (nonatomic, strong) CALayer *fireworksL;
//弹幕
@property (nonatomic, strong) BarrageRenderer *renderer;

@property (nonatomic, assign) NSInteger index;


@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addLoadingView];
    [self addPlayerView];
    [self addButton];
    [self.view addSubview:self.renderer.view];
}

//添加背景视图
- (void)addLoadingView{
    UIImageView *loadImageView=[[UIImageView alloc]initWithFrame:self.view.bounds];
    loadImageView.tag=1000;
    [loadImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://img.meelive.cn/%@", _imageUrl]] placeholderImage:[UIImage imageNamed:@"liveRoom"]];
    UIVisualEffect *effect=[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView=[[UIVisualEffectView alloc]initWithEffect:effect];
    effectView.frame=loadImageView.bounds;
    [loadImageView addSubview:effectView];
    [self.view addSubview:loadImageView];
}

//添加播放界面
- (void)addPlayerView{
    self.player=[[IJKFFMoviePlayerController alloc]initWithContentURL:[NSURL URLWithString:self.liveUrl] withOptions:nil];
    self.player.view.frame=self.view.bounds;
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.player setScalingMode:IJKMPMovieScalingModeAspectFill];
    [self.view insertSubview:self.player.view atIndex:1];
    [self.player prepareToPlay];
    [self.player play];
    [self installMovieNotificationObservers];
}

//按钮
- (void)addButton{
    // 返回
    UIButton * backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, 64 / 2 - 8, 33, 33);
    [backBtn setImage:[UIImage imageNamed:@"返回"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    backBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    backBtn.layer.shadowOffset = CGSizeMake(0, 0);
    backBtn.layer.shadowOpacity = 0.5;
    backBtn.layer.shadowRadius = 1;
    [self.view addSubview:backBtn];
    
    // 暂停
    UIButton * playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake(XJScreenW - 33 - 10, 64 / 2 - 8, 33, 33);
    [playBtn setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateNormal)];
    [playBtn setImage:[UIImage imageNamed:@"开始"] forState:(UIControlStateSelected)];
    [playBtn addTarget:self action:@selector(play_btn:) forControlEvents:(UIControlEventTouchUpInside)];
    playBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    playBtn.layer.shadowOffset = CGSizeMake(0, 0);
    playBtn.layer.shadowOpacity = 0.5;
    playBtn.layer.shadowRadius = 1;
    [self.view addSubview:playBtn];
    
    CGFloat btnHW = 36;
    CGFloat margin = 20;
    CGFloat btnY = XJScreenH - 36 - 10;
    CGFloat linesW = (XJScreenW - (btnHW) - (margin * 2))/3;
    NSArray *images = @[@"normalMsg",@"privateMsg",@"share_live",@"gift_live"];
    for (int i = 0; i < 4; ++i) {
        UIButton * heartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        heartBtn.frame = CGRectMake(margin + (linesW * i),btnY , btnHW, btnHW);
        [heartBtn setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        [heartBtn addTarget:self action:@selector(showTheLove:) forControlEvents:UIControlEventTouchUpInside];
        heartBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        heartBtn.layer.shadowOffset = CGSizeMake(0, 0);
        heartBtn.layer.shadowOpacity = 0.5;
        heartBtn.layer.shadowRadius = 1;
        heartBtn.tag=100+i;
        heartBtn.adjustsImageWhenHighlighted = NO;
        [self.view addSubview:heartBtn];
    }
    __weak typeof(self) weakSelf=self;
    //爱心
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf rotation];
    }];
    //弹幕
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf autoSendBarrage];
        [weakSelf.renderer start];
    }];
    //保时捷礼物
    [NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf showMyPorsche918];
    }];
}

//返回
- (void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

//播放／暂停
- (void)play_btn:(UIButton *)sender{
    sender.selected=!sender.selected;
    if ([self.player isPlaying]) {
        [self.player pause];
    }else{
        [self.player play];
    }
}

//献爱心
- (void)showTheLove:(UIButton *)sender{
    NSInteger tag=sender.tag-100;
    switch (tag) {
        case 0:
            [self showMyPorsche918];
            break;
        case 1:
        {
            [self autoSendBarrage];
            //弹幕
            [self.renderer start];
        }
            break;
        case 2:
            
            break;
        case 3:
            [self rotation];
            break;
            
        default:
            break;
    }
}

//爱心动画
- (void)rotation{
    CGFloat _heartSize = 35;
    DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    heart.center = CGPointMake(XJScreenW-_heartSize, XJScreenH- _heartSize/2.0 - 10);
    [self.view addSubview:heart];
    [heart animateInView:self.view];
}

//送礼物
- (void)showMyPorsche918 {
    CGFloat durTime = 3.0;
    UIImageView *porsche918 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"porsche"]];
    //设置汽车初始位置
    porsche918.frame = CGRectMake(0, 0, 0, 0);
    [self.view addSubview:porsche918];
   //给汽车添加动画
    [UIView animateWithDuration:durTime animations:^{
       porsche918.frame = CGRectMake(XJScreenW * 0.5 - 120, XJScreenH * 0.5 - 60 * 0.5, 240, 120);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            porsche918.alpha = 0;
        } completion:^(BOOL finished) {
            [porsche918 removeFromSuperview];
        }];
    });
    //烟花
    CALayer *fireworksL = [CALayer layer];
    fireworksL.frame = CGRectMake((XJScreenW - 250) * 0.5, 100, 250, 50);
    fireworksL.contents = (id)[UIImage imageNamed:@"gift_fireworks_0"].CGImage;
    [self.view.layer addSublayer:fireworksL];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [fireworksL removeFromSuperlayer];
    });
    self.fireworksL=fireworksL;
    NSMutableArray *tempArray = [NSMutableArray array];
    for (int i = 1; i < 3; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"gift_fireworks_%d",i]];
        [tempArray addObject:image];
    }
    self.fireworksArray=tempArray;
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update) userInfo:nil repeats:YES];
}

static int _fishIndex = 0;
- (void)update {
    _fishIndex++;
    if (_fishIndex > 1) {
        _fishIndex = 0;
    }
    UIImage *image = self.fireworksArray[_fishIndex];
    _fireworksL.contents = (id)image.CGImage;
}




//添加通知
- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}

#pragma Selector func

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    
    UIImageView *loadImageView=[self.view viewWithTag:1000];
    loadImageView.hidden = YES;
    
    switch (_player.playbackState) {
            
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

//移除通知
- (void)removeMovieNotificationObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    
}



- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.player pause];
    [self.player stop];
    [self.player shutdown];
    [self removeMovieNotificationObservers];
    [self.renderer stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


#pragma mark 懒加载弹幕
- (BarrageRenderer *)renderer{
    if (!_renderer) {
        _renderer=[[BarrageRenderer alloc]init];
        _renderer.canvasMargin=UIEdgeInsetsMake(20, 0,20, 0);
        //_renderer.view.userInteractionEnabled = YES;
    }
    return _renderer;
}

- (void)autoSendBarrage
{
    NSInteger spriteNumber = [_renderer spritesNumberWithName:nil];
     // 用来演示如何限制屏幕上的弹幕量
    if (spriteNumber <= 500) {
        //纯文本过场动画（从右到左）
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L side:BarrageWalkSideLeft]];
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L side:BarrageWalkSideDefault]];
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L side:BarrageWalkSideRight]];
        //图片过场动画（从右到左）
        [_renderer receive:[self walkImageSpriteDescriptorWithDirection:BarrageWalkDirectionR2L]];
        [_renderer receive:[self walkImageSpriteDescriptorWithDirection:BarrageWalkDirectionR2L]];
        
        //纯文本悬浮动画（从下到上）
        [_renderer receive:[self floatTextSpriteDescriptorWithDirection:BarrageFloatDirectionB2T side:BarrageFloatSideCenter]];
        [_renderer receive:[self floatTextSpriteDescriptorWithDirection:BarrageFloatDirectionB2T side:BarrageFloatSideCenter]];
        //图片悬浮动画（从下到上）
        [_renderer receive:[self floatTextSpriteDescriptorWithDirection:BarrageFloatDirectionB2T side:BarrageFloatSideCenter]];
        [_renderer receive:[self floatImageSpriteDescriptorWithDirection:BarrageFloatDirectionB2T]];
        
        [_renderer receive:[self walkImageTextSpriteDescriptorBWithDirection:BarrageWalkDirectionR2L]];
    }
}


#pragma mark - 弹幕描述符生产方法

/// 生成精灵描述 - 过场文字弹幕
- (BarrageDescriptor *)walkTextSpriteDescriptorWithDirection:(BarrageWalkDirection)direction
{
    return [self walkTextSpriteDescriptorWithDirection:direction side:BarrageWalkSideDefault];
}

/// 生成精灵描述 - 过场文字弹幕
- (BarrageDescriptor *)walkTextSpriteDescriptorWithDirection:(BarrageWalkDirection)direction side:(BarrageWalkSide)side
{
    
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"text"] = [NSString stringWithFormat:@"过场文字弹幕:%ld",(long)self.index++];
    descriptor.params[@"textColor"] = [UIColor blueColor];
    //descriptor.params[@"backgroundColor"] = [UIColor blackColor];
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"side"] = @(side);
    descriptor.params[@"clickAction"] = ^{
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"弹幕被点击" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alertView show];
    };
    return descriptor;
}

// 生成精灵描述 - 浮动文字弹幕
- (BarrageDescriptor *)floatTextSpriteDescriptorWithDirection:(NSInteger)direction
{
    return [self floatTextSpriteDescriptorWithDirection:direction side:BarrageFloatSideCenter];
}

/// 生成精灵描述 - 浮动文字弹幕
- (BarrageDescriptor *)floatTextSpriteDescriptorWithDirection:(NSInteger)direction side:(BarrageFloatSide)side
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageFloatTextSprite class]);
    descriptor.params[@"text"] = [NSString stringWithFormat:@"悬浮文字弹幕:%ld",(long)_index++];
    descriptor.params[@"textColor"] = [UIColor purpleColor];
    descriptor.params[@"duration"] = @(3);
    descriptor.params[@"fadeInTime"] = @(1);
    descriptor.params[@"fadeOutTime"] = @(1);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"side"] = @(side);
    return descriptor;
}

/// 生成精灵描述 - 过场图片弹幕
- (BarrageDescriptor *)walkImageSpriteDescriptorWithDirection:(NSInteger)direction
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkImageSprite class]);
    descriptor.params[@"image"] = [[UIImage imageNamed:@"account_highlight"]barrageImageScaleToSize:CGSizeMake(20.0f, 20.0f)];
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"trackNumber"] = @5; // 轨道数量
    return descriptor;
}

// 生成精灵描述 - 浮动图片弹幕
- (BarrageDescriptor *)floatImageSpriteDescriptorWithDirection:(NSInteger)direction
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageFloatImageSprite class]);
    descriptor.params[@"image"] = [[UIImage imageNamed:@"account_highlight"]barrageImageScaleToSize:CGSizeMake(40.0f, 15.0f)];
    descriptor.params[@"duration"] = @(3);
    descriptor.params[@"direction"] = @(direction);
    return descriptor;
}

/// 图文混排精灵弹幕 - 过场图文弹幕A
- (BarrageDescriptor *)walkImageTextSpriteDescriptorAWithDirection:(NSInteger)direction
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkImageTextSprite class]);
    descriptor.params[@"text"] = [NSString stringWithFormat:@"AA-图文混排/::B过场弹幕:%ld",(long)_index++];
    descriptor.params[@"textColor"] = [UIColor greenColor];
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    return descriptor;
}

/// 图文混排精灵弹幕 - 过场图文弹幕B
- (BarrageDescriptor *)walkImageTextSpriteDescriptorBWithDirection:(NSInteger)direction
{
    NSTextAttachment * attachment = [[NSTextAttachment alloc]init];
    attachment.image = [[UIImage imageNamed:@"account_highlight"]barrageImageScaleToSize:CGSizeMake(25.0f, 25.0f)];
    NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc]initWithString:
                                              [NSString stringWithFormat:@"BB-图文混排过场弹幕:%ld",(long)_index++]];
    [attributed insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachment] atIndex:7];
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"textColor"] = [UIColor greenColor];
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"attributedText"] = attributed;
    return descriptor;
}


@end
