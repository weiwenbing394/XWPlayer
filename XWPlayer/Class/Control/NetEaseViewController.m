//
//  NetEaseViewController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/15.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "NetEaseViewController.h"
#import "PlayerModel.h"
#import "PlayerTableViewCell.h"
#import "PlayerViewController.h"
#define mainURL @"http://service.inke.com/api/live/aggregation?imsi=&uid=147970465&proto=6&idfa=3EDE83E7-9CD1-4186-9F37-EE77B7423265&lc=0000000000000027&cc=TG0001&imei=&sid=20tJHn0JsxdmOGkbNjpEjo3DIKFyoyboTrCjMvP7zNxofi1QNXT&cv=IK3.2.00_Iphone&devi=134a83cdf2e6701fa8f85c099c5e68ac3ea7bd4b&conn=Wifi&ua=iPhone%205s&idfv=5CCB6FE7-1F0F-4288-90DC-946D6F6C45C2&osversion=ios_9.300000&interest=1&location=0"
#define Ratio 708/550


@interface NetEaseViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (nonatomic,strong) NSMutableArray *dataSource;

@property (nonatomic,strong) IJKFFMoviePlayerController *player;

@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@end

static NSString *const indentifer=@"Cell";

@implementation NetEaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title=@"映客直播";
    //添加下拉刷新
    [self addRefreshAndFootMore];
    [self.tableview.mj_header beginRefreshing];
}

//上拉加载更多，下拉刷新
- (void)addRefreshAndFootMore{
    __unsafe_unretained UITableView *tableView=self.tableview;
    tableView.tableFooterView=[[UIView alloc]initWithFrame:CGRectZero];
    [tableView registerClass:[PlayerTableViewCell class] forCellReuseIdentifier:indentifer];
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
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:mainURL]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSDictionary *jsonObject=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *listArray = [jsonObject objectForKey:@"lives"];
        for (NSDictionary *dic in listArray) {
            MJWeakSelf
            PlayerModel *playerModel = [[PlayerModel alloc] initWithDictionary:dic];
            playerModel.city = dic[@"city"];
            playerModel.portrait = dic[@"creator"][@"portrait"];
            playerModel.name = dic[@"creator"][@"nick"];
            playerModel.online_users = [dic[@"online_users"] intValue];
            NSLog(@"playerModel.online_users = %d",playerModel.online_users);
            playerModel.url = dic[@"stream_addr"];
            [weakSelf.dataSource addObject:playerModel];
        }
        [self.tableview reloadData];
        [self.tableview.mj_header endRefreshing];

    } ];
}

//上拉加载更多
- (void)loadMoreData{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:mainURL]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSDictionary *jsonObject=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *listArray = [jsonObject objectForKey:@"lives"];
        for (NSDictionary *dic in listArray) {
            MJWeakSelf
            PlayerModel *playerModel = [[PlayerModel alloc] initWithDictionary:dic];
            playerModel.city = dic[@"city"];
            playerModel.portrait = dic[@"creator"][@"portrait"];
            playerModel.name = dic[@"creator"][@"nick"];
            playerModel.online_users = [dic[@"online_users"] intValue];
            NSLog(@"playerModel.online_users = %d",playerModel.online_users);
            playerModel.url = dic[@"stream_addr"];
            [weakSelf.dataSource addObject:playerModel];
        }
        [self.tableview reloadData];
        [self.tableview.mj_header endRefreshing];
        
    } ];

}


#pragma mark  tableviewDelegate
-(NSInteger )numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [UIScreen mainScreen].bounds.size.width * Ratio + 1;;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PlayerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifer];
    cell.playerModel = [self.dataSource objectAtIndex:indexPath.row];
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PlayerViewController * playerVc = [[PlayerViewController alloc] init];
    PlayerModel * PlayerModel = self.dataSource[indexPath.row];
    playerVc.liveUrl = PlayerModel.url;
    playerVc.imageUrl = PlayerModel.portrait;
    playerVc.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:playerVc animated:true];
    [self.navigationController setNavigationBarHidden:YES];
}


#pragma mark 懒加载
- (NSMutableArray *)dataSource{
    if (!_dataSource) {
        _dataSource=[NSMutableArray array];
    }
    return _dataSource;
}

@end
