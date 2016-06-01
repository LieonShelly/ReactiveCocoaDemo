//
//  ZETweet.h
//  ReacttiveCocoaDemo
//
//  Created by apple on 16/6/1.
//  Copyright © 2016年 lieon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZETweet : NSObject

@property(nonatomic,copy) NSString * next_results;
@property(nonatomic,copy) NSString * refresh_url;

@property(nonatomic,copy) NSString * profileImageUrl;

+ (instancetype)tweetWithStatus:(id)tweet;

@end
