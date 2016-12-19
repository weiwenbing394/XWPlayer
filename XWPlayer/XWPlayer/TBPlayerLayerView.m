//
//  TBPlayerLayerView.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/11/19.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "TBPlayerLayerView.h"

@implementation TBPlayerLayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)setPlayerLayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

@end
