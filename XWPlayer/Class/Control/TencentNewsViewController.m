//
//  TencentNewsViewController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/15.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "TencentNewsViewController.h"
#import "SidModel.h"
#import "VideoModel.h"
#import "VideoCell.h"

@interface TencentNewsViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (nonatomic,strong) NSMutableArray *dataSource;

@property (nonatomic,strong) XWPlayer *xwPlayer;

@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@property (nonatomic,assign) BOOL isSmallScreen;

@end

static NSString *const indentifer=@"Cell";

@implementation TencentNewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title=@"腾讯视频";
    //注册播放完成通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(videoDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //注册全屏播放通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fullScreenBtnClick:) name:@"fullScreenBtnClickNotice" object:nil];
    //注册关闭视频通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(closeTheVideo:) name:@"closeTheVideo" object:nil];
    //添加下拉刷新
    [self addRefreshAndFootMore];
    [self.tableview.mj_header beginRefreshing];
}

//上拉加载更多，下拉刷新
- (void)addRefreshAndFootMore{
    __unsafe_unretained UITableView *tableView=self.tableview;
    tableView.tableFooterView=[[UIView alloc]initWithFrame:CGRectZero];
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([VideoCell class]) bundle:nil] forCellReuseIdentifier:indentifer];
    __weak typeof(self) weakSelf=self;
    tableView.mj_header=[MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadData];
    }];
    tableView.mj_footer=[MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weakSelf loadMoreData];
    }];
}

//下拉刷新
- (void)loadData{
    [[DataManager shareManager] getSIDArrayWithURLString:@"http://c.m.163.com/nc/video/home/0-10.html" success:^(NSArray *sidArray, NSArray *videoArray) {
        [self.tableview.mj_header endRefreshing];
        self.dataSource=[NSMutableArray arrayWithArray:videoArray];
        [self.tableview reloadData];
    } failed:^(NSError *error) {
        NSLog(@"加载失败");
    }];
}

//上拉加载更多
- (void)loadMoreData{
    NSString *urlString=[NSString stringWithFormat:@"http://c.m.163.com/nc/video/home/%ld-10.html",self.dataSource.count];
    [[DataManager shareManager] getSIDArrayWithURLString:urlString success:^(NSArray *sidArray, NSArray *videoArray) {
        [self.tableview.mj_footer endRefreshing];
        [self.dataSource addObjectsFromArray:videoArray];
        [self.tableview reloadData];
    } failed:^(NSError *error) {
        NSLog(@"加载失败");
    }];
}


#pragma mark  tableviewDelegate
-(NSInteger )numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 314;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifer];
    cell.model = [self.dataSource objectAtIndex:indexPath.row];
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playBtn.tag = indexPath.row;
#pragma mark 超出屏幕小屏幕播放
    if (self.xwPlayer&&self.xwPlayer.superview) {
        if (indexPath==self.currentIndexPath) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        NSArray *indexPaths=[tableView indexPathsForVisibleRows];
        if ([indexPaths containsObject:self.currentIndexPath]) {
        }else{
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:self.xwPlayer]) {
                self.xwPlayer.hidden=NO;
            }else{
                self.xwPlayer.hidden = YES;
                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
            }
        }
    }
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}
#pragma mark 视频播放操作
//开始播放
- (void)startPlayVideo:(UIButton *)btn{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentIndexPath=[NSIndexPath indexPathForRow:btn.tag inSection:0];
        VideoModel *model=[self.dataSource objectAtIndex:btn.tag];
        VideoCell  *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
        if (self.xwPlayer) {
            [self.xwPlayer removeFromSuperview];
            [self.xwPlayer setVideoURLStr:model.mp4_url];
        }else{
            XWPlayer *player=[[XWPlayer alloc]initWithFrame:currentCell.backgroundIV.bounds videoURLStr:model.mp4_url];
            self.xwPlayer=player;
        }
        self.xwPlayer.frame=currentCell.backgroundIV.bounds;
        [currentCell.backgroundIV addSubview:self.xwPlayer];
        [currentCell.backgroundIV bringSubviewToFront:self.xwPlayer];
        [currentCell.playBtn.superview sendSubviewToBack:currentCell.playBtn];
        self.xwPlayer.playOrPauseBtn.selected=NO;
        _xwPlayer.isFullscreen=NO;
        _xwPlayer.fullScreenBtn.selected=NO;
        self.isSmallScreen=NO;
        [self.tableview reloadData];
    });
}


#pragma mark scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView==self.tableview) {
        if (self.xwPlayer==nil) {
            return;
        }
        //有打开的视频
        if (self.xwPlayer.superview) {
            //正在播放的cell在主屏幕的位置
            CGRect rectInTableView=[self.tableview rectForRowAtIndexPath:self.currentIndexPath];
            CGRect rectInSuperView=[self.tableview convertRect:rectInTableView toView:[self.tableview superview]];
            if (rectInSuperView.origin.y<-(314-64-35)||rectInSuperView.origin.y>kScreenHeight-49-64) {
                //超出屏幕显示位置
                //已有小屏幕
                if ([[UIApplication sharedApplication].keyWindow.superview.subviews containsObject:self.xwPlayer]&&self.isSmallScreen) {
                    self.isSmallScreen=YES;
                }else{
                    //放小屏幕
                    [self toSmallScreen];
                }
            }else{
                //屏幕中显示
                VideoCell *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
                //若在小屏幕上显示
                if (![currentCell.backgroundIV.subviews containsObject:self.xwPlayer]) {
                    //在tableviewcell上面显示
                    [self toCell];
                }
            }
        }
    }
}

//添加小屏幕
- (void)toSmallScreen{
    [self.xwPlayer removeFromSuperview];
    [UIView animateWithDuration:0.25 animations:^{
        _xwPlayer.transform=CGAffineTransformIdentity;
        _xwPlayer.frame=CGRectMake(kScreenWidth/2, 64, kScreenWidth/2, (kScreenWidth/2)*0.75);
        [[UIApplication sharedApplication].keyWindow addSubview:_xwPlayer];
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
    }completion:^(BOOL finished) {
        _xwPlayer.isFullscreen=NO;
        _xwPlayer.fullScreenBtn.selected=NO;
        self.isSmallScreen=YES;
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:_xwPlayer];
    }];
}

//在tableviewcell上面显示
- (void)toCell{
    VideoCell *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
    [_xwPlayer removeFromSuperview];
    [UIView animateWithDuration:0.25 animations:^{
        _xwPlayer.transform=CGAffineTransformIdentity;
        _xwPlayer.frame=currentCell.backgroundIV.bounds;
        [currentCell.backgroundIV addSubview:_xwPlayer];
        [currentCell.backgroundIV bringSubviewToFront:_xwPlayer];
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
        self.isSmallScreen=NO;
        _xwPlayer.fullScreenBtn.selected=NO;
    }];
}


//播放完成
- (void)videoDidFinished:(NSNotification *)notice{
    [_xwPlayer.player pause];
    [_xwPlayer.player.currentItem cancelPendingSeeks];
    [_xwPlayer.player.currentItem.asset cancelLoading];
    [self.xwPlayer removeFromSuperview];
    VideoCell *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
}

//全屏播放
- (void)fullScreenBtnClick:(NSNotification *)notice{
    UIButton *fullScreenBtn=(UIButton *)[notice object];
    if (fullScreenBtn.isSelected) {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        if (self.isSmallScreen) {
            [self toSmallScreen];
        }else{
            [self toCell];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
                [self toCell];
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

//关闭视频播放
- (void)closeTheVideo:(NSNotification *)notice{
    VideoCell *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self releaseXWPlayer];
}



#pragma mark 懒加载
- (NSMutableArray *)dataSource{
    if (!_dataSource) {
        _dataSource=[NSMutableArray array];
    }
    return _dataSource;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    VideoCell *currentCell=[self.tableview cellForRowAtIndexPath:self.currentIndexPath];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self releaseXWPlayer];
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.currentIndexPath=nil;
}




@end
