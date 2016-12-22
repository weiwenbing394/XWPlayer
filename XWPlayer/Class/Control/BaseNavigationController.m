//
//  BaseNavigationController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/15.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "BaseNavigationController.h"

@interface BaseNavigationController ()

@end

@implementation BaseNavigationController


+ (void)initialize{
    UINavigationBar *bar=[UINavigationBar appearance];
    //barbuttonItem的颜色
    [bar setTintColor:[UIColor whiteColor]];
    //bar的颜色
    [bar setBarTintColor:[UIColor redColor]];
    //返回图片
    UIImage *image=[[UIImage imageNamed:@"navigator_btn_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [bar setBackIndicatorImage:image];
    [bar setBackIndicatorTransitionMaskImage:image];
    //设置标题
    [bar setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    //隐藏返回按钮后面的文字
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60) forBarMetrics:UIBarMetricsDefault];
    //设置UIBarButtonItem
    UIBarButtonItem *item = [UIBarButtonItem appearance];
    
    NSMutableDictionary *itemDicNormal=[NSMutableDictionary dictionary];
    [itemDicNormal setValue:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [itemDicNormal setValue:[UIFont systemFontOfSize:15] forKey:NSFontAttributeName];
    [item setTitleTextAttributes:itemDicNormal forState:UIControlStateNormal];
    
    NSMutableDictionary *itemDicHight=[NSMutableDictionary dictionary];
    [itemDicHight setValue:[UIColor lightGrayColor] forKey:NSForegroundColorAttributeName];
    [itemDicHight setValue:[UIFont systemFontOfSize:15] forKey:NSFontAttributeName];
    [item setTitleTextAttributes:itemDicHight forState:UIControlStateHighlighted];
    
    
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (self.viewControllers.count>0) {
        viewController.hidesBottomBarWhenPushed=YES;
    }
    [super pushViewController:viewController animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}



@end
