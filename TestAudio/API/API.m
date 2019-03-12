//
//  API.m
//  TestAudio
//
//  Created by macbookpro on 2019/3/12.
//  Copyright © 2019年 macbookpro. All rights reserved.
//

#import "API.h"

@implementation API
+ (void)sendGetRequest:(NSString *)baseUrl :(NSString*)postOrGet :(NSDictionary *)dict :(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://10.135.9.212:1337/api/1%@",baseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = postOrGet;//@"POST";
    request.HTTPBody = [[NSString stringWithFormat:@"%@",dict] dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    // 由于要先对request先行处理,我们通过request初始化task
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            completionHandler(data,response,error);
                                            NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]); }];
    [task resume];
}

@end
