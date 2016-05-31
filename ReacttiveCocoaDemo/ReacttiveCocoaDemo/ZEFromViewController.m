//
//  ZEFromViewController.m
//  ReacttiveCocoaDemo
//
//  Created by apple on 16/5/30.
//  Copyright © 2016年 lieon. All rights reserved.
//

#import "ZEFromViewController.h"
#import "ReactiveCocoa.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

typedef NS_ENUM(NSInteger, RWTwitterInstantError) {
    ZETwitterInstantErrorAccessDenied,
    ZETwitterInstantErrorNoTwitterAccounts,
    ZETwitterInstantErrorInvalidResponse
};

static NSString * const RWTwitterInstantDomain = @"TwitterInstant";

@interface ZEFromViewController ()
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

/**
 *  ACAccountsStore类能让你访问你的设备能连接到的多个社交媒体账号，
 */
@property (strong, nonatomic) ACAccountStore *accountStore;
/**
 *  ACAccountType类则代表账户的类型
 */
@property (strong, nonatomic) ACAccountType *twitterAccountType;
@end

@implementation ZEFromViewController

/**
 *  @weakify宏让你创建一个弱引用的影子对象（如果你需要多个弱引用，你可以传入多个变量）
    @strongify让你创建一个对之前传入@weakify对象的强引用。
 
 
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建了一个account store和Twitter账户标识符。
    self.accountStore = [[ACAccountStore alloc]init];
    self.twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    @weakify(self);
    
   RACSignal * searchTextSignal = [self.searchTextField
    
    // 获取search text field 的text signal
    .rac_textSignal
                                   
    // 将其转换为颜色来标示输入是否有
    map:^id(NSString * text) {
         return [self_weak_ isvalidSearchText:text] ? [UIColor redColor] :[UIColor yellowColor];
    }];
    
    RAC(self.searchTextField,backgroundColor)=
    
    [searchTextSignal map:^id(UIColor * value) {
        return value;

    }];


    [[[[[[self requestAcceccToTwitterSignal]
      // then方法会等待completed事件的发送，然后x再订阅由then block返回的signal。这样就高效地把控制权从一个signal传递给下一个。
        then:^RACSignal *{
            @strongify(self)
            return self.searchTextField.rac_textSignal;
        }]
       
        filter:^BOOL(NSString * text) {
            @strongify(self)
            return [self isvalidSearchText:text];
        }]
     
        flattenMap:^RACStream *(NSString * text) {
            @strongify(self)
           return [self signalForSearchWithText:text];
        }]
      
      // 回到主线程
       deliverOn:[RACScheduler mainThreadScheduler]]
     
        subscribeNext:^(id x) {
            NSLog(@"%@",x);
        } error:^(NSError *error) {
            NSLog(@"error");
        }];

}

- (RACSignal*)requestAcceccToTwitterSignal
{
    // 1. define an error
    NSError * accessError = [NSError errorWithDomain:RWTwitterInstantDomain  code:ZETwitterInstantErrorAccessDenied  userInfo:nil];
    
    // 2.create signal
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 3 - request access to twitter
        @strongify(self)
        [self.accountStore requestAccessToAccountsWithType:self.twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
            
             // 4 - handle the response
            if (!granted) {
                [subscriber sendError:accessError];
            }else
            {
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }
        }];
        return  nil;
    }];
    
    
}


- (BOOL)isvalidSearchText:(NSString*)text
{
    return text.length > 3;
}

- (SLRequest *)requestforTwitterSearchWithText:(NSString *)text {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSDictionary *params = @{@"q" : text};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET
        URL:url parameters:params];
    return request; 
}

- (RACSignal*)signalForSearchWithText:(NSString *)text
{
    // 1.define an error
    NSError *noAccountsError = [NSError errorWithDomain:RWTwitterInstantDomain   code:ZETwitterInstantErrorNoTwitterAccounts userInfo:nil];
    
    // 2 - create the signal block
    @weakify(self) ;
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self);
        
        // 3 - create the request
        SLRequest *request = [self requestforTwitterSearchWithText:text];
        
        // 4 - supply a twitter account
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterAccountType];         if (twitterAccounts.count == 0) {
            [subscriber sendError:noAccountsError];
        } else {
            [request setAccount:[twitterAccounts lastObject]];}
        // 5 - perform the request
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (urlResponse.statusCode == 200)
            {
                // 6 - on success, parse the response
                NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData  options:NSJSONReadingAllowFragments error:nil];
                [subscriber sendNext:timelineData];
                [subscriber sendCompleted];
            }else{
                // 7 - send an error on failure
                [subscriber sendError:error];
            }
        }];
        return  nil;
    }];
}
@end
