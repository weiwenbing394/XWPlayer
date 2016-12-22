//
//  LFLivePreview.h
//  XWPlayer
//
//  Created by 大家保 on 2016/12/20.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFLivePreview : UIView

@property (nonatomic, strong) UIButton *closeButton;  //关闭按钮

@property (nonatomic, strong) UISlider *meibaiSlider;  //美白的slider

@property (nonatomic, strong) UISlider *mopiSlider;  //磨皮的slider

@property (nonatomic, strong) LFLiveSession *session;

@end
