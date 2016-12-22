//
//  BaseTabbar.h
//  XWPlayer
//
//  Created by 大家保 on 2016/12/20.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BaseTabbar;

@protocol BaseTabbarDelegate <NSObject>

- (void)tabBarPushBtnClick:(BaseTabbar *)tabBar;

@end

@interface BaseTabbar : UITabBar

@property (nonatomic,weak) id<BaseTabbarDelegate> mydelagate;

@end
