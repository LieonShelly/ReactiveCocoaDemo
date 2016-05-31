//
//  ViewController.m
//  ReacttiveCocoaDemo
//
//  Created by apple on 16/5/30.
//  Copyright © 2016年 lieon. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"


typedef void(^singalResponse)(BOOL);

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UIButton *signBtn;

@end

@implementation ViewController

- (IBAction)signBtnClick:(id)sender
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // 1.监听文本框的输入
//    [self text1];
    
    // 2.监听文本框的输入，并设置过滤条件
//    [self test2];
    
    // 3.事件类型转换
//    [self test3];
    
    // 练习一: 响应式的登录
      [self test5];
    
}


/**
 *  监听文本框的输入
 */
- (void)text1
{
    [self.userNameTextField.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

/**
 *  监听文本框的输入，并设置过滤条件
 */
- (void)test2
{
    [[self.userNameTextField.rac_textSignal
      
      // 2.1 设置过滤条件(filter操作的输出也是RACSignal)
      filter:^BOOL(id value) {
          NSString * text = value;
          
          // 返回过滤条件
          return text.length > 3;
      }]
     
     // 2.2 设置next事件(当满足过滤添加时，才执行next事件)
     subscribeNext:^(id x) {
         NSLog(@"%@",x);
     }];
}

/**
 *  事件类型类型转换
 */
- (void)test3
{
    [[[self.userNameTextField.rac_textSignal
       
    // 将字符串转换为NSNumber
    map:^id(NSString * text) {
        return @(text.length);
    }]
      
    // 设置map信号的过滤条件
    filter:^BOOL(NSNumber * length) {
        return length.integerValue > 3;
    }]
     
     // 设置fileter 信号的next事件
    subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

/**
 *  事件类型转换 --- 例子
 */
- (void)test4
{
    // 1. 设置起始信号
    
    
    RACSignal * validPwdSingle = [self.pwdTextField.rac_textSignal
      
                                  
      map:^NSNumber* (NSString * text) {
          NSLog(@"isValidPassword--%@",[self isValidPassword:text]);
          return [self isValidPassword:text];
      }];

    // 转换起始信号
    [[validPwdSingle
      
      // 此时的map的返回值是个UIColor，输入next中
      map:^UIColor* (NSNumber  * validPwd) {
          return validPwd.boolValue ? [UIColor clearColor] : [UIColor grayColor];
      }]
     
     // next事件
     subscribeNext:^(UIColor * color) {
         self.pwdTextField.backgroundColor = color;
     }];
}


/**
 *  响应式的登录
 */

- (void)test5
{
    // 1.创建有效状态信号
    RACSignal * validUserNameSingle = [self.userNameTextField.rac_textSignal

   // map操作通过block改变了事件的数据。map从上一个next事件接收数据，通过执行block把返回值传给下一个next事件
       map:^NSNumber* (NSString * text){
           return [self isValidUsername:text];
       }];
    
    RACSignal * validPwdSingle = [self.pwdTextField.rac_textSignal
                                  
      map:^NSNumber* (NSString * text) {
          NSLog(@"isValidPassword--%@",[self isValidPassword:text]);
          return [self isValidPassword:text];
      }];
    
    /**
     *  RAC宏允许直接把信号的输出应用到对象的属性上。RAC宏有两个参数，第一个是需要设置属性值的对象，第二个是属性名。每次信号产生一个next事件，传递过来的值都会应用到该属性上
     */
    RAC(self.userNameTextField,backgroundColor) = [validUserNameSingle map:^id(NSNumber * value) {
        return value.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.pwdTextField,backgroundColor) =
    [validPwdSingle map:^id(NSNumber * value) {
        
        return value.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    // combineLatest:reduce:方法把validUsernameSignal和validPasswordSignal产生的最新的值聚合在一起，并生成一个新的信号。每次这两个源信号的任何一个产生新值时，reduce block都会执行，block的返回值会发给下一个信号。
   
    // 2. 聚合信号
    RACSignal * signupActiveSingal =
    
    [RACSignal combineLatest:@[validPwdSingle,validUserNameSingle] reduce:^id(NSNumber * usernameValid,NSNumber * userpwdValid){
        
        return @(userpwdValid.boolValue && usernameValid.boolValue);
    }];
    
   //3. 用signupActiveSingle把信号和按钮的enabled属性绑定
    
  //这些改动的结果就是，代码中没有用来表示两个输入框有效状态的私有属性了。这就是用响应式编程的一个关键区别，你不需要使用实例变量来追踪瞬时状态
    [signupActiveSingal subscribeNext:^(NSNumber * signupActive) {
        self.signBtn.enabled = signupActive.boolValue;
    }];
    
    // 4.为按钮添加响应事件
    [[[[self.signBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
      
       // 添加附加操作
      doNext:^(id x) {
          self.signBtn.enabled = NO;
          
      } ]
      
    // 一个外部信号里面还有一个内部信号(signInSingal 返回的是一个RACSignal，我们要的是RACSignal内部的Bool信号)
    flattenMap:^RACStream *(id value) {
        
        NSLog(@"flattenMap--%@",[self signInSingal]);
        return [self signInSingal];
        
    }]
     
    subscribeNext:^(NSNumber * signup) {
        
        BOOL success = signup.boolValue;
        if (success) {
            [self performSegueWithIdentifier:@"a" sender:nil];
        }
    }];
    
}

/**
 *  创建一个使用用户名和密码登录的信号
 */
- (RACSignal*)signInSingal
{
    // 创建信号
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self signupWithUsername:self.userNameTextField.text password:self.pwdTextField.text complete:^(BOOL success ) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        
        return nil;
    }];
    
}

- (void)signupWithUsername:(NSString*)username password:(NSString*)pwd complete:(singalResponse)comepleteBlock
{
    double time = 2.0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL success = [username isEqualToString:@"123456" ]&& [pwd isEqualToString:@"1234567"];
        if (comepleteBlock) {
            comepleteBlock(success);
        }
    });
}

- (NSNumber *)isValidUsername:(NSString*)tesxt
{
    return @(tesxt.length > 3);
}

- (NSNumber *)isValidPassword:(NSString*)text
{
    NSLog(@"%@",@(text.length > 6));
    return @(text.length > 6);
}


@end
