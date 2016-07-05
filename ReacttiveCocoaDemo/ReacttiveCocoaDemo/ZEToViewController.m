//
//  ZEToViewController.m
//  ReacttiveCocoaDemo
//
//  Created by apple on 16/5/30.
//  Copyright © 2016年 lieon. All rights reserved.
//

#import "ZEToViewController.h"
#import "ReactiveCocoa.h"
#import "ZETweet.h"


@interface ZEToViewController ()

@property (nonatomic,strong) NSArray * tweets;

@end

@implementation ZEToViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)displayTweets:(NSArray *)tweets
{
    self.tweets = tweets;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return  self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"result" forIndexPath:indexPath];
    ZETweet * tweet = self.tweets[indexPath.row];
    [[[self signalForLoadingImage:tweet.profileImageUrl]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIImage *image) {
         cell.imageView.image = image;
     }];
    
    return cell;
}

-(RACSignal *)signalForLoadingImage:(NSString *)imageUrl {
    RACScheduler *scheduler = [RACScheduler
                               schedulerWithPriority:RACSchedulerPriorityBackground];
    
    return [[RACSignal createSignal:^RACDisposable *(id subscriber) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        [subscriber sendNext:image];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:scheduler];
}

@end
