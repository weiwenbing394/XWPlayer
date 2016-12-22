//
//  RootTabBarController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/15.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "RootTabBarController.h"
#import "BaseNavigationController.h"
#import "TencentNewsViewController.h"
#import "SinaNewsViewController.h"
#import "NetEaseViewController.h"
#import "StartLiveViewController.h"
#import "MyViewController.h"
#import "BaseTabbar.h"

@interface RootTabBarController ()<BaseTabbarDelegate>

@end

@implementation RootTabBarController

+ (void)initialize{
    UITabBar *bar=[UITabBar appearance];
    bar.tintColor=[UIColor redColor];
    bar.barTintColor=[UIColor whiteColor];
    
    UITabBarItem *item=[UITabBarItem appearance];
    [item setTitlePositionAdjustment:UIOffsetMake(0, -2)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setViewControl:[[TencentNewsViewController alloc]init] title:@"腾讯" imageName:@"found" selectedImageName:@"found_s"];
    [self setViewControl:[[SinaNewsViewController alloc]init] title:@"新浪" imageName:@"message" selectedImageName:@"message_s"];
    [self setViewControl:[[NetEaseViewController alloc]init] title:@"映客直播" imageName:@"share" selectedImageName:@"share_s"];
    [self setViewControl:[MyViewController new] title:@"我的" imageName:@"account_normal" selectedImageName:@"account_highlight"];
    
    BaseTabbar *basetabbar=[[BaseTabbar alloc]init];
    basetabbar.mydelagate=self;
    [self setValue:basetabbar forKeyPath:@"tabBar"];
    
}

-(void)setViewControl:(UIViewController *)controller title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName{
    controller.tabBarItem.title=title;
    controller.tabBarItem.image=[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    controller.tabBarItem.selectedImage=[[UIImage imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    if (title.length==0) {
        controller.tabBarItem.imageInsets=UIEdgeInsetsMake(6, 0, -6, 0);
    }
    BaseNavigationController *nav=[[BaseNavigationController alloc]initWithRootViewController:controller];
    [self addChildViewController:nav];
}

- (void)tabBarPushBtnClick:(BaseTabbar *)tabBar{
    StartLiveViewController *live=[StartLiveViewController new];
    BaseNavigationController *nav=[[BaseNavigationController alloc]initWithRootViewController:live];
    [self presentViewController:nav animated:YES completion:nil];
    [nav setNavigationBarHidden:YES];
}
@end
