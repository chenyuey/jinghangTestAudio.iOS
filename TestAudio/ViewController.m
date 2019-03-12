//
//  ViewController.m
//  TestAudio
//
//  Created by macbookpro on 2019/3/11.
//  Copyright © 2019年 macbookpro. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn1 = [[UIButton alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 100)/2, 100, 100, 100)];
    [btn1 addTarget:self action:@selector(startTestAudio:) forControlEvents:UIControlEventTouchUpInside];
    [btn1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn1 setTitle:@"开始测试" forState:UIControlStateNormal];
    [self.view addSubview:btn1];
    
//    UIButton *btn2 = [[UIButton alloc]initWithFrame:CGRectMake(10, 300, 100, 100)];
//    [btn2 setTitle:@"停止测试" forState:UIControlStateNormal];
//    [btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [btn2 addTarget:self action:@selector(endTestAudio:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn2];
    
//    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"https://cms-1255803335.cos.ap-beijing.myqcloud.com/f711cbabfd79141bc573ce27f0da05b0_knAprLlIsJ.mpga"]];
    
}
//开始测试
- (void)startTestAudio:(id)sender{
    UIButton *btn = (UIButton *)sender;
    if (isStarting == NO) {
        isStarting = YES;
        [self fetchTestJob];
        [btn setTitle:@"结束测试" forState:UIControlStateNormal];
    }else{
        isStarting = NO;
        [btn setTitle:@"开始测试" forState:UIControlStateNormal];
    }
    
}
- (void)fetchTestJob{
    [PFCloud callFunctionInBackground:@"fetchTestJob" withParameters:@{@"equipment":@{@"equipment_name": @"iOS", @"player_name": @"AVPlayer", @"system_version":[[UIDevice currentDevice] systemVersion]}} block:^(id  _Nullable object, NSError * _Nullable error) {
        self->mediaInfo = object;
        [self replaceTestCurrentItem:[self->mediaInfo objectForKey:@"mediaUrl"]];
//        NSLog(@"mediaUrl:%@",[self->mediaInfo objectForKey:@"mediaUrl"]);
        //        [self replaceTestCurrentItem:@"https://cms-1255803335.cos.ap-beijing.myqcloud.com/f711cbabfd79141bc573ce27f0da05b0_knAprLlIsJ.mpga"];
    }];
}

- (void)replaceTestCurrentItem:(NSString *)audioUrl{
    if (self.globalPlayer) {
        [self.globalPlayer.currentItem removeObserver:self forKeyPath:@"status" context:nil];
    }
    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:audioUrl]];
    if (self.globalPlayer == nil) {
        self.globalPlayer = [AVPlayer playerWithPlayerItem:playItem];
        if([[UIDevice currentDevice] systemVersion].intValue>=10){
            self.globalPlayer.automaticallyWaitsToMinimizeStalling = NO;
        }
    }else{
        [self.globalPlayer replaceCurrentItemWithPlayerItem:playItem];
    }
    [self checkAudio];
}
//结束测试
- (void)endTestAudio:(id)sender{
    isStarting = NO;
//    [self.globalPlayer pause];
}
- (void)checkAudio{
    [self.globalPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}
#pragma mark - 监听网络音频状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        BOOL isPlayable = NO;
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
//            [self.globalPlayer.currentItem removeObserver:self forKeyPath:@"status"];
            NSLog(@"AVPlayerStatusReadyToPlay");
            isPlayable = YES;
//            [self.globalPlayer playImmediatelyAtRate:1.0];
        }else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            isPlayable = NO;
        }
        if (isStarting == YES) {
            [PFCloud callFunctionInBackground:@"uploadTestReport" withParameters:@{@"success": [NSNumber numberWithBool:isPlayable], @"mediaId": [mediaInfo objectForKey:@"mediaId"], @"mediaUrl": [mediaInfo objectForKey:@"mediaUrl"],@"equipment":@{@"equipment_name": @"iOS", @"player_name": @"AVPlayer", @"system_version":[[UIDevice currentDevice] systemVersion]}} block:^(id  _Nullable object, NSError * _Nullable error) {
                NSLog(@"uploadTestReport%@",object);
                [self fetchTestJob];
            }];
            
            
        }
        
    }
}

@end
