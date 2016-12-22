//
//  StartLiveViewController.m
//  XWPlayer
//
//  Created by 大家保 on 2016/12/20.
//  Copyright © 2016年 大家保. All rights reserved.
//

#import "StartLiveViewController.h"
#import "LFLivePreview.h"

@interface StartLiveViewController (){
    LFLivePreview *preview;
}

@end

@implementation StartLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor lightGrayColor];
    preview=[[LFLivePreview alloc]initWithFrame:self.view.bounds];
    [preview.closeButton addTarget:self action:@selector(closeSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:preview];
}

- (void)closeSelf{
    [preview.session stopLive];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (void)viewDidDisappear:(BOOL)animated{
//    [super viewDidDisappear:animated];
//    [preview.session stopLive];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
