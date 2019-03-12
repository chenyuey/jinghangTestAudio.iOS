//
//  ViewController.h
//  TestAudio
//
//  Created by macbookpro on 2019/3/11.
//  Copyright © 2019年 macbookpro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface ViewController : UIViewController{
    NSDictionary *mediaInfo;
    BOOL isStarting;
}
@property(nonatomic,strong)AVPlayer * globalPlayer;


@end

