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
    
//    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"https://cms-1255803335.cos.ap-beijing.myqcloud.com/f711cbabfd79141bc573ce27f0da05b0_knAprLlIsJ.mpga"]];
    UIView *videoView = [self createPlayerInViewWithFrame:CGRectMake(20, 220, [UIScreen mainScreen].bounds.size.width - 40, 150)];
    [self.view addSubview:videoView];
    
    self.audioProcessView = [self createProgressWithFrame:CGRectMake(50, videoView.frame.size.height+  videoView.frame.origin.y + 17,[UIScreen mainScreen].bounds.size.width - 100, 4)];
    self.audioProcessView.progress = 0;
    
    
}
//添加视频播放页面
- (UIView *)createPlayerInViewWithFrame:(CGRect)frame{
    UIView *playerView = [[UIView alloc]initWithFrame:frame];
    playerView.layer.cornerRadius = 8;
    playerView.backgroundColor = [UIColor whiteColor];
    // 实例化媒体播放控件
    self.mpMoviePlayer = [[MPMoviePlayerController alloc] init];
//    self.mpMoviePlayer.controlStyle = MPMovieControlStyleNone ;
    self.mpMoviePlayer.view.frame=playerView.bounds;
    playerView.clipsToBounds = YES;
    [playerView addSubview:self.mpMoviePlayer.view];
    return playerView;
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
    NSDictionary *dictInfo = @{@"equipment":@{@"equipment_name": [ViewController deviceModelName], @"player_name": @"AVPlayer", @"system_version":[NSString stringWithFormat:@"iOS%@",[[UIDevice currentDevice] systemVersion]]}};
    [PFCloud callFunctionInBackground:@"fetchTestJob" withParameters:dictInfo block:^(id  _Nullable object, NSError * _Nullable error) {
        if (object != nil) {
            self->mediaInfo = object;
            [self replaceTestCurrentItem:[self->mediaInfo objectForKey:@"mediaUrl"] :@"video"];
        }
        NSLog(@"mediaUrl:%@",object);
    }];
}

- (void)replaceTestCurrentItem:(NSString *)audioUrl :(NSString *)mediaType{
    //音频类型
    if ([mediaType isEqualToString:@"audio"]) {
        if (self.globalPlayer) {
            [self.globalPlayer.currentItem removeObserver:self forKeyPath:@"status" context:nil];
            if (self.timeObserver) {
                [self.globalPlayer removeTimeObserver:self.timeObserver];
                self.timeObserver = nil;
            }
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
        [self addObserverWithAudio];
    }else if ([mediaType isEqualToString:@"video"]){
        //视频类型
        NSString *videoUrl = [audioUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *mediaUrl = [NSURL URLWithString:videoUrl];
        [self.mpMoviePlayer setContentURL:mediaUrl];
        [self.mpMoviePlayer prepareToPlay];
        [self.mpMoviePlayer setShouldAutoplay:NO];
        [self addNotification];
    }else if(mediaType != nil){
        [self fetchTestJob];
    }
}
//结束测试
- (void)endTestAudio:(id)sender{
    isStarting = NO;
//    [self.globalPlayer pause];
}
#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
- (void)addObserverWithAudio{
    [self.globalPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    AVPlayerItem *songItem = self.globalPlayer.currentItem;
    kWeakSelf(self);
    self.timeObserver = [self.globalPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = songItem.duration.value;
        if (current) {
            weakself.audioProcessView.progress = current / total;
            if (current >= 5) {
                [weakself stopAudioAndTestNext];
            }
            
        }
    }];
}
#pragma mark - 监听网络音频状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            [self.globalPlayer playImmediatelyAtRate:1.0];
        }else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            [self getNextTestMediaPlayerWithIsSuccess:NO];
        }
        
    }
}

#pragma mark -获取设备型号
+ (NSString*)deviceModelName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceModel;
}

#pragma mark - 视频状态监听
-(void)addNotification{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.mpMoviePlayer];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerLoadStatechanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.mpMoviePlayer];
}
- (void)removeNotification{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.mpMoviePlayer];
    [notificationCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.mpMoviePlayer];
    
}
- (void)mediaPlayerLoadStatechanged:(NSNotification *)notification{
    switch (self.mpMoviePlayer.loadState) {
        case MPMovieLoadStatePlayable:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.mpMoviePlayer play];
            NSLog(@"可以播放");
            break;
        case MPMovieLoadStateUnknown:
//            NSLog(@"加载失败");
//            [self getNextTestMediaPlayerWithIsSuccess:NO];
        default:
            break;
    }
}

/**
 *  播放完成
 *
 *  @param notification 通知对象
 */
-(void)mediaPlayerPlaybackFinished:(NSNotification *)notification{
    NSNumber * reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    [self removeNotification];
    switch ([reason intValue]) {
        case MPMovieFinishReasonPlaybackEnded:
            NSLog(@"Playback Ended");
            [self getNextTestMediaPlayerWithIsSuccess:YES];
            break;
        case MPMovieFinishReasonPlaybackError:
            NSLog(@"Playback Error");
            [self getNextTestMediaPlayerWithIsSuccess:YES];
            break;
        case MPMovieFinishReasonUserExited:
            NSLog(@"User Exited");
            break;
        default:
            break;
    }
}
- (void)getNextTestMediaPlayerWithIsSuccess:(BOOL)isSuccess
{
    if (isStarting == YES) {
        NSDictionary *dictInfo = @{@"success": [NSNumber numberWithBool:isSuccess], @"mediaId": [mediaInfo objectForKey:@"mediaId"], @"mediaUrl": [mediaInfo objectForKey:@"mediaUrl"],@"equipment":@{@"equipment_name": [ViewController deviceModelName], @"player_name": @"AVPlayer", @"system_version":[NSString stringWithFormat:@"iOS%@",[[UIDevice currentDevice] systemVersion]]}};
        [PFCloud callFunctionInBackground:@"uploadTestReport" withParameters:dictInfo block:^(id  _Nullable object, NSError * _Nullable error) {
            [self fetchTestJob];
        }];
    }
}
//创建进度条
- (UIProgressView *)createProgressWithFrame:(CGRect)frame{
    UIProgressView *processView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    processView.frame = frame;
    processView.progressTintColor = [UIColor colorWithRed:31/255.0 green:194/255.0 blue:155/255.0 alpha:1.0];
    processView.trackTintColor = [UIColor colorWithRed:71/255.0 green:71/255.0 blue:71/255.0 alpha:1.0];
    [self.view addSubview:processView];
    return processView;
}
//
- (void)stopAudioAndTestNext{
    [self.globalPlayer pause];
    [self getNextTestMediaPlayerWithIsSuccess:YES];
}

@end
