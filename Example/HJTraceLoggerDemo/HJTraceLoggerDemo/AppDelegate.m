//
//  AppDelegate.m
//  HJTraceLoggerDemo
//
//  Created by navy on 2021/8/16.
//

#import "AppDelegate.h"
#import <HJTraceLogger/HJTraceLogger.h>
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [HJTraceLoggerManager start];
    XLOG_INFO(@"您正在使用 iOS 远程日志查看服务！");
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    ViewController *vc = [[ViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
