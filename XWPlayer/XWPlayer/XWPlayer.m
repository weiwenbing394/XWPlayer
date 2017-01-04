//
//  XWPlayer.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/14.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "XWPlayer.h"

#define WMVideoSrcName(file) [@"XWPlayer.bundle" stringByAppendingPathComponent:file]

#define WMVideoFrameworkSrcName(file) [@"Frameworks/XWPlayer.framework/XWPlayer.bundle" stringByAppendingPathComponent:file]

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;

@interface XWPlayer ()<UIGestureRecognizerDelegate>
//播放进度
@property (nonatomic, strong) UISlider *progressSlider;
//缓冲进度条
@property (nonatomic, strong) UIProgressView *loadedProgress;
//视频进度条的单击事件
@property (nonatomic, strong) UITapGestureRecognizer *tap;
//音量大小进度条
@property (nonatomic, strong) UISlider *volumeSlider;
//视频播放时长与总时长
@property (nonatomic, strong) UILabel *timeLabel;
//音量的增加减小
@property (nonatomic,assign)CGPoint firstPoint;
//音量的增加减小
@property (nonatomic,assign)CGPoint secondPoint;
//自动隐藏操作栏定时器
@property (nonatomic,retain)NSTimer *autoDismissTimer;
//是否在播放
@property (nonatomic,assign)BOOL isPlaying;
//是否在快进／后退
@property (nonatomic,assign)BOOL slider;
//时间转化器
@property (nonatomic, retain)NSDateFormatter *dateFormatter;
//加载图标
@property (nonatomic, strong)UIActivityIndicatorView *indicatorView;


@end

@implementation XWPlayer{
    //音量控制器中间件
    UISlider *systemSlider;
    //页面单击
    UITapGestureRecognizer* singleTap;
    //页面双击
    UITapGestureRecognizer* doubleTap;
}

/**
 *  alloc init的初始化方法
 */
- (instancetype)init{
    self = [super init];
    if (self){
        [self initXWPlayer];
    }
    return self;
}
/**
 *  storyboard、xib的初始化方法
 */
- (void)awakeFromNib{
    [super awakeFromNib];
    [self initXWPlayer];
}
/**
 *  initWithFrame的初始化方法
 */
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initXWPlayer];
    }
    return self;
}

//初始化播放器
- (void)initXWPlayer{
    
    self.backgroundColor=[UIColor blackColor];
    
    //底部操作栏设置
    self.bottomView=[[UIView alloc]init];
    
    self.bottomView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    
    [self addSubview:self.bottomView];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(40);
    }];
    
    
    //暂停播放按钮
    self.playOrPauseBtn=[[UIButton alloc]init];
    
    self.playOrPauseBtn.showsTouchWhenHighlighted=YES;
    
    [self.playOrPauseBtn addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.playOrPauseBtn setImage:[UIImage imageNamed:WMVideoSrcName(@"pause")] ? : [UIImage imageNamed:WMVideoFrameworkSrcName(@"pause")] forState:UIControlStateNormal];
    
    [self.playOrPauseBtn setImage:[UIImage imageNamed:WMVideoSrcName(@"play")] ?: [UIImage imageNamed:WMVideoFrameworkSrcName(@"play")] forState:UIControlStateSelected];
    
    [self.bottomView addSubview:self.playOrPauseBtn];
    
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.top.mas_equalTo(0);
        make.width.mas_equalTo(40);
    }];
    
    
    //播放进度条
    self.progressSlider=[[UISlider alloc]init];
    
    self.progressSlider.minimumValue=0;
    
    self.progressSlider.value=0;
    
    [self.progressSlider setThumbImage:[UIImage imageNamed:WMVideoSrcName(@"dot")] ? : [UIImage imageNamed:WMVideoFrameworkSrcName(@"dot")] forState:UIControlStateNormal];
    
    self.progressSlider.minimumTrackTintColor=[UIColor redColor];
    
    self.progressSlider.maximumTrackTintColor=[UIColor clearColor];
    
    //拖动快进
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventValueChanged];
    
    //拖动完成
    [self.progressSlider addTarget:self action:@selector(updateProgressEnd:) forControlEvents:UIControlEventTouchUpInside];
    
    //给进度条添加单击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapGesture:)];
    
    self.tap.delegate = self;
    
    [self.progressSlider addGestureRecognizer:self.tap];
    
    [self.bottomView addSubview:self.progressSlider];
    
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.bottomView);
        make.left.mas_equalTo(45);
        make.right.mas_equalTo(-45);
    }];
    
    //缓冲进度条
    self.loadedProgress=[[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    
    self.loadedProgress.progressTintColor=[UIColor lightGrayColor];
    
    self.loadedProgress.trackTintColor=[UIColor darkGrayColor];
    
    [self.loadedProgress setProgress:0];
    
    [self.bottomView addSubview:self.loadedProgress];
    
    [self.loadedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.progressSlider);
        make.center.equalTo(self.progressSlider).with.offset(0.7);
    }];
    
    [self.bottomView sendSubviewToBack:self.loadedProgress];
    
    //全屏按钮
    self.fullScreenBtn=[[UIButton alloc]init];
    
    self.fullScreenBtn.showsTouchWhenHighlighted=YES;
    
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.fullScreenBtn setImage:[UIImage imageNamed:WMVideoSrcName(@"fullscreen")] ?: [UIImage imageNamed:WMVideoFrameworkSrcName(@"fullscreen")] forState:UIControlStateNormal];
    
    [self.fullScreenBtn setImage:[UIImage imageNamed:WMVideoSrcName(@"nonfullscreen")] ?: [UIImage imageNamed:WMVideoFrameworkSrcName(@"nonfullscreen")] forState:UIControlStateSelected];
    
    [self.bottomView addSubview:self.fullScreenBtn];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(45);
    }];
    
    //视频播放时长／总时长
    self.timeLabel=[[UILabel alloc]init];
    
    self.timeLabel.textAlignment=NSTextAlignmentRight;
    
    self.timeLabel.textColor=[UIColor whiteColor];
    
    self.timeLabel.backgroundColor=[UIColor clearColor];
    
    self.timeLabel.font=[UIFont systemFontOfSize:11];
    
    [self.bottomView addSubview:self.timeLabel];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(45);
        make.right.mas_equalTo(-45);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    
    [self bringSubviewToFront:self.bottomView];
    
    //关闭按钮
    self.closeBtn=[[UIButton alloc]init];
    
    self.closeBtn.showsTouchWhenHighlighted=YES;
    
    self.closeBtn.hidden=YES;
    
    [self.closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.closeBtn setImage:[UIImage imageNamed:WMVideoSrcName(@"close")] ?: [UIImage imageNamed:WMVideoFrameworkSrcName(@"close")] forState:UIControlStateNormal];
    
    self.closeBtn.layer.cornerRadius = 30/2;
    
    self.closeBtn.clipsToBounds=YES;
    
    [self addSubview:self.closeBtn];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(5);
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(5);
        make.width.mas_equalTo(30);
    }];
    
    //缓冲label
    self.indicatorView=[[UIActivityIndicatorView  alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    self.indicatorView.center=self.center;
    
    self.indicatorView.hidesWhenStopped=YES;
    
    self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    [self addSubview:self.indicatorView];
    
    [self bringSubviewToFront:self.indicatorView];
    
    //声音视图
    MPVolumeView *volumeView=[[MPVolumeView alloc]init];
    
    [self addSubview:volumeView];
    
    [volumeView sizeToFit];
    
    systemSlider=[[UISlider alloc]init];
    
    systemSlider.backgroundColor=[UIColor clearColor];
    
    for (UIControl *control in volumeView.subviews) {
        
        if ([control.superclass isSubclassOfClass:[UISlider class]]) {
            
            systemSlider=(UISlider *)control;
        }
    }
    
    systemSlider.hidden=YES;
    
    [self addSubview:systemSlider];
    
    self.volumeSlider=[[UISlider alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    self.volumeSlider.tag=1000;
    
    self.volumeSlider.hidden=YES;
    
    self.volumeSlider.minimumValue=systemSlider.minimumValue;
    
    self.volumeSlider.maximumValue=systemSlider.maximumValue;
    
    self.volumeSlider.value=systemSlider.value;
    
    [self.volumeSlider addTarget:self action:@selector(updateSystemVolumeValue:) forControlEvents:UIControlEventValueChanged];
    
    [self addSubview:self.volumeSlider];
    
    //页面单击
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    
    singleTap.numberOfTapsRequired = 1;
    
    [self addGestureRecognizer:singleTap];

    //回到前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomActive:)name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //退回后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backToBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma  mark 设置播放源
- (void)setVideoURLStr:(NSString *)videoURLStr{
    //清除ui上面的缓存进度条啥的
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearUIValues];
        [self.indicatorView startAnimating];
    });
    //移除原先的avplayerItem
    if (self.currentItem) {
        [self removeCurrentItemObser];
    }
    //实例新的avplayerItem
    self.currentItem=[self getPlayerItemWithURLString:videoURLStr];
    //新的avplayerItem添加监控
    [self addCurrentItemObser];
    //更改avplayer
    self.player=[AVPlayer playerWithPlayerItem:self.currentItem];
    //更换视频播放的视图
    [self.playerView setPlayerLayer:self.player];
    if (![self.subviews containsObject:self.playerView]) {
        [self insertSubview:self.playerView atIndex:0];
    }
    //开始播放
    [self.player play];
    self.isPlaying=YES;
    self.playOrPauseBtn.selected=NO;
    //停止底部操作栏5秒隐藏的定时器
    [self invalidTimer];
    //显示底部操作栏
    if (self.bottomView.alpha==0) {
        self.bottomView.alpha=1;
        self.closeBtn.alpha=1;
    }
}


//根据url返回avplayerItem
- (AVPlayerItem *)getPlayerItemWithURLString:(NSString *)urlString{
    AVPlayerItem *playerItem;
    if ([urlString containsString:@"http"]) {
        //网络url
        playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }else{
        //本地文件url
        AVURLAsset *asst=[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:urlString] options:nil];
        playerItem=[AVPlayerItem playerItemWithAsset:asst];
    }
    return playerItem;
}



//清除ui上面的缓存，进度条啥的
- (void)clearUIValues{
    [self.progressSlider setValue:0 animated:NO];
    [self.loadedProgress setProgress:0];
    self.timeLabel.text=@"00:00/00:00";
    self.seekTime=0;
}


//移除当前的item的相关监控
- (void)removeCurrentItemObser{
    [self.player pause];
    [self.currentItem cancelPendingSeeks];
    [self.currentItem.asset cancelLoading];
    [self.currentItem removeObserver:self forKeyPath:@"status"];
    [self.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    //移除视频播放结束通知
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
}

//添加当前的item的相关监控
- (void)addCurrentItemObser{
    [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    [self.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    [self.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    [self.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
    
}




#pragma  maik 监听视频加载状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if (context==PlayViewStatusObservationContext) {
        
        if (([keyPath isEqualToString:@"status"])) {
            
            AVPlayerItemStatus status=[[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            switch (status) {
                    //播放准备完成
                case AVPlayerItemStatusReadyToPlay:{
                    
                    //页面双击
                    doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
                    
                    doubleTap.numberOfTapsRequired = 2;
                    
                    //如果双击成立，则取消单击手势（双击的时候不回走单击事件）
                    [singleTap requireGestureRecognizerToFail:doubleTap];
                    
                    [self addGestureRecognizer:doubleTap];
                    
                    //获取总时长
                    if (CMTimeGetSeconds(self.player.currentItem.duration)) {
                        
                        double _x = CMTimeGetSeconds(self.player.currentItem.duration);
                        
                        if (!isnan(_x)) {
                            self.progressSlider.maximumValue=CMTimeGetSeconds(self.player.currentItem.duration);
                            
                        }
                    }
                    
                    //刷新进度条，获取总时长等操作
                    [self initTimer];
                    
                    [self.indicatorView stopAnimating];
                    
                    // 跳到xx秒播放视频
                    if (self.seekTime) {
                        [self seekToTimeToPlay:self.seekTime];
                    }
                    self.faildLabel.hidden = YES;
                    
                    //初始化自动隐藏操作栏定时器  播放完成定时器
                    [self initDissMissTimer];
                    
                }
                    break;
                case AVPlayerItemStatusFailed:
                
                {
                    NSError *error = [self.player.currentItem error];
                    
                    if (error) {
                        
                        self.faildLabel.hidden = NO;
                       
                        [self.indicatorView stopAnimating];
                    }

                }
                    break;
                case AVPlayerItemStatusUnknown:
                    
                    [self.indicatorView startAnimating];
                    
                    self.faildLabel.hidden =YES;
                    
                    break;
                    
                default:
                    break;
            }
            
            
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
            
            if ([self duration]) {
                
                //缓存进度条
                [self.loadedProgress setProgress:[self loadRange]/[self duration] animated:YES];
                
            }
            
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
            
            [self.indicatorView startAnimating];
            
            // 当缓冲是空的时候
            if (self.currentItem.playbackBufferEmpty) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [self PlayOrPause:self.playOrPauseBtn];
                    
                    [self.indicatorView stopAnimating];
                });
            }
            
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            [self.indicatorView stopAnimating];
            
        }
        
    }
}



//自动隐藏播放器操作栏
-(void)autoDismissBottomView:(NSTimer *)timer{
    //正在播放
    if (self.player.rate==1&&self.slider==NO&&self.bottomView.alpha==1) {
            [UIView animateWithDuration:0.25 animations:^{
                self.bottomView.alpha=0;
                self.closeBtn.alpha=0;
                [self invalidTimer];
            }];
    }
}

//获取当前播放的时长
- (double)currentTime{
    return CMTimeGetSeconds([self.player currentTime]);
}

//获取视频总时长
- (double)duration{
    AVPlayerItem *playerItem=[self.player currentItem];
    if (playerItem.status==AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }
    return 0.0f;
}

//获取缓存的总长度
- (CGFloat)loadRange{
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        NSArray *loadedTimeRanges=[playerItem loadedTimeRanges];
        CMTimeRange timeRange=[loadedTimeRanges.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return startSeconds+durationSeconds;
    }
    else{
        return 0.f;
    }
}


//播放或者暂停
- (void)PlayOrPause:(UIButton *)btn{
    btn.selected=!btn.selected;
    if (self.player.rate!=1) {
        if ([self currentTime]==[self duration]) {
            //设置开始播放为开始位置
            [self setCurrentTime:0];
        }
        //开始播放
        [self.player play];
        self.isPlaying=YES;
        [self initDissMissTimer];
    }else{
        //暂停播放
        [self.player pause];
        [self.indicatorView stopAnimating];
        self.isPlaying=NO;
        [self invalidTimer];
    }
}

//更新播放声音
- (void)updateSystemVolumeValue:(UISlider *)slider{
    systemSlider.value = slider.value;
}


//设置视频从哪个时间点播放
- (void)setCurrentTime:(double)time{
    [self.player seekToTime:CMTimeMakeWithSeconds(time, 1)];
}


//跳转到多少秒播放
- (void)seekToTimeToPlay:(double)time{
    if (self.player&&self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (time>[self duration]) {
            time = [self duration];
        }
        if (time<=0) {
            time=0.0;
        }
        [self.player seekToTime:CMTimeMakeWithSeconds(time, _currentItem.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        }];
    }
}


//更新播放进度
- (void)updateProgress:(UISlider *)slider{
    self.slider=YES;
    self.bottomView.alpha=1;
    self.closeBtn.alpha=1;
    [self setCurrentTime:slider.value];
    [self invalidTimer];
}

//拖动结束
- (void)updateProgressEnd:(UISlider *)slider{
    self.slider=NO;
    [self setCurrentTime:slider.value];
    [self initDissMissTimer];
}

//视频进度条的点击事件
- (void)actionTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchLocation = [sender locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (touchLocation.x/self.progressSlider.frame.size.width);
    [self.progressSlider setValue:value animated:YES];
    [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.currentItem.currentTime.timescale)];
    if (self.player.rate != 1.f) {
        if ([self currentTime] == [self duration])
            [self setCurrentTime:0.f];
    }
    [self invalidTimer];
    self.slider=NO;
    [self initDissMissTimer];
}


//全屏播放
- (void)fullScreenAction:(UIButton *)sender{
    sender.selected=!sender.selected;
    [[UIApplication sharedApplication] setStatusBarHidden:sender.selected];
    if (self.xwDelegate&&[self.xwDelegate respondsToSelector:@selector(xwplayer:clickedFullScreenButton:)]) {
        [self.xwDelegate xwplayer:self clickedFullScreenButton:sender];
    }
}

//关闭视频播放
- (void)colseTheVideo:(UIButton *)sender{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.isPlaying=NO;
    [self.player pause];
    [self invalidTimer];
    [self.currentItem cancelPendingSeeks];
    [self.currentItem.asset cancelLoading];
    if (self.xwDelegate&&[self.xwDelegate respondsToSelector:@selector(xwplayer:clickedCloseButton:)]) {
        [self.xwDelegate xwplayer:self clickedCloseButton:sender];
    }
}

//视频播放结束
- (void)moviePlayDidEnd:(NSNotification *)notification{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    __weak typeof(self) weakSelf = self;
    [weakSelf.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        self.isPlaying=NO;
        [weakSelf clearUIValues];
        [weakSelf.player pause];
        [weakSelf.currentItem cancelPendingSeeks];
        [weakSelf.currentItem.asset cancelLoading];
        [weakSelf invalidTimer];
        weakSelf.playOrPauseBtn.selected=NO;
        if (weakSelf.xwDelegate&&[weakSelf.xwDelegate respondsToSelector:@selector(xwplayerFinishedPlay:)]) {
            [weakSelf.xwDelegate xwplayerFinishedPlay:self];
        };
    }];
    
}

//回到前台通知
- (void)becomActive:(NSNotification *)noti{
    if (self.isPlaying==YES) {
        [self.player play];
        self.playOrPauseBtn.selected=NO;
    }
}

//后台
- (void)backToBackGround:(NSNotification *)noti{
    if (self.isPlaying==YES) {
        [self.player pause];
    }
}


//单击
- (void)handleSingleTap{
    [UIView animateWithDuration:0.25 animations:^{
        if (self.bottomView.alpha==1) {
            self.bottomView.alpha=0;
            self.closeBtn.alpha=0;
            [self invalidTimer];
        }else{
            self.bottomView.alpha=1;
            self.closeBtn.alpha=1;
            [self initDissMissTimer];
        }
    }];
}

#pragma mark 控制隐藏操作栏定时器
- (void)invalidTimer{
    if (self.autoDismissTimer!=nil) {
        [self.autoDismissTimer invalidate];
        self.autoDismissTimer=nil;
    }
}

- (void)initDissMissTimer{
    if (self.autoDismissTimer==nil&&self.player.rate==1&&self.bottomView.alpha==1) {
        self.autoDismissTimer=[NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    }
}


//双击
- (void)handleDoubleTap{
    [UIView animateWithDuration:0.25 animations:^{
        self.playOrPauseBtn.selected=!self.playOrPauseBtn.selected;
        if (self.player.rate!=1) {
            //未播放
            if ([self currentTime]==[self duration]) {
                [self setCurrentTime:0];
            }
            [self.player play];
            self.isPlaying=YES;
        }else{
            //正在播放
            [self.player pause];
            self.isPlaying=NO;
            [self.indicatorView stopAnimating];
        }
    }];
}




#pragma  maik 定时器
- (void)initTimer{
    
    double interval = .1f;
    
    CMTime playerDuration=[self getPlayerItemDuration];
    
    if (CMTIME_IS_INVALID(playerDuration)) {
        
        return;
        
    }
    
    double duration=CMTimeGetSeconds(playerDuration);
    
    if (isfinite(duration)) {
        
        CGFloat width=CGRectGetWidth(self.progressSlider.bounds);
        
        interval=duration/width/2.0;
    }
    
    __weak typeof(self) weakSelf=self;
    
    //监听播放进度
    [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        [weakSelf syncScrubber];
        
    }];
    
    
}

//获取视频时间的结构体
- (CMTime)getPlayerItemDuration{
    
    AVPlayerItem *playerItem=[self.player currentItem];
    
    if (playerItem.status==AVPlayerItemStatusReadyToPlay) {
        
        return [playerItem duration];
    }
    
    return kCMTimeInvalid;
}

//同步播放进度条进度
- (void)syncScrubber{
    
    CMTime playDuration=[self getPlayerItemDuration];
    
    if (CMTIME_IS_INVALID(playDuration)) {
        
        self.progressSlider.minimumValue=0.0;
        
        return;
    }
    
    double duration=CMTimeGetSeconds(playDuration);
    
    if (isfinite(duration)) {
        
        float minValue=[self.progressSlider minimumValue];
        
        float maxValue=[self.progressSlider maximumValue];
        
        double time=CMTimeGetSeconds([self.player currentTime]);
        
        self.timeLabel.text=[NSString stringWithFormat:@"%@/%@",[self convertTime:time],[self convertTime:duration]];
        
        [self.progressSlider setValue:time/duration*(maxValue-minValue)+minValue];
    }
}

//根据秒数获取时间字符串
- (NSString *)convertTime:(CGFloat)second{
    
    NSDate *d=[NSDate dateWithTimeIntervalSince1970:second];
    
    if (second/3600>=1) {
        
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
        
    }else{
        
        [[self dateFormatter] setDateFormat:@"mm:ss"];
        
    }
    
    NSString *newTime=[[self dateFormatter] stringFromDate:d];
    
    return newTime;
}

- (NSDateFormatter *)dateFormatter{
    
    if (!_dateFormatter) {
        
        _dateFormatter=[[NSDateFormatter alloc]init];
    }
    
    return _dateFormatter;
}

//调节音量大小
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *touch in event.allTouches) {
        
        self.firstPoint=[touch locationInView:self];
    }
    
    UISlider *volumeSlider=(UISlider *)[self viewWithTag:1000];
    
    volumeSlider.value=systemSlider.value;
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *touch in event.allTouches) {
        
        self.secondPoint=[touch locationInView:self];
        
    }
    
    systemSlider.value+=(self.firstPoint.y-self.secondPoint.y)/500.00;
    
    UISlider *volumeSlider=(UISlider *)[self viewWithTag:1000];
    
    volumeSlider.value=systemSlider.value;
    
    self.firstPoint=self.secondPoint;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    self.firstPoint=self.secondPoint=CGPointZero;
    
}

//重置播放器
-(void )resetXWPlayer{
    [self setVideoURLStr:@""];
    [self.player pause];
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self removeFromSuperview];
    [self.playerView removeFromSuperview];
    self.player=nil;
    self.playerView=nil;
    self.currentItem=nil;
    self.closeBtn=nil;
    self.bottomView=nil;
   
};

- (void)dealloc{

    self.seekTime=0;
    
    [self removeCurrentItemObser];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.autoDismissTimer invalidate];
    
    self.autoDismissTimer=nil;
    
    self.player=nil;
    
}

#pragma mark 懒加载
- (TBPlayerLayerView *)playerView{
    if (!_playerView) {
        _playerView=[[TBPlayerLayerView alloc]initWithFrame:CGRectZero];
    }
    return _playerView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.playerView.frame=self.bounds;
}

- (UILabel *)faildLabel{
    if (_faildLabel==nil) {
        _faildLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 30)];
        _faildLabel.center=self.center;
        _faildLabel.textColor = [UIColor whiteColor];
        _faildLabel.textAlignment = NSTextAlignmentCenter;
        _faildLabel.text = @"视频加载失败";
        _faildLabel.hidden = YES;
        _faildLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_faildLabel];
        [self bringSubviewToFront:_faildLabel];
    }
    return _faildLabel;
}
@end
