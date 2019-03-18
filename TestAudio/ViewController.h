//
//  ViewController.h
//  TestAudio
//
//  Created by macbookpro on 2019/3/11.
//  Copyright © 2019年 macbookpro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <sys/utsname.h>


@interface ViewController : UIViewController{
    NSDictionary *mediaInfo;
    BOOL isStarting;
//    UIProgressView *audioProcessView;
    UILabel *playURLLabel;
}
@property(nonatomic,strong)AVPlayer * globalPlayer;
@property(nonatomic,strong)id timeObserver;
//视频
@property(nonatomic, strong)MPMoviePlayerController *mpMoviePlayer;
@property(nonatomic, strong)UIProgressView *audioProcessView;


@end

