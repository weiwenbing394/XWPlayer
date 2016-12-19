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

@interface XWPlayer ()
//播放进度
@property (nonatomic, strong) UISlider *progressSlider;
//缓冲进度条
@property (nonatomic, strong) UIProgressView *loadedProgress;
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


@property (nonatomic,assign)BOOL slider;

@property (nonatomic, retain)NSDateFormatter *dateFormatter;

@property (nonatomic, strong)UIActivityIndicatorView *indicatorView;

@end

@implementation XWPlayer{
    
    UISlider *systemSlider;
    
}

//初始化方法
- (instancetype) initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr{
    
    if (self=[super initWithFrame:frame]) {
        
        self.backgroundColor=[UIColor blackColor];
        
        self.currentItem=[self getPlayerItemWithURLString:videoURLStr];
        
        self.player=[AVPlayer playerWithPlayerItem:self.currentItem];
        
        [self.playerView setPlayerLayer:self.player];
        
        [self addSubview:self.playerView];
        
        //底部操作栏设置
        self.bottomView=[[UIView alloc]init];
        
        self.bottomView.backgroundColor=[UIColor clearColor];
        
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
        
#pragma warming
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
        
        //缓冲进度条
        self.loadedProgress=[[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        
        self.loadedProgress.progressTintColor=[UIColor lightGrayColor];
        
        self.loadedProgress.trackTintColor=[UIColor darkGrayColor];
        
        [self.loadedProgress setProgress:0];
        
        [self.bottomView addSubview:self.loadedProgress];
        
        [self.loadedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(45);
            make.right.mas_equalTo(-45);
            make.centerY.mas_equalTo(1);
            make.height.mas_equalTo(2);
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
        
        [self.bottomView addSubview:self.progressSlider];
        
        [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.left.mas_equalTo(45);
            make.right.mas_equalTo(-45);
        }];
        
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
        
        self.indicatorView.hidesWhenStopped=YES;
        
        [self.indicatorView startAnimating];
        
        [self addSubview:self.indicatorView];
        
        [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(0);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
        
        //页面单击
        UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
        
        singleTap.numberOfTapsRequired = 1;
        
        [self addGestureRecognizer:singleTap];
        
        //页面单击
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
        
        doubleTap.numberOfTapsRequired = 2;
        
        [self addGestureRecognizer:doubleTap];
        
        //添加监控
        [self addCurrentItemObser];
        
        [self initTimer];
        
    }
    return self;
};

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


#pragma  maik 监听视频加载状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if (context==PlayViewStatusObservationContext) {
        
        if (([keyPath isEqualToString:@"status"])) {
            
            AVPlayerItemStatus status=[[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            
            switch (status) {
                    //播放准备完成
                case AVPlayerItemStatusReadyToPlay:{
                    //获取总时长
                    if (CMTimeGetSeconds(self.player.currentItem.duration)) {
                        
                        self.progressSlider.maximumValue=CMTimeGetSeconds(self.player.currentItem.duration);
                        
                        [self.indicatorView stopAnimating];
                        
                        NSLog(@"开始播放");
                        //开始播放
                        [self.player play];
                     }
                    
                    //刷新进度条，获取总时长等操作
                    [self initTimer];
                    
                    //初始化自动隐藏操作栏定时器  播放完成定时器
                    [self initDissMissTimer];
                    
                }
                    break;
                case AVPlayerItemStatusFailed:
                    
                    NSLog(@"播放失败");
                    
                    [self.indicatorView startAnimating];
                    
                    break;
                case AVPlayerItemStatusUnknown:
                    
                    NSLog(@"未知错误");
                    
                    [self.indicatorView startAnimating];
                    
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
            
            NSLog(@"缓存用完");
            
            [self.indicatorView startAnimating];
            
            
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            [self.indicatorView stopAnimating];
            
            NSLog(@"缓存开始");
            
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
        [self initDissMissTimer];
    }else{
        //暂停播放
        [self.player pause];
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

//全屏播放
- (void)fullScreenAction:(UIButton *)sender{
    sender.selected=!sender.selected;
    //用通知的形式把点击全屏的时间发送到app的任何地方，方便处理其他逻辑
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fullScreenBtnClickNotice" object:sender];
}

//关闭视频播放
- (void)colseTheVideo:(UIButton *)sender{
    [self.player pause];
    [self invalidTimer];
    [self.currentItem cancelPendingSeeks];
    [self.currentItem.asset cancelLoading];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeTheVideo" object:sender];
}

//视频播放结束
- (void)moviePlayDidEnd:(NSNotification *)notification{
    __weak typeof(self) weakSelf = self;
    [weakSelf.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf clearUIValues];
        [weakSelf.player pause];
        [weakSelf.currentItem cancelPendingSeeks];
        [weakSelf.currentItem.asset cancelLoading];
        [weakSelf invalidTimer];
        weakSelf.playOrPauseBtn.selected=NO;
    }];
    
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
        }else{
            //正在播放
            [self.player pause];
        }
    }];
}

#pragma  mark 设置播放的视频
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
    //停止底部操作栏5秒隐藏的定时器
    [self invalidTimer];
    //显示底部操作栏
    if (self.bottomView.alpha==0) {
        self.bottomView.alpha=1;
        self.closeBtn.alpha=1;
    }
}


//清除ui上面的缓存，进度条啥的
- (void)clearUIValues{
    [self.progressSlider setValue:0 animated:NO];
    [self.loadedProgress setProgress:0];
    self.timeLabel.text=@"00:00/00:00";
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

- (void)dealloc{
    
    [self removeCurrentItemObser];
    
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
@end
