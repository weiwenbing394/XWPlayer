//
//  BaseTabbar.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/20.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "BaseTabbar.h"
#define LBMagin 10

@interface  BaseTabbar ()

@property (nonatomic,strong)UIButton *pushButton;

@end

@implementation BaseTabbar

- (instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self setShadowImage:[UIImage imageWithColor:[UIColor clearColor]]];
        
        UIButton *plusBtn = [[UIButton alloc] init];
        [plusBtn setBackgroundImage:[UIImage imageNamed:@"post_normal"] forState:UIControlStateNormal];
        [plusBtn setBackgroundImage:[UIImage imageNamed:@"post_normal"] forState:UIControlStateHighlighted];
        [plusBtn addTarget:self action:@selector(plusBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
        
        self.pushButton = plusBtn;
        [self addSubview:plusBtn];    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    //调整发布按钮的位置
    //调整发布按钮的中线点Y值
    self.pushButton.size = CGSizeMake(self.pushButton.currentBackgroundImage.size.width, self.pushButton.currentBackgroundImage.size.height);
    self.pushButton.center = CGPointMake(self.width/2.0, self.height/2.0-2*LBMagin);
    //发布按钮下面的标题
    UILabel *label = [[UILabel alloc] init];
    label.text = @"直播";
    label.font = [UIFont systemFontOfSize:10];
    [label sizeToFit];
    label.textColor = [UIColor lightGrayColor];
    [self addSubview:label];
    label.centerX = self.pushButton.centerX;
    label.centerY = CGRectGetMaxY(self.pushButton.frame) + LBMagin ;
    //系统自带的按钮类型是UITabBarButton，找出这些类型的按钮，然后重新排布位置，空出中间的位置
    Class class=NSClassFromString(@"UITabBarButton");
    int btnIndex=0;
    for (UIView *btn in self.subviews) {
        if ([btn isKindOfClass:class]) {
            CGRect btnRect=btn.frame;
            btnRect.size.width=self.frame.size.width/5.0;
            btnRect.origin.x=self.frame.size.width/5.0*btnIndex;
            btn.frame=btnRect;
            btnIndex++;
            if (btnIndex==2) {
                btnIndex++;
            }
            
        }
    }
    [self bringSubviewToFront:self.pushButton];
}


- (void)plusBtnDidClick{
    if (self.mydelagate&&[self.mydelagate respondsToSelector:@selector(tabBarPushBtnClick:)]) {
        [self.mydelagate  tabBarPushBtnClick:self];
    }
}

//重写hitTest方法，去监听发布按钮的点击，目的是为了让凸出的部分点击也有反应
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    //这一个判断是关键，不判断的话push到其他页面，点击发布按钮的位置也是会有反应的，这样就不好了
    //self.isHidden == NO 说明当前页面是有tabbar的，那么肯定是在导航控制器的根控制器页面
    //在导航控制器根控制器页面，那么我们就需要判断手指点击的位置是否在发布按钮身上
    //是的话让发布按钮自己处理点击事件，不是的话让系统去处理点击事件就可以了
    if (self.isHidden == NO) {
        //将当前tabbar的触摸点转换坐标系，转换到发布按钮的身上，生成一个新的点
        CGPoint newP = [self convertPoint:point toView:self.pushButton];
        //判断如果这个新的点是在发布按钮身上，那么处理点击事件最合适的view就是发布按钮
        if ( [self.pushButton pointInside:newP withEvent:event]) {
            return self.pushButton;
        }else{//如果点不在发布按钮身上，直接让系统处理就可以了
            return [super hitTest:point withEvent:event];
        }
    }else {//tabbar隐藏了，那么说明已经push到其他的页面了，这个时候还是让系统去判断最合适的view处理就好了
        return [super hitTest:point withEvent:event];
    }
}

@end
