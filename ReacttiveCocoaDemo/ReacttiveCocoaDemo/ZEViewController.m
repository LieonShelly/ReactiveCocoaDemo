//
//  ZEViewController.m
//  ReacttiveCocoaDemo
//
//  Created by apple on 16/6/1.
//  Copyright © 2016年 lieon. All rights reserved.
//

#import "ZEViewController.h"
#import "ReactiveCocoa.h"

@interface ZEViewController ()
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

@property (weak, nonatomic) IBOutlet UILabel *inptutLabel;
@end

@implementation ZEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    RAC(self.inptutLabel,text) = self.inputTextField.rac_textSignal;
    
    
}

@end
