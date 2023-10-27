//
//  AppDelegate.mm
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
    NSString *pubKey = @"572d1e2710ae5fbca54c76a382fdd44050b3a675cb2bf39feebe85ef63d947aff0fa4943f1112e8b6af34bebebbaefa1a0aae055d9259b89a1858f7cc9af9df1";
//    NSString *privKey = @"145aa7717bf9745b91e9569b80bbf1eedaa6cc6cd0e26317d810e35710f44cf8";
    [HJTraceLoggerManager setupLog:@"" pubKey:pubKey];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    ViewController *vc = [[ViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [HJTraceLoggerManager closeLog];
}

@end
