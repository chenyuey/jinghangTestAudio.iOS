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
    
    UILabel *playURLDesLabel = [self createLabelWithFrame:CGRectMake(20, self.audioProcessView.frame.origin.y + 30, 80, 60) :15 :@"Arial" :[UIColor redColor] :NSTextAlignmentLeft];
    playURLDesLabel.text = @"测试链接:";
    [self.view addSubview:playURLDesLabel];
    playURLLabel = [self createLabelWithFrame:CGRectMake(playURLDesLabel.frame.origin.x +playURLDesLabel.frame.size.width , playURLDesLabel.frame.origin.y , [UIScreen mainScreen].bounds.size.width - 40 - playURLDesLabel.frame.origin.x, 60) :15 :@"Arial" :[UIColor redColor] :NSTextAlignmentLeft];
    playURLLabel.numberOfLines = 0;
    [self.view addSubview:playURLLabel];
    
    
}
#pragma mark - 创建UI
- (UILabel *)createLabelWithFrame:(CGRect)frame :(CGFloat)fontSize :(NSString *)fontName :(UIColor *)fontColor :(NSTextAlignment)alignment{
    UILabel *label = [[UILabel alloc]initWithFrame:frame];
    label.font = [UIFont fontWithName:fontName size:fontSize];
    label.textColor = fontColor;
    label.textAlignment = alignment;
    return label;
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
//添加视频播放页面
- (UIView *)createPlayerInViewWithFrame:(CGRect)frame{
    UIView *playerView = [[UIView alloc]initWithFrame:frame];
    playerView.layer.cornerRadius = 8;
    playerView.backgroundColor = [UIColor whiteColor];
    // 实例化媒体播放控件
    self.mpMoviePlayer = [[MPMoviePlayerController alloc] init];
    self.mpMoviePlayer.controlStyle = MPMovieControlStyleNone ;
    self.mpMoviePlayer.view.frame=playerView.bounds;
    playerView.clipsToBounds = YES;
    [playerView addSubview:self.mpMoviePlayer.view];
    return playerView;
}
#pragma mark - 事件
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
            [self getFileContentWithUrl:[self->mediaInfo objectForKey:@"mediaUrl"] andFileType :@"video"];
        }
        NSLog(@"mediaUrl:%@",object);
    }];
}

- (void)replaceTestCurrentItem:(NSString *)audioUrl :(NSString *)mediaType{
    playURLLabel.text = audioUrl;
//    audioUrl = @"https://cms-1255803335.cos.ap-beijing.myqcloud.com/af6bbc5bd93eacaadf5b955e7660feb0_bc59eaea-b767-4900-8e49-766913bbe45f.mp3";
//    mediaType = @"audio";
    //音频类型
    if ([mediaType isEqualToString:@"audio"]) {
        if (self.globalPlayer) {
            [self.globalPlayer.currentItem removeObserver:self forKeyPath:@"status" context:nil];
            if (self.timeObserver) {
                [self.globalPlayer removeTimeObserver:self.timeObserver];
                self.timeObserver = nil;
            }
        }
        if ([self getIsValidAudioFormatWithURL:audioUrl]) {
            AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:audioUrl]];
            if (self.globalPlayer == nil) {
                self.globalPlayer = [AVPlayer playerWithPlayerItem:playItem];
                if([[UIDevice currentDevice] systemVersion].intValue>=10){
                    self.globalPlayer.automaticallyWaitsToMinimizeStalling = NO;
                }
            }else{
                [self.globalPlayer replaceCurrentItemWithPlayerItem:playItem];
            }
            [self.globalPlayer playImmediatelyAtRate:1.0];
            [self addObserverWithAudio];
        }else{
            [self getNextTestMediaPlayerWithIsSuccess:NO :@"音频格式有误，moviePlayer只支持MP3,WMA,RM,ACC,OGG,APE,FLAC,FLV格式"];
        }
        
        
    }else if ([mediaType isEqualToString:@"video"]){
        //视频类型
        if ([self getIsValidVideoFormatWithURL:audioUrl]) {
            NSString *videoUrl = [audioUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *mediaUrl = [NSURL URLWithString:videoUrl];
            [self.mpMoviePlayer setContentURL:mediaUrl];
            [self.mpMoviePlayer prepareToPlay];
            [self.mpMoviePlayer setShouldAutoplay:NO];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [self.mpMoviePlayer play];
            [self addNotification];
        }else{
            [self getNextTestMediaPlayerWithIsSuccess:NO :@"视频格式有误，moviePlayer只支持MOV、MP4、M4V、3GP格式"];
        }
        
        
    }else if(mediaType != nil){
        [self fetchTestJob];
    }
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
            if (current >= 100) {
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
//            [self.globalPlayer playImmediatelyAtRate:1.0];
        }else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            [self getNextTestMediaPlayerWithIsSuccess:NO :@"音频加载失败"];
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
#pragma mark - 检查音频和视频的格式
- (BOOL)getIsValidVideoFormatWithURL:(NSString *)strURL{
    NSArray *allFormat = @[@"mov",@"mp4",@"m4v",@"3gp"];
    NSArray *arrURLs = [strURL componentsSeparatedByString:@"."];
    if (arrURLs.count>0) {
        if ([allFormat containsObject:[arrURLs objectAtIndex:arrURLs.count -1]]) {
            return YES;
        }
    }
    return FALSE;
}
- (BOOL)getIsValidAudioFormatWithURL:(NSString *)strURL{
    NSArray *allFormat = @[@"mp3",@"wma",@"rm",@"acc",@"ogg",@"ape",@"flac",@"flv"];
    NSArray *arrURLs = [strURL componentsSeparatedByString:@"."];
    if (arrURLs.count>0) {
        if ([allFormat containsObject:[arrURLs objectAtIndex:arrURLs.count -1]]) {
            return YES;
        }
    }
    return FALSE;
}

#pragma mark - 视频状态监听
-(void)addNotification{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.mpMoviePlayer];
}
- (void)removeNotification{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.mpMoviePlayer];
}

/**
 *  播放完成
 *
 *  @param notification 通知对象
 */
-(void)mediaPlayerPlaybackFinished:(NSNotification *)notification{
    
    MPMovieFinishReason reason  = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        [self removeNotification];
        [self getNextTestMediaPlayerWithIsSuccess:YES :@""];
    }else if (reason == MPMovieFinishReasonPlaybackError){
        
    }
}
- (void)getNextTestMediaPlayerWithIsSuccess:(BOOL)isSuccess :(NSString *)errorMessage
{
    if (isStarting == YES) {
        NSDictionary *dictInfo = @{@"success": [NSNumber numberWithBool:isSuccess],@"errorMsg":errorMessage, @"mediaId": [mediaInfo objectForKey:@"mediaId"], @"mediaUrl": [mediaInfo objectForKey:@"mediaUrl"],@"equipment":@{@"equipment_name": [ViewController deviceModelName], @"player_name": @"AVPlayer", @"system_version":[NSString stringWithFormat:@"iOS%@",[[UIDevice currentDevice] systemVersion]]}};
        [PFCloud callFunctionInBackground:@"uploadTestReport" withParameters:dictInfo block:^(id  _Nullable object, NSError * _Nullable error) {
            [self fetchTestJob];
        }];
    }
}

//
- (void)stopAudioAndTestNext{
    [self.globalPlayer pause];
    [self getNextTestMediaPlayerWithIsSuccess:YES : @""];
}

//检测远程文件是否存在
- (void)getFileContentWithUrl:(NSString *)strURL andFileType:(NSString *)type{
    NSURL *url = [NSURL URLWithString:strURL];
    //A Boolean value that turns an indicator of network activity on or off.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *xmlData = [NSData dataWithContentsOfURL:url];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString *xmlString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSError *err;
    NSString *htmlString = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSASCIIStringEncoding error:&err];
    if (xmlData == nil) {
        NSLog(@"File read failed!:%@", @"文件不存在");
        [self getNextTestMediaPlayerWithIsSuccess:NO :@"文件不存在"];
    }
    else {
        [self replaceTestCurrentItem:strURL :type];
    }
}
@end
