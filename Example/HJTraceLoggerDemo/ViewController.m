//
//  ViewController.m
//  HJTraceLoggerDemo
//
//  Created by navy on 2021/8/16.
//

#import "ViewController.h"
#import <HJTraceLogger/HJTraceLogger.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom;
    }
    
    UIButton *btn2 = [self createButton:CGRectMake(CGRectGetWidth(self.view.frame) * 0.5 - 30, CGRectGetHeight(self.view.frame) - 60 - bottom, 60.0, 60.0)];
    btn2.backgroundColor = [UIColor redColor];
    [btn2 addTarget:self action:@selector(doTest:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
}

- (UIButton *)createButton:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitle:@"测试" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    btn.exclusiveTouch = YES;
    return btn;
}

#pragma mark - Action

- (void)doTest:(id)sender {
    TLogFile(@"INFO 测试:  您正在使用 iOS 远程日志查看服务！");
    TLogFile_WARNING(@"WARNING 测试:  您正在使用 iOS 远程日志查看服务！");
    TLogFile_ERROR(@"ERROR 测试:  您正在使用 iOS 远程日志查看服务！");
    
    [SVProgressHUD show];
    [HJTraceLoggerManager uploadLog:self
                         completion:^(NSString * _Nonnull zipPath) {
        NSLog(@"zipPath = %@", zipPath);
        [SVProgressHUD dismiss];
        if (!zipPath) {
            [SVProgressHUD showErrorWithStatus:@"Zip file fail"];
        }
    }];
}

@end
