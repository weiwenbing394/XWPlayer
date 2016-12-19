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

@interface RootTabBarController ()

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
    [self setViewControl:[[NetEaseViewController alloc]init] title:@"网易" imageName:@"share" selectedImageName:@"share_s"];
    
}

-(void)setViewControl:(UIViewController *)controller title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName{
    controller.tabBarItem.title=title;
    controller.tabBarItem.image=[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    controller.tabBarItem.selectedImage=[[UIImage imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    BaseNavigationController *nav=[[BaseNavigationController alloc]initWithRootViewController:controller];
    [self addChildViewController:nav];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
